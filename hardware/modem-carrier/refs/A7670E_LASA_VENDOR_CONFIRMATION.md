# A7670E-LASA supplier confirmation required before module symbol / footprint release

**Candidate ordered part:** SIMCom A7670E-LASA, LCSC part C49260456  
**Current design assumption:** 24 × 24 × 2.5 mm, 88 LGA pads (68 outer-ring pads + 20 inner pads), A7670E variant.

This document is a request for written manufacturer/distributor confirmation. Do not use an inferred pin map or a generic A7670 family drawing as final authority for PCB layout.

## Why confirmation is required

The two available SIMCom family hardware guides share the 24 × 24 × 2.5 mm, 88-pad package, but some pin-function and power specifications differ:

| Item | A7670 Series Hardware Design V1.00 | A7670 Series Hardware Design V1.03 | Design disposition |
|---|---|---|---|
| Pad 66 | Table 3 identifies STATUS; the GND list excludes pad 66 | Figure 2 / Table 4 identify STATUS, but Table 8 also includes pad 66 in its GND list; STATUS type is marked DI while timing text describes an output | R25 STATUS and R28 GND options both remain DNP until written confirmation |
| Pads 36 / 47 / 51 | NC | A7670E top-view diagram marks NC; alternate family functions appear in other variants | Keep NC |
| Pads 49 / 50 | GPIO4 / GPIO5 (UART3 RX/TX) | GPIO10 / GPIO11 | Do not assign optional GPIO functions until exact revision is confirmed |
| Pads 53 / 67 / 68 | NC / GPIO10 / GPIO11 | GPIO12 / GPIO13 / GPIO14 | Do not assign optional GPIO functions until exact revision is confirmed |
| VBAT peak | 2.8 A | 2 A | Carrier is conservatively designed for 2.8 A pending confirmation |
| External bulk capacitance | 300 µF when supply supports the stated peak; larger if not | 300 µF for a 2 A-capable supply; 600 µF if the source cannot supply the peak | Current design uses two 330 µF polymer capacitors plus local ceramics |

The pad-66 discrepancy is not the only concern: the GPIO assignments and peak-current statements differ between revisions. The module's exact order code and hardware revision must be tied to one authoritative pin table and land-pattern drawing.

## Questions for SIMCom / authorized distributor

1. Does the exact order code **A7670E-LASA**, LCSC C49260456, use the 88-pad pin assignment in V1.00 or V1.03? Please provide the applicable hardware-design document revision and module hardware revision.
2. Confirm pad 66's function and electrical direction. Is it a 1.8 V STATUS output, or a GND pad? If STATUS, confirm output-high/low behavior, drive capability and timing. Please clarify the V1.03 Table 8 GND-list entry.
3. Confirm the exact functions of pads 49, 50, 53, 67 and 68 for this order code. In particular, resolve the GPIO4/5 vs GPIO10/11 and GPIO10/11 vs GPIO12/13/14 differences between V1.00 and V1.03.
4. Confirm pads 36, 47 and 51 are NC for this exact module revision.
5. Confirm the peak VBAT current and recommended external capacitance for this exact module revision: 2 A or 2.8 A, and the required bulk capacitance when the regulator can supply the peak current directly.
6. Supply the official 88-pad PCB land-pattern CAD data (DXF, STEP, IPC-7351/KiCad footprint, or dimensioned drawing), including pad coordinates, pad dimensions, inner ground-pad dimensions, solder-mask expansion, paste apertures, keep-out/forbidden areas and module orientation/pin-1 marking.
7. Confirm the exact RF_ANT pin, supported LTE bands for this suffix, and the recommended antenna matching/ESD network for the LASA variant.
8. Confirm USB_VBUS electrical range and role (USB device/peripheral only), USB_DP/DM pad numbers, and whether any additional USB_BOOT or test-point requirements apply.
9. Confirm SIM_DET electrical behavior and card-detect polarity, plus SIM_VDD 1.8 V / 3.0 V capability.
10. Confirm PWRKEY and RESET voltage domain, pull-up characteristics and exact power-on, power-off and reset pulse timings.

## Current safe design decisions while awaiting confirmation

- Keep R25 (1.8 V STATUS path) and R28 (GND alternative) DNP. Populate exactly one only after pad 66 is confirmed; the NPN level-shift path to controller J2 pin 6 is present but should not be relied on until the module function is verified.
- Keep pads 36, 47 and 51 NC.
- Do not assign optional GPIO functions to pads 49, 50, 53, 67 or 68.
- Retain the conservative 2.8 A VBAT design target and 660 µF nominal polymer bulk bank until the module revision is confirmed.
- Do not create or release a production module footprint from an approximate drawing. Use the exact official LASA land pattern and verify it against a physical sample or manufacturer CAD.
- Do not export Gerbers, drill files, assembly files or BOM for manufacturing until all pin-map, footprint, DRC, power, RF and thermal gates pass.

## Source documents

- SIMCom A7670 Series Hardware Design V1.00 (released 2020-06-09): https://makerselectronics.com/wp-content/uploads/2025/09/A7670-Series-Hardware-Design_V1.00.pdf
- SIMCom A7670 Series Hardware Design V1.03: https://make.net.za/wp-content/datasheets/SIMCom%20A7670%20Series%20Hardware%20Design%20v1.03.pdf