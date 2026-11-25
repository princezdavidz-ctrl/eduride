# Edu Ride Dual-Board Architecture — Vision and GPS Variants

**Status:** System architecture baseline for schematic design; not a fabrication release.

## 1. Product requirement

Edu Ride shall support two distinct vehicle hardware variants connected to one shared backend. Both variants have a driver dashboard. Only the Vision Board has camera hardware and student image capture.

| Capability | Board 1 — Vision + GPS | Board 2 — GPS only |
|---|---:|---:|
| Vehicle location / GNSS | Yes | Yes |
| Cellular backend connection | Yes | Yes |
| Camera and student boarding image capture | Yes | **No** |
| Student recognition | Backend computer vision | Not applicable |
| Boarding event reporting | Yes, from backend-confirmed recognition and/or approved fallback | No camera-derived recognition |
| Driver dashboard | Yes | Yes |
| Driver buttons / status indicators | Yes | Yes |
| Image storage / upload queue | Yes, encrypted and bounded | **No image subsystem** |

## 2. Shared backend flow

1. Each board authenticates as a provisioned bus/device and reports bus ID, timestamp, GNSS position, connectivity and health.
2. Board 1 captures a boarding event at the doorway. It sends a privacy-minimized image/frame or short event clip to the backend over an authenticated encrypted connection. Avoid continuous video streaming by default; use event-triggered capture, compression, upload retries and a bounded encrypted offline queue.
3. Backend computer vision performs student matching against the school's authorized student reference set. It must return a confidence score and an explicit outcome: matched, uncertain, or unmatched.
4. Only a sufficiently confident, policy-approved match creates a confirmed boarding event. Uncertain cases go to a safe manual confirmation workflow; never silently guess a child's identity.
5. Backend associates the event with the bus, route, student, school and parent/guardian notification preferences, then sends the appropriate parent and school messages.
6. Both boards report GPS telemetry for live bus tracking, route progress and arrival estimates. Board 2 reports no images and cannot create image-derived identity events.

## 3. Board 1 — Vision + GPS hardware

Board 1 is a two-processor architecture:

- **Vehicle controller MCU:** ESP32-S3-WROOM-1-N16R8 for vehicle power-state monitoring, GNSS, buttons, LEDs, buzzer, dashboard control interface and watchdog / health reporting.
- **Vision capture computer:** a separately selected Linux-capable compute module or camera processor with a supported camera interface (for example MIPI CSI-2 or USB, selected only after camera and compute-module datasheets are reviewed). It captures doorway images/event clips and securely transfers them to the backend.
- **Cellular data path:** select a modem/carrier and interface that the vision computer can actually use for image upload (USB data is a likely option); define whether the ESP32 shares telemetry through UART or a separate modem interface. Do not assume the ESP32-S3 alone can handle high-bandwidth camera ingestion, image encoding and reliable cellular upload.
- **Camera:** mount at the bus entrance with controlled field of view, suitable low-light performance, vibration-resistant mounting and a protected cable/connector. The camera must cover the boarding zone without unnecessarily recording unrelated cabin activity.
- **Dashboard:** the same external display controller / HDMI touchscreen arrangement as Board 2. The Linux vision computer or ESP32 may provide dashboard data, but the display controller owns HDMI video; do not route HDMI through ESP32 GPIO.
- **Storage:** encrypted, bounded event buffer with automatic expiry and upload acknowledgement. Avoid retaining raw child images longer than the approved operational retention policy.

The 100 × 80 mm board size must be re-evaluated for Board 1. A camera/vision compute module, cellular modem, power conversion and thermal requirements may require a larger carrier board or a separate compute module enclosure. Do not assume the existing 100 × 80 mm target fits without placement and thermal analysis.

## 4. Board 2 — GPS-only hardware

Board 2 is a simpler controller variant:

- ESP32-S3-WROOM-1-N16R8 (or a separately validated controller) for GNSS acquisition, cellular telemetry, dashboard controls, indicators, buzzer and display communication.
- GNSS receiver and antenna.
- Cellular modem / data connection for location and device-health telemetry.
- External display controller and HDMI touchscreen.
- Vehicle-grade protected power input.
- **No camera connector, camera sensor, CSI/USB camera interface, image buffer, image upload service or student biometric recognition component.** The PCB and firmware feature set must enforce this separation.

Board 2 may show bus location, route, next stop, connectivity, speed and driver prompts on its dashboard. It must not claim that a student has boarded based on image recognition.

## 5. Dashboard requirements common to both boards

The driver dashboard should display, as applicable:

- Bus identity and assigned route.
- GPS fix, current location, speed and connectivity status.
- Next stop and route progress.
- Vision-board camera / recognition service health (Board 1 only).
- Boarding confirmations and unresolved/uncertain boarding cases (Board 1 only).
- System power, modem, GNSS and storage health.
- Clear offline / retry / fault indicators and a safe manual fallback.

The dashboard must not distract the driver while the vehicle is moving. Use large high-contrast status elements, limited interaction while moving and audible/visual prompts only where appropriate.

## 6. Privacy, security and child-safety requirements

Student face recognition involves sensitive biometric information, and the subjects are children. Before deployment, Edu Ride must complete a privacy impact assessment and obtain the required school, parent/guardian and legal approvals under applicable Kenyan data-protection requirements. Define lawful purpose, transparency, consent or other valid legal basis, access controls, retention/deletion, breach response and data-subject rights with qualified counsel / the responsible data-protection officer.

Technical controls:
- TLS for all board-to-backend traffic; per-device identity, credentials and revocation.
- Encrypt image buffers at rest; do not store credentials or reference face data in plaintext.
- Minimize capture to boarding events and the doorway zone; privacy mask unrelated areas where practical.
- Role-based access and audit logs for image access and student matching.
- Separate image storage and access from ordinary GPS telemetry.
- Define retention limits and automated deletion; no indefinite image retention.
- Never expose images or biometric templates to parents or unrelated school users.
- Provide a non-biometric/manual attendance alternative for opt-outs, low confidence, camera faults or connectivity loss.
- Do not use face recognition as the sole safety mechanism for deciding whether a child is on the bus.

## 7. Hardware design gates

1. Confirm camera model, lens, field of view, resolution, frame rate and low-light requirements.
2. Select a supported vision compute module and verify camera interface, RAM, thermal design, boot/storage and operating temperature.
3. Select cellular modem/carrier with verified upload interface and realistic uplink performance; test burst current and antenna performance.
4. Define offline capture queue capacity, encryption, retention and retry behavior.
5. Keep Board 2 physically and logically camera-free.
6. Design common vehicle power protection for 12/24 V with reverse-polarity and automotive transient validation.
7. Capture separate KiCad variants/sheets and BOMs; run ERC/DRC and verify each board independently.
8. Validate camera recognition performance in real bus lighting, movement, occlusion and crowded boarding conditions before relying on automated notifications.

**Release status:** Architecture baseline only. No completed schematic, ERC/DRC, camera qualification, privacy approval or automotive qualification is implied.
