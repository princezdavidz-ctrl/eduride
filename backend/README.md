# Edu Ride Backend

Persistent API shared by the parent mobile app, CRM, and approved school portals.

## Runtime requirements

- Node.js 20 or newer
- PostgreSQL 14 or newer
- A private database connection string supplied as `DATABASE_URL`

The backend intentionally has **no in-memory or demo-data fallback**. It will refuse to start without a database connection. Never use the former demo account or store real passwords in environment files or source control.

## Configure

Copy `.env.example` to your deployment's secret/environment configuration and set:

- `DATABASE_URL`: PostgreSQL connection string
- `DATABASE_SSL=true` when the database provider requires verified TLS
- `PORT`: HTTP port (default 8787)
- `APP_BASE_PATH=/backend` when the reverse proxy mounts this service below `/backend`
- `CORS_ORIGIN`: comma-separated exact browser origins, for example `https://eduride.co.ke,https://crm.eduride.co.ke`
- `DB_POOL_MAX`: optional PostgreSQL connection pool size (default 10)

Native mobile requests do not require a browser Origin header. Browser origins are denied unless explicitly listed. Do not use `*` in production.

## First deployment

Run these commands from this directory:

```bash
npm install
npm run migrate
```

Create the first transport administrator using secret environment variables:

- `BOOTSTRAP_ADMIN_EMAIL`
- `BOOTSTRAP_ADMIN_PASSWORD` (at least 16 characters)
- `BOOTSTRAP_ADMIN_NAME`
- `BOOTSTRAP_ORGANIZATION_NAME`

Then run:

```bash
npm run bootstrap-admin
npm start
```

Remove the bootstrap password from the deployment environment after the one-time account has been created. The script creates a new organization and administrator; it is not an idempotent reset command.

To register a vehicle device, set `DEVICE_BUS_ID`, `DEVICE_CODE`, and `DEVICE_VARIANT` (`gps_only` or `vision_gps`) and run:

```bash
npm run provision-device
```

The command prints a high-entropy device token once. Provision it securely on that single device and do not commit or reuse it. The telemetry endpoint accepts GPS fields only; image and biometric payloads are rejected.

## Security and data boundaries

- Passwords are stored as bcrypt hashes (cost 12), never as plaintext.
- Random bearer tokens are returned once; only SHA-256 token hashes are stored in PostgreSQL.
- Sessions expire after eight hours and logout revokes the stored session.
- Login attempts are throttled per source address. Put a shared rate limiter at the reverse proxy/API gateway for multi-instance deployments.
- Parent access is scoped to the authenticated parent's children and active child-to-bus assignments.
- Driver access is scoped to buses assigned to that driver.
- School and transport administrators are scoped to their organization.
- SQL uses parameterized queries; request bodies are limited to 16 KiB.
- Browser CORS origins must be explicitly allow-listed.
- Device telemetry uses a separate device credential and can only write coordinates for the bus bound to that device.
- The GPS telemetry API accepts position, speed, heading and recorded time only. It does not accept images or biometric data. A GPS-only device must remain image-free.

## API

Public:
- `GET /health` — database readiness
- `POST /api/auth/login`
- `POST /api/auth/signup` — creates parent accounts only
- `POST /api/auth/forgot-password` — returns `available: false` until a verified email/SMS delivery provider is configured

Bearer-authenticated:
- `GET /api/auth/me`, `POST /api/auth/logout`
- `GET/PATCH /api/profile`
- `GET/POST /api/children`, `PATCH /api/children/:id`
- `GET/POST /api/verification`
- `GET/PATCH /api/preferences`
- `GET /api/buses`
- `GET /api/notifications`
- `GET /api/schools`
- `GET /api/routes`
- `GET /api/journeys`
- Admin-only: `GET /api/alerts`, `PATCH /api/alerts/:id`

Device-authenticated:
- `POST /api/device/telemetry` with `X-Device-Token` and JSON `latitude`, `longitude`, optional `speedKph`, `heading`, and `recordedAt`.

## Data model

The initial PostgreSQL schema covers organizations, users, hashed sessions, schools, children, buses, routes, child/bus assignments, journeys, alerts, per-user alert acknowledgements, preferences, registered devices and GPS telemetry.

Bus `updatedAt` is sourced from the latest recorded telemetry timestamp. It is never generated at read time. The API separately reports whether the latest GPS report is fresh (within two minutes). ETA remains null until a validated routing/ETA service is connected; clients should show “ETA unavailable” rather than inventing a value.

## Quality checks

```bash
npm test
npm run migrate
```

The backend GitHub Actions workflow runs unit and PostgreSQL-backed integration tests against PostgreSQL 16.

## Deployment gates still required

- Provision managed PostgreSQL, TLS, backups, monitoring and least-privilege database credentials.
- Configure exact production CORS origins and reverse-proxy path/health checks.
- Configure verified password-reset delivery and push notifications.
- Provision each vehicle device with a unique secret; never reuse a shared fleet-wide key.
- Complete school/family authorization, operational acceptance tests and Kenyan privacy/DPIA review before any student identity or vision workflow is piloted.
