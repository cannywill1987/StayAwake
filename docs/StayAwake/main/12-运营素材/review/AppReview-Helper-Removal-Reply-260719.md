创建日期：260719

# App Review Helper Removal Reply

## Current Build

- App: NoSleepy - Wake Keeper
- Bundle ID: `com.linzhibin.stayawake`
- Version: `1.0.0`
- Build: `4`
- Exported package: `build/macos/export/NoSleepy-1.0.0-4-260719/NoSleepy - Wake Keeper.pkg`

## Reply Text

```text
Hello App Review Team,

Thank you for your review. We have updated the app to make the closed-display helper removal path clear and user-accessible.

1. How is the helper installed?
The closed-display helper is not installed with SMJobBless or SMAppService. SMAppService is only used for the main app login item / start-at-login preference.

The closed-display helper is installed only after the user explicitly enables the closed-display keep-awake feature and confirms an administrator authorization prompt. The helper is a restricted shell helper placed at:

/Library/PrivilegedHelperTools/com.linzhibin.stayawake.powerprotect

The app also creates a limited sudoers rule at:

/private/etc/sudoers.d/stayawake_powerProtect

This rule only allows the helper to run three specific commands:
enable, disable, and status.

2. Is the helper removed/uninstalled?
The helper is not silently or automatically removed when the user deletes the app from Finder.

To make this clear and controllable for users, we added a visible “Remove Helper” button in the top-right area of the main app window when the helper is installed. The same removal option is also available in Settings.

When the user chooses “Remove Helper,” the app asks for confirmation and removes both:
- /Library/PrivilegedHelperTools/com.linzhibin.stayawake.powerprotect
- /private/etc/sudoers.d/stayawake_powerProtect

The removal flow also restores the closed-display sleep setting by running pmset disablesleep 0 when needed.

3. What entitlements are requested by the helper?
The helper itself is not a separate signed app extension, launch daemon bundle, or privileged executable with its own entitlement file. It is a restricted shell helper, so it does not request any macOS entitlements.

The Release app entitlement is:
- com.apple.security.app-sandbox = true

No additional helper entitlements are requested.

We have attached/provided a screenshot showing the new “Remove Helper” control in the app’s main window. Users can now clearly remove the helper at any time from inside the app.

Best regards,
NoSleepy Team
```

## Local Release Status

- `flutter analyze`: passed
- `flutter test`: passed
- `flutter build macos --build-name=1.0.0 --build-number=4`: passed
- `xcodebuild archive`: passed
- `xcodebuild -exportArchive` with `macos/ExportOptions-appstore.plist`: passed
- Direct upload with Xcode export `destination=upload`: blocked by local Xcode account credentials: `missing Xcode-Token`
