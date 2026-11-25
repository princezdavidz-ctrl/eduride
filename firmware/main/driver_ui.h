#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "esp_err.h"

typedef enum {
    ER_DRIVER_EVENT_PICKUP_CONFIRM = 1,
    ER_DRIVER_EVENT_NEXT_STOP,
    ER_DRIVER_EVENT_MENU_BACK
} er_driver_event_type_t;

typedef struct {
    er_driver_event_type_t type;
    int64_t monotonic_time_us;
} er_driver_event_t;

/*
 * Driver UI bring-up is disabled by default. Enable only after board revision,
 * switch wiring, GPIO voltage levels and LED paths have been inspected.
 */
esp_err_t er_driver_ui_start(void);
esp_err_t er_driver_ui_wait_event(er_driver_event_t *event, uint32_t timeout_ms);

/* LED outputs are active-high per the current schematic; call only after review. */
esp_err_t er_driver_ui_set_leds(bool gps, bool network, bool status);
