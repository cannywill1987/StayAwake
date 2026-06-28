# StayAwake

StayAwake is a Flutter macOS utility that keeps the Mac awake through a native menu bar controller and IOKit power assertions.

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
