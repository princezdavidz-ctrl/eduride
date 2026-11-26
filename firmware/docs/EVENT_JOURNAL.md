# Event Journal

## Purpose

A bounded, persistent metadata queue on the controller. Each event carries a random 128-bit hexadecimal event ID, a monotonically increasing per-device sequence, device and trip identifiers, hardware/firmware metadata, variant, event type, time-quality metadata and a bounded payload string.

No student name, face template, raw image, image bytes, parent contact or credential belongs in this journal. The vision computer/backend own image processing and student identity resolution.

## Persistence and recovery

- Prototype implementation stores each event as a CRC-protected NVS blob in one of 32 fixed slots.
- The next sequence value is committed before the event blob. Power loss between these commits can create a sequence gap but does not reuse a sequence.
- Each slot is independently committed. On boot, consumers scan slots and process the lowest valid sequence first.
- A backend acknowledgement must reference the exact event ID. Only that slot is erased.
- Repeated upload after a lost acknowledgement is expected. The backend must enforce a unique constraint on `(device_id, event_id)` and treat duplicates idempotently.
- CRC-invalid or size-invalid slots are ignored by scanning; they require diagnostic reporting and recovery policy before production.
- The factory-reset API erases event slots but deliberately retains the sequence counter.

## Important limitations

NVS is a prototype backend for low-rate event metadata, not a high-volume production event log. Repeated commits consume flash endurance; capacity is 32 records; there is no SD-card spillover, encryption policy implementation, upload worker, backoff scheduler, server acknowledgement protocol or durable event migration. Do not store images or large payloads here.

The production storage decision must be made after selecting and validating the microSD socket/card and defining a power-fail-safe FAT/append-only journal. Secure flash encryption and device identity provisioning must also be configured before field deployment.

## Event policy

- A matched boarding event is only created after backend vision approval.
- UNCERTAIN and UNMATCHED recognition states remain distinct and are never promoted to MATCHED by this firmware.
- Driver confirmation is a separate event and must refer to the related server event in its metadata once the protocol defines that reference.
- Event timestamps with no trusted wall clock carry UTC zero and `ER_TIME_UNSYNCED`; monotonic timestamps are local to one boot.
- Device ID must be provisioned; the journal refuses an unknown variant or blank device ID.

## API

See `main/event_journal.h`. The journal provides init, enqueue, oldest-first peek, exact-ID ack, count and factory-reset clear operations. It is not thread-safe at the application level beyond its internal mutex, and the caller must initialize it once before use.

## Validation status

Code committed for review only. No ESP-IDF compile, power-cut test, NVS wear test, CRC corruption test, queue-capacity test or backend idempotency test has been performed. Add these to Phase 5 testing.
