# Prompt for Antigravity — Sentinel Mobile App (Employee + Manager Access)

> Paste everything below into Antigravity as-is.

---

## Context

The web app (React/HTML + Node.js/Express — Admin/Manager-facing dashboard, QR kiosk
display, etc.) lives in a separate repository:
`https://github.com/aivinjmca2527/Sentinel-Attendance`. **Do not touch that repo.** Do
not clone it, do not read its code beyond the API route signatures you already have in
this prompt, and do not put any mobile code inside it.

Build the mobile app as a **brand-new Flutter project** in its own, separate repository:

```
https://github.com/nandanarajendran2004-a11y/Sentinel-App
```

This repo currently only contains a `.gitignore` — treat it as empty. Initialize the
Flutter project at the repo root (not nested under a `web/` or `admin/` folder — there
is no such folder here, and there shouldn't be one). The only connection between this
app and the web app's backend is HTTP calls to the same Express REST API; there is no
shared code, no shared folder, and no shared git history between the two repos.

## Non-negotiable architecture rules (carried over from the web app — do not deviate)

1. **The mobile app NEVER talks to MongoDB directly.** Every read/write goes through the
   existing Express REST API over HTTPS.
2. **The server is the source of truth for every decision** (QR signature/expiry, leave
   approval permissions, attendance status). The app only displays what the server
   returns and submits raw user input — it never computes or self-reports a
   pass/fail verdict.
3. Do **not** build face authentication or geofencing. Those are an explicitly deferred
   future phase — ignore any related backend fields you notice
   (`reference_face_photo_url`, `check_in_latitude/longitude`, etc.).
4. Do **not** modify anything in `/modules`, `/shared`, `/Templates`, or root-level
   `server.js`. If an API contract seems to be missing something you need, flag it in
   your output instead of editing backend code.

## Scope: this app is now for BOTH Employees and Managers

Previous plan (v1) was employee-only. This build supersedes that — the same app now
supports two roles, gated by the `role` field already returned on login
(`employee` | `manager` | `admin` — treat `admin` as out of scope for mobile; if an
admin logs in, show a message that admin accounts must use the web app).

Route the user to a different navigation shell after login based on `role`:

### Employee shell (role = `employee`)
- **Home** — today's attendance status (not checked in / checked in at HH:MM / checked
  out at HH:MM), with a Check In / Check Out button.
- **Scanner** — opens the camera to scan the kiosk's rotating QR code, then submits it to
  the check-in/out endpoint.
- **Leave** — a simple list of the employee's own leave requests with status
  (pending/approved/denied), and a form to submit a new one (type, start date, end date,
  reason).
- **Profile** — name, department, designation, logout.

### Manager shell (role = `manager`)
- **Home** — a lightweight team summary for today (counts of on-time / late /
  on-leave / not-yet-checked-in for their department), pulled from the existing
  dashboard/reports endpoints.
- **Team Attendance** — a list/date-filterable view of their department's attendance
  records (read-only).
- **Leave Approvals** — master-detail list of pending leave requests **for their own
  department only** (the backend already enforces this rule — the app just calls the
  endpoint and shows what comes back), with Approve/Reject actions.
- **Profile** — name, department, designation, logout.

If a manager account also has personal attendance to log (i.e. they're an Employee
record too), it's fine to also show the Home/Scanner check-in flow for them — check with
me before adding this if the API doesn't make it obvious; don't guess at a new endpoint.

## Auth flow specifics

- Single login screen (email + password) for all roles — same endpoint issues tokens for
  both platforms, so pass `platform: "mobile"` if the API expects it.
- **TOTP is mandatory for `manager` accounts** (and would be for `admin`, but admins
  aren't using mobile). After password login, if the response indicates TOTP is
  required and not yet set up, show a TOTP setup screen (QR/secret display + 6-digit
  confirmation) before letting the user in. If already set up, show a plain 6-digit
  TOTP entry screen. Employees skip TOTP entirely.
- Store the JWT in `flutter_secure_storage`. Attach it as `Authorization: Bearer <token>`
  on every API call. On a 401, clear the token and return to login.

## Tech stack

- Flutter (latest stable)
- `dio` for networking (with an interceptor for the auth header + 401 handling)
- `flutter_secure_storage` for the JWT
- `mobile_scanner` for QR capture (employee flow only)
- Simple state management — `Provider` or `ChangeNotifier`, no need for anything heavier
- One `.env`-style config file (or `--dart-define`) for the API base URL, so it's easy to
  point at localhost during development and at the deployed API later

## Deliverables

1. A working Flutter project at the root of `Sentinel-App`
   (`pubspec.yaml`, `lib/`, etc.), committed and pushed to `main` on that repo.
2. A `README.md` at the repo root explaining: how to set the API base URL, how to run
   it, and a short list of screens per role.
3. Clear folder structure inside `lib/`, e.g.:
   ```
   lib/
     core/          (api client, secure storage, theme)
     auth/          (login, TOTP setup/verify)
     employee/      (home, scanner, leave)
     manager/       (home, team attendance, leave approvals)
     shared_widgets/
   ```
4. Confirm the app boots, a test employee can log in and see the Home screen, and a test
   manager can log in through TOTP and see their Home screen — before considering this
   done.

## Explicitly out of scope for this build

- Face auth, geofencing (future phase)
- Admin role on mobile
- Any change to the web app or backend routes/models
- Push notifications, offline mode, biometric app-lock (nice-to-haves, not now)

---

*(End of prompt — after Antigravity finishes, verify the branch/folder location and role
gating manually before merging.)*
