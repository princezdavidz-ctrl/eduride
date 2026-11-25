# Device Event Ingestion API v1

Endpoint: `POST /api/device/events`
Authentication: unique per-device `X-Device-Token`. Deploy behind HTTPS with certificate validation; no plaintext fallback. The server derives device, bus and organization from the credential.

## Request
Batch size 1–10; HTTP body limit 16 KiB. Keep events queued until their exact IDs are acknowledged.

```json
{
  "schema_version": 1,
  "events": [{
    "event_id": "0123456789abcdef0123456789abcdef",
    "device_id": "BUS-DEVICE-001",
    "device_sequence": "42",
    "event_type": "DEVICE_HEALTH",
    "trip_id": null,
    "event_time_utc": "2026-11-25T10:30:00.000Z",
    "monotonic_time_us": "987654321",
    "time_quality": "GNSS",
    "firmware_version": "0.1.0",
    "hardware_revision": "rev-a",
    "variant": "gps_only",
    "payload": {"state":"degraded"}
  }]
}
```

device_id is the provisioned device_code and must match the authenticated device. Sequence and monotonic values are decimal strings to preserve uint64 precision. event_time_utc is null when time is untrusted. trip_id is a bounded opaque string or null.

Allowed types: BOOT, TRIP_STARTED, TRIP_ENDED, STUDENT_BOARDING_MATCHED, STUDENT_BOARDING_UNCERTAIN, STUDENT_BOARDING_UNMATCHED, DRIVER_PICKUP_CONFIRMED, DRIVER_NEXT_STOP, DEVICE_HEALTH, DEVICE_FAULT. GPS_ONLY cannot submit STUDENT_BOARDING_* events. Payload is an object no larger than 192 UTF-8 bytes; identity, biometric, image and parent-contact fields are rejected. Do not send student PII.

## Response
HTTP 202 returns `acknowledged`, `duplicates` and `rejected` arrays. Repeated (authenticated device,event_id) is acknowledged as duplicate without another insert. Reusing a sequence with another event ID is rejected. Remove only exact IDs listed in acknowledged or duplicates from local storage. Rejected and unacknowledged events remain queued.

Transient errors use bounded exponential backoff and jitter; never change event ID or sequence on retry. Permanent schema/auth failures must surface as device faults. Apply schema with `npm run migrate`; provision unique device tokens and never commit them. Put the service behind a trusted TLS proxy.
