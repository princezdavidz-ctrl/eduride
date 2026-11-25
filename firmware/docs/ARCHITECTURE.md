# Edu Ride Firmware Architecture

## Task model
Use FreeRTOS tasks with bounded execution, explicit queues, task watchdog participation and priority separation. Do not perform blocking network work in GNSS parsing, button handling or event generation.

| Task | Responsibilities | Policy |
|---|---|---|
| Supervisor | Startup sequencing, subsystem state, variant capability checks | Owns system state transitions |
| GNSS | UART parser, fix validity, freshness, PPS/time if available | Emits location snapshots; no networking |
| Modem | Modem power/control, registration, signal, transport | Reconnect with bounded exponential backoff |
| Event | Create, validate, sequence, persist events | Durable before acknowledging critical event |
| Transport | Upload queued data, receive commands/config | TLS; retry and deduplicate |
| Driver UI | Debounce buttons, LED patterns, buzzer | Never blocks on network |
| Health | Heap, task status, GNSS/modem status, supply inputs where available | Report faults, no unsafe recovery loops |
| Vision Link | Optional authenticated link to Linux vision computer | Compiled/activated only for Vision + GPS |

## Boot sequence
1. Read/reset-cause and initialize watchdog.
2. Load configuration and verify integrity; reject invalid configuration safely.
3. Initialize board interfaces and identify firmware variant.
4. Initialize durable queue and recovery scan.
5. Initialize GNSS and modem independently; one failure must not prevent diagnostics from running.
6. Start supervisor-managed operational state and report health when connectivity permits.

## Trip state machine
- IDLE: trip not active.
- READY: device healthy enough to start trip; GPS/network may be degraded but clearly reported.
- ACTIVE: trip started, events and location snapshots are associated with trip ID.
- END_PENDING: end event persisted and awaiting sync.
- DEGRADED: a subsystem is impaired; continue safe functions and communicate status.
- FAULT: unrecoverable or critical subsystem fault requiring controlled recovery or service.

Trip state must be persisted across resets; no state may silently fabricate an active trip or location.

## Offline queue
- Store events atomically with unique event ID, device sequence and trip context.
- Queue is bounded. On capacity pressure, never silently discard critical boarding/trip events; alert, preserve prioritized event records and record any loss of noncritical telemetry.
- Use checksums and power-loss recovery.
- Upload batches with acknowledgement; remove only acknowledged records.
- Backend deduplication is required because retries may duplicate deliveries.
- Keep student data minimal; do not store facial images or recognition embeddings on the controller.

## Security
- TLS with server authentication; device identity and credential lifecycle.
- No shared default device secret or secret committed to source.
- Secure Boot and flash encryption enabled in release configuration where hardware and provisioning support them.
- Credential rotation/revocation and secure manufacturing provisioning documented.
- Signed OTA images, version checks, rollback protection and controlled rollback to known-good image.
- Validate command authorization, payload schema, freshness and replay protection.
- Debug interfaces and logs must not leak credentials or student identifiers.

## Variant isolation
GPS-only builds must not contain or expose the camera/vision event interface, image capture, image storage or recognition capability. Vision + GPS builds may communicate with the separate vision computer but cannot themselves run facial recognition. Backend and provisioning must enforce the registered variant, not trust a firmware claim alone.

## Fault policy
- GNSS failure: mark location unavailable/stale; preserve last valid snapshot with age; never report it as current.
- Cellular failure: persist events and retry; UI indicates offline/degraded state.
- Vision-link failure: GPS and controller functions continue; recognition events unavailable; never convert this to a confirmed boarding event.
- Watchdog reset: record reset reason; recover queue; do not automatically start or end trips without explicit persisted state logic.
- Critical power/system faults: alert and attempt controlled recovery without interfering with vehicle operation.
