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


## LMR38010 layout and EMC review — new blockers

A PCB geometry inspection found the following in the current PCBKit workspace:
- U2 input bypass capacitors C6 (100 nF) and C5 (10 µF) are approximately 4.61 mm and 5.59 mm from the U2 footprint centre, respectively. C8 (100 nF bootstrap) is approximately 5.22 mm from the centre. These centre-to-centre distances are screening measurements, not pin-to-pad loop measurements; the VIN/GND and BOOT/SW loops still require detailed review.
- The exposed thermal pad has four split copper segments and **zero thermal vias within 4 mm of U2**. The board is a two-layer stackup and currently has no B.Cu GND zone/plane. This does not implement TI's recommended thermal-via array into a ground-plane heat spreader.
- Fine/normal EMC analysis identifies reference discontinuities on all three fast nets: USB_DN crosses a 5.8 mm B.Cu reference gap, USB_DP crosses a 9.97 mm gap, and SD_SCK crosses a 2.32 mm gap. USB_DN also changes reference at a via without a nearby ground via. USB_DP has the largest modeled loop area (64.1 mm²).

TI's LMR38010 guidance calls for a very small VIN/input-capacitor high-di/dt loop, short/wide BOOT-to-SW capacitor connections, a short FB divider connection away from SW, the thermal pad tied to ground, and thermal vias into a ground-plane heat spreader. The present two-layer layout needs a deliberate ground-reference and thermal redesign; simply adding vias without a continuous B.Cu ground plane and preserving the ESP32 antenna keepout would not close this gate.

Recommended corrective direction: evaluate a four-layer stackup with a continuous inner GND plane, a ground-backed routing strategy for USB and SD clock, thermal vias under U2 EP, and an explicit copper keepout beneath/around the ESP32-S3 module antenna per Espressif's module layout requirements. If retaining two layers, prove the same return-path and heat-spreading objectives with a verified B.Cu GND pour and explicit antenna keepout before rerouting.


## Revision B four-layer prototype (PCBKit workspace only; not synchronized to GitHub)

A separate file, `Edu-Ride-Bus-Tracker-4L.kicad_pcb`, was created so the two-layer recovery baseline remains unchanged. This is an early engineering prototype, not a completed four-layer layout:
- Copper layer count: 4; stackup declared as F.Cu / In1.Cu / In2.Cu / B.Cu with nominal FR-4 dielectric total 1.43 mm and 35 µm copper on each layer (nominal total before masks about 1.57 mm). Fabricator stackup and impedance capability still need confirmation.
- A GND reference plane zone was added on In1.Cu. The ESP32 module antenna keepout remains defined across copper layers by its footprint keepout.
- Four 0.60 mm / 0.30 mm tented through vias were placed at the centres of the four U2 LMR38010 exposed-pad GND segments. The In1.Cu plane provides their intended ground/thermal connection.
- The existing outer-layer routing was carried over; it has not yet been migrated or optimized for four layers. In2.Cu is currently available but not assigned a completed power-plane strategy.
- PCBKit check reports 0 unconnected pads but 8 hole-clearance errors at USB connector J3 between signal pads and its NPTH shell/anchor holes (actual 0.1751–0.2099 mm against the current 0.25 mm rule). These need footprint/manufacturer-rule review; do not globally weaken hole clearance.
- The four-layer prototype is not yet source-synchronized to GitHub. Only the status document is being updated here. Do not merge this PR as a final hardware source snapshot and do not manufacture this prototype.

Next revision tasks: verify the stackup with the selected fabricator; assign In2.Cu power distribution; reroute USB_D+/D− and SD_SCK with controlled return paths; validate differential impedance and skew; review the buck converter high-di/dt loops and thermal path; resolve J3 hole-clearance errors against its exact datasheet/footprint; run full DRC and signal/PDN/thermal/EMC analyses.
