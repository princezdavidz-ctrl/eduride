# Edu Ride — Four-Layer In2.Cu Power-Plane Audit

**Board:** `Edu-Ride-Bus-Tracker-4L.kicad_pcb`  
**Status:** Prototype audit; no power-plane copper added in this pass.

## Confirmed stack and geometry
- Board outline bounding box: X 99.95–200.05 mm, Y 119.95–200.05 mm.
- Copper layers: F.Cu, In1.Cu, In2.Cu, B.Cu.
- Existing In1.Cu zone is GND and must remain the continuous reference plane.
- Existing power-via inventory: 10 V3V3 through-vias and 1 V5_LOGIC through-via.

## Existing power-via coordinates (mm)
### V3V3
- (156.65, 191.25)
- (176.15, 176.35)
- (131.95, 192.35)
- (186.75, 180.05)
- (175.75, 177.65)
- (167.95, 182.45)
- (169.25, 186.95)
- (161.45, 182.45)
- (134.25, 191.45)
- (132.45, 195.35)

### V5_LOGIC
- (125.25, 178.05)

## Why a blanket split was rejected
Supply pads and existing vias are spatially interleaved around the left-side regulator/connector region. A simple rectangular V3V3/V5_LOGIC split could capture unrelated pads or leave narrow, fragmented copper. The current via population is not sufficient to assume uniform plane feeding, especially for V5_LOGIC.

## Modeled electrical baseline (not measured)
- V3V3: 550 mA scenario; worst modeled drop 77.6 mV (2.4%); 354 mΩ copper to worst load.
- V5_LOGIC: 470 mA scenario; worst modeled drop 19.8 mV (0.4%); 87.4 mΩ copper to worst load.
- V3V3 PDN at U1: 412 mΩ at 3.76 MHz, within the current 600 mΩ target.
- U1's nearest modeled V3V3 capacitor is approximately 9.88 mm away; add/relocate local decoupling after checking exact supply-pin geometry and available placement area.

## Additional four-layer prototype findings
- PCB DRC: no violations and nothing unconnected at this audit point.
- Thermal model at 40 °C still air: board under U3 reaches 78.2 °C; estimated U3 junction 92 °C using the supplied 400 mW loss assumption. Improve copper spreading and verify actual regulator loss and thermal path.
- USB_DN/USB_DP modeled differential impedance: 171 Ω against 90 Ω target (+90%); route and tune against the fabricator's actual stackup.
- USB_DN modeled loop area: 39.5 mm²; USB_DP: 38.6 mm².
- Crosstalk candidates: MODEM_RESET/MODEM_STATUS 9.1% over 27.3 mm at 0.2 mm spacing; GPS_PPS/GPS_RESET 5.6% over 53.2 mm.
- These are simulation/model results, not measurements, compliance tests, or sign-off.

## Next implementation gates
1. Identify safe, non-overlapping In2.Cu polygons around actual power routes and via tie-ins; no blanket rectangular split.
2. Add deliberate through-via tie-ins near regulator outputs and decoupling/load clusters after checking all-layer clearances and return-plane continuity.
3. Route short F.Cu stubs from regulator output/capacitor pads to the new vias; avoid via-in-pad unless fabrication and assembly explicitly support it.
4. Add separate V3V3 and V5_LOGIC In2.Cu regions with explicit priority and appropriate thermal/solid connections.
5. Refill zones, run DRC, inspect all-layer connectivity, then rerun fine DC and PDN analysis.
6. Revisit U1 local decoupling, USB differential impedance, LMR38010 hot-loop layout, thermal and EMC before release.

## Release caveat
No power-plane zones or new power vias were introduced in this audit. The original two-layer baseline remains unchanged. The four-layer prototype is not manufacturing-ready; the hardware PR must remain unmerged until the exact PCB and rule files are synchronized and reviewed.
