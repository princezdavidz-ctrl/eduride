# Edu Ride Embedded Firmware — Test List (Deferred)

No tests in this document are claimed to have passed. Execute in the dedicated testing phase.

## Unit tests
- GNSS parsing, invalid sentences, missing fields, checksum failure and stale-fix handling.
- Event envelope schema, sequence persistence, ID generation and duplicate detection.
- Trip-state transition legality.
- Button debounce, short/long press and stuck input.
- LED/buzzer pattern scheduler.
- Queue atomicity, corruption recovery, capacity policy and power-loss recovery.
- Time quality and UTC conversion.
- Variant capability enforcement.
- Event JSON serialization, uint64 decimal-string preservation and sensitive-payload rejection.

## Integration tests
- GNSS UART and receiver reset/recovery.
- Modem UART, registration, data session, reconnect and modem reset.
- Backend authentication, upload acknowledgement, retry and duplicate delivery.
- Offline queue replay in order and partial batch acknowledgement.
- Lost response after server commit followed by safe duplicate retry.
- Reused sequence with different event ID rejection.
- Unknown device, wrong device ID, variant mismatch and invalid event schema rejection.
- GPS-only rejection of all STUDENT_BOARDING_* event types.
- Driver confirmation workflow with uncertain recognition.
- Vision computer link authentication, disconnect/reconnect and malformed payload rejection (Vision + GPS only).
- Configuration download, validation and rollback.
- OTA signature validation, interrupted update and rollback.

## Fault and security tests
- Brownout, sudden power removal, repeated reboot and queue recovery.
- GNSS loss, modem loss, antenna faults where testable, time drift.
- Queue full and flash wear behavior.
- TLS failure, certificate rejection, revoked credentials and credential rotation.
- Replay, malformed messages, unauthorized commands and variant mismatch.
- Secure boot, flash encryption, OTA signing and anti-rollback checks.
- Watchdog timeout, task deadlock and recovery behavior.
- Privacy audit: logs and stored data do not contain unnecessary student personal data, images or embeddings.

## Hardware-in-loop / field validation
- Pin map confirmation against schematic and PCB revision.
- Button, LEDs and buzzer electrical behavior.
- GPS accuracy and time behavior under real installation conditions.
- Cellular coverage and offline operation.
- Vehicle power transient, temperature, vibration and EMI/EMC review.
- Enclosure, antenna placement and cable installation.
- Supervised route trial with synthetic/authorized test data; no production student recognition deployment until privacy and safety approvals.

- Uploader exact-ID acknowledgement parsing, malformed JSON and oversized response handling.
- HTTPS-only URL validation, root-CA trust and credential redaction.
- Uploader remains inactive until endpoint, device token and trusted CA are securely provisioned.

- Authenticated config returns server-assigned device variant and capabilities; revoked credentials receive 401.
- Duplicate device-code provisioning is refused; rotation invalidates old token; revocation prevents config/event access.
- Secure token delivery, encrypted storage lifecycle, interrupted provisioning and factory-reset recovery.

- Firmware event journal refuses all three STUDENT_BOARDING_* event types when initialized as GPS_ONLY.
