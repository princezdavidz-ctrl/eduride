# Edu Ride Firmware Pin Map — ESP32-S3-WROOM-1-N16R8

Source of truth: PCBKit project `Edu Ride Bus Tracker`, `scripts/design.py`, ESP32-S3-WROOM-1-N16R8 part definition and the schematic's U1 net assignments. The first numeric column is the **module land/pad number**; the GPIO column is the actual ESP32-S3 GPIO signal. Do not confuse the two.

| Signal | U1 module pad | ESP32-S3 GPIO | Role |
|---|---:|---:|---|
| BUZZER_CTRL | 4 | GPIO4 | Buzzer driver control |
| I2C_SDA | 5 | GPIO5 | I2C data |
| I2C_SCL | 6 | GPIO6 | I2C clock |
| DISPLAY_TO_MCU_RX | 7 | GPIO7 | Display UART receive |
| MCU_TO_MODEM_TX | 8 | GPIO15 | Modem UART transmit |
| MODEM_TO_MCU_RX | 9 | GPIO16 | Modem UART receive |
| MCU_TO_GPS_RX | 10 | GPIO17 | GNSS UART transmit |
| GPS_TO_MCU_RX | 11 | GPIO18 | GNSS UART receive |
| MCU_TO_DISPLAY_TX | 12 | GPIO8 | Display UART transmit |
| USB_DN | 13 | GPIO19 / USB_DM | Native USB D- |
| USB_DP | 14 | GPIO20 / USB_DP | Native USB D+ |
| LED_GPS | 17 | GPIO9 | GPS indicator |
| LED_NET | 18 | GPIO10 | Network indicator |
| SD_MOSI | 19 | GPIO11 | microSD SPI MOSI |
| SD_SCK | 20 | GPIO12 | microSD SPI clock |
| SD_MISO | 21 | GPIO13 | microSD SPI MISO |
| SD_CS | 22 | GPIO14 | microSD SPI chip select |
| LED_STATUS | 23 | GPIO21 | Status indicator |
| MENU_BACK | 25 | GPIO48 | Driver button input |
| MODEM_PWRKEY | 31 | GPIO38 | Modem power-key control |
| MODEM_RESET | 32 | GPIO39 | Modem reset control |
| MODEM_STATUS | 33 | GPIO40 | Modem status input |
| GPS_PPS | 34 | GPIO41 | GNSS pulse-per-second input |
| GPS_RESET | 35 | GPIO42 | GNSS reset control |
| DEBUG_RX | 36 | GPIO44 / U0RXD | Debug UART receive |
| DEBUG_TX | 37 | GPIO43 / U0TXD | Debug UART transmit |
| NEXT_STOP | 38 | GPIO2 | Driver button input |
| PICKUP_CONFIRM | 39 | GPIO1 | Driver confirmation input |

Ground: module pads 1, 40 and 41. Supply: module pad 2 (3V3).

## Connector assignments recovered from the schematic

- J2 modem: GND, MCU_TO_MODEM_TX, MODEM_TO_MCU_RX, MODEM_PWRKEY, MODEM_RESET, MODEM_STATUS.
- J4 GNSS: V3V3, GND, MCU_TO_GPS_RX, GPS_TO_MCU_RX, GPS_PPS, GPS_RESET.
- J5 display: V3V3, GND, DISPLAY_TO_MCU_RX, MCU_TO_DISPLAY_TX.
- J7 driver controls: PICKUP_CONFIRM, NEXT_STOP, MENU_BACK.
- J8 buzzer: V5_LOGIC, BUZZER_CTRL.
- J9 I2C: V3V3, SDA, SCL, GND.
- J10 debug: V3V3, GND, DEBUG_TX, DEBUG_RX.

## Important silicon and board constraints

- This mapping is for the ESP32-S3-WROOM-1-N16R8 variant named in the PCB source. Re-check if the module SKU changes.
- GPIO19/GPIO20 are the ESP32-S3 native USB D-/D+ pins. Keep their USB function reserved.
- GPIO43/GPIO44 are UART0 TX/RX and may carry ROM boot logs/programming traffic. Debug-console configuration must account for this.
- GPIO1, GPIO2 and GPIO48 are assigned to driver buttons. Confirm external circuitry does not disturb reset/boot or cause false presses.
- GPIO0 (module pad 27) is a boot-strapping pin and is connected elsewhere in the board design; inspect its SW2/reset behavior before release.
- GPIO35/GPIO36/GPIO37 are unavailable on N16R8 octal-PSRAM variants; they are not assigned to board functions here.
- GPIO45/GPIO46 are strapping pins; do not repurpose without a boot-strap review.
- GPIO48 has variant-dependent voltage notes in the family datasheet; confirm the exact N16R8 electrical limits and board-level pull network before enabling it.
- Module-pad-to-GPIO mapping is now recovered, but electrical polarity, external pull resistors, connector voltage compatibility, buzzer/LED driver topology, modem PWRKEY timing, and GNSS reset timing still require schematic/component-level verification.
- No hardware driver is enabled by this documentation. Firmware must remain in safe/degraded mode until those checks and bench tests are complete.

## Bring-up hold points

1. Reconcile this table against the exact PCB revision intended for assembly.
2. Confirm every external interface's voltage levels and input protection.
3. Confirm button active level and pull network; debounce in software.
4. Confirm LED and buzzer active level and transistor/driver topology.
5. Confirm modem and GNSS control timing from the selected module/carrier datasheets.
6. Confirm the microSD socket wiring and card voltage requirements.
7. Only then enable the relevant driver behind an explicit board-I/O configuration option.
