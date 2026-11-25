#include "driver_ui.h"

#include "sdkconfig.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "board_pins.h"

static const char *TAG = "er_driver_ui";

#if CONFIG_ER_ENABLE_DRIVER_UI

#define ER_BUTTON_SAMPLE_MS       10
#define ER_BUTTON_DEBOUNCE_MS     30
#define ER_DRIVER_EVENT_QUEUE_LEN 16
#define ER_DRIVER_UI_TASK_STACK   3072
#define ER_DRIVER_UI_TASK_PRIO    4

typedef struct {
    gpio_num_t gpio;
    er_driver_event_type_t event;
    bool stable_level;
    bool last_sample;
    uint32_t equal_samples;
} button_state_t;

static QueueHandle_t s_events;

static button_state_t s_buttons[] = {
    { ER_GPIO_BUTTON_PICKUP, ER_DRIVER_EVENT_PICKUP_CONFIRM, true, true, 0 },
    { ER_GPIO_BUTTON_NEXT_STOP, ER_DRIVER_EVENT_NEXT_STOP, true, true, 0 },
    { ER_GPIO_BUTTON_MENU_BACK, ER_DRIVER_EVENT_MENU_BACK, true, true, 0 },
};

static esp_err_t configure_inputs(void)
{
    const gpio_config_t cfg = {
        .pin_bit_mask = (1ULL << ER_GPIO_BUTTON_PICKUP) |
                        (1ULL << ER_GPIO_BUTTON_NEXT_STOP) |
                        (1ULL << ER_GPIO_BUTTON_MENU_BACK),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    return gpio_config(&cfg);
}

static esp_err_t configure_leds(void)
{
    const gpio_config_t cfg = {
        .pin_bit_mask = (1ULL << ER_GPIO_LED_GNSS) |
                        (1ULL << ER_GPIO_LED_NETWORK) |
                        (1ULL << ER_GPIO_LED_STATUS),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    esp_err_t err = gpio_config(&cfg);
    if (err != ESP_OK) return err;

    /* LEDs are active-high in the current schematic. Start all off. */
    if ((err = gpio_set_level(ER_GPIO_LED_GNSS, 0)) != ESP_OK) return err;
    if ((err = gpio_set_level(ER_GPIO_LED_NETWORK, 0)) != ESP_OK) return err;
    return gpio_set_level(ER_GPIO_LED_STATUS, 0);
}

static void button_task(void *arg)
{
    (void)arg;
    const uint32_t required_samples = ER_BUTTON_DEBOUNCE_MS / ER_BUTTON_SAMPLE_MS;

    for (;;) {
        for (size_t i = 0; i < (sizeof(s_buttons) / sizeof(s_buttons[0])); ++i) {
            button_state_t *button = &s_buttons[i];
            const bool sample = gpio_get_level(button->gpio) != 0;

            if (sample == button->last_sample) {
                if (button->equal_samples < required_samples) {
                    button->equal_samples++;
                }
            } else {
                button->last_sample = sample;
                button->equal_samples = 1;
            }

            if (button->equal_samples >= required_samples &&
                sample != button->stable_level) {
                button->stable_level = sample;

                /* Buttons are wired to GND: a stable low level is a press. */
                if (!sample) {
                    const er_driver_event_t event = {
                        .type = button->event,
                        .monotonic_time_us = esp_timer_get_time(),
                    };
                    if (xQueueSend(s_events, &event, pdMS_TO_TICKS(100)) != pdPASS) {
                        ESP_LOGE(TAG, "Driver event queue full; event %d not queued",
                                 (int)event.type);
                    }
                }
            }
        }
        vTaskDelay(pdMS_TO_TICKS(ER_BUTTON_SAMPLE_MS));
    }
}

esp_err_t er_driver_ui_start(void)
{
    if (s_events != NULL) return ESP_ERR_INVALID_STATE;

    s_events = xQueueCreate(ER_DRIVER_EVENT_QUEUE_LEN, sizeof(er_driver_event_t));
    if (s_events == NULL) return ESP_ERR_NO_MEM;

    esp_err_t err = configure_inputs();
    if (err != ESP_OK) {
        vQueueDelete(s_events);
        s_events = NULL;
        return err;
    }

    err = configure_leds();
    if (err != ESP_OK) {
        vQueueDelete(s_events);
        s_events = NULL;
        return err;
    }

    if (xTaskCreate(button_task, "er_buttons", ER_DRIVER_UI_TASK_STACK,
                    NULL, ER_DRIVER_UI_TASK_PRIO, NULL) != pdPASS) {
        vQueueDelete(s_events);
        s_events = NULL;
        return ESP_ERR_NO_MEM;
    }

    ESP_LOGW(TAG, "Driver UI enabled: confirm PCB revision and electrical checks before field use");
    return ESP_OK;
}

esp_err_t er_driver_ui_wait_event(er_driver_event_t *event, uint32_t timeout_ms)
{
    if (event == NULL || s_events == NULL) return ESP_ERR_INVALID_STATE;
    const TickType_t wait = timeout_ms == UINT32_MAX
        ? portMAX_DELAY : pdMS_TO_TICKS(timeout_ms);
    return xQueueReceive(s_events, event, wait) == pdPASS
        ? ESP_OK : ESP_ERR_TIMEOUT;
}

esp_err_t er_driver_ui_set_leds(bool gps, bool network, bool status)
{
    if (s_events == NULL) return ESP_ERR_INVALID_STATE;
    esp_err_t err = gpio_set_level(ER_GPIO_LED_GNSS, gps ? 1 : 0);
    if (err != ESP_OK) return err;
    err = gpio_set_level(ER_GPIO_LED_NETWORK, network ? 1 : 0);
    if (err != ESP_OK) return err;
    return gpio_set_level(ER_GPIO_LED_STATUS, status ? 1 : 0);
}

#else

esp_err_t er_driver_ui_start(void)
{
    ESP_LOGI(TAG, "Driver UI disabled by default; enable only after electrical review");
    return ESP_ERR_NOT_SUPPORTED;
}

esp_err_t er_driver_ui_wait_event(er_driver_event_t *event, uint32_t timeout_ms)
{
    (void)event;
    (void)timeout_ms;
    return ESP_ERR_NOT_SUPPORTED;
}

esp_err_t er_driver_ui_set_leds(bool gps, bool network, bool status)
{
    (void)gps;
    (void)network;
    (void)status;
    return ESP_ERR_NOT_SUPPORTED;
}

#endif
