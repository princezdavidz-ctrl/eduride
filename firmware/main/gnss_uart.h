#pragma once

#include <stdbool.h>
#include "esp_err.h"
#include "gnss_parser.h"

#ifdef __cplusplus
extern "C" {
#endif

/* UART GNSS is opt-in until the receiver electrical interface and baud are confirmed. */
esp_err_t er_gnss_uart_start(void);
bool er_gnss_uart_is_running(void);
esp_err_t er_gnss_uart_get_snapshot(er_gnss_snapshot_t *snapshot);

#ifdef __cplusplus
}
#endif
