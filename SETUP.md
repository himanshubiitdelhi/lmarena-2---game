# ORBIT HOP setup

## 1. Local Android build

Required on the development machine:

- Flutter stable **3.38.1 or newer** and Dart supplied by Flutter.
- Android Studio with Android SDK Platform/Build Tools **36**, Android command-line tools, and an emulator or physical Android device.
- A **JDK 17** installation (`flutter doctor -v` must report it).
- For a Windows shell, PowerShell; for macOS/Linux, `curl` or `wget` and `unzip` for the first Gradle bootstrap.

The Android application ID is `com.orbithop.game`; the display orientation is portrait; the minimum SDK is API 24, with compile/target SDK 36. `android/gradlew` bootstraps Gradle 8.13 from the official Gradle distribution service on first build and caches it in the normal Gradle user directory. The build does not require a separately installed Gradle command.

From the repository root:

```sh
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run
```

For a device-specific launch, list devices with `flutter devices`, then use `flutter run -d DEVICE_ID`. The first Android build downloads Flutter/Gradle/plugin dependencies. `android/local.properties` is generated locally by Flutter and is ignored by Git. This project contains no private keystore or Google service credentials.

The project is local-first. The first playable run does not wait for ads, Firebase, Google Play Games, purchase verification, or sign-in. When these services are not configured, their buttons report that state and offline play remains available.

## 2. Safe defaults already in source

- `lib/config/game_config.dart` selects Google/AdMob **test ad unit IDs** (`useTestAds = true`). `android/app/src/main/res/values/strings.xml` uses Google's sample AdMob application ID.
- Play Games leaderboard IDs start empty and the Android game-services ID is `0` until a Play Games project is created. The plugin does not submit/show a leaderboard without an ID; sign-in errors are caught and local scores keep working.
- Firebase Gradle plugins are applied only when `android/app/google-services.json` exists. Firebase initialization errors are caught. Analytics and Crashlytics collection are **off by default** and can be opted into in Settings.
- Purchases fail closed until an HTTPS receipt-verification endpoint is provided. No client-side test purchase is treated as a real paid grant.
- Purchased gems unlock cosmetics only. The client has no coin packs and grants no gameplay upgrade or run currency from paid products.

Do not change these safeguards to release credentials until the matching accounts, IDs, policy forms, and backend are ready.

## 3. Google Play Games (optional)

1. Create the game in Google Play Console and link it to a Google Play Games Services project. Create the **Classic best score** and **Daily Challenge** leaderboards.
2. Add the Android package `com.orbithop.game` and the SHA-1 fingerprints for debug and upload/release signing certificates in Play Console. The certificate used for local debug is not the Play App Signing certificate.
3. In `android/app/src/main/res/values/strings.xml`, replace the development value in `play_games_app_id` with the numeric Play Games Services application ID (the number, not a resource name).
4. In `lib/config/game_config.dart`, set `playBestScoreLeaderboardId` and `playDailyLeaderboardId` to the exact Android leaderboard IDs issued by Play Console.
5. Publish the Play Games configuration to the same testing track as the Android build and add tester accounts. Test sign-in and both score boards from a signed internal-test build.

Sign-in is always optional; do not gate local gameplay or local best scores on Play Games availability.

## 4. Firebase Analytics and Crashlytics (optional)

1. Create a Firebase project and register the Android app with package `com.orbithop.game`.
2. Download `google-services.json` and place it at `android/app/google-services.json`. It is excluded by `.gitignore`; never commit it.
3. Build again. The conditional Gradle setup will apply Google Services and Crashlytics plugins only when the file exists. Confirm Firebase starts in device logs.
4. Analytics and crash collection remain opt-in and off by default. A player can enable or disable them in Settings. Keep retention windows and incident access restricted in Firebase Console.

A missing or invalid Firebase project must not block local play. Do not add account identifiers, email addresses, or precise location to events. The current event schema records game lifecycle, score, run duration, failure category, ad-format events, and product IDs, and does not send the local save file.

## 5. AdMob, UMP consent, and ad policy

The app contains no banner placements. Optional rewarded placements are limited to one revive in a run, one post-run coin double, and one daily chest. Interstitial requests are only made from the completed game-over screen; frequency rules exclude the first three sessions and enforce both three runs between impressions and a 90-second minimum gap. Remove-ads disables interstitials, not optional rewarded ads.

Before production ads:

1. Create the Android app and ad units in AdMob. Publish a privacy policy and configure the UMP consent message/privacy-options entry for every applicable region.
2. Replace `admob_app_id` in `android/app/src/main/res/values/strings.xml`, then set `useTestAds` to `false` and populate the two empty live rewarded/interstitial ID constants in `lib/config/game_config.dart`. The app skips ad loading while either live unit ID is blank.
3. Use the ad-content rating and teen treatment required by the intended 13+ audience. The source sets a T maximum rating and `AgeRestrictedTreatment.teen`; do not mark the app as child-directed.
4. Verify test ads and consent flows first. Only request ads when UMP reports they may be requested. Keep rewarded rewards optional and never add an ad that interrupts an active run.

Google's sample app ID and test units are safe for development only. They are not monetization IDs and must not be represented as production ads.

## 6. Google Play Billing and receipt verification

The Play product IDs are declared in `GameConfig`: `orbit_remove_ads` (non-consumable), `orbit_gems_25` (consumable cosmetic currency), and `orbit_starter_bundle` (one-time Mango skin plus five cosmetic gems, offered after run five). Prices are taken from Play's localized `ProductDetails`; the suggested cents in source are documentation only. There are no purchasable coin packs, random rewards, or paid gameplay upgrades.

Purchases are deliberately disabled until there is a trusted verifier. Implement a server endpoint backed by the Google Play Developer API, then build with:

```sh
flutter build appbundle --release \
  --dart-define=ORBIT_PURCHASE_VERIFICATION_ENDPOINT=https://YOUR_VERIFIER_HOST/google-play/verify
```

Replace the example URL with the HTTPS URL controlled by your service; do not put Google service-account credentials in the app. The client POST body contains `packageName`, `productId`, `purchaseToken`, and `purchaseId`. The verifier must authenticate the token with Google, check package/product/purchase state, reject refunds/cancellations, map each allowed product to a fixed grant, and make `grantId` idempotent per purchase token. It must return HTTP 200 JSON with:

```json
{
  "verified": true,
  "grantId": "server-generated-stable-id",
  "newGrant": true,
  "coins": 0,
  "gems": 25,
  "removeAds": false,
  "starterBundle": false
}
```

The values above are an example **response shape**, not a grant to hard-code. For `orbit_remove_ads`, return `removeAds: true`, no currency, and a stable grant. For `orbit_gems_25`, return exactly the server-authorized cosmetic gem amount. For `orbit_starter_bundle`, return `starterBundle: true` and the five cosmetic gems. Keep `coins` at zero for every paid product: the client intentionally ignores paid coin grants so purchases cannot buy gameplay power. `newGrant` must be false on repeat verification. Never trust client-supplied grant amounts or use a placeholder verifier in a public build.

The client listens to the purchase stream before querying products. It consumes a gem purchase only after the server confirms it and the local save is written; failed/offline verification leaves the transaction retryable. Test with Play license testers and an internal track, including duplicate tokens, interrupted verification, restore, refund, and reinstall cases. See [`TESTING.md`](TESTING.md).

## 7. Updating app identity and version

The release display/version values are in `pubspec.yaml` (`1.0.0+1`) and mirrored in `GameConfig`. Increment the build number for every Play upload; keep the package name unchanged after the first published listing. SDK targets, manifest metadata, test IDs, and account placeholders are centralized in `android/` and `lib/config/game_config.dart`.

The app uses no runtime permission for contacts, location, camera, or microphone. Internet is needed only by optional online services; vibration is used only when the player's haptics setting is enabled.
