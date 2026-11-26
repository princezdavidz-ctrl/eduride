#include "gnss_uart.h"

#include <string.h>
#include "board_pins.h"
#include "driver/uart.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "gnss_parser.h"

static const char *TAG = "er_gnss_uart";
#define ER_GNSS_UART_PORT UART_NUM_1
#define ER_GNSS_RX_BUFFER 2048
#define ER_GNSS_TASK_STACK 4096

static bool s_running;

static void gnss_reader_task(void *arg)
{
    (void)arg;
    uint8_t chunk[128];
    char line[ER_GNSS_LINE_MAX];
    size_t used = 0;
    bool discarding_overlong = false;
    for (;;) {
        int count = uart_read_bytes(ER_GNSS_UART_PORT, chunk, sizeof(chunk),
                                    pdMS_TO_TICKS(250));
        if (count < 0) {
            ESP_LOGW(TAG, "GNSS UART read error");
            vTaskDelay(pdMS_TO_TICKS(500));
            continue;
        }
        for (int i = 0; i < count; ++i) {
            if (chunk[i] == '\n') {
                if (!discarding_overlong && used > 0)
                    (void)er_gnss_parser_feed(line, used, esp_timer_get_time());
                used = 0;
                discarding_overlong = false;
            } else if (chunk[i] != '\r' && !discarding_overlong) {
                if (used < sizeof(line) - 1) line[used++] = (char)chunk[i];
                else { used = 0; discarding_overlong = true; }
            }
        }
    }
}

esp_err_t er_gnss_uart_start(void)
{
#if !CONFIG_ER_ENABLE_GNSS_UART
    return ESP_ERR_NOT_SUPPORTED;
#else
    if (s_running) return ESP_ERR_INVALID_STATE;
    esp_err_t parser_err = er_gnss_parser_init();
    if (parser_err != ESP_OK) return parser_err;
    const uart_config_t config = {
        .baud_rate = CONFIG_ER_GNSS_UART_BAUD,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT
    };
    esp_err_t err = uart_driver_install(ER_GNSS_UART_PORT, ER_GNSS_RX_BUFFER,
                                        0, 0, NULL, 0);
    if (err != ESP_OK) return err;
    err = uart_param_config(ER_GNSS_UART_PORT, &config);
    if (err == ESP_OK) err = uart_set_pin(ER_GNSS_UART_PORT,
        ER_GPIO_GNSS_TX, ER_GPIO_GNSS_RX, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    if (err != ESP_OK) {
        uart_driver_delete(ER_GNSS_UART_PORT);
        return err;
    }
    if (xTaskCreate(gnss_reader_task, "er_gnss", ER_GNSS_TASK_STACK,
                    NULL, 6, NULL) != pdPASS) {
        uart_driver_delete(ER_GNSS_UART_PORT);
        return ESP_ERR_NO_MEM;
    }
    s_running = true;
    ESP_LOGI(TAG, "GNSS UART reader started on UART1 at %d baud",
             CONFIG_ER_GNSS_UART_BAUD);
    return ESP_OK;
#endif
}

bool er_gnss_uart_is_running(void) { return s_running; }

esp_err_t er_gnss_uart_get_snapshot(er_gnss_snapshot_t *snapshot)
{
    if (snapshot == NULL) return ESP_ERR_INVALID_ARG;
    if (!s_running) return ESP_ERR_INVALID_STATE;
    er_gnss_parser_get_snapshot(snapshot);
    const int64_t now_us = esp_timer_get_time();
    if (snapshot->received_monotonic_us <= 0 ||
        now_us - snapshot->received_monotonic_us > 5000000) {
        snapshot->fix_valid = false;
    }
    return ESP_OK;
}
