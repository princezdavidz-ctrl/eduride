# Edu Ride Power-Stage and PCB Recovery Status

**Status: routed source snapshot committed for engineering review; not approved for fabrication or vehicle installation.**

## Schematic and PCB checks

- Custom LMR38010 symbol corrected to the intended device pin functions: GND, EN, VIN, RT/SYNC, FB, PG, BOOT, SW and exposed thermal pad.
- RT/SYNC assigned to `vehiclePower_rt`; R21 is 49.9 kΩ from RT/SYNC to GND, subject to final datasheet/design-frequency confirmation.
- Exposed thermal pad assigned to GND.
- Latest schematic ERC: zero violations.
- Latest PCB DRC: zero errors, zero unconnected items and zero warnings after hiding R21 backside reference and sourcing fields from silkscreen.
- PCB/schematic pad connectivity comparison: matching.
- PCBKit autorouter reported 192/192 connections routed, 953 tracks and 83 vias.

## Preliminary electrical and thermal analysis

- Modelled V3V3 drop to ESP32-S3 U1.2: 11.5 mV at an assumed 97 mA load.
- Modelled board temperature under U1: 34 °C in 25 °C still air, with 320 mW assumed for U1.
- PDN analysis flags the nearest V3V3 capacitor to U1 as approximately 13 mm away. Local decoupling should be placed close to the supply pin and re-analysed.
- MODEM_5V_EXT and MODEM_5V_RAW have no modelled loads. The current model therefore does not validate modem peak current, regulator thermal limits or vehicle-input power performance.

## Remaining engineering gates

1. Improve ESP32-S3 local decoupling and rerun PDN analysis.
2. Add realistic loads for ESP32-S3, GNSS, cellular modem (including transmit peaks), display and external interfaces; rerun DC-drop and thermal analysis.
3. Review LMR38010 layout against TI guidance, especially input-capacitor, switch-node, bootstrap and feedback loops.
4. Complete 12/24 V automotive transient/load-dump, reverse-polarity, TVS/fuse coordination and thermal review.
5. Verify connector pinouts, exact modem carrier, voltage levels and all component ordering codes against manufacturer datasheets.
6. Add a reproducible PCB generation script and complete footprint-library bundle; verify the project opens cleanly on a separate KiCad workstation.
7. Obtain independent engineering review and bench validation before any vehicle pilot.

## Release restrictions

- Do not fabricate or install this board in a vehicle yet.
- Do not describe this board as fully validated or manufacturing-ready.
- Do not suppress checks or warnings to obtain a nominal pass.
- No Gerber, drill, pick-and-place or BOM manufacturing package is approved by this status record.
