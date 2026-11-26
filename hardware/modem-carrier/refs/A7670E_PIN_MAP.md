# SIMCom A7670E module pin map — transcription for carrier design

Source: SIMCom A7670 Series Hardware Design V1.03, Figure 2 and Table 4, pp. 14–16. This is the current working transcription for the A7670E family. V1.00 differs on several optional GPIO assignments (notably pads 49/50/53/67/68); obtain written confirmation that the exact A7670E-LASA order code/revision uses the V1.03 pin assignment and land pattern before releasing a footprint or buying parts.

| Pad | Signal | Electrical class / domain | Carrier decision |
|---:|---|---|---|
| 1 | PWRKEY | 1.8V-domain input, internally pulled up to VBAT | Open-drain low-side transistor from controller GPIO38 |
| 2 | GND | Ground | GND plane |
| 3 | DTR | 1.8V input | NC (unused) |
| 4 | RI | 1.8V output | NC (unused) |
| 5 | DCD | 1.8V output | NC (unused) |
| 6 | USB_BOOT | 1.8V input / boot control | NC; never pull high before module power-up |
| 7 | CTS | 1.8V output | NC; two-wire UART mode |
| 8 | RTS | 1.8V input | NC; two-wire UART mode |
| 9 | TXD | 1.8V output | TXU0202 B2 input from modem |
| 10 | RXD | 1.8V input | TXU0202 B1Y output to modem |
| 11 | PCM_CLK | 1.8V digital output | NC |
| 12 | PCM_SYNC | 1.8V digital I/O | NC |
| 13 | PCM_DIN | 1.8V digital input | NC |
| 14 | PCM_DOUT | 1.8V digital output | NC |
| 15 | VDD_1V8 | 1.8V power output, max 50mA | TXU0202 VCCB after sequencing validation |
| 16 | RESET | 1.8V-domain input, internally pulled up to VBAT | Open-drain low-side transistor from controller GPIO39 |
| 17 | GND | Ground | GND plane |
| 18 | GND | Ground | GND plane |
| 19 | GPIO1 | 1.8V GPIO | NC |
| 20 | GPIO2 | 1.8V GPIO | NC |
| 21 | GPIO3 | 1.8V GPIO | NC |
| 22 | UART_LOG_RX | 1.8V input | NC |
| 23 | UART_LOG_TX | 1.8V output | NC |
| 24 | VBUS | USB 5V input / detect | USB host VBUS through SIMCom reference circuit; isolate from carrier 5V |
| 25 | ADC | Analog input | NC |
| 26 | NC | No connect | Leave open |
| 27 | USB_DP | USB 2.0 D+ | USB ESD → USB-C device receptacle D+ |
| 28 | USB_DM | USB 2.0 D− | USB ESD → USB-C device receptacle D− |
| 29 | GND | Ground | GND plane |
| 30 | SIM_VDD | SIM power output, 1.8V/3.0V | SIM socket VCC; local decoupling per SIMCom |
| 31 | SIM_DATA | SIM bidirectional data | SIM I/O through ESD / series network per SIMCom |
| 32 | SIM_CLK | SIM clock output | SIM CLK through ESD / series network per SIMCom |
| 33 | SIM_RST | SIM reset output | SIM RST through ESD / series network per SIMCom |
| 34 | SIM_DET | SIM detect input | Socket card-detect switch; polarity to be checked against socket drawing |
| 35 | NC | No connect | Leave open |
| 36 | NC | A7670E top-view assignment diagram marks NC; GPIO6 appears only in the separate A7670C-only GPIO table | Leave open; do not repurpose |
| 37 | I2C_SDA | 1.8V I²C bidirectional | NC |
| 38 | I2C_SCL | 1.8V I²C clock | NC |
| 39 | GND | Ground | GND plane |
| 40 | NC | No connect | Leave open |
| 41 | NC | No connect | Leave open |
| 42 | NC | No connect | Leave open |
| 43 | NC | No connect | Leave open |
| 44 | NC | No connect | Leave open |
| 45 | GND | Ground | GND plane |
| 46 | GND | Ground | GND plane |
| 47 | NC | A7670E top-view assignment diagram marks NC; GPIO8 appears only in the separate A7670C-only GPIO table | Leave open; do not repurpose |
| 48 | GPIO9 | 1.8V GPIO | NC |
| 49 | GPIO10 | 1.8V GPIO | NC; V1.00 lists GPIO4/UART3_RX on this pad |
| 50 | GPIO11 | 1.8V GPIO | NC; V1.00 lists GPIO5/UART3_TX on this pad |
| 51 | NC | A7670E top-view assignment diagram marks NC; ADC1 alternate pad 51 is listed for other family variants | Leave open; do not repurpose |
| 52 | NETLIGHT | 1.8V digital output | Optional LED only after current and drive checks; default NC |
| 53 | GPIO12 | 1.8V GPIO | NC; V1.00 lists NC on this pad |
| 54 | GND | Ground | GND plane |
| 55 | VBAT | 3.4–4.2V power input | 3.8V rail; high-current local bulk/ceramics |
| 56 | VBAT | 3.4–4.2V power input | 3.8V rail; high-current local bulk/ceramics |
| 57 | VBAT | 3.4–4.2V power input | 3.8V rail; high-current local bulk/ceramics |
| 58 | GND | Ground | GND plane |
| 59 | GND | Ground | GND plane |
| 60 | RF_ANT | RF antenna port | 50Ω RF path and matching / connector per SIMCom |
| 61 | GND | Ground | GND plane |
| 62 | GND | Ground | GND plane |
| 63 | GND | Ground | GND plane |
| 64 | GND | Ground | GND plane |
| 65 | GND | Ground | GND plane |
| 66 | STATUS / GND documentation conflict | V1.00 Table 3 and V1.03 Figure 2 / Table 4 show STATUS; V1.03 Table 8 also includes pad 66 in its GND list, and STATUS type is marked DI despite output timing text | HOLD — do not connect to GND or controller until SIMCom confirms exact LASA pad assignment and electrical direction in writing |
| 67 | GPIO13 | 1.8V GPIO | NC; V1.00 lists GPIO10 on this pad |
| 68 | GPIO14 | 1.8V GPIO | NC; V1.00 lists GPIO11 on this pad |
| 69 | GND | Ground | Central ground-pad array; connect to GND plane |
| 70 | GND | Ground | Central ground-pad array; connect to GND plane |
| 71 | GND | Ground | Central ground-pad array; connect to GND plane |
| 72 | GND | Ground | Central ground-pad array; connect to GND plane |
| 73 | GND | Ground | Central ground-pad array; connect to GND plane |
| 74 | GND | Ground | Central ground-pad array; connect to GND plane |
| 75 | GND | Ground | Central ground-pad array; connect to GND plane |
| 76 | GND | Ground | Central ground-pad array; connect to GND plane |
| 77 | GND | Ground | Central ground-pad array; connect to GND plane |
| 78 | GND | Ground | Central ground-pad array; connect to GND plane |
| 79 | GND | Ground | Central ground-pad array; connect to GND plane |
| 80 | GND | Ground | Central ground-pad array; connect to GND plane |
| 81 | GND | Ground | Central ground-pad array; connect to GND plane |
| 82 | GND | Ground | Central ground-pad array; connect to GND plane |
| 83 | GND | Ground | Central ground-pad array; connect to GND plane |
| 84 | GND | Ground | Central ground-pad array; connect to GND plane |
| 85 | GND | Ground | Central ground-pad array; connect to GND plane |
| 86 | GND | Ground | Central ground-pad array; connect to GND plane |
| 87 | GND | Ground | Central ground-pad array; connect to GND plane |
| 88 | GND | Ground | Central ground-pad array; connect to GND plane |

## Critical pin-map conflicts — release blockers

1. **Pad 66 conflict:** V1.00 Table 3 and V1.03 Figure 2 / Table 4 assign pad 66 to STATUS; V1.00's GND list excludes it. V1.03 Table 8 also includes pad 66 in its GND list. Both guides mark STATUS as DI in a pin-type field, while the power-on timing and status description show the module driving STATUS high after initialization. This is likely a documentation inconsistency, but do not route pad 66 until SIMCom confirms the exact A7670E-LASA pad function and direction.
2. **Pads 36 / 47 / 51:** the A7670E top-view assignment diagram marks these pads NC. Keep them NC and do not repurpose them.
3. **Optional GPIO revision differences:** V1.00 and V1.03 differ on pads 49, 50, 53, 67 and 68. This carrier does not use these GPIOs; keep them unconnected until the exact LASA revision is confirmed.

## Critical checks before schematic release

1. Confirm exact A7670E-LASA variant uses this A7670E pin map and same 88-pad footprint. Do not infer from the generic A7670E series label alone.
2. Confirm pin 15 VDD_1V8 startup timing and maximum available current. The V1.03 guide lists 50mA maximum; do not load it with anything else.
3. Confirm pin 24 VBUS implementation from SIMCom's USB reference circuit; never tie USB host VBUS directly to the carrier's protected MODEM_5V_EXT rail.
4. Check USB_BOOT default state and do not pull it high during startup.
5. Confirm all 88 pad numbers and land-pattern positions against the official Figure 5 drawing; central pads 69–88 are all GND.
6. The module's exact RF_ANT matching and antenna keep-out must follow the exact revision's RF guide.

This table is a working transcription of the family guide, not a substitute for SIMCom's confirmation of the exact LASA order code.