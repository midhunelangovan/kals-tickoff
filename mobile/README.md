# Habit Tracker Mobile (Flutter)

A clean, modern Android-first personal habit tracker mobile application built with Flutter, Riverpod, Dio, and Clean Architecture.

It connects to the local Spring Boot backend API running at `http://localhost:8080` (or `http://10.0.2.2:8080` in the Android Emulator).

---

## Features

- **Today's Habits**: Lists active habits with completion status and streak count.
- **Daily Progress**: Real-time progress bar and percentage (e.g. `2 of 4 completed • 50%`).
- **Instant Toggle with Optimistic UI**: Check/uncheck habits with fluid animated feedback and automatic rollback on network failure.
- **Streak Tracking**: Displays consecutive completed days with flame badges (`🔥 5 day streak`).
- **Add Habit Flow**: Sleek modal bottom sheet with input validation and error feedback.
- **Clean Architecture**: Domain, Data, Presentation, and Core layers with repository abstraction.

---

## Setup & Running

### 1. Start the Spring Boot Backend

In the backend directory `D:\projects\backend\tickoff`:
```bash
.\gradlew.bat bootRun
```
The backend starts at `http://localhost:8080`.

### 2. Configure API Base URL

The API URL is configured in `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android Emulator:
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';

  // For Physical Device on same Wi-Fi (replace with your computer's LAN IP):
  // static const String apiBaseUrl = 'http://192.168.1.100:8080/api/v1';
}
```

> **Note on Physical Devices**: When running on a physical Android phone, connect both your computer and phone to the same Wi-Fi network and set `apiBaseUrl` to your machine's local IP address (find via `ipconfig` on Windows).

### 3. Run on Android Emulator

```bash
flutter run
```

### 4. Running Automated Tests

```bash
flutter test
flutter analyze
```
