# Sentinel — Mobile App

Employee & Manager mobile app for the Sentinel Employee Attendance Management System (EAMS).

## Tech Stack

- **Flutter** (Dart) — latest stable
- **Dio** — HTTP client with auth interceptor
- **flutter_secure_storage** — JWT token persistence
- **mobile_scanner** — QR code scanning (camera-based)
- **Provider** — state management
- **Google Fonts** — Inter + Outfit typography

## Setting the API Base URL

The app connects to the Sentinel Express REST API. Configure the URL using `--dart-define`:

```bash
# Android emulator → localhost (default)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api

# Physical device on same network
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api

# Deployed API
flutter run --dart-define=API_BASE_URL=https://your-server.com/api
```

Default (no flag): `http://10.0.2.2:3000/api`

## Running

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run on Chrome (for quick UI testing)
flutter run -d chrome

# Build APK
flutter build apk
```

## Screens by Role

### Employee
| Tab | Description |
|-----|-------------|
| **Home** | Today's attendance status (not checked in / checked in / checked out) |
| **Scanner** | Camera QR scan → check-in or check-out via the kiosk QR code |
| **Leave** | List of own leave requests + form to submit a new one (type, dates, reason) |
| **Profile** | Name, department, designation, logout |

### Manager
| Tab | Description |
|-----|-------------|
| **Dashboard** | Team summary for today: on-time / late / on-leave / not checked in counts |
| **Team** | Date-filterable list of department attendance records (read-only) |
| **Approvals** | Pending leave requests for their department with approve/reject actions |
| **Profile** | Name, department, designation, logout |

### Admin
Admin accounts are shown a message to use the web app — mobile is Employee + Manager only.

## Auth Flow

1. **Login** — email + password (same endpoint for all roles, sends `platform: "mobile"`)
2. **TOTP** — mandatory for Managers:
   - First login → TOTP Setup screen (scan QR / enter secret in authenticator app → confirm 6-digit code)
   - Subsequent logins → TOTP Verify screen (enter 6-digit code)
3. **JWT** — stored in `flutter_secure_storage`, attached to all API calls. On 401 → auto-logout.

## Project Structure

```
lib/
  main.dart                       # App entry, providers, routes, splash screen
  core/                           # API client, storage, theme, constants
  auth/                           # Login, TOTP setup/verify
  employee/                       # Employee home, QR scanner, leave management
  manager/                        # Manager dashboard, team attendance, leave approvals
  shared_widgets/                 # Profile, status badges, app bar, error view
```

## Architecture Rules

- The mobile app **never** writes to MongoDB directly — all reads/writes go through the Express REST API.
- The **server** is the source of truth for QR verification, leave approvals, and attendance status.
- Face auth and geofencing are **not built** — they are a future phase.
