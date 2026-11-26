#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_system.h"
#include "system_state.h"
#include "gnss_uart.h"

static const char *TAG = "edu_ride";

static void supervisor_task(void *arg)
{
    (void)arg;
    er_state_set(ER_STATE_INITIALIZING);
    ESP_LOGI(TAG, "Supervisor started; unverified board I/O remains disabled.");
#if CONFIG_ER_ENABLE_GNSS_UART
    esp_err_t gnss_err = er_gnss_uart_start();
    if (gnss_err == ESP_OK) {
        ESP_LOGI(TAG, "GNSS UART started; waiting for a validated receiver fix.");
    } else {
        ESP_LOGE(TAG, "GNSS UART startup failed: %s", esp_err_to_name(gnss_err));
    }
#else
    ESP_LOGI(TAG, "GNSS UART is disabled by configuration.");
#endif
    ESP_LOGI(TAG, "Cellular modem driver remains disabled pending module selection.");
    er_state_set(ER_STATE_DEGRADED);
    for (;;) {
        er_gnss_snapshot_t fix = {0};
        if (er_gnss_uart_get_snapshot(&fix) == ESP_OK && fix.fix_valid) {
            ESP_LOGI(TAG, "GNSS fix available; satellites=%u HDOP=%.1f",
                     (unsigned)fix.satellites, fix.hdop);
        }
        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "Edu Ride controller boot; reset reason=%d",
             (int)esp_reset_reason());
    er_state_set(ER_STATE_BOOT);
    if (xTaskCreate(supervisor_task, "supervisor", 4096, NULL, 5, NULL) != pdPASS) {
        ESP_LOGE(TAG, "Supervisor task creation failed");
        er_state_set(ER_STATE_FAULT);
    }
}
