#pragma once
#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef enum {
    ER_CELLULAR_OFF = 0, ER_CELLULAR_POWERING, ER_CELLULAR_SIM_CHECK,
    ER_CELLULAR_REGISTERING, ER_CELLULAR_PDP_CONNECTING, ER_CELLULAR_ONLINE,
    ER_CELLULAR_DEGRADED, ER_CELLULAR_FAULT
} er_cellular_state_t;
typedef struct {
    er_cellular_state_t state;
    int last_error;
    int signal_quality; /* -1 means unknown; no modem-specific scale is assumed. */
    bool sim_ready;
    bool packet_data_ready;
    int64_t state_changed_us;
} er_cellular_status_t;
/* Status/lifecycle contract only: no UART, AT commands, APN, PWRKEY or RESET I/O. */
esp_err_t er_cellular_link_init(void);
esp_err_t er_cellular_link_transition(er_cellular_state_t next_state, int last_error);
esp_err_t er_cellular_link_set_observations(bool sim_ready, bool packet_data_ready, int signal_quality);
esp_err_t er_cellular_link_get_status(er_cellular_status_t *out_status);
const char *er_cellular_state_name(er_cellular_state_t state);
#ifdef __cplusplus
}
#endif
