# Device Provisioning and Configuration

Use the backend CLI from a trusted operator workstation with DATABASE_URL set. Tokens are one-time secrets; never put them in source control, tickets, chat or logs.

- Provision: `DEVICE_BUS_ID=<bus UUID> DEVICE_CODE=<unique code> DEVICE_VARIANT=gps_only npm run provision-device`
- Rotate: `DEVICE_CODE=<existing code> npm run provision-device -- rotate`
- Revoke: `DEVICE_CODE=<existing code> npm run provision-device -- revoke`

The CLI creates a 256-bit random base64url token and stores only its hash. Duplicate device codes are refused. Rotation immediately invalidates the previous token; securely deliver the replacement before rotating an installed controller to avoid lockout. Revocation sets active=false.

`GET /api/device/config` with `X-Device-Token` returns protocol version, device code, server-assigned variant, event endpoint path, server UTC time and allowed capabilities. The backend is authoritative for device variant. Revoked credentials receive 401.

## Production security gate

Firmware currently accepts endpoint, token and CA in RAM only. It does not implement secure persistent credential storage or a manufacturing provisioning channel. Do not deploy device tokens to field firmware yet. Select and validate encrypted NVS/flash-encryption provisioning or a secure element for the actual module, including key lifecycle, factory reset and recovery. Never disable TLS certificate verification.
