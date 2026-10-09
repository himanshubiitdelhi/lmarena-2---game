# ORBIT HOP Android release and signing

## Release identity

- Package/application ID: `com.orbithop.game` (do not change after listing creation).
- Initial version: `1.0.0+1` (`versionName=1.0.0`, `versionCode=1`). Increment the build number for every upload.
- Minimum Android API: 24. Compile/target API: 36.
- Store audience: ages 13+; content rating and ad declaration must match [`STORE.md`](STORE.md).
- The source defaults to Google test ads. Production ads, Firebase, Play Games, and billing are separate account/configuration work described in [`SETUP.md`](SETUP.md).

## Create a private upload key once

Use the JDK 17 `keytool` command and store the keystore and passwords outside the repository. For example, create an upload keystore in a private directory under your home folder:

```sh
mkdir -p "$HOME/orbit-hop-signing"
keytool -genkeypair -v \
  -keystore "$HOME/orbit-hop-signing/orbit-hop-upload.jks" \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias orbit-hop-upload
```

Choose a strong keystore/key password and save them in your organization's password manager. Do not paste them into chat, source files, CI logs, or Git. Back up the keystore securely; loss of the upload key can delay updates. Enroll in Google Play App Signing and retain the upload certificate separately from the Play app-signing certificate.

Create `android/key.properties` locally (it is Git-ignored) with these property names and your actual values:

```properties
storeFile=/absolute/path/to/orbit-hop-upload.jks
storePassword=your-keystore-password
keyAlias=orbit-hop-upload
keyPassword=your-key-password
```

Replace the example path/password values on your machine; do not commit the file. `android/app/build.gradle` reads this file and uses its release signing configuration when present. Without it, release artifacts use the Flutter debug key only for local smoke tests and are **not suitable for Play upload**.

## Build a signed Android App Bundle

Install Flutter 3.38.1+, Android SDK Platform 36, and JDK 17, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=ORBIT_PURCHASE_VERIFICATION_ENDPOINT=https://YOUR_VERIFIER_HOST/google-play/verify
```

For a build that does not expose purchases, omit the `--dart-define`; purchases then remain disabled. For a monetized release, replace `YOUR_VERIFIER_HOST` with your controlled HTTPS verifier host and complete the server setup in `SETUP.md` before shipping. A reserved example hostname is not a working endpoint.

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

The Gradle setup uses Android release minification/resource shrinking. Verify the release AAB with `bundletool` or upload it to a Play internal-testing track; test on at least one API 24 device/emulator and one current API 36 device before staged rollout.

## Play Console release checklist

1. Create the app using package `com.orbithop.game`; enable Play App Signing and upload the signed AAB.
2. Complete the store listing, privacy-policy URL, target audience, IARC rating, ads declaration, and Data safety form using [`STORE.md`](STORE.md). Host [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) at a public HTTPS URL and update its developer contact route.
3. Create and activate only the Play Billing product IDs listed in `SETUP.md`; configure license testers and server-side purchase verification before enabling live purchases.
4. If using Play Games, publish the correct game-services configuration, leaderboards, numeric app ID, and debug/upload SHA-1s to the test track.
5. If using Firebase, install the matching `google-services.json` privately and verify opt-in settings. If using production ads, replace all sample IDs, set the production ad switch, configure UMP and consent/privacy URLs, and keep teen treatment enabled.
6. Install the internal-track build from Play (not a side-loaded debug APK) and verify Play Billing, Play Games, signing, and leaderboard APIs with authorized tester accounts.
7. Run the entire acceptance plan in [`TESTING.md`](TESTING.md), check Play pre-launch reports for crashes/ANRs, verify a clean offline launch, and review all data disclosures against actual SDK/backend behavior.
8. Stage rollout gradually; monitor crash-free sessions, consent/form failures, refunds, purchase verification, and user feedback. Keep a rollback/build-number record.

## Build status for this checkout

This source tree is configured for an AAB build, but no signed AAB was generated in the current sandbox because Flutter, Dart, Java/JDK, Gradle, and Android SDK tooling are not installed. The first provisioned-machine build must run analysis/tests and fix any package/Gradle API drift before publishing.
