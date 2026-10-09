# ORBIT HOP test plan

Run from the repository root after installing Flutter stable 3.38.1+, Android SDK 36, and JDK 17:

```sh
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d DEVICE_ID
```

A release test bundle uses the signing/verifier instructions in [`LAUNCH.md`](LAUNCH.md). Store, ads, Play Games, and Firebase integration tests must run on an internal Play track or test device with test accounts; do not validate live purchases or production ad inventory on a public listing.

## Automated rule coverage

`test/domain_rules_test.dart` checks:

- Score increments, perfect-combo reset/multiplier caps, and Fever reward multiplication.
- Stable same-UTC-day course/mission seeds and three unique daily missions.
- Daily reward once-per-day behavior, streak continuation, weekly freeze, and reset after a longer gap.
- Mutable fresh-save cosmetic inventories and coin-only gameplay upgrades.
- Backup recovery after corrupt primary JSON.
- Interstitial session exclusion, three-run spacing, 90-second spacing, and remove-ads suppression.
- Catalog counts (24 skins, 12 trails, 6 themes) and the no-paid-coin product list.
- Five-locale score-card copy, localized game labels/death lines, and the bounded orbit wait.

## Manual game acceptance

Test portrait phones at narrow and tall aspect ratios, Android API 24 and a current API 36 device. Verify:

1. Cold launch reaches Home without network, account, Firebase, AdMob, billing, or Play Games.
2. The first run teaches the single tap-to-launch gesture once; subsequent runs do not repeat the first-run tutorial.
3. Taps launch only from the ready orbit; score increases only after landing; a perfect increments combo; an ordinary landing resets it; Fever begins at the configured perfect chain and expires visibly.
4. Coin pickups and rare gems are collected once, upgrades affect classic runs, and daily challenge ignores upgrades/shields and is seeded identically for the same UTC date.
5. Moving planets, spikes, shrinking planets, near-miss slowdown, danger-zone rise, shield, death, one optional revive, restart, and quitting from pause do not duplicate run rewards.
6. A daily attempt is recorded at start and cannot be restarted on the same UTC date. A qualifying run (at least 10 seconds) receives its one-time daily bonus; a short quit does not.
7. Offline saves survive force-stop/restart. Corrupt the primary test save and verify recovery from its last-known-good copy; corrupt both and verify safe defaults.
8. Settings toggles persist: sound, music, haptics, reduced motion, language, and opt-in analytics/crash reporting. Verify no analytics/crash collection while opted out.
9. Home, shop, missions, achievements, rewards, leaderboards, and settings fit small screens, scroll correctly, and remain legible with Android display/font scaling.
10. Verify every UI language selection (English, Hindi, Spanish, Portuguese, Indonesian) updates the UI and persists after restart.

## Ads and consent tests

Use AdMob test units only. Exercise UMP consent required/not-required/error paths, privacy-options entry, ads disallowed, rewarded load failure, reward earned, dismissal, show failure, and app backgrounding. Confirm:

- No banner request exists.
- A rewarded ad is never started without a direct tap; a missing ad simply leaves the reward unavailable.
- Reward callbacks are idempotent: no more than one revive per run, one coin double per completed run, and one daily chest per UTC day.
- An interstitial is requested only from the completed game-over flow, not during an active run, pause, app resume, or first three sessions.
- The maximum frequency is one impression per three runs, with at least 90 seconds between impressions; a failed-to-show request does not count as an impression.
- Remove-ads suppresses interstitials but does not suppress optional rewarded ads.
- Teen treatment and the T maximum ad rating appear in request configuration; the consent form and privacy options behave for applicable regions.

## Billing, Play Games, and Firebase

### Billing

Use Play license testers and an internal testing track with the HTTPS verifier from `SETUP.md`. Exercise successful/failed/pending/canceled/restored purchases, repeated tokens, delayed/offline verification, process death before grant, process death after local save but before consume/acknowledge, refund/revoke, and reinstall. Verify the verifier's `grantId` is idempotent, the client never grants from an unverified purchase, consumable gems are consumed only after verified durable save, restore rehydrates only verified entitlements, paid products grant no coins or upgrades, and starter bundle unlocks after run five.

### Play Games

Test sign-in cancellation, unavailable service, missing leaderboard IDs, successful score submission, returning from leaderboard UI, and a device without Google Play Games. Local best scores and gameplay must be unchanged in every failure case.

### Firebase

Test with no `google-services.json`, an invalid file, and the intended Firebase Android app. Startup and offline runs must work in all cases. With configuration, verify collection starts disabled; opt-in enables both requested services, opt-out disables them, and event parameters contain only the intended gameplay/diagnostic fields.

## Release/performance checks

- Run on a low-to-mid-tier physical Android device; profile a long run for steady 60 FPS, allocation spikes, memory growth, thermal throttling, and jank after zone changes.
- Confirm particles stay within the configured cap, only active planets/pickups are retained, audio can be interrupted by focus changes, and reduced-motion mode suppresses shakes/limits flashes.
- Test Android back, app switching, screen lock, phone interruption, low memory, and process recreation during Home, active run, rewarded ad, interstitial, purchase, and share sheet.
- Check `flutter build appbundle --release` with the upload signing key, `bundletool` or Play's internal-track delivery, Android 24 minimum, Android 36 target, icon, orientation, exported activity, privacy policy URL, ads declaration, content rating, Data safety answers, billing products, and Play Games IDs.
- Use Play Console pre-launch report and Accessibility Scanner. Fix all crashes, ANRs, blocked touch targets, clipping, unexpected network failure screens, and policy warnings before rollout.

## Execution status in this workspace

The source and unit tests are written, but this sandbox currently has no Flutter, Dart, Java/JDK, Gradle, or Android SDK executable. Therefore `flutter pub get`, `flutter analyze`, `flutter test`, device integration, and AAB generation have **not** been run here. A Tree-sitter Dart grammar pass accepts all 25 Dart source/test files, Android XML/SVG files parse as well-formed XML, and `sh -n android/gradlew` passes; these lightweight checks do not type-check Dart, validate plugin APIs, or replace Flutter analysis. Run the commands above in a provisioned Flutter/Android environment before considering the build verified; resolve package API or analyzer errors there before release.
