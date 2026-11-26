#pragma once
#include <stdbool.h>
typedef enum { ER_STATE_BOOT=0, ER_STATE_INITIALIZING, ER_STATE_READY, ER_STATE_DEGRADED, ER_STATE_FAULT } er_system_state_t;
const char *er_state_name(er_system_state_t state);
void er_state_set(er_system_state_t state);
er_system_state_t er_state_get(void);
