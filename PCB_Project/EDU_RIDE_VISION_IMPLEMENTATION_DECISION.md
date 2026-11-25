# Edu Ride Vision Implementation Decision

**Decision:** Board 1 uses camera-based student face matching, with all identity matching performed by the Edu Ride backend. Board 1 is a capture and secure transport device, not the authoritative identity engine. Board 2 remains GPS-only and has no camera or biometric capability.

**Status:** Approved architecture direction for engineering design. Not production approval or legal authorization to process children's biometric data.

## 1. End-to-end boarding workflow

1. Board 1 starts only when the bus is in an authorized boarding state / at a configured stop, subject to product safety policy.
2. The entrance camera observes the boarding zone. Edge logic may detect a person crossing the doorway and select a small number of useful frames; it must not make the final student identity decision.
3. The vision computer packages an event with device ID, bus ID, route/stop context, event timestamp, camera ID and image/frame reference. Avoid continuous cabin video.
4. The device encrypts the event in a bounded local queue and uploads it over authenticated TLS when connectivity is available.
5. The backend validates device identity, bus assignment, route context, timestamp, image integrity and event replay protection.
6. The backend compares the submitted face against only the authorized student reference records for that school / route / trip. It returns one of:
   - MATCHED: confidence meets the configured, validated threshold and policy permits automatic confirmation.
   - UNCERTAIN: image quality, occlusion, multiple faces or confidence is insufficient; require manual review/driver confirmation.
   - UNMATCHED: no eligible student match; do not create a confirmed student boarding event.
   - REJECTED: invalid device, unauthorized context, expired event, corrupt payload or policy restriction.
7. Only a valid MATCHED result creates a confirmed boarding event. An UNCERTAIN result creates a pending case, not an attendance confirmation.
8. The notification service sends parent/guardian and school messages according to verified student-to-guardian relationships and notification preferences.
9. The backend acknowledges the event. Board 1 removes the queued image according to the approved retention policy; retries must be idempotent.
10. On connectivity loss, retain only the minimum encrypted event data for the approved short period. Do not show an unverified event as confirmed.

## 2. Hardware consequences for Board 1

The existing ESP32-S3 remains the vehicle controller for GNSS, buttons, LEDs, buzzer, watchdog, power-state and dashboard control. It is not the primary camera ingest, face-embedding or image-upload processor.

Board 1 therefore needs a separately selected vision computer with:
- Supported camera interface (USB or MIPI CSI-2, determined by the selected compute module).
- Adequate RAM and hardware/software support for camera capture, image encoding and secure networking.
- Storage for a bounded, encrypted offline event queue.
- Cellular data connectivity with a verified data path from the vision computer. Do not assume the ESP32 UART modem connection can carry image uploads.
- Thermal design and power budget for the compute module, camera and modem under hot vehicle conditions.
- A watchdog / health interface to the vehicle controller and a controlled power-down strategy.

The camera should be mounted to capture the entrance/boarding zone, with a suitable lens, low-light capability, exposure control, vibration-resistant mounting and protected cabling. Verify the actual field of view in a representative bus before freezing the enclosure.

## 3. Backend services required

Separate services or bounded modules should provide:
- Device identity, provisioning, authentication, revocation and bus assignment.
- Image/event ingestion with payload limits, content validation, TLS and replay protection.
- School-tenant-isolated student reference data and face matching.
- Match confidence calibration and explicit matched / uncertain / unmatched outcomes.
- Boarding-event ledger with idempotency keys and auditable status transitions.
- Parent/guardian relationship verification and notification preferences.
- Parent and school notification delivery with retry, delivery status and duplicate suppression.
- Image retention/deletion lifecycle, access audit and data-subject request handling.
- Monitoring for recognition quality, false matches, false non-matches, camera health, upload failures and notification failures.

Do not place face templates or raw student images in ordinary GPS telemetry records. Keep image and biometric stores logically and access-control separated from fleet-location data.

## 4. Recognition quality and fallback

Before pilot use, evaluate the complete workflow on representative bus-entry footage and lighting:
- Daylight, shade, dusk and night lighting.
- Motion blur, camera vibration, backlighting and partial face visibility.
- Children boarding in groups, occlusion, masks/headwear and similar-looking students.
- Camera angle, height, lens distortion and changes in student appearance.
- Network loss, delayed upload, duplicate event delivery and device clock drift.

Measure false-match and false-non-match rates by relevant operating conditions. Set thresholds using validation data and a documented risk policy; do not choose a threshold merely to maximize automatic matches. If performance is uncertain, fall back to driver confirmation or a non-biometric identifier. Facial recognition must not be the sole safety control for determining whether a child is present.

## 5. Child privacy and deployment gate

Face recognition of children is sensitive biometric processing. Before any real-student pilot:
- Complete a data-protection impact assessment and obtain advice from the responsible data-protection officer / qualified Kenyan counsel.
- Establish the applicable lawful basis, notices, parent/guardian authorization where required, student rights and opt-out route.
- Provide an equivalent non-biometric process for students who opt out or cannot be reliably recognized.
- Limit image capture to the boarding zone and necessary boarding events.
- Encrypt data in transit and at rest; use per-device credentials, least-privilege access, audit logs and key rotation.
- Define a short, purpose-limited image retention period and automatic deletion after the event is resolved, subject to documented legal obligations.
- Restrict access to authorized school roles; do not expose raw images or biometric templates in parent-facing apps.
- Prohibit secondary use such as discipline profiling, advertising, generalized surveillance or model training without a separately reviewed lawful basis and authorization.
- Establish breach response, correction/appeal, deletion and complaint workflows.

No real children's biometric data should be collected during development or testing without the required approvals. Use synthetic, consented adult or otherwise properly authorized test data.

## 6. Board 2 invariants

Board 2 must remain camera-free by design:
- No camera connector or sensor footprint.
- No camera/vision compute module.
- No image capture, image buffer, image upload endpoint or face template.
- No biometric matching capability in its firmware.
- GNSS, cellular telemetry, vehicle controls and dashboard only.

Backend authorization must also enforce the device variant. A GPS-only device must not be able to submit image events or claim camera-derived boarding recognition.

## 7. Next engineering sequence

1. Select and verify a vision compute module and compatible camera from manufacturer documentation.
2. Build a camera + compute-module bench prototype and validate field of view / low-light performance.
3. Define the image event API and device provisioning contract.
4. Implement backend ingestion, tenant-isolated matching, event ledger and notification state machine.
5. Design the shared automotive power subsystem with separate power budgeting for the vision computer and modem.
6. Capture two independent KiCad variants: Vision + GPS and GPS-only.
7. Run ERC/DRC, power/thermal testing, camera validation and security/privacy reviews before a vehicle pilot.

**Release status:** Decision record only. No component has yet been selected or qualified, and no production or vehicle-installation readiness is claimed.
