Android debug builds fail while configuring `google_mobile_ads` 6.0.0 when Gradle 9 is selected, with `Could not get unknown property 'all'`. This change pins a compatible Android toolchain that also supports Flutter 3.38.4's API 36 compile SDK.

- Use Gradle 8.11.1, Android Gradle Plugin 8.10.1, and Kotlin 2.2.10.
- Remove the obsolete Kotlin 1.7.1 standard-library override so the Kotlin plugin supplies the matching library.
- Document the supported toolchain and debug build command.

### Validation

- `flutter build apk --debug` passed for the working application.
- `flutter build apk --debug` passed in a clean checkout of commit `57b1a18` (41.7 seconds).
- `git diff HEAD^ HEAD --check` passed.

Java 8 target and deprecated-API warnings remain. No runtime or release-build verification was performed. This PR contains only Android build configuration and documentation.
