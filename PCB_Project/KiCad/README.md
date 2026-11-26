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

## Latest checks

- Schematic ERC: zero violations.
- PCB DRC: zero errors, zero unconnected items, zero warnings.
- Schematic/PCB pad comparison: matching.
- Latest autorouter: 192/192 connections routed, 935 tracks and 95 vias.
- C13 (100 nF) moved closer to ESP32-S3 U1; fine PDN analysis now reports 9.76 mm distance to the load, improved from approximately 13 mm. It is still farther away than ideal.

## Important limitations

This is an engineering source snapshot, not a manufacturing release:
- The repository snapshot does not yet include a reproducible PCB-generation script (`scripts/board.py`) or the complete project footprint-library bundle. The routed `.kicad_pcb` is the authoritative current board snapshot.
- MODEM_5V_EXT and MODEM_5V_RAW have no modeled loads. Current DC/thermal analysis does not represent modem transmit-current peaks or full system load.
- 12/24 V automotive transient/load-dump, reverse-polarity, fuse/TVS coordination, thermal, connector and exact modem-carrier checks remain open.
- Independent schematic/layout review and bench validation are required before vehicle installation.

Do not generate or order manufacturing files from this snapshot until all open engineering gates are closed and a separate release approval is recorded.
