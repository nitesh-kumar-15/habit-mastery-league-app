# Habit Mastery League

Offline-first Flutter habit tracker for students (CSC 4360 — Mobile App Development, Project 1). Data stays on device using **SQLite** (`sqflite`) and **SharedPreferences** for settings—no cloud.

## Team

| Name | Role |
|------|------|
| Nitesh Kumar | UI/UX, navigation, documentation, SQLite, business logic, validation, testing |

## Features

- **Habits (CRUD):** title, description, category, frequency (daily / weekdays / weekly), start date with validation.
- **Check-ins:** mark **Done** or **Miss** per day; stored in `habit_logs`.
- **Streaks & stats:** current streak, completion %, best streak, weekly check-ins.
- **Progress & missions:** weekly goals (e.g. 5 check-ins), badges (first step, 7-day streak, 10 completions).
- **Rule-based coach:** local tips from SQLite history (missed days, long streaks, weekday-heavy patterns).
- **Settings:** theme (system / light / dark), daily reminder time (stored locally), toggle coach tips on Home.

## Tech

- Flutter 3.x, Dart 3.x
- `sqflite`, `path_provider`, `shared_preferences`, `intl`, `provider`

## Environment
- Flutter 3.38.7
- Dart 3.10.7
- DevTools 2.51.1

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable).
2. From this folder:

```bash
flutter pub get
flutter run
```

3. Release APK:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Database schema (SQLite)

**habits**

| Column | Type |
|--------|------|
| id | INTEGER PK |
| title | TEXT |
| description | TEXT |
| category | TEXT |
| frequency | TEXT (`daily`, `weekdays`, `weekly`) |
| start_date | TEXT (`yyyy-MM-dd`) |
| created_at, updated_at | TEXT (ISO-8601) |

**habit_logs**

| Column | Type |
|--------|------|
| id | INTEGER PK |
| habit_id | INTEGER FK → habits(id) ON DELETE CASCADE |
| date | TEXT (`yyyy-MM-dd`) |
| status | TEXT (`completed`, `missed`) |
| notes | TEXT |

Unique index: `(habit_id, date)`.

## SharedPreferences keys

- `theme_mode` — `system` | `light` | `dark`
- `daily_reminder_time_minutes` — minutes from midnight (0–1439)
- `show_motivation_tips` — bool

## Known limitations

- Reminder time is saved locally; OS notification scheduling is not wired (optional follow-up).
- Tests cover date helpers; add widget/integration tests as needed.

## License

MIT
