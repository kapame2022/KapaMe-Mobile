# kapame

A new Flutter project.

## Android builds

The Android build uses Gradle 8.11.1, Android Gradle Plugin 8.10.1, and
Kotlin 2.2.10. This combination supports the API 36 compile SDK used by
Flutter 3.38.4. Use JDK 17 or 21; `flutter doctor -v` shows which Java
installation Flutter selected.

Keep the Gradle wrapper on 8.x while using `google_mobile_ads` 6.x. Its
Android build script accesses `configurations.all` as a property, which
fails under Gradle 9 with `Could not get unknown property 'all'`.
Do not patch the shared pub cache or bypass Flutter dependency validation.

Validate Android build changes with:

```sh
flutter pub get
flutter build apk --debug
```

Compatibility references: [Android Gradle Plugin 8.10](https://developer.android.com/build/releases/agp-8-10-0-release-notes)
and [Kotlin Gradle compatibility](https://kotlinlang.org/docs/gradle-configure-project.html).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
