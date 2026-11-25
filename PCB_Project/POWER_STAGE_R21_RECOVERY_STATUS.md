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


## Revision B continuation — J3 USB-C clearance investigation

The eight DRC hole-clearance errors were traced to the USB-C receptacle footprint J3 (`USB_C_Receptacle_USB2.0_16P`) and its shell-anchor NPTH holes. The closest reported signal-pad-to-anchor-hole clearances are 0.1751 mm (GND pads) and 0.2099 mm (VBUS pads), against the current 0.25 mm board rule. The two shell-anchor NPTH centres are at approximately (178.36, 192.925) mm and (184.14, 192.925) mm. The affected signal pads are the outer GND/VBUS pads.

No global hole-clearance rule was weakened and no footprint pad was moved. The exact connector manufacturer/part number is not yet confirmed, so it is not safe to waive these errors or alter the land pattern. Next step: select the exact USB-C receptacle and compare the library footprint to its manufacturer-recommended PCB land pattern, including shell-anchor drill, copper-to-hole clearance, courtyard and board-fabrication capability. Then either correct the footprint from the manufacturer drawing or add a narrowly scoped, documented rule exception only if the manufacturer explicitly permits it and the fabricator confirms capability.

Power-layer planning: the board has 23 V3V3 pads, but they are predominantly F.Cu SMD pads. An In2.Cu V3V3 plane alone would be electrically isolated from those pads unless properly placed transition vias and short surface connections are added. Do not add a floating plane and call it power distribution. First define the actual load budget and place a via-transition strategy at the source and loads, then zone In2.Cu and verify connectivity, voltage drop, clearances and thermal behavior. MODEM_5V_EXT and MODEM_5V_RAW are still connector-fed rails without a selected modem load and should not be committed to a plane width/current assumption yet.


## Revision B continuation — connector mismatch and signal-integrity results

### J3 connector identification remains unresolved
A manufacturer drawing was located for SHOUHAN TYPE-C 16P LCH9.3-A143 (LCSC C32713002). Its recommended PCB layout shows two rows of eight contact holes, 0.5 mm pitch, plus elongated shell-retention slots; its stated rating is 3 A, 20 V, and 10,000 cycles. The present generic `USB_C_Receptacle_USB2.0_16P` footprint in J3 instead has all 16 contact pads in one SMD row, two NPTH holes and four shell tabs. It is visibly not the A143 footprint. Therefore A143 is evidence of a possible connector family, not a confirmed replacement. Do not fit this part to the existing footprint. Exact connector selection and a matching footprint/drawing are still required. The eight 0.1751–0.2099 mm hole-clearance DRC errors remain open against the 0.25 mm rule.

### Four-layer signal and EMC analysis
Fine analysis of `Edu-Ride-Bus-Tracker-4L.kicad_pcb` reports:
- USB_DN/USB_DP differential impedance: 171 Ω against a 90 Ω target (+90%); pair length 39.1 mm, skew 13 ps, 4 vias. The pair is not within 10% of target. Re-route and tune track width/gap against the actual confirmed stackup/fabricator impedance capability; do not accept this result.
- USB_DN loop area: 39.5 mm²; USB_DP: 38.6 mm²; SD_SCK: 16.9 mm². EMC model reports no fast nets crossing a reference gap, but this does not establish compliance at the cable/connector or in an enclosure.
- Crosstalk candidates: MODEM_RESET/MODEM_STATUS 9.1% near-end over 27.3 mm at 0.2 mm spacing; USB_DP/MODEM_PWRKEY 5.7% over 8.46 mm; GPS_PPS/GPS_RESET 5.6% over 53.2 mm. Review and separate where practical.
- V3V3 PDN maximum at U1: 412 mΩ at 3.76 MHz against 600 mΩ target. Nearest 100 nF C13 remains about 9.76 mm from U1; still needs a closer local bypass.
- V5_LOGIC PDN is within its modeled target; this is not a substitute for measured load-transient testing.

These are simulation/model results from the current preliminary 4-layer stackup (35 µm copper, 0.18/1.07/0.18 mm FR-4 dielectrics, εr 4.2). The fabricator must confirm the actual dielectric, copper and impedance tolerances before controlled-impedance routing is finalized. The 4-layer board still has 0 unconnected pads and 8 J3 hole-clearance DRC errors; no manufacturing release.


## Revision B continuation — 25 November 2026 connector candidate and layer audit

### USB-C connector candidate under verification (not yet approved)
PCBKit parts search identified G-Switch GT-USB-7010B (JLCPCB C2837092) as a stocked USB 2.0 Type-C, 16-contact, right-angle SMD receptacle. Its linked manufacturer drawing states 5 A VBUS rating, 24 V rating, -40 °C to +85 °C operating range and 10,000 mating cycles. The drawing's recommended PCB land pattern and the library footprint still require a pad-by-pad comparison, including contact-row geometry, shell-anchor geometry, solder lands, drill/slot dimensions and connector body datum. Do not replace J3 or waive its DRC errors until that comparison is complete. This candidate is not an approved BOM selection.

### Four-layer layer/zone audit
The current PCBKit four-layer prototype enables F.Cu, In1.Cu, In2.Cu and B.Cu. Current zones include In1.Cu GND, B.Cu VIN_RAW, and existing F.Cu/B.Cu supply regions. In2.Cu currently has no power-distribution zone. The current layer audit found 269 GND tracks and 26 GND vias; V3V3 has 145 tracks and 10 vias; V5_LOGIC has 24 tracks and 1 via. A future In2.Cu distribution scheme must be based on confirmed load budgets and real transitions from SMD pads, with continuous GND reference retained on In1.Cu. Do not pour isolated or floating power islands, and do not allocate modem rails until a modem/carrier and its TX peak current are selected.

### Current DRC status
The latest PCBKit check of `Edu-Ride-Bus-Tracker-4L.kicad_pcb` reports 0 unconnected pads, 8 J3 hole-clearance errors and 0 warnings. The errors remain 0.1751–0.2099 mm actual versus the 0.2500 mm rule. No global clearance rule was relaxed. The original two-layer baseline remains untouched. The four-layer PCB remains a PCBKit-workspace-only prototype and is not synchronized to GitHub.


## Revision B continuation — 25 November 2026 J3 manufacturer verification and four-layer DRC rule

### J3 exact part identified and verified
The existing J3 value is **GCT USB4105-GF-A**. Its manufacturer drawing (USB4105, recommended PCB layout, component-side view, ±0.05 mm land-pattern tolerance) was compared against the current PCBKit footprint and KiCad's installed `USB_C_Receptacle_GCT_USB4105-xx-A_16P_TopMnt_Horizontal` footprint. The contact-land coordinates, widths, two Ø0.65 mm locating holes at ±2.89 mm / 1.075 mm relative to the current contact-row datum, and four shell-stake positions/dimensions match after a simple footprint-origin translation. The current J3 is therefore consistent with the selected GCT part; retain it.

G-Switch GT-USB-7010B (C2837092) was investigated as a possible alternative but is **not a verified drop-in replacement**: its shell-stake arrangement differs from the current GCT USB4105 geometry. It is not selected and must not be substituted without a new placement, mechanical check and routing revision.

### Four-layer board-specific J3 rule
The two-layer project already contains a narrowly scoped KiCad rule named `J3: pads by its own holes`, applying the hole-clearance exception only between objects within footprint J3. The four-layer board has a different filename and was not loading that rule. A corresponding `Edu-Ride-Bus-Tracker-4L.kicad_dru` was therefore created for the four-layer prototype only, preserving the same J3-only scope and leaving global clearance rules unchanged.

After applying the board-specific rule, PCBKit/KiCad check reports: **no violations, nothing unconnected** for `Edu-Ride-Bus-Tracker-4L.kicad_pcb`. This resolves the eight nominal DRC reports by applying the existing manufacturer-land-pattern exception; it does not constitute fabricator acceptance. Before fabrication, the selected board house must confirm its hole-to-copper capability against the GCT recommended land pattern and tolerances. Do not broaden this exception beyond J3.

### Source synchronization remains open
The four-layer PCB and its new board-specific rule file remain in PCBKit workspace and are not yet synchronized to GitHub. PR #4 remains draft/unmerged. No manufacturing release is authorized.
