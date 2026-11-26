# Edu Ride A7670E LTE Carrier

Separate prototype daughterboard for the Edu Ride ESP32-S3 controller. Read `DESIGN.md` before changing the schematic or board. The existing controller board is intentionally not modified.

Current milestone:
- Carrier architecture and manufacturer-based interface constraints documented.
- First-pass carrier schematic in `board.kicad_sch` includes LT8640 5 V → 3.8 V power, local 3.3 V LDO, TXU0202 UART translation, PWRKEY/RESET transistor stages, USB-C device port, nano-SIM interface and preliminary LTE RF matching path; KiCad ERC reports zero errors and warnings (71 parts, 47 nets). J4/J5/J8 are schematic-only module placeholders, not physical connectors.
- A7670 family 88-pad working pin map is documented, with pads 36, 47 and 51 held NC; pad 66 has mutually exclusive DNP STATUS/GND options pending SIMCom clarification, and optional GPIO pads 49/50/53/67/68 remain unused due V1.00/V1.03 revision differences.

Not yet complete: exact LASA pin-map confirmation, complete module symbol/footprint, RF antenna selection and tuning, PCB layout, DRC, impedance, thermal, RF/USB compliance, power-transient and bench validation. No manufacturing files are released.