# Fix Android build toolchain compatibility

Branch: `feature-codex/android-build-compatibility`
Base: `main`
Commit: `57b1a18`

Fix Android debug builds that fail while configuring google_mobile_ads 6.0.0 with `Could not get unknown property 'all'`. The locally selected Gradle 9.7.1 is incompatible with the plugin's Android build script. Align the toolchain with Flutter 3.38.4's API 36 compile SDK.

- Pin Gradle 8.11.1, Android Gradle Plugin 8.10.1, and Kotlin 2.2.10.
- Remove the obsolete Kotlin 1.7.1 standard-library override, allowing the Kotlin plugin to supply the matching library.
- Document the supported toolchain and debug build command.

Only build configuration and documentation are included. Other local application changes and the version bump remain uncommitted.

## Validation

- Working application: `flutter build apk --debug` passed before the shutdown.
- Clean checkout of commit `57b1a18`: `flutter build apk --debug` passed after restart (41.7 seconds).
- Remaining compiler output consists of Java 8 target and deprecated-API warnings; the ads configuration failure and Flutter Kotlin-version warning are resolved.
- `git diff HEAD^ HEAD --check`: passed.

## Publishing

PR: https://github.com/kapame2022/KapaMe-Mobile/pull/1

Branch pushed and PR opened against `main`. Left unmerged for review.
