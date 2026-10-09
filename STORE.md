# Google Play store package and declarations

## Listing copy

**App title (28/30 characters):** `ORBIT HOP: Neon Space Arcade`

**Short description (under 80 characters):** `Tap, launch, and land across neon planets. One more orbit?`

**Full description:**

> Meet your tiny blob and see how far it can hop through a very large universe.
>
> Tap once to launch from a rotating planet. Aim for the next orbit, scoop up coins, and chain perfect landings to start Fever Mode. Every course brings new moving planets, spike hazards, color zones, and the cosmic soup rising below.
>
> **A quick, skill-first arcade loop**
> • One-thumb controls and a short first-run tutorial.
> • Smoothly changing orbit timing, planet motion, and hazards.
> • Six neon zones, Fever Mode, near-miss effects, and funny space mishaps.
> • Earn coins and gems through play; collect 24 blobs, 12 trails, and 6 themes.
> • Upgrade your classic runs, complete daily missions, build streaks, and earn achievements.
> • Try a shared, seeded Daily Challenge once each UTC day.
> • Play offline with local saves and local best scores. Google Play Games leaderboards are optional.
>
> ORBIT HOP is designed for players aged 13 and older. No account is required to play. Optional rewarded videos can grant a limited in-game reward; a limited interstitial may appear after some game-over screens. There are no banners during a run. Optional purchases are direct and visible: remove interstitial ads or unlock cosmetic gems and a starter skin. Purchases do not sell gameplay power, and there are no loot boxes or random paid rewards.

**Category:** Game → Arcade.

**Suggested tags:** Arcade, Casual, Single-player, Offline.

**Store assets:** Upload the generated app icon from `assets/icon/orbit_hop_icon.svg` after rasterizing at Play's required icon size; use genuine device screenshots from a release candidate. Do not imply real-time multiplayer, guaranteed earnings, child-directed content, or paid competitive advantage. Screenshot copy must match the released game and ad behavior.

## Audience and content rating questionnaire

1. **Target audience:** select only age bands **13–15, 16–17, and 18+**. Do not select any under-13 age band. State in the listing that the game is for ages 13+. Use age-appropriate art/marketing and do not direct campaigns or store creative to children. If the Play Console's child-appeal review flags the cute art, resolve the art/listing concern instead of selecting a false audience answer.
2. **IARC content questionnaire:** answer from the shipped build, not from the intended rating. For the current source, choose:
   - Violence, sexual content/nudity, sexual themes, strong language, controlled substances, gambling/simulated gambling, and horror: **No**. The blob's cartoon fall/game-over has no attack, blood, injury detail, or violent depiction.
   - User-generated content, in-app chat, open social networking, and real-time player-to-player interaction: **No**. There is no chat or user-posted content. The optional Play Games leaderboard shows scores; score-card sharing opens Android's external system share sheet.
   - In-app purchases: **Yes**. Google Play Billing products are configured for direct purchases (cosmetic gems/starter cosmetic bundle and remove-interstitials); no randomized paid items.
   - Advertising: **Yes**. The production build includes Google Mobile Ads and may show optional rewarded videos and frequency-capped post-game interstitials. No banners are used.
3. Submit the questionnaire and use the actual IARC-assigned ratings in every storefront. The publisher cannot set a rating by writing “13+” in the description; answer honestly if gameplay or third-party SDK behavior changes.
4. Keep the Play target-audience selection, ad SDK age treatment (`teen`), store listing, privacy policy, and UMP settings in agreement. Do not enable child-directed ad treatment.

## Ads declaration

In Play Console → **App content → Ads**, answer **Yes, my app contains ads** for the production build. The Google Mobile Ads SDK is included and the configured release can request ads. Declare both rewarded video and interstitial formats; the lack of banner placements does not make the answer “No.” Test IDs used during development do not change the production declaration. If a future build removes the SDK and all ad inventory, re-evaluate the answer for that build.

In AdMob/UMP, set the content treatment for the 13+ audience and configure regional consent, a valid privacy-policy URL, and privacy-options entry. Ads are requested only after UMP allows them. Do not add banners, forced rewarded videos, or an interstitial during active gameplay. Current interstitial rules: no impressions during the first three app sessions; at most one per three completed runs; at least 90 seconds between impressions; only after game over; none after the player owns Remove Ads.

## Google Play Data safety — release answers

The form must reflect the final release, including SDK behavior and the real verifier. With the configured optional SDKs in this project, use the following answers; do not claim “no data collected” simply because a feature is optional or consent-gated.

- **Does the app collect or share any required user data types?** **Yes** for a release with production ads, optional Google Play Games, a configured purchase verifier, or opted-in Firebase. Data can be transmitted when the player uses those features/consents.
- **Is data encrypted in transit?** **Yes** for Google/Firebase SDK traffic and the HTTPS-only purchase verifier. Never use a cleartext verifier URL.
- **Can users request deletion of their data?** **Yes, through the monitored Contact developer privacy-request channel on the Play listing**, for server/provider data the publisher controls and where retention is not legally required. Local profile data is erased by uninstalling or clearing app storage. Set up and monitor that channel before submitting; otherwise answer according to the actual request mechanism and revise this section.
- **Does the app provide an account-creation flow?** **No.** Play Games sign-in is optional and is not required to use offline features.

Declare data types and purposes as follows for each enabled integration:

| Data type to declare | When/why it is processed | Purpose(s) | Shared? |
| --- | --- | --- | --- |
| **App interactions / other app activity** (gameplay events, score, session/run duration, ad/product event) | Firebase Analytics only after opt-in; AdMob may process ad views/clicks when ads are requested | Analytics (Firebase); advertising/measurement/fraud prevention (AdMob); app functionality (score submission) | Yes, with Google/Firebase service providers when the feature is used |
| **Crash logs and diagnostics** | Crashlytics only after opt-in; ad/store SDK diagnostics as applicable | Analytics/diagnostics, app functionality, security | Yes, with Firebase/Google service providers when enabled |
| **Device or other IDs** (ad ID and SDK/app-instance/install identifiers) | Google Mobile Ads/UMP, Firebase, Play Games or billing SDK as enabled | Advertising, analytics, app functionality, fraud/security | Yes, with the relevant Google/Firebase service provider |
| **User IDs** (Play Games account/player identifier) | Only when the player signs in or submits/views online leaderboards | App functionality, account/service operation | Yes, with Google Play Games Services |
| **Financial info → purchase history** (product ID, purchase/order ID, purchase token/entitlement record) | Google Play purchase handling and HTTPS verifier; the app does not receive card/bank credentials | App functionality, purchase fulfillment, fraud/security/legal compliance | Yes, with Google Play and the publisher's verifier |

For each row, mark collection as **optional** where the player can skip the corresponding integration or opt out. Mark whether data is ephemeral only if the provider/backend actually deletes it as described by the final retention configuration. Mark “not used for tracking” only if no data is used to track users across apps/websites. Do not declare precise or approximate location, contacts, photos, videos, audio, email, phone number, or payment-card details: the current source does not request or collect them. The generated score card is local and only leaves the device if the player chooses an Android share target.

Additional release checks:

- Confirm Firebase Analytics and Crashlytics are disabled by default in the manifest and in-app setting; verify an opted-out device sends no events/crash reports.
- Confirm AdMob/UMP consent and device privacy controls work in all target regions. Google may process additional device/ad data; review the SDK's current Data safety disclosures in Play Console before upload.
- Restrict access and retention for the purchase-verification server. The verifier receives raw purchase tokens and must validate them with Google Play; do not store them longer than required for entitlement, fraud prevention, accounting, and legal obligations.
- Revisit this form whenever an SDK, ads setup, backend, event parameter, leaderboard, or share behavior changes. Provider SDK disclosures can change independently of this app.

## Purchases, ads, and child-safety summary

- No paid product grants coins, upgrades, shields, score, or leaderboard advantage. Gems are spent only on cosmetics; the starter bundle gives a skin and five cosmetic gems.
- No random paid rewards, loot boxes, fake countdowns, or misleading scarcity.
- Rewarded ads are explicit opt-in; interstitials are post-game-over and capped. There are no banners during active play.
- The declared audience is 13+. Do not target under-13s or mark the app as designed for children. Use the IARC result assigned after the final questionnaire.
