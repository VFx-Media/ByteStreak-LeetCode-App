# ByteStreak

A Duolingo-style desktop app for LeetCode / DSA practice: one learning path
(**LeetCode Mastery**), lessons that mix multiple-choice and coding questions,
hearts, XP, streaks, and a global leaderboard. Built with Flutter for Windows.

The full plan lives in `Plan/bytestreak-project-plan.md` in the team folder.

---

## Run it

One-time setup on Windows: turn on **Developer Mode**
(Settings → System → For developers). Flutter needs it to link plugins.

```bash
flutter pub get
flutter run -d windows
```

The backend isn't built yet, so the app runs on an **in-memory fake** (see
"Backend" below). Everything works, but nothing is saved between runs.

- **Sign up** creates a fresh player with 0 XP.
- **Log in** with the demo account (**`dev123` / `password`**) to see a player
  with a few weeks of history, so every screen has data.

## Test it

```bash
flutter test                                    # 117 tests: rules, state, every screen, user flows
flutter test test/screenshots --update-goldens  # regenerate screenshots of every screen
```

The screenshots land in `test/screenshots/goldens/`, light and dark, at
1280 × 800. They're handy for reviewing the UI and for the class report.

---

## How the code is organised

```
lib/
├── main.dart             Starts the app: window size, backend, providers
├── app.dart              MaterialApp: theme, dark mode, router
├── theme/                Colours, colour roles (AppPalette), text styles
├── domain/               Pure Dart, no UI: the rules of the game
│   ├── models.dart          Questions, lessons, player, settings...
│   ├── game_rules.dart      Hearts, XP, levels, leagues, streaks (every number lives here)
│   ├── path_progress.dart   Which nodes on the path are done / current / locked
│   ├── lesson_session.dart  One run through a lesson, quiz, review or practice
│   ├── achievements.dart    The badge catalogue and progress
│   ├── stats.dart           Everything on the Stats screen
│   └── share_lines.dart     One-liners on the share card (Person C)
├── data/
│   ├── repositories.dart    THE CONTRACT: what the UI needs from the backend
│   └── fake/                In-memory stand-ins + sample content (to be replaced)
├── state/                Riverpod providers + PlayerController (applies the rules)
├── router/               Every screen's address, sign-in redirects
├── widgets/              Shared pieces: shell, nav rail, top bar, tags, cards...
└── screens/              One folder per screen (18 screens + dialogs)
```

**The rule that keeps this manageable:** screens never change player data
themselves. They call `PlayerController` (`answer`, `revealHint`,
`finishSession`, `refillHearts`...), which applies `GameRules` and saves
through the repository. Screens just *read* state and redraw when it changes.

### Screens

| Plan | Screen | File |
|---|---|---|
| 1.1 | Onboarding | `screens/onboarding/onboarding_screen.dart` |
| 1.2, 1.2b | Create profile (2 steps) | `screens/auth/signup_*_screen.dart` |
| 1.3 | Home / LeetCode Mastery path | `screens/home/home_screen.dart` |
| 1.4 | Chapter quiz intro | `screens/lesson/quiz_intro_screen.dart` |
| 1.5, 1.6 | Questions (MCQ + code editor) | `screens/lesson/lesson_screen.dart`, `mcq_view.dart`, `code_view.dart` |
| 1.7 | Hints overlay | `screens/lesson/hints_dialog.dart` |
| 1.8, 1.16 | Achievements, Badge detail | `screens/achievements/` |
| 1.9 | Leaderboard | `screens/leaderboard/leaderboard_screen.dart` |
| 1.10 | Stats | `screens/stats/stats_screen.dart` |
| 1.11 | Settings | `screens/settings/settings_screen.dart` |
| 1.12 | Profile | `screens/profile/profile_screen.dart` |
| 1.13 | Log in | `screens/auth/login_screen.dart` |
| 1.14 | Lesson complete | `screens/lesson/lesson_complete_screen.dart` |
| 1.15 | Out of hearts | `screens/lesson/out_of_hearts_dialog.dart` |
| 1.17 | Share card preview | `screens/share/share_preview_dialog.dart` |

### Keyboard shortcuts (it's a desktop app)

| Where | Keys |
|---|---|
| Multiple choice | `1`–`4` or `A`–`D` to pick, `Enter` to check, `Enter` to continue |
| Code editor | `Ctrl+Enter` run, `Ctrl+Shift+Enter` submit |
| Lessons, dialogs | `Esc` to quit / close |
| Quiz intro, Lesson complete | `Enter` to start / continue |

---

## Backend: what Person B replaces

The UI only talks to the interfaces in `lib/data/repositories.dart`:

| Interface | Fake now | Real version |
|---|---|---|
| `ContentRepository` | `fake/fake_content.dart` | drift (SQLite) + content pull from Supabase |
| `AuthRepository` | `FakeBackend.auth` | Supabase Auth (email + password) |
| `PlayerRepository` | `FakeBackend.players` | drift (SQLite) + XP-event sync |
| `SettingsRepository` | `FakeBackend.settingsRepo` | drift `settings` table |
| `LeaderboardRepository` | `FakeBackend.leaderboard` | Supabase ranking query |
| `CodeRunner` | `FakeCodeRunner` | `run-code` Edge Function → Judge0 |

Write the real classes, then change **one line** in `lib/main.dart`
(`AppServices.fake(...)` → your `AppServices(...)`). No screen changes.

The fake code runner can't run Python: it fails code that still has the
starter's `TODO` (or no `return`) and passes anything else.
