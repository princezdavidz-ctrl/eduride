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

## Updated preliminary DC, thermal and PDN scenario

The earlier 97 mA ESP32-S3 load assumption was replaced. Espressif's ESP32-S3-WROOM-1 datasheet reports up to 355 mA peak for 802.11b TX at 20.5 dBm. The preliminary model therefore assigns U1 a 450 mA design allowance and a 550 mA total V3V3 rail load, including small placeholder loads for the exposed headers and microSD. The 5 V logic rail is modelled at 470 mA. These are analysis scenarios, not measured system loads.

Fine-resolution results at 40 °C ambient:
- V3V3: 550 mA total; worst modeled drop 77.6 mV (2.4%) at J4.1; drop to U1.2 is 70.9 mV.
- V5_LOGIC: 470 mA total; worst modeled drop 19.8 mV (0.4%) at J8.1.
- PDN: V3V3 impedance at U1 is 557 mΩ at 29.9 MHz against the current 600 mΩ model target.
- Nearest V3V3 capacitor remains C13, 100 nF, at 9.76 mm from U1; still too far for ideal high-frequency local decoupling.
- Thermal scenario: board under U3 is 79.9 °C and estimated U3 junction is 94 °C; board under U1 is 63.5 °C and under U2 is 62.6 °C.
- Component heat-loss inputs (U1 0.8 W, U2 0.3 W, U3 0.4 W) are provisional estimates, not measured dissipation. Thermal output is therefore indicative only.

The board's modem connectors remain unloaded in the model: MODEM_5V_EXT and MODEM_5V_RAW have no modeled current. There is no approved modem part/carrier profile yet. GNSS, display, external peripherals, startup/inrush, and simultaneous worst-case loads are not fully characterized. Do not treat these results as system-level or automotive sign-off.

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
