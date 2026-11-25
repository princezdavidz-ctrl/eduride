# Edu Ride Controller Event and Transport Contract (Draft)

This is an initial firmware/backend contract, subject to backend API alignment.

## Event envelope
Each event includes:
- `event_id`: random UUID.
- `device_id`: provisioned device identity.
- `device_sequence`: monotonically increasing sequence number persisted across reboot.
- `event_type`: enumerated event name.
- `event_time_utc`: UTC timestamp only when time quality is sufficient.
- `time_source`: GNSS, synchronized server time, or unknown.
- `time_quality`: valid, estimated, or unknown.
- `trip_id`: nullable trip identifier.
- `firmware_version` and `hardware_revision`.
- `variant`: GPS_ONLY or VISION_GPS.
- `payload`: schema-validated, minimal data for event type.

## Location payload
- latitude/longitude only when a valid GNSS fix exists.
- fix quality, satellites used, speed, heading when valid.
- capture timestamp and age/validity.
- accuracy estimate when the receiver provides it.

## Event categories
- Device lifecycle and health: boot, health report, fault, recovery.
- GNSS: fix acquired/lost, location snapshot.
- Trip: trip started/ended.
- Driver interaction: acknowledgement, confirm, reject.
- Boarding: backend/vision-originated event status passed through, not inferred by the controller.
- Connectivity: network offline/restored.

## Boarding safeguards
- Controller-originated driver confirmation must reference the event ID and explicit decision.
- A vision result is a candidate until backend/driver policy confirms it.
- Uncertain/unmatched results must remain unconfirmed.
- GPS-only device rejects vision-specific payloads.
- The backend is authoritative for student roster, recognition result, notifications and event status.

## Transport behavior
- Prefer secure TLS transport (HTTPS API or authenticated MQTT over TLS once backend decides).
- Device authenticates using provisioned credentials; authorization is device- and variant-specific.
- Batch event uploads; server acknowledgements specify accepted event IDs/sequences.
- Retries use backoff and jitter; transport retries must not alter event identity.
- Validate inbound commands for signature/authentication, schema, expiry and replay.
- Firmware does not accept arbitrary remote shell, executable payloads or unbounded commands.
