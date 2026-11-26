#include "cellular_link.h"
#include <string.h>
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/portmacro.h"
static portMUX_TYPE s_lock = portMUX_INITIALIZER_UNLOCKED;
static er_cellular_status_t s_status;
static bool s_initialized;
static bool transition_allowed(er_cellular_state_t from, er_cellular_state_t to)
{
    if (to == ER_CELLULAR_FAULT) return from != ER_CELLULAR_FAULT;
    switch (from) {
    case ER_CELLULAR_OFF: return to == ER_CELLULAR_POWERING;
    case ER_CELLULAR_POWERING: return to == ER_CELLULAR_SIM_CHECK || to == ER_CELLULAR_OFF;
    case ER_CELLULAR_SIM_CHECK: return to == ER_CELLULAR_REGISTERING || to == ER_CELLULAR_DEGRADED || to == ER_CELLULAR_OFF;
    case ER_CELLULAR_REGISTERING: return to == ER_CELLULAR_PDP_CONNECTING || to == ER_CELLULAR_DEGRADED || to == ER_CELLULAR_OFF;
    case ER_CELLULAR_PDP_CONNECTING: return to == ER_CELLULAR_ONLINE || to == ER_CELLULAR_DEGRADED || to == ER_CELLULAR_REGISTERING || to == ER_CELLULAR_OFF;
    case ER_CELLULAR_ONLINE: return to == ER_CELLULAR_DEGRADED || to == ER_CELLULAR_REGISTERING || to == ER_CELLULAR_OFF;
    case ER_CELLULAR_DEGRADED: return to == ER_CELLULAR_REGISTERING || to == ER_CELLULAR_PDP_CONNECTING || to == ER_CELLULAR_ONLINE || to == ER_CELLULAR_OFF;
    case ER_CELLULAR_FAULT: return to == ER_CELLULAR_OFF;
    default: return false;
    }
}
esp_err_t er_cellular_link_init(void)
{
    taskENTER_CRITICAL(&s_lock);
    memset(&s_status, 0, sizeof(s_status));
    s_status.state = ER_CELLULAR_OFF;
    s_status.signal_quality = -1;
    s_status.state_changed_us = esp_timer_get_time();
    s_initialized = true;
    taskEXIT_CRITICAL(&s_lock);
    return ESP_OK;
}
esp_err_t er_cellular_link_transition(er_cellular_state_t next_state, int last_error)
{
    if (next_state < ER_CELLULAR_OFF || next_state > ER_CELLULAR_FAULT) return ESP_ERR_INVALID_ARG;
    taskENTER_CRITICAL(&s_lock);
    if (!s_initialized) { taskEXIT_CRITICAL(&s_lock); return ESP_ERR_INVALID_STATE; }
    if (!transition_allowed(s_status.state, next_state)) { taskEXIT_CRITICAL(&s_lock); return ESP_ERR_INVALID_STATE; }
    s_status.state = next_state;
    s_status.last_error = last_error;
    s_status.state_changed_us = esp_timer_get_time();
    if (next_state == ER_CELLULAR_OFF || next_state == ER_CELLULAR_FAULT) {
        s_status.sim_ready = false; s_status.packet_data_ready = false; s_status.signal_quality = -1;
    }
    if (next_state != ER_CELLULAR_ONLINE) s_status.packet_data_ready = false;
    taskEXIT_CRITICAL(&s_lock);
    return ESP_OK;
}
esp_err_t er_cellular_link_set_observations(bool sim_ready, bool packet_data_ready, int signal_quality)
{
    if (signal_quality < -1) return ESP_ERR_INVALID_ARG;
    taskENTER_CRITICAL(&s_lock);
    if (!s_initialized) { taskEXIT_CRITICAL(&s_lock); return ESP_ERR_INVALID_STATE; }
    if (packet_data_ready && s_status.state != ER_CELLULAR_ONLINE) {
        taskEXIT_CRITICAL(&s_lock); return ESP_ERR_INVALID_STATE;
    }
    s_status.sim_ready = sim_ready;
    s_status.packet_data_ready = packet_data_ready;
    s_status.signal_quality = signal_quality;
    taskEXIT_CRITICAL(&s_lock);
    return ESP_OK;
}
esp_err_t er_cellular_link_get_status(er_cellular_status_t *out_status)
{
    if (!out_status) return ESP_ERR_INVALID_ARG;
    taskENTER_CRITICAL(&s_lock);
    if (!s_initialized) { taskEXIT_CRITICAL(&s_lock); return ESP_ERR_INVALID_STATE; }
    *out_status = s_status;
    taskEXIT_CRITICAL(&s_lock);
    return ESP_OK;
}
const char *er_cellular_state_name(er_cellular_state_t state)
{
    switch (state) {
    case ER_CELLULAR_OFF: return "OFF";
    case ER_CELLULAR_POWERING: return "POWERING";
    case ER_CELLULAR_SIM_CHECK: return "SIM_CHECK";
    case ER_CELLULAR_REGISTERING: return "REGISTERING";
    case ER_CELLULAR_PDP_CONNECTING: return "PDP_CONNECTING";
    case ER_CELLULAR_ONLINE: return "ONLINE";
    case ER_CELLULAR_DEGRADED: return "DEGRADED";
    case ER_CELLULAR_FAULT: return "FAULT";
    default: return "UNKNOWN";
    }
}
