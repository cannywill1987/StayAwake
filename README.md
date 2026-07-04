# NoSleepy - Wake Keeper

NoSleepy - Wake Keeper is a Flutter desktop utility that keeps your computer awake through a native menu bar controller and IOKit power assertions.

## Support

For questions, bug reports, or feature requests, open a GitHub issue:

https://github.com/cannywill1987/StayAwake/issues

Please include your app version, operating system version, what you expected to happen, and what happened instead. If you are reporting a keep-awake issue, include whether the session was started from the main window or the menu bar.

## Run

```bash
flutter pub get
flutter run -d macos
```

## Build

```bash
flutter analyze
flutter test
flutter build macos
```

Release app:

```text
build/macos/Build/Products/Release/StayAwake.app
```

## Architecture

- Flutter UI: `lib/main.dart`
- Native macOS bridge: `macos/Runner/AppDelegate.swift`
- Flutter/native channel: `app.stayawake/status_bar`
- Native power API: `IOPMAssertionCreateWithName`
- Documentation: `docs/StayAwake/unknown-branch/`

The current backend surface is local-only: Flutter state, MethodChannel contract, native macOS power assertion service, and system verification through `pmset`.
