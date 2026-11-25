# Edu Ride Power-Stage Recovery Status

**Status: PCBKit layout checks currently pass DRC, but the design is not approved for fabrication or vehicle installation.**

## Scope

This record tracks the LMR38010 vehicle-input buck stage in the existing Edu Ride Bus Tracker controller design. It is a work-in-progress engineering record, not a product release.

## Confirmed schematic work

- The custom LMR38010 symbol was corrected to reflect the device pin functions used in the design: GND, EN, VIN, RT/SYNC, FB, PG, BOOT, SW and exposed thermal pad.
- RT/SYNC is assigned to the dedicated `vehiclePower_rt` net.
- R21 is specified as 49.9 kΩ from RT/SYNC to GND, subject to final datasheet/design-frequency confirmation.
- The exposed thermal pad is assigned to GND.
- Latest schematic ERC: zero violations.

## Latest PCB routing and DRC

The original R21 front-side placement caused shorts and clearance/mask/courtyard violations. A trial backside route with two vias also collided with C5 and the VIN/GND pads. That manual trial was rejected.

The board was then rerouted using PCBKit's autorouter, which replaced the previous tracks and vias:
- 192 of 192 connections routed.
- 953 tracks and 83 vias generated.
- Latest KiCad DRC: 0 unconnected items, 0 errors, 10 warnings.
- Schematic-to-PCB pad connectivity comparison: matching.

The remaining 10 warnings are silkscreen overlap/clipping warnings around the backside R21 footprint. They are not electrical shorts or copper-clearance errors, but the silkscreen should be cleaned before manufacturing review.

## Preliminary physical analysis

A fast PCBKit analysis was run. Its results are preliminary because the board does not yet have a complete, verified load/current model:
- Modelled V3V3 drop to U1.2: 11.5 mV at an assumed 97 mA load.
- Modelled board temperature under U1: 34 °C in 25 °C still air, with 320 mW assumed for U1.
- PDN analysis flagged the nearest V3V3 capacitor to U1 as 13 mm away, and recommended local decoupling closer to the ESP32-S3 supply pin.
- Several supply rails show no load in the model. The current results therefore do not validate modem peak current, regulator thermal limits or vehicle-input power performance.

## Recovery and remaining work

1. Clean R21 backside silkscreen placement and remove the remaining 10 warnings where practical.
2. Review placement and routing against the LMR38010 datasheet and TI layout guidance, especially the input-capacitor, switch-node, bootstrap and feedback loops.
3. Add/verify local ESP32-S3 decoupling and rerun PDN analysis.
4. Populate a realistic power/load model for the ESP32-S3, GNSS, modem (including transmit peaks), display and all external interfaces; rerun DC drop, heat and PDN analyses.
5. Complete power-stage review for 12/24 V automotive transients, load dump, reverse polarity, TVS coordination, fuse coordination, thermal performance and modem current peaks.
6. Verify connector pinouts, exact modem carrier and all component ordering codes against manufacturer datasheets.
7. Run independent engineering review and bench validation before any vehicle pilot.
8. Only after all gates pass, prepare manufacturing outputs for review.

## Release restrictions

- Do not fabricate or install this board in a vehicle yet.
- Do not describe the current board as fully validated or manufacturing-ready.
- Do not suppress the remaining warnings to obtain a nominal pass.
- No Gerber, drill, pick-and-place or BOM manufacturing package is approved by this status record.

## Evidence boundary

This document records the latest results observed in the PCBKit workspace. The PCB file and complete KiCad source set have not yet been committed to this GitHub repository. This update is a documentation-only commit and does not contain a validated hardware release.
