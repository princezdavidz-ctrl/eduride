# Edu Ride Power-Stage and PCB Recovery Status

**Status: PCBKit workspace DRC passes; the latest placement revision has not yet been verified in the GitHub KiCad PCB file. Not approved for fabrication or vehicle installation.**

## Latest PCBKit workspace checks

- LMR38010 custom symbol pinout corrected: GND, EN, VIN, RT/SYNC, FB, PG, BOOT, SW and exposed thermal pad.
- RT/SYNC assigned to `vehiclePower_rt`; R21 is 49.9 kΩ from RT/SYNC to GND, pending final frequency/design confirmation.
- Exposed thermal pad assigned to GND.
- Latest KiCad ERC: zero violations.
- Latest KiCad PCB DRC: zero errors, zero unconnected items and zero warnings.
- Schematic-to-PCB pad connectivity: matching.
- Latest autorouter: 192/192 connections, 935 tracks and 95 vias.
- C13 reference silkscreen hidden; J1 reference repositioned to remove silkscreen warnings.

## ESP32-S3 decoupling improvement in PCBKit workspace

C13 (100 nF, 0402) was moved from approximately 15.2 mm to 9.76 mm from ESP32-S3 U1 in the fine PDN model. The board was autorouted again and passed DRC with zero errors and zero warnings.

Fine-resolution PDN results:
- Nearest V3V3 capacitor: C13, 100 nF, approximately 9.76 mm from U1.
- V3V3 impedance at U1: 557 mΩ at 29.9 MHz, against the model target of 3.4 Ω.
- The analyzer still recommends a capacitor directly beside the supply pin. The 9.76 mm result is an improvement, not an ideal final layout.

**Git synchronization caveat:** The PCBKit workspace placement revision has not been confirmed in the KiCad PCB file stored in GitHub. The latest verified PCB workspace and GitHub PCB source must be reconciled before PR #4 can be considered a complete source snapshot. The commit associated with this status update changes documentation only.

## Fine-resolution DC and thermal model limitations

- Modelled V3V3 drop to U1.2: 12.8 mV (0.4%) at 97.1 mA.
- Modelled board temperature under U1: 32.9 °C in 25 °C still air.
- Model assumes ESP32-S3 Wi-Fi peak current of 97 mA and U1 dissipation of 320 mW.
- MODEM_5V_EXT and MODEM_5V_RAW have no modeled loads. The model does not validate cellular modem transmit bursts, GNSS, display, peripherals, startup/inrush, or simultaneous peak loading. Apparent low temperature and voltage drop are not system-level sign-off.

## Remaining engineering gates

1. Reconcile and verify the latest PCBKit board file against the KiCad file stored in GitHub; commit the actual changed PCB source.
2. Improve C13 placement further if a legal location close to U1 can be created without violating the ESP32 module antenna keepout, connector courtyard, or routing constraints.
3. Build realistic loads for ESP32-S3, GNSS, cellular modem (including transmit peaks), display and external interfaces; rerun DC, thermal and PDN analyses.
4. Review LMR38010 layout against TI guidance: input-capacitor loop, switch-node copper, bootstrap loop, feedback routing and ground return.
5. Complete 12/24 V automotive transient/load-dump, reverse-polarity, TVS/fuse coordination, thermal and protection review.
6. Verify exact modem carrier, peak current, UART voltage levels, connector pinouts and component ordering codes against manufacturer datasheets.
7. Add a reproducible PCB generation script and complete footprint-library bundle; verify project portability on a separate KiCad workstation.
8. Obtain independent engineering review and bench validation before vehicle pilot.

## Release restrictions

- Do not fabricate or install this board in a vehicle yet.
- Do not describe this board as fully validated or manufacturing-ready.
- Do not suppress design checks to obtain a nominal pass.
- No Gerber, drill, pick-and-place or BOM manufacturing package is approved by this status record.
