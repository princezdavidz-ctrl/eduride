# Edu Ride Bus Tracker — recovered baseline design

This document records the existing combined controller prototype. It is a recovery baseline, not a fabrication release.

## Functional blocks
- Vehicle input, fuse, transient protection and buck conversion
- ESP32-S3 controller and debug header
- GNSS UART, PPS and reset interface
- Cellular modem power and UART/control interface
- USB-C data, VBUS and ESD protection
- microSD storage interface
- Driver controls, status LEDs, buzzer and expansion headers

## Canonical source
`scripts/design.py` contains the pin-to-net assignments recovered from the existing KiCad schematic. The schematic currently contains 77 symbols and 54 named nets. The source intentionally preserves the current names, including slash-containing internal nets, until the board/schematic net-name normalization is performed as one coordinated change.

## Known engineering holds
1. The board and schematic currently report 33 pad/net consistency conflicts, primarily where slash-containing net names are represented differently by KiCad/PCBKit. Resolve by normalizing names consistently in the source and board.
2. The current combined prototype must be split into two independent product variants: GPS-only and Vision + GPS.
3. Vehicle transient/reverse-polarity protection, regulator operating limits, modem supply transients and all custom symbol/footprint pin maps require manufacturer-datasheet verification.
4. The ESP32-S3 must not be treated as the camera/vision compute platform. Vision + GPS uses a separate Linux-capable vision computer; the ESP32 remains the vehicle controller.
5. Do not export manufacturing files or order boards until electrical, mechanical, power, thermal and interface checks are complete.

## Product variants
- **GPS-only:** GNSS, cellular telemetry, driver controls/status and shared backend connection; no camera or biometric hardware/software capability.
- **Vision + GPS:** GPS controller plus a separate vision computer/camera subsystem; backend recognition with explicit privacy controls and uncertain-match manual confirmation.

## Datasheet-level power-stage review (open corrective actions)

- **U2 LMR38010SDDAR:** datasheet pin 4 is RT/SYNC and requires a frequency-setting resistor to ground (or a valid synchronization source). It is currently unconnected. Add the datasheet-appropriate RT resistor (the datasheet's 49.9 kΩ example sets approximately 525 kHz) and connect U2.4 accordingly.
- **U2 exposed thermal pad:** the footprint's exposed pad is represented by pad 9 (split into multiple copper pads) and is currently unconnected. Bond all exposed-pad segments to GND in the schematic and PCB, following TI's layout guidance.
- **U2 PGOOD (pin 6):** currently unused; the datasheet permits leaving the open-drain output open when unused. Keep this as an intentional no-connect and document it in the schematic.
- **U3 TPS54202DDCR:** EN pin 5 is currently unconnected; TI specifies that a floating EN enables the device, so this is intentional for the current always-on design. Revisit if controlled shutdown is required.
- **Q1 AO3401A:** the 30 V P-channel MOSFET is on the 5 V modem rail switch, not the raw 12/24 V vehicle input. Its rating must still be checked against the modem rail's fault/transient environment; do not use it as the vehicle-input reverse-polarity element.
- **Vehicle TVS / U2 input:** SMCJ36A has 36 V stand-off and 58.1 V stated clamp, while U2 has 80 V recommended operating maximum and 85 V absolute maximum. This is a promising voltage-rating relationship, but it is not by itself proof of automotive load-dump compliance; validate the actual surge waveform, source impedance, TVS pulse energy, fuse coordination, temperature and PCB layout against the intended vehicle electrical environment.

These power-stage actions remain blockers for vehicle deployment and manufacturing release even though the current KiCad ERC/DRC and board/schematic connectivity checks pass.
