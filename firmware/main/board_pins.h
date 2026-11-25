#pragma once

/*
 * Edu Ride controller pin definitions.
 *
 * Derived from the ESP32-S3-WROOM-1-N16R8 module land-to-GPIO map and
 * the PCB schematic net assignments. Definitions only: this header does
 * not configure pins or authorize hardware activation. Verify the assembled
 * PCB revision and electrical characteristics before initializing GPIO.
 */

#include "driver/gpio.h"

#define ER_GPIO_BUZZER_CTRL       GPIO_NUM_4
#define ER_GPIO_I2C_SDA           GPIO_NUM_5
#define ER_GPIO_I2C_SCL           GPIO_NUM_6
#define ER_GPIO_DISPLAY_RX        GPIO_NUM_7
#define ER_GPIO_MODEM_TX          GPIO_NUM_15
#define ER_GPIO_MODEM_RX          GPIO_NUM_16
#define ER_GPIO_GNSS_TX           GPIO_NUM_17
#define ER_GPIO_GNSS_RX           GPIO_NUM_18
#define ER_GPIO_DISPLAY_TX        GPIO_NUM_8
#define ER_GPIO_USB_DM            GPIO_NUM_19
#define ER_GPIO_USB_DP            GPIO_NUM_20
#define ER_GPIO_LED_GNSS          GPIO_NUM_9
#define ER_GPIO_LED_NETWORK       GPIO_NUM_10
#define ER_GPIO_SD_MOSI           GPIO_NUM_11
#define ER_GPIO_SD_SCK            GPIO_NUM_12
#define ER_GPIO_SD_MISO           GPIO_NUM_13
#define ER_GPIO_SD_CS             GPIO_NUM_14
#define ER_GPIO_LED_STATUS        GPIO_NUM_21
#define ER_GPIO_BUTTON_MENU_BACK  GPIO_NUM_48
#define ER_GPIO_MODEM_PWRKEY      GPIO_NUM_38
#define ER_GPIO_MODEM_RESET       GPIO_NUM_39
#define ER_GPIO_MODEM_STATUS      GPIO_NUM_40
#define ER_GPIO_GNSS_PPS          GPIO_NUM_41
#define ER_GPIO_GNSS_RESET        GPIO_NUM_42
#define ER_GPIO_DEBUG_RX          GPIO_NUM_44
#define ER_GPIO_DEBUG_TX          GPIO_NUM_43
#define ER_GPIO_BUTTON_NEXT_STOP  GPIO_NUM_2
#define ER_GPIO_BUTTON_PICKUP     GPIO_NUM_1

/* GPIO19/20 are native USB. Do not repurpose while USB is enabled. */
/* GPIO43/44 are UART0. Console routing must be configured deliberately. */
/* GPIO0 is a board-level boot strap connection (U1 module pad 27). */
