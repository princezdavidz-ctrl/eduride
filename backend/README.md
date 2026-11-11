# TREAD Backend

Development API shared by the parent app, CRM, and browser portal.

## Run

```bash
npm start
```

The server listens on `http://localhost:8787` by default. Set `PORT` to change the port and `CORS_ORIGIN` to restrict browser access.
When the server is mounted under a URL prefix by a hosting provider, set `APP_BASE_PATH` to that prefix (for example, `/backend`) so the API routes continue to work under the mounted path.

For MapTiler, create an API key in the MapTiler dashboard and restrict its allowed HTTP origins to the web origins that host Tread, such as `http://localhost:8787` and your deployed web origin. The Flutter mobile and desktop builds pass the application user-agent identifier `com.example.trend`; they do not send a browser Origin header.

The current storage is in memory and resets when the process restarts. It is intended for local integration work, not production data.

## Demo CRM account

- Email: `admin@tread.local`
- Password: `TREAD-demo-2026`

## API groups

Public:

- `GET /health`
- `POST /api/auth/login`
- `POST /api/auth/signup`
- `POST /api/auth/forgot-password` (returns HTTP 200 with `available: false` until password-reset delivery is configured)

Authenticated:

- `GET /api/auth/me`
- `POST /api/auth/logout`
- `GET/PATCH /api/profile`
- `GET/POST /api/children`
- `GET/POST /api/verification`
- `GET/PATCH /api/preferences`
- `GET /api/buses`
- `GET /api/notifications`
- `GET /api/schools`
- `GET /api/routes`
- `GET /api/journeys`
- `GET /api/alerts`
- `PATCH /api/alerts/:id`

Send authenticated requests with:

```text
Authorization: Bearer <token>
```

Successful API operations return HTTP 200. Authentication, validation, and missing-resource failures retain their appropriate 4xx status codes. Password reset is not yet implemented; its endpoint explicitly reports that it is unavailable rather than claiming that an email was sent.

The next backend slice should add persistent storage, role-specific authorization, password reset delivery, real bus location ingestion, and push notification integration.
