# Cellular Modem Driver Contract

## Current implementation boundary

The controller has a documented modem UART/control pin assignment, but no exact modem, carrier board, SIM interface, supply requirement or carrier profile has been selected. This change adds only a hardware-agnostic lifecycle/status contract.

The generic module does not:
- toggle MODEM_PWRKEY (GPIO38) or MODEM_RESET (GPIO39);
- configure modem UART on GPIO15/GPIO16;
- assume UART baud, AT command dialect, logic voltage or pin polarity;
- select a SIM slot, APN, PDP type, band or carrier;
- claim cellular registration or packet-data connectivity;
- start the HTTPS event uploader.

A future modem-specific adapter must validate its datasheet and carrier-board documentation before reporting progress through the generic interface.

## State machine

| State | Meaning |
|---|---|
| OFF | Modem is not confirmed powered/available |
| POWERING | Adapter is executing the documented power-up sequence |
| SIM_CHECK | Adapter is checking SIM presence/readiness and PIN state |
| REGISTERING | Adapter is seeking/confirming network registration |
| PDP_CONNECTING | Adapter is establishing packet-data context |
| ONLINE | Adapter has verified packet-data connectivity |
| DEGRADED | Modem is present but service is impaired or unavailable |
| FAULT | Adapter detected a fault requiring controlled recovery/service |

Expected path: `OFF -> POWERING -> SIM_CHECK -> REGISTERING -> PDP_CONNECTING -> ONLINE`.

Loss of service should move ONLINE to DEGRADED. Recovery may proceed through REGISTERING or PDP_CONNECTING. FAULT may only return to OFF before a new start sequence. Invalid transitions are rejected.

The API records state, last error, signal-quality observation, SIM readiness, packet-data readiness and monotonic state-change time. Signal quality has no assumed scale; the selected adapter must document its modem-specific mapping.

## Board mapping (provisional until assembled-board review)

- MCU TX to modem RX: GPIO15
- MCU RX from modem TX: GPIO16
- MODEM_PWRKEY: GPIO38
- MODEM_RESET: GPIO39
- MODEM_STATUS: GPIO40
- Connector J2: modem UART and control signals

This is a logical net mapping only. Confirm J2 pin order, supply availability, signal direction, voltage thresholds, pull-ups, level shifting, reset polarity and power-key timing against the exact PCB revision and selected modem/carrier board.

## Adapter integration requirements

1. Identify exact modem and carrier-board manufacturer part numbers and hardware revisions.
2. Confirm supply voltage range, peak/transmit current, transient response, connector pinout and ground return. Do not use a rail that has not been sized for modem peak current.
3. Confirm UART logic levels and whether level translation is required.
4. Confirm PWRKEY/RESET/STATUS polarity, timing, open-drain requirements and startup/shutdown sequence.
5. Confirm SIM format, SIM voltage, PIN handling and carrier/APN/PDP configuration.
6. Confirm supported radio bands, network technology, Kenyan operator compatibility, antenna requirements and regulatory approvals.
7. Implement modem-specific UART framing, AT parser, command timeouts, unsolicited-result handling and bounded recovery.
8. Report state changes through `er_cellular_link_transition`; never report ONLINE until a real packet-data test succeeds.
9. Keep credentials out of logs and source. Use provisioned secrets and authenticated TLS.
10. Start event upload only after valid provisioning, trusted server CA, valid device token and confirmed packet-data connectivity.

## Event uploader integration gate

`er_event_uploader_start()` is not called by the supervisor. Future integration must gate it on successful provisioning and validated configuration, secure credential storage, verified ONLINE packet data, HTTPS endpoint and trusted root CA, backend migration/endpoint availability, and a defined stop/restart lifecycle.

## Required validation before enabling a modem

- Schematic and assembled-board J2 continuity/polarity review.
- Supply transient/current measurement during network attach and transmit.
- UART voltage and waveform verification.
- Power-up, reset, shutdown and brownout behavior.
- SIM absent, PIN locked, invalid APN, no coverage, roaming and registration-denied cases.
- Network loss/recovery and repeated attach cycles.
- TLS certificate failure, DNS failure, HTTP timeout, server rejection and duplicate event acknowledgement.
- Long-duration thermal, power and reconnect testing.
- Confirm GPS-only and Vision + GPS variants share secure transport policy without enabling vision capabilities on GPS-only devices.

All tests above are planned only; none are claimed as completed by this firmware scaffold.
