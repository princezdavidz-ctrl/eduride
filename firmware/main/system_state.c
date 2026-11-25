#include "system_state.h"
#include "esp_log.h"
static const char *TAG="er_state";
static er_system_state_t current_state=ER_STATE_BOOT;
const char *er_state_name(er_system_state_t s){switch(s){case ER_STATE_BOOT:return "BOOT";case ER_STATE_INITIALIZING:return "INITIALIZING";case ER_STATE_READY:return "READY";case ER_STATE_DEGRADED:return "DEGRADED";case ER_STATE_FAULT:return "FAULT";default:return "UNKNOWN";}}
void er_state_set(er_system_state_t s){if(s==current_state)return;ESP_LOGI(TAG,"state: %s -> %s",er_state_name(current_state),er_state_name(s));current_state=s;}
er_system_state_t er_state_get(void){return current_state;}
