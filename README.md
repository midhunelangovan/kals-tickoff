# Tickoff — Self-Contained Offline Personal Habit Tracker

Tickoff is a completely local, offline-first personal habit tracker application packaged into a self-contained Android APK. It executes a local HTTP REST API backend directly inside the Android process, persisting data to an app-private SQLite database.

```text
┌────────────────────────────────────────────────────────┐
│                      TICKOFF APK                       │
│                                                        │
│   Flutter UI                                           │
│      │                                                 │
│      │ HTTP (Dio)                                      │
│      ▼                                                 │
│   127.0.0.1:18080/tickoff                              │
│      │                                                 │
│      ▼                                                 │
│   Embedded Local Backend Server (NanoHTTPD)            │
│      │                                                 │
│      ▼                                                 │
│   Service Layer (HabitService + StreakService)         │
│      │                                                 │
│      ▼                                                 │
│   Repository Layer (HabitSqliteRepository)             │
│      │                                                 │
│      ▼                                                 │
│   Local SQLite Database (/data/data/.../tickoff.db)    │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## Architecture & How It Works

### 1. Embedded Local Backend Inside Android
- Android uses the ART runtime (Dalvik bytecode/DEX), not a desktop JVM. Desktop Spring Boot fat JARs cannot execute directly on Android.
- The business logic, services (`HabitService`, `StreakService`), validation, streak calculations, Habit Score algorithms, and SQLite schemas are ported 1:1 into native Android components (`io.kals.tickoff.local`).
- An embedded, ultra-lightweight HTTP server (`NanoHTTPD`) runs locally inside the Android process and binds strictly to `127.0.0.1:18080`.
- The server does **not** listen on `0.0.0.0` and is completely inaccessible to local Wi-Fi or LAN networks.

### 2. Startup & Server Lifecycle
- **App Launch**: `TickoffApp.onCreate()` automatically initializes `LocalBackendManager` and launches the embedded server on `127.0.0.1:18080`.
- **Readiness Verification**: Flutter displays a clean startup screen while verifying backend health via `GET http://127.0.0.1:18080/tickoff/internal/health`.
- **Ready State**: As soon as HTTP 200 `{"status": "UP"}` is received, Flutter initiates API communication and renders the main dashboard.
- **Graceful Termination**: When the application is closed or destroyed, `MainActivity.onDestroy()` cleanly shuts down the server, releases port `18080`, and closes database connections.

### 3. Local SQLite Database Storage
- The SQLite database (`tickoff.db`) is stored exclusively in the app-private internal storage:
  `/data/data/io.kals.tickoff/databases/tickoff.db`
- It is never stored on shared storage, SD cards, or cloud drives.
- Migrations are versioned (`V1`, `V2`, `V3`) mirroring Flyway schemas and run automatically on first launch or upgrade.

---

## Dual Mode: Development vs. Standalone Release

### A. Standalone Android Release Mode (APK)
- Fully self-contained: No PC, no Java installation, no Wi-Fi, and no external servers required.
- Flutter automatically routes all REST calls to `http://127.0.0.1:18080/tickoff`.
- Fully functional in **Airplane Mode**.

### B. Desktop Development Mode
The desktop Spring Boot backend in `backend/` remains completely functional for rapid local iteration:

```bash
# 1. Start Spring Boot desktop backend
cd backend
gradlew.bat bootRun

# 2. Run Flutter pointing to desktop server
cd mobile
flutter run --dart-define=API_BASE_URL=http://localhost:4000/tickoff
```

---

## Building the Release APK

To compile the self-contained production APK:

```bash
cd mobile/android
gradlew.bat assembleRelease
```

- **Output APK Path**: `mobile/build/app/outputs/apk/release/app-release.apk`
- **Output Size**: ~49.07 MB (51,457,699 bytes)
- **Application ID**: `io.kals.tickoff`
- **Target SDK**: Android 15 (API 35) / Min SDK: Android 8.0 (API 26)

---

## Android Permissions

| Permission | Purpose |
|---|---|
| `android.permission.INTERNET` | Technically required by Android OS for loopback TCP sockets (`127.0.0.1`). The app works 100% offline without any internet connection. |

No storage, camera, contacts, or location permissions are requested.

---

## Running Tests

### Backend Tests (JUnit 5 + MockMvc)
```bash
cd backend
gradlew test
```

### Mobile Tests (Flutter Test + Riverpod + Mocktail)
```bash
cd mobile
flutter test
```

---

## Future Cloud & Authentication Architecture

Tickoff is deliberately designed so that the local embedded architecture does not block future remote sync:

```text
Local Mode (Today):
Flutter UI ──> http://127.0.0.1:18080/tickoff ──> SQLite

Cloud Mode (Future):
Flutter UI ──> https://api.tickoff.io/tickoff ──> Remote Spring Boot ──> PostgreSQL
                      │
              Google Sign-In (OAuth2)
```

Because Flutter communicates exclusively through REST contracts (`/habits`, `/habits/score`, `/habits/{id}/completions/{date}`), transitioning to a remote server in the future only requires changing `ApiConfig.apiBaseUrl` and attaching authentication headers.
