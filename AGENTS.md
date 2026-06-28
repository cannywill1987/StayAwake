# AGENTS.md - StayAwake

## Project Rules

- Treat StayAwake as a macOS-first Flutter desktop utility.
- Keep UI work in `lib/main.dart` unless the app grows enough to split into smaller widgets.
- Keep macOS native behavior in `macos/Runner/AppDelegate.swift` and bridge it through `app.stayawake/status_bar`.
- Do not create a remote backend unless product scope adds accounts, sync, billing, or team policies.
- Verify keep-awake behavior with `pmset -g assertions`; UI-only success is not enough.
- When touching Status Bar or native power behavior, run:

```bash
flutter analyze
flutter test
flutter build macos
```

## Status Bar Contract

Flutter calls:

- `startSession({durationSeconds, preventDisplaySleep, allowScreenSaver})`
- `stopSession()`
- `getStatus()`

Native calls back:

- `startPreset(seconds)`
- `stopSession()`
- `nativeStatusChanged(payload)`

## Design Assets

Project docs live in:

```text
docs/StayAwake/unknown-branch/
```
