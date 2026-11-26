# Edu Ride A7670E LTE Carrier

Separate prototype daughterboard for the Edu Ride ESP32-S3 controller. Read `DESIGN.md` before changing the schematic or board. The existing controller board is intentionally not modified.

Current milestone:
- Carrier architecture and manufacturer-based interface constraints documented.
- First-pass carrier schematic in `board.kicad_sch` includes LT8640 5 V → 3.8 V power, local 3.3 V LDO, TXU0202 UART translation and PWRKEY/RESET transistor stages; KiCad ERC reports zero errors and warnings. J4 is a schematic-only module placeholder, not a physical connector.
- A7670 family 88-pad working pin map is documented, with pads 36, 47, 51 and especially 66 held unresolved pending exact A7670E-LASA manufacturer confirmation.

Not yet complete: exact LASA pin-map confirmation, module symbol/footprint, full modem schematic, USB/SIM/RF circuits, PCB layout, DRC, impedance, thermal, RF, power-transient and bench validation. No manufacturing files are released.