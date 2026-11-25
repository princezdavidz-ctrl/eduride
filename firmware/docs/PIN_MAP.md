# Edu Ride Firmware Pin Map — Recovered Signal Assignments

Source: recovered canonical `scripts/design.py` from PCBKit project. Signal-to-module-pad assignments below are schematic assignments, not confirmed GPIO numbers. Validate against the ESP32-S3-WROOM-1 module datasheet and final PCB revision before firmware GPIO configuration or powering peripherals.

| Signal | ESP32 module pad in source | Role | Status |
|---|---:|---|---|
| BUZZER_CTRL | 4 | Buzzer control | Verify GPIO/polarity/driver |
| DEBUG_RX | 36 | UART debug receive | Verify GPIO/connector |
| DEBUG_TX | 37 | UART debug transmit | Verify GPIO/connector |
| DISPLAY_TO_MCU_RX | 7 | Display UART receive | Verify |
| GPS_PPS | 34 | GNSS pulse input | Verify |
| GPS_RESET | 35 | GNSS reset control | Verify polarity |
| GPS_TO_MCU_RX | 11 | GNSS UART receive | Verify |
| I2C_SCL | 6 | I2C clock | Verify |
| I2C_SDA | 5 | I2C data | Verify |
| LED_GPS | 17 | GPS indicator | Verify LED active polarity |
| LED_NET | 18 | Network indicator | Verify LED active polarity |
| LED_STATUS | 23 | Status indicator | Verify LED active polarity |
| MCU_TO_DISPLAY_TX | 12 | Display UART transmit | Verify |
| MCU_TO_GPS_RX | 10 | GNSS UART transmit | Verify |
| MCU_TO_MODEM_TX | 8 | Modem UART transmit | Verify |
| MENU_BACK | 25 | Button input | Verify pull/debounce |
| MODEM_PWRKEY | 31 | Modem power-key control | Verify timing/polarity |
| MODEM_RESET | 32 | Modem reset control | Verify timing/polarity |
| MODEM_STATUS | 33 | Modem status input | Verify polarity/voltage |
| MODEM_TO_MCU_RX | 9 | Modem UART receive | Verify |
| NEXT_STOP | 38 | Button input | Verify pull/debounce |
| PICKUP_CONFIRM | 39 | Driver confirmation input | Verify pull/debounce |
| SD_CS | 22 | microSD SPI chip select | Verify |
| SD_MISO | 21 | microSD SPI input | Verify |
| SD_MOSI | 19 | microSD SPI output | Verify |
| SD_SCK | 20 | microSD SPI clock | Verify |
| USB_DN | 13 | USB data negative | Native USB function/pad mapping verify |
| USB_DP | 14 | USB data positive | Native USB function/pad mapping verify |
| V3V3 | 2 | ESP32 module supply | Confirm rail and current capability |
| GND | 1, 40, 41 | Ground | Module pads in source |

## Header assignments recovered
- J2 modem: GND, TX, RX, PWRKEY, RESET, STATUS.
- J4 GPS: V3V3, GND, TX, RX, PPS, RESET.
- J5 display: V3V3, GND, TX, RX.
- J7 driver buttons: PICKUP_CONFIRM, NEXT_STOP, MENU_BACK.
- J8 buzzer: V5_LOGIC and BUZZER_CTRL.
- J9 I2C: V3V3, SDA, SCL, GND.
- J10 debug: V3V3, GND, DEBUG_TX, DEBUG_RX.

## Verification hold
GPIO numbers, UART assignment, USB-native pin use, SD SPI mapping, voltage compatibility, input pulls, output driver topology, and button/LED/buzzer polarity are not confirmed. Final firmware pin configuration must be reconciled with KiCad schematic/PCB and exact datasheets before bench power-up.
