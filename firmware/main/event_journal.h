#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ER_EVENT_ID_HEX_LEN 32
#define ER_EVENT_DEVICE_ID_MAX 40
#define ER_EVENT_TRIP_ID_MAX 40
#define ER_EVENT_FIRMWARE_MAX 24
#define ER_EVENT_HW_REV_MAX 24
#define ER_EVENT_PAYLOAD_MAX 192
#define ER_EVENT_QUEUE_CAPACITY 32

typedef enum {
    ER_DEVICE_VARIANT_UNKNOWN = 0,
    ER_DEVICE_VARIANT_VISION_GPS = 1,
    ER_DEVICE_VARIANT_GPS_ONLY = 2
} er_device_variant_t;

typedef enum {
    ER_TIME_UNSYNCED = 0,
    ER_TIME_RTC = 1,
    ER_TIME_GNSS = 2,
    ER_TIME_NETWORK = 3
} er_time_quality_t;

typedef enum {
    ER_EVENT_BOOT = 1,
    ER_EVENT_TRIP_STARTED,
    ER_EVENT_TRIP_ENDED,
    ER_EVENT_STUDENT_BOARDING_MATCHED,
    ER_EVENT_STUDENT_BOARDING_UNCERTAIN,
    ER_EVENT_STUDENT_BOARDING_UNMATCHED,
    ER_EVENT_DRIVER_PICKUP_CONFIRMED,
    ER_EVENT_DRIVER_NEXT_STOP,
    ER_EVENT_DEVICE_HEALTH,
    ER_EVENT_DEVICE_FAULT
} er_event_type_t;

typedef struct {
    char device_id[ER_EVENT_DEVICE_ID_MAX];
    char trip_id[ER_EVENT_TRIP_ID_MAX];
    char firmware_version[ER_EVENT_FIRMWARE_MAX];
    char hardware_revision[ER_EVENT_HW_REV_MAX];
    er_device_variant_t variant;
} er_event_identity_t;

typedef struct {
    uint32_t schema_version;
    uint64_t sequence;
    char event_id[ER_EVENT_ID_HEX_LEN + 1];
    char device_id[ER_EVENT_DEVICE_ID_MAX];
    char trip_id[ER_EVENT_TRIP_ID_MAX];
    char firmware_version[ER_EVENT_FIRMWARE_MAX];
    char hardware_revision[ER_EVENT_HW_REV_MAX];
    er_device_variant_t variant;
    er_event_type_t type;
    int64_t utc_time_ms;       /* 0 when wall clock is not trusted */
    int64_t monotonic_time_us; /* ESP timer; valid only within this boot */
    er_time_quality_t time_quality;
    char payload[ER_EVENT_PAYLOAD_MAX]; /* bounded, non-sensitive metadata */
    uint32_t crc32;
} er_event_record_t;

/*
 * Prototype persistent journal backed by ESP-IDF NVS.
 * Capacity is deliberately bounded. NVS is suitable for low-rate metadata
 * events only; production/high-volume logging should move to a qualified
 * SD/FAT or dedicated append-only storage implementation.
 */
esp_err_t er_event_journal_init(const er_event_identity_t *identity);
esp_err_t er_event_journal_enqueue(er_event_type_t type,
                                   const char *trip_id,
                                   int64_t utc_time_ms,
                                   er_time_quality_t time_quality,
                                   const char *payload,
                                   er_event_record_t *created);
esp_err_t er_event_journal_peek(er_event_record_t *event);
esp_err_t er_event_journal_ack(const char *event_id);
esp_err_t er_event_journal_count(size_t *count);
esp_err_t er_event_journal_clear_for_factory_reset(void);

#ifdef __cplusplus
}
#endif
