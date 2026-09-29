# Sentinel Mobile App — Project Structure & Feature Documentation

> **Application Name:** Sentinel (EAMS) — Mobile Client  
> **Repository:** `nandanarajendran2004-a11y/Sentinel-App`  
> **Framework:** Flutter (Dart SDK `^3.12.2`)  
> **Target Audience:** Employees & Managers  
> **Last Updated:** September 2026  

---

## 1. Executive Summary & Architecture

The **Sentinel Mobile App** is the mobile client for the **Sentinel Employee Attendance Management System (EAMS)**. While administrators and managers use the Sentinel Web Application for global company configuration and kiosk displays, this mobile app serves as the daily operational tool for **Employees** (attendance scanning, status tracking, leave requests) and **Managers** (department attendance monitoring, real-time metrics, leave approvals).

```
┌────────────────────────────────────────────────────────┐
│                   Sentinel Mobile App                  │
│               (Flutter Multi-Platform)                 │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST (JSON)
                            │ Bearer JWT Auth Header
                            ▼
┌────────────────────────────────────────────────────────┐
│             Sentinel Express REST API                  │
│       (Auth, Attendance, Leave, Dashboard)             │
└───────────────────────────┬────────────────────────────┘
                            │ Mongoose ODM
                            ▼
┌────────────────────────────────────────────────────────┐
│                 MongoDB Atlas Database                 │
└────────────────────────────────────────────────────────┘
```

### Core Architecture Principles
1. **Zero Direct Database Access:** The mobile application never interfaces directly with MongoDB. All state reads and mutations strictly traverse the Express REST API.
2. **Server-Side Authority:** The server remains the ultimate source of truth for all critical business logic (cryptographic QR verification, leave approval privileges, attendance status computation). The client never self-reports verification verdicts.
3. **Role-Gated User Experiences:** Upon authentication, the app dynamically constructs either an **Employee Navigation Shell** or a **Manager Navigation Shell**. Admin accounts are intentionally restricted from mobile operations with guidance to access the web portal.
4. **Secure Token Lifecycle:** Bearer JWT tokens and cached session data are securely persisted via platform-native keychains/keystores (`flutter_secure_storage`). Automatic 401 interceptors purge credentials and redirect to login upon session expiration.

---

## 2. Complete Project Directory Structure

```
Sentinel-App/
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
├── README.md
├── Sentinel_Project_Memory.md
├── EAMS_Antigravity_Prompt_Mobile_Employee_Manager.md
├── docs/
│   └── API_CONTRACT_ATTENDANCE.md
├── android/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── gradle.properties
│   └── app/
│       ├── build.gradle.kts
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── kotlin/
│           └── res/
├── ios/
│   ├── Podfile
│   ├── Runner/
│   │   ├── Info.plist
│   │   ├── AppDelegate.swift
│   │   └── Assets.xcassets/
│   └── Runner.xcodeproj/
├── web/
│   ├── index.html
│   ├── manifest.json
│   └── favicon.png
├── macos/
├── linux/
├── windows/
├── test/
│   └── widget_test.dart
└── lib/
    ├── main.dart
    ├── core/
    │   ├── api_client.dart
    │   ├── api_endpoints.dart
    │   ├── constants.dart
    │   ├── secure_storage_service.dart
    │   └── theme.dart
    ├── auth/
    │   ├── models/
    │   │   └── user_model.dart
    │   ├── providers/
    │   │   └── auth_provider.dart
    │   └── screens/
    │       ├── login_screen.dart
    │       ├── totp_setup_screen.dart
    │       └── totp_verify_screen.dart
    ├── employee/
    │   ├── models/
    │   │   ├── attendance_model.dart
    │   │   └── leave_request_model.dart
    │   ├── providers/
    │   │   ├── employee_home_provider.dart
    │   │   └── leave_provider.dart
    │   └── screens/
    │       ├── employee_shell.dart
    │       ├── employee_home_screen.dart
    │       ├── scanner_screen.dart
    │       ├── leave_list_screen.dart
    │       └── leave_form_screen.dart
    ├── manager/
    │   ├── models/
    │   │   ├── leave_approval_model.dart
    │   │   ├── team_attendance_model.dart
    │   │   └── team_summary_model.dart
    │   ├── providers/
    │   │   ├── leave_approval_provider.dart
    │   │   ├── manager_home_provider.dart
    │   │   └── team_attendance_provider.dart
    │   └── screens/
    │       ├── manager_shell.dart
    │       ├── manager_home_screen.dart
    │       ├── team_attendance_screen.dart
    │       └── leave_approval_screen.dart
    └── shared_widgets/
        ├── error_view.dart
        ├── loading_overlay.dart
        ├── profile_screen.dart
        ├── sentinel_app_bar.dart
        └── status_badge.dart
```

---

## 3. Detailed Component & File Breakdown

### 3.1 App Initialization & Routing (`lib/`)
- **`lib/main.dart`**:
  - Initializes Flutter bindings and constrains device orientation to portrait mode.
  - Customizes system status bar and navigation bar styling to match dark theme aesthetics.
  - Registers multi-providers at the root level (`AuthProvider`, `EmployeeHomeProvider`, `LeaveProvider`, `ManagerHomeProvider`, `TeamAttendanceProvider`, `LeaveApprovalProvider`).
  - Sets up `MaterialApp` with `SentinelTheme.darkTheme`, routes table, and mounts `_SplashGate`.
  - **`_SplashGate`**: Shows an animated glowing shield logo, checks auto-login session (`tryAutoLogin()`), and seamlessly routes users to `/employee`, `/manager`, or `/login`.

### 3.2 Core Framework (`lib/core/`)
- **`api_client.dart`**:
  - Singleton `Dio` instance configured with base timeout intervals (15 seconds) and standard JSON headers.
  - **Auth Interceptor**: Automatically pulls the stored JWT token from `SecureStorageService` and injects `Authorization: Bearer <token>` into outbound requests.
  - **Error Interceptor**: Catches `401 Unauthorized` responses globally, wipes all local secure storage credentials, and redirects the app back to `/login` via `ApiClient.navigatorKey`.
- **`api_endpoints.dart`**:
  - Centralized registry of all backend REST endpoint routes:
    - Auth: `/auth/login`, `/auth/totp/setup`, `/auth/totp/verify`
    - Attendance: `/attendance/today`, `/attendance/check-in`, `/attendance/check-out`, `/attendance/department`
    - Leave: `/leave`, `/leave/balance`, `/leave/:id/approve`, `/leave/:id/reject`
    - Dashboard: `/dashboard/summary`
    - Profile: `/employees/me`
- **`secure_storage_service.dart`**:
  - Wrapper around `FlutterSecureStorage` using hardware-backed platform encryption (Android Keystore / iOS Keychain).
  - Handles token storage (`sentinel_jwt`), user metadata serialization (`sentinel_user`), and session clearing.
- **`constants.dart`**:
  - Holds configuration constants including `apiBaseUrl` with `--dart-define=API_BASE_URL=...` build flag fallback (defaults to `http://10.0.2.2:3000/api` for Android emulator local dev).
  - Animation durations and UI timing parameters.
- **`theme.dart`**:
  - Complete custom design system: Dark obsidian surfaces (`#0A0E1A`, `#111827`, `#162032`) paired with vibrant cyan (`#00E5FF`) and amber accents.
  - Color definitions for attendance statuses (`on-time`, `late`, `absent`, `on-leave`, `pending`, `approved`, `denied`, `incomplete`).
  - Google Fonts typography configurations using `Inter` for crisp body copy and `Outfit` for display headings.
  - Full Material 3 component theming for buttons, text fields, cards, app bars, and bottom navigation bars.

### 3.3 Authentication & Security (`lib/auth/`)
- **`models/user_model.dart`**:
  - Data model representing the logged-in user profile, role flags (`isAdmin`, `isManager`, `isEmployee`), designation, department ID, and TOTP flags (`totpEnabled`, `totpRequired`).
- **`providers/auth_provider.dart`**:
  - Coordinates state for login, session restoration, TOTP setup, TOTP verification, and sign-out.
  - Emits descriptive `LoginResult` states (`employeeSuccess`, `managerSuccess`, `totpSetupRequired`, `totpVerifyRequired`, `adminBlocked`, `error`).
- **`screens/login_screen.dart`**:
  - Cyber-styled authentication screen with company logo, email/password validation, show/hide password toggle, and error banner.
  - Intercepts admin accounts and displays an alert directing them to the web admin console.
- **`screens/totp_setup_screen.dart`**:
  - Mandatory onboarding for managers without 2FA configured.
  - Renders an authenticator QR code via `qr_flutter` alongside a copyable manual base32 secret.
  - Features 6-digit PIN input with auto-submission upon completion.
- **`screens/totp_verify_screen.dart`**:
  - 6-digit PIN entry interface for returning managers, authenticating the second factor before issuing the final session token.

### 3.4 Employee Self-Service (`lib/employee/`)
- **`models/attendance_model.dart`**:
  - Parses attendance records with fields for check-in time, check-out time, computed working hours, status, and verification method (`qr_only` / `qr_geo`).
  - Helper properties: `isNotCheckedIn`, `isCheckedIn`, `isCheckedOut`.
- **`models/leave_request_model.dart`**:
  - Represents an employee's leave application: type (Casual, Sick, Annual, Maternity/Paternity, Unpaid), start/end dates, reason, status, and submission timestamp.
- **`providers/employee_home_provider.dart`**:
  - Manages today's attendance state (`attendance`, `isLoading`, `error`).
  - Implements `fetchTodayAttendance()`, `checkIn(qrCode)`, and `checkOut(qrCode)`.
- **`providers/leave_provider.dart`**:
  - Manages employee leave history and new submissions.
  - Implements `fetchLeaveRequests()` and `submitLeaveRequest(...)`.
- **`screens/employee_shell.dart`**:
  - Persistent bottom navigation shell utilizing `IndexedStack` across 4 tabs: **Home**, **Scanner**, **Leave**, and **Profile**.
- **`screens/employee_home_screen.dart`**:
  - Daily overview showing date, attendance status badge, check-in and check-out time cards, and working hours calculation.
  - Dynamic contextual Action Button:
    - *Not Checked In:* Displays pulsing cyan "Check In" button switching directly to the camera scanner.
    - *Checked In:* Displays amber "Check Out" button switching to the scanner.
    - *Checked Out:* Displays green "Day Completed" confirmation with total logged hours.
  - Pull-to-refresh integration.
- **`screens/scanner_screen.dart`**:
  - Hardware camera scanner using `mobile_scanner`.
  - Custom dark semi-transparent viewfinder overlay with animated scanning laser and guide box.
  - Debounces duplicate scans; automatically determines whether to call check-in or check-out based on current state.
  - Displays instant in-screen success/error banners before auto-resetting.
- **`screens/leave_list_screen.dart`**:
  - Displays all leave requests submitted by the logged-in employee with color-coded status badges and dates.
  - Floating Action Button ("Apply Leave") that opens the submission form.
- **`screens/leave_form_screen.dart`**:
  - Interactive form featuring leave type selector dropdown, calendar date range pickers with start/end date validation, and optional reason text field.

### 3.5 Manager Operations (`lib/manager/`)
- **`models/team_summary_model.dart`**:
  - Parses department metrics: `totalEmployees`, `presentCount`, `onTime`, `late_`, `onLeave`, and `notCheckedIn`.
- **`models/team_attendance_model.dart`**:
  - Represents individual employee attendance within the department (name, designation, check-in/out times, working hours, and status).
- **`models/leave_approval_model.dart`**:
  - Model for department leave requests pending manager review.
- **`providers/manager_home_provider.dart`**:
  - Fetches department-wide aggregated metrics from `/dashboard/summary`.
- **`providers/team_attendance_provider.dart`**:
  - Fetches and filters department attendance logs by selected calendar date via `/attendance/department`.
- **`providers/leave_approval_provider.dart`**:
  - Loads pending department leave requests (`/leave?status=pending`) and executes `approveRequest(id)` or `rejectRequest(id)`.
- **`screens/manager_shell.dart`**:
  - 4-tab bottom navigation shell for managers: **Dashboard**, **Team**, **Approvals**, and **Profile**.
- **`screens/manager_home_screen.dart`**:
  - Executive team dashboard with a 4-card metric grid:
    - **On Time** (Emerald green badge & count)
    - **Late** (Amber badge & count)
    - **On Leave** (Blue badge & count)
    - **Not Checked In** (Red/Muted badge & count)
  - Quick action summary cards.
- **`screens/team_attendance_screen.dart`**:
  - Date-filterable department attendance roster.
  - Day stepper controls (Previous Day / Next Day) and interactive calendar date picker.
  - List of employees with designations, arrival times, departure times, and status badges.
- **`screens/leave_approval_screen.dart`**:
  - Master list of pending department leave requests.
  - Detailed card view showing applicant name, designation, requested dates, duration in days, and justification.
  - One-tap "Approve" and "Reject" action buttons with instant list updates.

### 3.6 Shared Widgets (`lib/shared_widgets/`)
- **`sentinel_app_bar.dart`**: Branded top navigation bar with custom typography and subtle borders.
- **`status_badge.dart`**: Universal colored badge component with contextual icons for all attendance and approval states.
- **`profile_screen.dart`**: Displays user identity (avatar, full name, email, designation, department, and role badge), application diagnostics, and secure logout action with confirmation dialog.
- **`error_view.dart`**: Clean error presentation card with retry button callback.
- **`loading_overlay.dart`**: Non-blocking or modal loading indicators.

---

## 4. Current Feature Matrix

| Feature Domain | Feature Description | Implemented | Mobile Role Scope |
| :--- | :--- | :---: | :--- |
| **Authentication** | Email & Password authentication with JWT issuance | ✅ | Employee & Manager |
| **Authentication** | Automatic session restoration from Secure Storage | ✅ | Employee & Manager |
| **Authentication** | Global 401 handling with automatic session wipe & logout | ✅ | All |
| **Authentication** | Admin role detection & redirection to Web App | ✅ | Admin |
| **Authentication** | TOTP 2FA Setup with dynamic QR code & manual key | ✅ | Manager |
| **Authentication** | TOTP 2FA Verification via 6-digit PIN input | ✅ | Manager |
| **Authentication** | Secure logout & credential purge | ✅ | Employee & Manager |
| **Attendance** | Today's Attendance status tracking (on-time, late, incomplete) | ✅ | Employee |
| **Attendance** | Working hours calculation & check-in/out timestamps | ✅ | Employee |
| **Attendance** | Camera QR Scanner for kiosk rotating codes | ✅ | Employee |
| **Attendance** | Scan debouncing & automated check-in/check-out routing | ✅ | Employee |
| **Attendance** | In-app scan verification feedback banners | ✅ | Employee |
| **Leave Management** | Personal leave request history & status tracking | ✅ | Employee |
| **Leave Management** | Leave request submission form with date validation | ✅ | Employee |
| **Manager Dashboard**| Today's team overview metrics (On Time, Late, Leave, Absent) | ✅ | Manager |
| **Manager Monitoring**| Department attendance roster filtered by date | ✅ | Manager |
| **Manager Monitoring**| Date navigation stepper (prev/next day & calendar picker) | ✅ | Manager |
| **Leave Approvals** | Department-specific pending leave requests queue | ✅ | Manager |
| **Leave Approvals** | One-tap Approve / Reject actions with live list removal | ✅ | Manager |
| **User Profile** | User avatar, department, designation, and build diagnostics | ✅ | Employee & Manager |
| **Design System** | Obsidian dark mode, glassmorphism surfaces, cyan accents | ✅ | All screens |
| **Geofencing** | Mobile GPS capture (`latitude`, `longitude`, `accuracy_m`) | ⏳ *Next Phase* | Employee (Backend ready) |
| **Biometrics** | Face authentication check before QR unlock | ⏳ *Deferred* | Future Phase |

---

## 5. Mobile & Backend REST API Contract Mapping

| Screen / Provider | HTTP Method | Endpoint Path | Function & Role |
| :--- | :---: | :--- | :--- |
| `AuthProvider` | `POST` | `/auth/login` | Authenticate credentials; returns role and token |
| `AuthProvider` | `POST` | `/auth/totp/setup` | Generate TOTP secret and QR URL for manager setup |
| `AuthProvider` | `POST` | `/auth/totp/verify` | Verify 6-digit TOTP code and finalize manager login |
| `EmployeeHomeProvider` | `GET` | `/attendance/today` | Fetch employee check-in/out status for current day |
| `EmployeeHomeProvider` | `POST` | `/attendance/check-in` | Submit scanned QR code payload to register check-in |
| `EmployeeHomeProvider` | `POST` | `/attendance/check-out` | Submit scanned QR code payload to register check-out |
| `LeaveProvider` | `GET` | `/leave` | Fetch leave request history for logged-in employee |
| `LeaveProvider` | `POST` | `/leave` | Submit new leave application with date bounds & type |
| `ManagerHomeProvider` | `GET` | `/dashboard/summary` | Fetch today's department aggregated attendance statistics |
| `TeamAttendanceProvider` | `GET` | `/attendance/department?date=YYYY-MM-DD` | Fetch department employee attendance records by date |
| `LeaveApprovalProvider` | `GET` | `/leave?status=pending` | Fetch pending leave applications in manager's department |
| `LeaveApprovalProvider` | `PUT` | `/leave/:id/approve` | Approve a specific employee leave application |
| `LeaveApprovalProvider` | `PUT` | `/leave/:id/reject` | Reject a specific employee leave application |
| `ProfileScreen` | `GET` | `/employees/me` | Fetch detailed employee/manager profile record |

---

## 6. Build & Execution Instructions

### 6.1 Prerequisites
- Flutter SDK `^3.12.2` or later
- Android SDK (API 34+) / Xcode for iOS
- Camera permission enabled on test device

### 6.2 Running Locally
```bash
# Fetch pub dependencies
flutter pub get

# Run on Android Emulator (points to host machine localhost:3000 via 10.0.2.2)
flutter run

# Run on physical mobile device with custom API host
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api

# Run on production/staging backend
flutter run --dart-define=API_BASE_URL=https://sentinel-api.example.com/api
```
