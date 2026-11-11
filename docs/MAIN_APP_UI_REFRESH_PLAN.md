# Edu Ride Main App UI Refresh

## Scope

This workstream refreshes the Flutter parent-facing mobile app in `app/`. The public marketing website in `main-web/`, CRM, and backend are separate workstreams. The main app remains connected to the existing API contracts; this UI work must not invent live trip data, student status, or notification events.

## Product experience and screen order

1. App identity and launcher icon
2. Splash / startup health status
3. Language selection (English and Kiswahili)
4. Sign in / sign up
5. Forgot password and verification states
6. Family / child setup
7. Parent home dashboard
8. Live bus tracking
9. Children and school association
10. Trip history
11. School schedule
12. Pickup and drop-off points
13. Notifications
14. Messages
15. Emergency and safety
16. Parent profile
17. Settings and notification preferences
18. Privacy and security
19. Help and support
20. Contact school
21. About Edu Ride
22. Terms and conditions

## Visual direction

- Use the Edu Ride blue as the primary action colour, deep navy for hierarchy, and a restrained green for confirmed/healthy states.
- Use a soft cool-grey page background, white elevated surfaces, consistent 16–24 px radii, and clear spacing.
- Keep typography high-contrast and readable, with strong page titles and concise supporting text.
- Use consistent loading, empty, offline, error, and success states. A missing bus assignment must never look like a confirmed live trip.
- Keep navigation predictable: Home and Children in the bottom bar; secondary pages in the drawer.
- Preserve accessibility: semantic labels, readable contrast, large tap targets, and layouts that survive small screens and large text.

## Implementation sequence

### UI milestone 1 — Foundation and first-run experience
- Shared Material 3 design tokens and component themes.
- Branded splash screen and language selection.
- Consistent authentication layout, form controls, and action states.

### UI milestone 2 — Parent journey dashboard
- Clear parent dashboard hierarchy.
- Live map as a dedicated, bounded panel rather than an unstructured full-screen canvas.
- Bus assignment, school, status, and ETA presented separately.
- Explicit waiting/error states when the API has no bus record.
- Keep the location permission state visible and recoverable.

### UI milestone 3 — Family and trip workflows
- Children list, add-child, change-school and verification states.
- Live tracking, trip history, schedule, and pickup/drop-off screens.
- Consistent cards, status labels, empty states, and refresh affordances.

### UI milestone 4 — Communication and account
- Notifications and read/unread states.
- Messages, emergency/safety, profile, settings, privacy, help, contact, about and terms.
- Confirm every action is connected to a real backend operation or clearly marked unavailable.

### UI milestone 5 — Release quality
- Small-screen and tablet layout checks.
- Accessibility and interaction review.
- Flutter format, analyze, widget/unit tests, and Android release build.
- Fix all blockers before merging; do not merge this UI branch without review.

## Current implementation in this branch

- Refreshed shared Material 3 theme tokens, typography, input fields, cards, buttons, navigation bar, dividers and snackbars.
- Reworked splash screen into a branded blue startup experience while preserving the existing health-check and permission flow.
- Updated shared authentication layout to use the new design system.
- Rebuilt the parent home hierarchy around a clear header, contained map, map controls, and a separate journey-status card.
- Replaced the old static live-tracking mock screen with a map and status card driven by the existing bus API provider; empty and error states are explicit.
- Added Live bus tracking to the parent navigation drawer and aligned the parent profile with the shared theme.
- Kept existing data providers and API calls; no new sample trip records or fake boarding events were introduced.

## Known follow-up items

- The app currently uses a placeholder Flutter package identity (`com.example.trend`) and package name `trend`; replace these with approved production identifiers before store release.
- The home map must be checked on-device with a real assigned bus and with location permission denied.
- The full child, tracking, notifications, profile and secondary-page visual pass remains part of the next UI slices.
- Backend persistence, role-based access, device telemetry ingestion and push delivery are intentionally deferred until the main app UI work is complete.
