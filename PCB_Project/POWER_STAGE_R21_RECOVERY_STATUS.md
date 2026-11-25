# Edu Ride Power-Stage and PCB Recovery Status

**Status: PCB DRC passes; power-integrity and automotive validation remain open. Not approved for fabrication or vehicle installation.**

## Latest schematic and PCB checks

- LMR38010 custom symbol pinout corrected: GND, EN, VIN, RT/SYNC, FB, PG, BOOT, SW and exposed thermal pad.
- RT/SYNC assigned to `vehiclePower_rt`; R21 is 49.9 kΩ from RT/SYNC to GND, pending final frequency/design confirmation.
- Exposed thermal pad assigned to GND.
- Latest KiCad ERC: zero violations.
- Latest KiCad PCB DRC: zero errors, zero unconnected items and zero warnings.
- Schematic-to-PCB pad connectivity: matching.
- Latest PCBKit autorouter run: 192/192 connections routed, 935 tracks and 95 vias.
- R21 sourcing/reference fields and C13 reference silkscreen were hidden where they conflicted with assembly silkscreen. J1 reference was repositioned to a clear area.

## ESP32-S3 decoupling improvement

C13 (100 nF, 0402) was moved from approximately 15.2 mm to 9.76 mm from the ESP32-S3 V3V3 load in the PDN model. The move required a full autoroute and DRC rerun. DRC now reports no violations.

Fine-resolution PDN analysis now reports:
- Nearest V3V3 capacitor: C13, 100 nF, approximately 9.76 mm from U1.
- V3V3 impedance at U1: 557 mΩ at 29.9 MHz, against the model target of 3.4 Ω.
- The analyzer still flags the capacitor as farther away than ideal and recommends placing a capacitor directly beside the supply pin. The 9.76 mm result is an improvement, not an ideal final layout.

## Fine-resolution DC and thermal model

- Modelled V3V3 drop to U1.2: 12.8 mV (0.4%) at 97.1 mA.
- Modelled board temperature under U1: 32.9 °C in 25 °C still air.
- The model assumes ESP32-S3 Wi-Fi peak current of 97 mA and U1 dissipation of 320 mW.
- MODEM_5V_EXT and MODEM_5V_RAW have no modelled loads. The model does not validate cellular modem transmit bursts, GNSS, display, peripherals, startup/inrush, or simultaneous peak loading. The apparent low temperature and voltage drop must not be treated as system-level sign-off.

## Remaining engineering gates

1. Improve C13 placement further if a legal location close to U1 can be created without violating the ESP32 module antenna keepout, connector courtyard, or routing constraints.
2. Build a realistic load model for ESP32-S3, GNSS, cellular modem (including transmit peaks), display and external interfaces; rerun DC, thermal and PDN analyses.
3. Review LMR38010 layout against TI guidance: input-capacitor loop, switch-node copper, bootstrap loop, feedback routing and ground return.
4. Complete 12/24 V automotive transient/load-dump, reverse-polarity, TVS/fuse coordination, thermal and protection review.
5. Verify exact modem carrier, peak current, UART voltage levels, connector pinouts and all component ordering codes against manufacturer datasheets.
6. Add a reproducible PCB generation script and complete footprint-library bundle; verify project portability on a separate KiCad workstation.
7. Obtain independent engineering review and bench validation before vehicle pilot.

## Release restrictions

- Do not fabricate or install this board in a vehicle yet.
- Do not describe this board as fully validated or manufacturing-ready.
- Do not suppress design checks to obtain a nominal pass.
- No Gerber, drill, pick-and-place or BOM manufacturing package is approved by this status record.
