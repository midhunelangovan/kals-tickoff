# Tickoff — Local-First Habit Tracker API (Phase 1)

A clean, local-first REST API backend for personal habit tracking built with Spring Boot 3, Java 21, Spring Data JPA, SQLite, and Flyway.

> [!NOTE]
> This API is intentionally local-only and has **no authentication**, user accounts, cloud sync, or external service dependencies. All data is persisted locally in an embedded SQLite database file.

---

## Features

- **Habit Management**: Create habits and list active habits ordered newest-first.
- **Completion Tracking**: Mark or unmark habit completions for any calendar date (`YYYY-MM-DD`).
- **Idempotent Operations**: Safely retry completion or unmark requests without side effects.
- **Streak Calculation**: Computes the consecutive active daily streak ending on any requested date (or today).
- **Embedded Local Persistence**: Automatically creates and manages SQLite schema via Flyway migrations.
- **Framework Integration**: Reuses base repository contracts and error abstractions from `io.kals:core-framework`.

---

## Tech Stack

- **Java 21**
- **Spring Boot 3.4.3**
- **Spring Web**
- **Spring Data JPA**
- **SQLite** (`sqlite-jdbc` + Hibernate Community Dialects)
- **Flyway** (Database schema migrations)
- **Gradle 8.14.4**
- **JUnit 5 / MockMvc / AssertJ**

---

## Database Configuration

By default, the SQLite database is stored locally at:
```
./data/habit-tracker.db
```

You can customize the database location in `src/main/resources/application.properties` or by setting the `SPRING_DATASOURCE_URL` environment variable:
```properties
spring.datasource.url=jdbc:sqlite:./data/habit-tracker.db
```
The application automatically creates the parent directory (`./data`) on startup if it does not already exist.

---

## Getting Started

### Prerequisites

- Java 21 JDK installed (`java -version`)
- Gradle (the provided `gradlew` / `gradlew.bat` wrapper is recommended)

### Running Locally

```bash
# On Linux/macOS
./gradlew bootRun

# On Windows (PowerShell / CMD)
.\gradlew.bat bootRun
```

The server starts on `http://localhost:8080`.

### Building Runnable JAR

```bash
.\gradlew.bat bootJar
java -jar build/libs/tickoff-0.0.1-SNAPSHOT.jar
```

### Running Automated Tests

```bash
.\gradlew.bat test
```

---

## API Documentation

Base Path: `/api/v1`

### 1. Create a Habit
`POST /api/v1/habits`

**Request Body:**
```json
{
  "name": "Read for 20 minutes"
}
```

**Response (`201 Created`):**
```json
{
  "id": "e2f7b2dc-9f0e-4c3e-88ef-2270bb3f06e1",
  "name": "Read for 20 minutes",
  "createdAt": "2026-09-01T10:30:00",
  "archived": false,
  "currentStreak": 0,
  "completedToday": false
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:8080/api/v1/habits \
  -H "Content-Type: application/json" \
  -d '{"name": "Read for 20 minutes"}'
```

---

### 2. List Habits
`GET /api/v1/habits?date=YYYY-MM-DD`

- The `date` parameter is optional and defaults to the server's current local date.
- Returns non-archived habits ordered newest first with completion status on that date and the current streak.

**Response (`200 OK`):**
```json
[
  {
    "id": "e2f7b2dc-9f0e-4c3e-88ef-2270bb3f06e1",
    "name": "Read for 20 minutes",
    "createdAt": "2026-09-01T10:30:00",
    "archived": false,
    "currentStreak": 3,
    "completedOnDate": true
  }
]
```

**cURL Examples:**
```bash
# Query for today
curl -X GET http://localhost:8080/api/v1/habits

# Query for a specific date
curl -X GET "http://localhost:8080/api/v1/habits?date=2026-09-01"
```

---

### 3. Mark a Habit Done for a Date
`PUT /api/v1/habits/{habitId}/completions/{date}`

- Marks completion for the specified `YYYY-MM-DD` date.
- Operation is idempotent (repeating the call will not duplicate records or error).

**Response (`200 OK`):**
```json
{
  "habitId": "e2f7b2dc-9f0e-4c3e-88ef-2270bb3f06e1",
  "completionDate": "2026-09-01",
  "completed": true,
  "currentStreak": 1
}
```

**cURL Example:**
```bash
curl -X PUT http://localhost:8080/api/v1/habits/e2f7b2dc-9f0e-4c3e-88ef-2270bb3f06e1/completions/2026-09-01
```

---

### 4. Unmark a Habit for a Date
`DELETE /api/v1/habits/{habitId}/completions/{date}`

- Removes completion for the specified `YYYY-MM-DD` date.
- Operation is idempotent (returns success even if no completion existed).

**Response (`200 OK`):**
```json
{
  "habitId": "e2f7b2dc-9f0e-4c3e-88ef-2270bb3f06e1",
  "completionDate": "2026-09-01",
  "completed": false,
  "currentStreak": 0
}
```

**cURL Example:**
```bash
curl -X DELETE http://localhost:8080/api/v1/habits/e2f7b2dc-9f0e-4c3e-88ef-2270bb3f06e1/completions/2026-09-01
```

---

## Error Handling

Standardized error response shape:

```json
{
  "timestamp": "2026-09-01T10:30:00",
  "status": 404,
  "error": "NOT_FOUND",
  "message": "Habit not found: 123",
  "path": "/api/v1/habits/123/completions/2026-09-01"
}
```

- `400 Bad Request`: Blank name, name length > 100 characters, invalid date format.
- `404 Not Found`: Non-existent habit ID.
- `500 Internal Server Error`: Unexpected runtime failure.
