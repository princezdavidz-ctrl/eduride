# Edu Ride Power-Stage Recovery Status

**Status: engineering work in progress — not approved for fabrication**

## Scope

This record tracks the LMR38010 vehicle-input buck stage in the existing Edu Ride Bus Tracker controller design. It does not represent a completed or released PCB.

## Confirmed schematic work

- The custom LMR38010 symbol was corrected to reflect the device pin functions used in the design: GND, EN, VIN, RT/SYNC, FB, PG, BOOT, SW and exposed thermal pad.
- RT/SYNC is assigned to the dedicated `vehiclePower_rt` net.
- R21 is specified as 49.9 kΩ from RT/SYNC to GND, subject to final datasheet/design-frequency confirmation.
- The exposed thermal pad is assigned to GND.
- The schematic ERC passed with zero violations in the latest recorded check.

## PCB layout status

The PCB layout is not clean. The initial front-side R21 placement caused shorts, solder-mask bridge, courtyard and clearance violations around the TVS and fused-input copper. A trial backside placement with vias also caused additional collisions with C5 and VIN/GND copper. That trial is rejected.

The latest recorded check after the backside trial reported:
- 0 unconnected items
- 9 DRC errors
- 10 warnings
- Schematic/PCB pad connectivity comparison matched

A subsequent attempt to restore the previous placement encountered a KiCad PCB editing process failure. Therefore, the current PCB workspace must be treated as an experimental state, not as a recoverable or verified release candidate.

## Recovery plan

1. Recover or recreate a known-good PCB baseline from a verified source; do not use the experimental backside-via placement.
2. Revisit the power-stage placement as a group. Move C5 and/or other local components if necessary to create a legal RT/SYNC resistor escape route.
3. Keep the RT/SYNC resistor close to U2 and provide a short, clean ground return, following the manufacturer's layout guidance.
4. Refill copper zones and run KiCad DRC after routing.
5. Confirm schematic-to-PCB pad mapping, no shorts, no unconnected pads, courtyard and hole clearances, and inspect the 2D/3D layout.
6. Complete power-stage review for 12/24 V automotive transients, load dump, reverse polarity, TVS coordination, fuse coordination, thermal performance and the selected modem's current peaks.
7. Only after these gates pass, prepare manufacturing outputs and request independent engineering review.

## Release restrictions

- Do not fabricate or install this board in a vehicle.
- Do not describe the current PCB as DRC-clean or manufacturing-ready.
- Do not suppress the reported violations to obtain a nominal pass.
- No Gerber, drill, pick-and-place or BOM manufacturing package is approved by this status record.

## Evidence boundary

This document records the latest results observed in the PCBKit workspace. The PCB file itself has not yet been committed to this GitHub branch. This commit is a documentation-only status update and does not contain a validated PCB layout or a manufacturing release.
