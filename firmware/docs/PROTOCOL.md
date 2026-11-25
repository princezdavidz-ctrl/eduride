# Edu Ride Controller Event and Transport Contract v1

The backend endpoint is `POST /api/device/events`; see `backend/docs/DEVICE_EVENT_API.md`.

- schema_version: 1.
- event_id: 32 lowercase hex characters, generated once and stable across retries.
- device_id: provisioned device_code.
- device_sequence and monotonic_time_us: uint64 decimal strings.
- event_type: BOOT, TRIP_STARTED, TRIP_ENDED, STUDENT_BOARDING_MATCHED, STUDENT_BOARDING_UNCERTAIN, STUDENT_BOARDING_UNMATCHED, DRIVER_PICKUP_CONFIRMED, DRIVER_NEXT_STOP, DEVICE_HEALTH, DEVICE_FAULT.
- event_time_utc: ISO-8601 UTC or null when time is untrusted.
- time_quality: UNSYNCED, RTC, GNSS, NETWORK.
- trip_id: opaque identifier or null.
- firmware_version, hardware_revision, variant, and minimal payload object (max 192 UTF-8 bytes).

POST batches of 1–10 events with X-Device-Token over HTTPS. Server derives device/bus/organization from credentials. Exact event IDs are acknowledged. Duplicate (device,event_id) is safe; reused sequence with a different ID is rejected. Delete only acknowledged/duplicate IDs from persistent storage; retain rejected/unacknowledged events.

GPS_ONLY cannot submit STUDENT_BOARDING_* events. Never include student names/IDs, biometrics, images, embeddings, parent contacts or credentials. Backend remains authoritative for recognition, roster and notifications.

Retry transient errors with bounded exponential backoff and jitter; preserve event ID and sequence. Validate TLS certificates; no plaintext fallback. Surface permanent auth/schema errors as device faults. Never accept arbitrary remote commands.
