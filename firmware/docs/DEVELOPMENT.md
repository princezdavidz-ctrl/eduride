# Firmware Development Setup

Requirements: ESP-IDF toolchain (version to be pinned after compatibility review), CMake and Ninja.

Build in an ESP-IDF shell from this directory:

```bash
idf.py set-target esp32s3
idf.py build
```

Flash/monitor instructions are withheld until board pin mapping, power and USB interfaces are verified.

This scaffold starts a supervisor FreeRTOS task and reports a degraded placeholder state. It does not yet initialize GPIO, GNSS, modem, microSD, buttons, buzzer, vision link, networking or OTA.
