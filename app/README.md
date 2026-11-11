# Edu Ride mobile app

## Backend configuration

Debug and release builds use the cPanel backend over HTTPS at `https://s1103.usc1.mysecurecloudhost.com/backend/api` and send `Host: eduride.co.ke` so shared hosting routes requests to the Edu Ride account. This avoids `localhost`, which would refer to the phone in an installed app. For local backend development, override the defaults with `--dart-define=API_BASE_URL=http://10.0.2.2:8787/api --dart-define=API_HOST_HEADER=`.

Override either setting at build time if the hosting route changes:

```sh
flutter build apk \
  --dart-define=API_BASE_URL=https://your-backend-host/backend/api \
  --dart-define=API_HOST_HEADER=your-account-hostname
```

Use `--dart-define=API_HOST_HEADER=` when the backend host is directly assigned to the account and does not require a separate virtual-host header.

The app's splash screen checks the backend health endpoint. Login, sign-up,
session restore/logout, profile, preferences, children, and drawer data use the
configured API. The debug-only `test@gmail.com` demo login stays local for
offline access; use a backend account to load authenticated server data.

The backend currently does not deliver OTP codes or password-reset emails.
Backend logins therefore continue directly into the app, while password reset
reports that the feature is not configured instead of displaying a fake OTP
verification flow.
