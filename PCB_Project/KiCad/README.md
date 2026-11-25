# Edu Ride Bus Tracker — KiCad source snapshot

This directory contains the current PCBKit/KiCad source snapshot for the Edu Ride controller board.

## Files

- `Edu-Ride-Bus-Tracker.kicad_pcb` — routed PCB.
- `Edu-Ride-Bus-Tracker.kicad_sch` — schematic.
- `Edu-Ride-Bus-Tracker.kicad_pro` — KiCad project settings.
- `Edu-Ride-Bus-Tracker.kicad_dru` — design rules.
- `pcbkit.kicad_sym` and `parts.kicad_sym` — project symbol libraries.
- `scripts/design.py` — recovered PCBKit schematic source.
- `DESIGN.md` — recovered baseline and known design notes.

Open the project file in KiCad from this directory. Confirm library resolution on the target workstation before editing.

## Current checks (2026-11-25)

- Schematic ERC: zero violations.
- PCB DRC: zero errors, zero unconnected items, zero warnings after hiding the backside R21 reference and sourcing fields from silkscreen.
- PCBKit schematic/PCB pad comparison: matching.
- PCBKit autorouter reported 192/192 connections routed, 953 tracks and 83 vias.

## Important limitations

This is a source snapshot, not a manufacturing release:
- The repository snapshot does not yet include a reproducible PCB-generation script (`scripts/board.py`) or the complete project footprint-library bundle. The routed `.kicad_pcb` is the authoritative current board snapshot.
- PCBKit PDN analysis still flags the nearest V3V3 capacitor to ESP32-S3 U1 as approximately 13 mm away. Local decoupling placement must be improved and re-analysed.
- Current DC/thermal models do not represent modem transmit-current peaks; MODEM_5V_EXT and MODEM_5V_RAW have no modelled loads.
- 12/24 V automotive transient/load-dump, reverse-polarity, fuse/TVS coordination, thermal, connector and exact modem-carrier checks remain open.
- Independent schematic/layout review and bench validation are required before vehicle installation.

Do not generate or order manufacturing files from this snapshot until all open engineering gates are closed and a separate release approval is recorded.
