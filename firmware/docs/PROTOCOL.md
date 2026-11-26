# Edu Ride Controller Event and Transport Contract v1

Backend endpoint: POST /api/device/events; see backend/docs/DEVICE_EVENT_API.md. Firmware uploader: event_uploader.c, opt-in through er_event_uploader_start.

Each event contains schema_version 1, stable 32-character lowercase hexadecimal event_id, provisioned device_code, uint64 decimal-string device_sequence and monotonic_time_us, event_type, nullable trip_id, nullable ISO-8601 UTC event_time_utc, time_quality, firmware_version, hardware_revision, variant and a minimal operational JSON payload (maximum 192 UTF-8 bytes).

Uploader sends one event per HTTPS request using X-Device-Token. TLS verification requires a trusted root CA supplied by secure provisioning. No plaintext or insecure certificate fallback is permitted. Backend derives device, bus and organization from the token.

Only exact IDs returned in acknowledged or duplicates are removed from persistent storage. Rejected, missing and unacknowledged events remain queued. Retry with bounded exponential backoff and jitter without changing event ID or sequence. GPS_ONLY cannot submit STUDENT_BOARDING_* events. Never include student names/IDs, biometrics, images, embeddings, parent contacts or credentials.

Uploader is not started by app_main. Secure provisioning must deliver endpoint, device token and CA. Do not hardcode secrets or enable upload before provisioning is implemented and reviewed.
