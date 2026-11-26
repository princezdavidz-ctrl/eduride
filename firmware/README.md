# Edu Ride Embedded Firmware

## Platform
- MCU: ESP32-S3 (controller only; no student recognition inference).
- Framework: ESP-IDF, FreeRTOS, CMake.
- Languages: C/C++ with module boundaries and interface contracts.
- Variants: `gps_only` and `vision_gps`; compile-time capabilities and device registration must agree with server-side variant policy.

## Responsibilities
1. Safe boot and self-diagnostics.
2. GNSS acquisition and quality-aware location reporting.
3. Cellular modem control, link status and reconnection.
4. Driver controls (buttons, LEDs, buzzer) and trip state machine.
5. Durable event queue, deduplication and retry/backoff.
6. Secure transport, device identity, configuration and firmware updates.
7. Watchdog, health monitoring and bounded fault recovery.
8. Optional vision-computer link on Vision + GPS variant only.

## Non-responsibilities
- Face recognition or student identity inference.
- Making an uncertain recognition result a confirmed boarding record.
- Direct parent notifications (backend owns communication and delivery).
- Vehicle engine control, immobilization, braking or safety-critical control.

## Suggested source layout
```
firmware/
  CMakeLists.txt
  sdkconfig.defaults
  components/
    eduride_core/       # startup, state machine, common types
    eduride_gnss/       # GNSS parser and quality checks
    eduride_modem/      # modem interface and link state
    eduride_events/     # event definitions, validation, sequence IDs
    eduride_queue/      # durable queue and replay
    eduride_driver/     # buttons, LEDs, buzzer
    eduride_security/   # device identity and TLS helpers
    eduride_health/     # health, watchdog, diagnostics
    eduride_vision/     # optional vision-link component
    eduride_ota/        # signed update lifecycle
  main/
    app_main.c
  docs/
    PIN_MAP.md
    PROTOCOL.md
    TEST_PLAN.md
```

## Firmware implementation gates
- [ ] Confirm PCB pin map against schematic and actual assembled board revision.
- [ ] Confirm GNSS and modem model/firmware and UART/flow-control requirements.
- [ ] Define variant and device provisioning procedure.
- [ ] Implement state machine and event format.
- [ ] Implement GNSS parser with stale/invalid-data handling.
- [ ] Implement modem state machine and reconnect policy.
- [ ] Implement durable event queue and duplicate-safe upload.
- [ ] Implement driver controls and event acknowledgement semantics.
- [ ] Implement TLS, device credentials and server-side authorization.
- [ ] Implement secure OTA and rollback policy.
- [ ] Implement optional vision link for Vision + GPS variant.
- [ ] Hardware-in-loop, fault-injection, power-loss, security and road-test checks (not yet performed).

## Engineering caution
Firmware pin mappings and hardware interfaces are provisional until checked against the finalized PCB revision, exact module datasheets and bench measurements. This repository documentation is not evidence of validated or vehicle-ready firmware.
