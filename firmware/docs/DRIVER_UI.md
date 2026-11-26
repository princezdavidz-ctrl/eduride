# Driver UI Firmware Component

## Scope

This ESP-IDF component reads the three driver buttons and controls the three onboard indicator LEDs. It is intentionally independent from trip state, event persistence, GNSS and cellular transport.

## Default safety state

`CONFIG_ER_ENABLE_DRIVER_UI` defaults to `n`. With the option disabled, all public functions return `ESP_ERR_NOT_SUPPORTED` and no GPIO is configured. Do not enable it for field operation until the assembled PCB revision and electrical review are complete.

## Recovered electrical behavior

- SW3 / PICKUP_CONFIRM: active-low, switch closes to GND.
- SW4 / NEXT_STOP: active-low, switch closes to GND.
- SW5 / MENU_BACK: active-low, switch closes to GND.
- Internal ESP32 pull-ups are enabled by the component; the current schematic does not show external pull-ups on these nets.
- D2 / LED_GPS, D3 / LED_NET and D4 / LED_STATUS: active-high, LED cathodes to GND, anodes fed through R16/R17/R18.
- Buzzer is not driven by this component. J8 exposes V5_LOGIC and BUZZER_CTRL but the current schematic does not define the buzzer or its driver stage.

## API behavior

- `er_driver_ui_start()`: creates a bounded 16-event queue, configures the button inputs and LEDs, then starts a 10 ms polling task.
- Debounce: 30 ms stable sampling; an event is generated on a stable press transition only, not on release.
- `er_driver_ui_wait_event()`: retrieves one event with a caller-specified timeout. Event timestamps use the monotonic ESP timer and are not wall-clock time.
- `er_driver_ui_set_leds()`: sets GNSS, network and status indicators. The API does not impose a blink pattern.

## Integration requirements

1. The event consumer must be running and draining the queue promptly. The queue is volatile RAM, not a durable event journal.
2. A pickup-confirm event must be validated against the active trip and persisted by the event subsystem before any success acknowledgement is shown.
3. If the queue fills, the current implementation logs an error and reports the event was not queued. This is a fault requiring visible degraded status and further queue/backpressure hardening before production.
4. Never interpret a button press as proof that a student was identified. It is only a driver action associated with a backend event.
5. Do not connect GPIO4 directly to a buzzer until the buzzer's electrical load and driver topology are designed and verified.

## Not implemented

No modem, GNSS, SD card, display, I2C peripheral, USB, cellular networking, vision link, OTA, durable queue, trip state integration or backend command processing is enabled by this component.

## Validation status

Source committed; no ESP-IDF build, hardware-in-loop test, switch debounce test, LED current measurement or assembled-board test has been performed. These belong in the later project testing phase.
