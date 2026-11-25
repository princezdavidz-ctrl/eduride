#include "event_journal.h"

#include <stdio.h>
#include <string.h>

#include "esp_crc.h"
#include "esp_log.h"
#include "esp_random.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "nvs.h"
#include "nvs_flash.h"

#define ER_NVS_NAMESPACE "er_events"
#define ER_NVS_SEQ_KEY "next_seq"
#define ER_SLOT_PREFIX 's'
#define ER_RECORD_SCHEMA 1U

static const char *TAG = "er_event_journal";
static er_event_identity_t s_identity;
static SemaphoreHandle_t s_lock;
static bool s_initialized;

static void make_slot_key(size_t slot, char key[5])
{
    (void)snprintf(key, 5, "%c%02u", ER_SLOT_PREFIX, (unsigned)slot);
}

static uint32_t record_crc(const er_event_record_t *record)
{
    return esp_crc32_le(0, (const uint8_t *)record,
                        offsetof(er_event_record_t, crc32));
}

static bool record_valid(const er_event_record_t *record)
{
    return record->schema_version == ER_RECORD_SCHEMA &&
           record->sequence > 0 &&
           record->event_id[ER_EVENT_ID_HEX_LEN] == '\0' &&
           record->crc32 == record_crc(record);
}

static esp_err_t open_nvs(nvs_handle_t *handle)
{
    return nvs_open(ER_NVS_NAMESPACE, NVS_READWRITE, handle);
}

static esp_err_t read_slot(nvs_handle_t handle, size_t slot,
                           er_event_record_t *record)
{
    char key[5];
    size_t size = sizeof(*record);
    make_slot_key(slot, key);
    esp_err_t err = nvs_get_blob(handle, key, record, &size);
    if (err == ESP_OK && size != sizeof(*record)) return ESP_ERR_INVALID_SIZE;
    if (err == ESP_OK && !record_valid(record)) return ESP_ERR_INVALID_CRC;
    return err;
}

static esp_err_t find_free_slot(nvs_handle_t handle, size_t *free_slot)
{
    for (size_t i = 0; i < ER_EVENT_QUEUE_CAPACITY; ++i) {
        er_event_record_t record;
        esp_err_t err = read_slot(handle, i, &record);
        if (err == ESP_ERR_NVS_NOT_FOUND || err == ESP_ERR_INVALID_CRC ||
            err == ESP_ERR_INVALID_SIZE) {
            *free_slot = i;
            return ESP_OK;
        }
        if (err != ESP_OK) return err;
    }
    return ESP_ERR_NO_MEM;
}

static esp_err_t find_oldest(nvs_handle_t handle,
                             er_event_record_t *oldest,
                             size_t *oldest_slot,
                             size_t *count)
{
    bool found = false;
    *count = 0;
    for (size_t i = 0; i < ER_EVENT_QUEUE_CAPACITY; ++i) {
        er_event_record_t current;
        esp_err_t err = read_slot(handle, i, &current);
        if (err == ESP_ERR_NVS_NOT_FOUND || err == ESP_ERR_INVALID_CRC ||
            err == ESP_ERR_INVALID_SIZE) continue;
        if (err != ESP_OK) return err;
        ++(*count);
        if (!found || current.sequence < oldest->sequence) {
            *oldest = current;
            *oldest_slot = i;
            found = true;
        }
    }
    return found ? ESP_OK : ESP_ERR_NOT_FOUND;
}

static void make_event_id(char out[ER_EVENT_ID_HEX_LEN + 1])
{
    uint32_t words[4];
    for (size_t i = 0; i < 4; ++i) words[i] = esp_random();
    (void)snprintf(out, ER_EVENT_ID_HEX_LEN + 1,
                   "%08lx%08lx%08lx%08lx",
                   (unsigned long)words[0], (unsigned long)words[1],
                   (unsigned long)words[2], (unsigned long)words[3]);
}

esp_err_t er_event_journal_init(const er_event_identity_t *identity)
{
    if (identity == NULL || identity->device_id[0] == '\0' ||
        identity->variant == ER_DEVICE_VARIANT_UNKNOWN) {
        return ESP_ERR_INVALID_ARG;
    }
    if (s_initialized) return ESP_ERR_INVALID_STATE;

    memcpy(&s_identity, identity, sizeof(s_identity));
    s_identity.device_id[ER_EVENT_DEVICE_ID_MAX - 1] = '\0';
    s_identity.firmware_version[ER_EVENT_FIRMWARE_MAX - 1] = '\0';
    s_identity.hardware_revision[ER_EVENT_HW_REV_MAX - 1] = '\0';
    s_lock = xSemaphoreCreateMutex();
    if (s_lock == NULL) return ESP_ERR_NO_MEM;

    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES ||
        err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_LOGE(TAG, "NVS requires maintenance; refusing automatic erase");
        vSemaphoreDelete(s_lock);
        s_lock = NULL;
        return err;
    }
    if (err != ESP_OK) {
        vSemaphoreDelete(s_lock);
        s_lock = NULL;
        return err;
    }

    nvs_handle_t handle;
    err = open_nvs(&handle);
    if (err == ESP_OK) {
        uint64_t next = 1;
        esp_err_t seq_err = nvs_get_u64(handle, ER_NVS_SEQ_KEY, &next);
        if (seq_err == ESP_ERR_NVS_NOT_FOUND) {
            err = nvs_set_u64(handle, ER_NVS_SEQ_KEY, 1);
            if (err == ESP_OK) err = nvs_commit(handle);
        } else if (seq_err != ESP_OK) {
            err = seq_err;
        }
        nvs_close(handle);
    }
    if (err != ESP_OK) {
        vSemaphoreDelete(s_lock);
        s_lock = NULL;
        return err;
    }

    s_initialized = true;
    ESP_LOGI(TAG, "Event journal ready; capacity=%u", ER_EVENT_QUEUE_CAPACITY);
    return ESP_OK;
}

esp_err_t er_event_journal_enqueue(er_event_type_t type,
                                   const char *trip_id,
                                   int64_t utc_time_ms,
                                   er_time_quality_t time_quality,
                                   const char *payload,
                                   er_event_record_t *created)
{
    if (!s_initialized || type < ER_EVENT_BOOT || type > ER_EVENT_DEVICE_FAULT ||
        time_quality < ER_TIME_UNSYNCED || time_quality > ER_TIME_NETWORK) {
        return ESP_ERR_INVALID_ARG;
    }
    if (xSemaphoreTake(s_lock, portMAX_DELAY) != pdTRUE) return ESP_ERR_TIMEOUT;

    esp_err_t err;
    nvs_handle_t handle;
    size_t slot = 0;
    err = open_nvs(&handle);
    if (err != ESP_OK) goto done;
    err = find_free_slot(handle, &slot);
    if (err != ESP_OK) goto close;

    uint64_t sequence = 1;
    err = nvs_get_u64(handle, ER_NVS_SEQ_KEY, &sequence);
    if (err != ESP_OK) goto close;
    if (sequence == UINT64_MAX) { err = ESP_ERR_INVALID_STATE; goto close; }

    /* Persist sequence first. A power loss may leave a harmless sequence gap. */
    err = nvs_set_u64(handle, ER_NVS_SEQ_KEY, sequence + 1);
    if (err == ESP_OK) err = nvs_commit(handle);
    if (err != ESP_OK) goto close;

    er_event_record_t record = {0};
    record.schema_version = ER_RECORD_SCHEMA;
    record.sequence = sequence;
    make_event_id(record.event_id);
    memcpy(record.device_id, s_identity.device_id, sizeof(record.device_id));
    if (trip_id != NULL) {
        (void)snprintf(record.trip_id, sizeof(record.trip_id), "%s", trip_id);
    }
    memcpy(record.firmware_version, s_identity.firmware_version,
           sizeof(record.firmware_version));
    memcpy(record.hardware_revision, s_identity.hardware_revision,
           sizeof(record.hardware_revision));
    record.variant = s_identity.variant;
    record.type = type;
    record.utc_time_ms = utc_time_ms > 0 ? utc_time_ms : 0;
    record.monotonic_time_us = esp_timer_get_time();
    record.time_quality = utc_time_ms > 0 ? time_quality : ER_TIME_UNSYNCED;
    if (payload != NULL) {
        (void)snprintf(record.payload, sizeof(record.payload), "%s", payload);
    }
    record.crc32 = record_crc(&record);

    char key[5];
    make_slot_key(slot, key);
    err = nvs_set_blob(handle, key, &record, sizeof(record));
    if (err == ESP_OK) err = nvs_commit(handle);
    if (err == ESP_OK && created != NULL) *created = record;

close:
    nvs_close(handle);
done:
    xSemaphoreGive(s_lock);
    return err;
}

esp_err_t er_event_journal_peek(er_event_record_t *event)
{
    if (!s_initialized || event == NULL) return ESP_ERR_INVALID_ARG;
    if (xSemaphoreTake(s_lock, portMAX_DELAY) != pdTRUE) return ESP_ERR_TIMEOUT;
    nvs_handle_t handle;
    esp_err_t err = open_nvs(&handle);
    if (err == ESP_OK) {
        size_t slot = 0, count = 0;
        err = find_oldest(handle, event, &slot, &count);
        nvs_close(handle);
    }
    xSemaphoreGive(s_lock);
    return err;
}

esp_err_t er_event_journal_ack(const char *event_id)
{
    if (!s_initialized || event_id == NULL ||
        strlen(event_id) != ER_EVENT_ID_HEX_LEN) return ESP_ERR_INVALID_ARG;
    if (xSemaphoreTake(s_lock, portMAX_DELAY) != pdTRUE) return ESP_ERR_TIMEOUT;
    nvs_handle_t handle;
    esp_err_t err = open_nvs(&handle);
    if (err == ESP_OK) {
        bool found = false;
        for (size_t i = 0; i < ER_EVENT_QUEUE_CAPACITY; ++i) {
            er_event_record_t record;
            esp_err_t read_err = read_slot(handle, i, &record);
            if (read_err == ESP_ERR_NVS_NOT_FOUND ||
                read_err == ESP_ERR_INVALID_CRC ||
                read_err == ESP_ERR_INVALID_SIZE) continue;
            if (read_err != ESP_OK) { err = read_err; break; }
            if (strcmp(record.event_id, event_id) == 0) {
                char key[5];
                make_slot_key(i, key);
                err = nvs_erase_key(handle, key);
                if (err == ESP_OK) err = nvs_commit(handle);
                found = true;
                break;
            }
        }
        if (err == ESP_OK && !found) err = ESP_ERR_NOT_FOUND;
        nvs_close(handle);
    }
    xSemaphoreGive(s_lock);
    return err;
}

esp_err_t er_event_journal_count(size_t *count)
{
    if (!s_initialized || count == NULL) return ESP_ERR_INVALID_ARG;
    if (xSemaphoreTake(s_lock, portMAX_DELAY) != pdTRUE) return ESP_ERR_TIMEOUT;
    nvs_handle_t handle;
    esp_err_t err = open_nvs(&handle);
    if (err == ESP_OK) {
        er_event_record_t oldest = {0};
        size_t slot = 0;
        err = find_oldest(handle, &oldest, &slot, count);
        if (err == ESP_ERR_NOT_FOUND) { *count = 0; err = ESP_OK; }
        nvs_close(handle);
    }
    xSemaphoreGive(s_lock);
    return err;
}

esp_err_t er_event_journal_clear_for_factory_reset(void)
{
    if (!s_initialized) return ESP_ERR_INVALID_STATE;
    if (xSemaphoreTake(s_lock, portMAX_DELAY) != pdTRUE) return ESP_ERR_TIMEOUT;
    nvs_handle_t handle;
    esp_err_t err = open_nvs(&handle);
    if (err == ESP_OK) {
        for (size_t i = 0; i < ER_EVENT_QUEUE_CAPACITY; ++i) {
            char key[5];
            make_slot_key(i, key);
            esp_err_t erase_err = nvs_erase_key(handle, key);
            if (erase_err != ESP_OK && erase_err != ESP_ERR_NVS_NOT_FOUND) {
                err = erase_err;
                break;
            }
        }
        /* Sequence deliberately retained to prevent ID/order reuse. */
        if (err == ESP_OK) err = nvs_commit(handle);
        nvs_close(handle);
    }
    xSemaphoreGive(s_lock);
    return err;
}
