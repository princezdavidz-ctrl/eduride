# Secure Event Uploader

The uploader is opt-in and is not started by app_main. A future secure provisioning component must supply an HTTPS endpoint, unique device token and trusted server root CA PEM at runtime.

- Reads the oldest persistent journal event and uploads one event per HTTPS request.
- Requires certificate verification using the supplied CA; no plaintext or insecure TLS path exists.
- Removes a record only when its exact ID appears in acknowledged or duplicates.
- Retains rejected, unacknowledged and transport-failed records.
- Retries using exponential backoff with jitter, capped at five minutes.
- Never logs credentials or event payloads.

## Gates and limitations
- Credential provisioning and protected credential storage are not implemented. Never hardcode tokens or pass them through public config.
- CA trust-anchor delivery and rotation must be designed and reviewed.
- Backend accepts batches up to ten; firmware currently sends one event per request.
- Permanent authorization/schema errors remain queued and retry; service fault reporting is future work.
- NVS journal is a low-rate prototype, not production high-volume storage.
- Pin down the ESP-IDF version and verify component/API compatibility before enabling.
- Build, TLS, reconnect, power-loss and hardware tests are pending. No tests are claimed to have passed.
