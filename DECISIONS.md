# ORBIT HOP — decisions log

Every entry records a deliberate implementation or release choice and its reason.

## Step 1 — product and Android setup

- **Android-only, portrait, one-thumb play.** This keeps scope centered on the requested mobile arcade loop and permits precise safe-area/input tuning.
- **Flutter with Flame; package `com.orbithop.game`.** Flame supplies a lightweight 2D loop while Flutter handles accessible menus, settings, purchases, and forms; the stable reverse-domain ID avoids a later Play listing rename.
- **Minimum Android API 24; compile and target API 36.** The minimum covers current Play-distribution plugin requirements while targeting the current Android SDK stated for this release plan.
- **Players aged 13 and over; no child-directed design.** This follows the requested audience and avoids collecting or targeting data from children.
- **Local-first saves with a last-known-good backup; network integrations are optional.** The game remains playable without accounts, Firebase, ads, or a connection, and corrupted saves can recover.
- **All account-dependent integrations start in test/offline-safe mode.** Test AdMob IDs and replaceable Play Games/Firebase/store configuration make development safe without real account credentials.
- **A daily challenge uses a deterministic UTC seed and one attempt per UTC date.** Everyone receives the same course without timezone or local-difficulty advantages.
- **Daily challenges ignore gameplay upgrades and shields.** This preserves leaderboard fairness while leaving classic runs fully customizable.
- **Coins earned in play buy gameplay upgrades; paid products never grant coins or gameplay power.** This enforces the no-pay-to-win requirement; purchased gems are cosmetic-only.
- **The IAP catalog is limited to removing interstitials and cosmetic gems/a cosmetic starter bundle; skin-collection achievements grant no currency.** This prevents cosmetic purchases from indirectly earning gameplay coins or upgrades.
- **No banner inventory is included.** Banners would intrude on portrait gameplay and conflict with the requested no-banners rule.
- **Rewarded ads are opt-in and grant only a single revive, post-run coin double, or one daily chest.** The reward is explicit, bounded, and never required to continue playing.
- **Interstitials are scheduled only after game over, excluding the first three sessions, at most once per three runs and at least 90 seconds apart.** This encodes the exact frequency guardrail requested.
- **Ad requests use teen-restricted treatment and a T maximum content rating.** This aligns ad delivery with the stated 13+ audience.
- **Play Games is optional; local leaderboards always remain available.** The account sign-in path cannot block play or erase local progress.
- **Firebase analytics and Crashlytics initialize only when native Firebase configuration exists, and collection is off until the player opts in.** The default empty project launches privately offline instead of failing at startup.
- **Localization uses five selectable language codes: English, Hindi, Spanish, Portuguese, and Indonesian.** These match the requested launch languages and are stored per device.
- **A new player sees a single tap-to-launch tutorial once.** One concise first-run hint teaches the central gesture without delaying repeat runs.
- **Audio is synthesized locally and the score card is rendered from vector shapes.** This avoids third-party asset licensing and keeps the offline build self-contained.
- **Backgrounding or leaving the game silences audio even after a run has ended.** This prevents the ambient track from continuing behind another screen or outside the app.
- **The initial signing fallback is Flutter's debug key; Play release signing is documented as an external secret.** No keystore or private signing material belongs in Git.
- **App version starts at `1.0.0+1`.** The initial release has an explicit Play-compatible version that can be incremented for each upload.
- **The Gradle bootstrap uses the pinned 8.13 distribution rather than an arbitrary system Gradle.** This keeps AGP 8.13 builds deterministic across Android hosts.
- **Live AdMob units and Play Games leaderboard IDs start empty; SDK loaders skip them safely.** This keeps account-dependent features inert instead of shipping fake or unresolved IDs.
- **A dependency-free browser harness mirrors the core timing loop for quick playtests, but stays outside the Android release.** This gives immediate interaction feedback without implying web-platform support or substituting for Android verification.

## Later implementation choices

- **Six 25-planet visual zones loop while difficulty continues to rise.** The palette cadence gives readable milestones without a difficulty cap.
- **Spikes, drifting/shrinking planets, the rising danger zone, near-miss slowdown, and Fever Mode use seeded rules.** Deterministic generation simplifies replay, testing, and same-day challenges.
- **A missed launch is the primary failure; each run may use at most one rewarded revive.** This keeps the core arcade loop legible and limits ad rewards.
- **Cosmetics are direct-purchase with visible prices; there are no loot boxes or fake countdowns.** Players can see exactly what they unlock.
- **Play purchase fulfillment fails closed until an HTTPS receipt verifier is configured.** The client cannot safely validate Play purchase tokens or grant paid items on its own.
- **Consumables are consumed only after server verification and durable local save.** This reduces lost purchases and makes server-side idempotency the source of truth.
- **An absent or invalid optional SDK is contained rather than blocking the game.** Offline play and local scores remain the baseline behavior.
- **Score-card artwork and share-sheet copy follow the selected UI locale.** Shared results should remain understandable when players use any supported language.
- **Play purchase-stream batches are serialized and retried by idempotent grant ID.** This avoids overlapping grants, duplicate-token busy locks, and consume-before-save failures.
