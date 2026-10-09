import 'dart:math' as math;

/// Single source of truth for tuning, rewards, and monetization guardrails.
/// Store prices are recommendations only; Google Play supplies localized prices.
class GameConfig {
  GameConfig._();

  static const String gameName = 'ORBIT HOP';
  static const String packageName = 'com.orbithop.game';
  static const String versionName = '1.0.0';
  static const int buildNumber = 1;
  static const int saveSchemaVersion = 3;

  // Current Google Play submission target (Android 16 / API 36, Oct 2026).
  static const int minAndroidSdk = 24;
  static const int compileAndroidSdk = 36;
  static const int targetAndroidSdk = 36;

  // Frame/game feel. The logical playfield is always portrait and adapts to size.
  static const double playerRadius = 12;
  static const double initialPlanetRadius = 37;
  static const double minimumPlanetRadius = 20;
  static const double orbitGap = 35;
  static const double initialOrbitSpin = 1.22;
  static const double maximumOrbitSpin = 3.35;
  static const double initialLaunchSpeed = 430;
  static const double maximumLaunchSpeed = 600;
  static const double targetOrbitDistance = 220;
  static const double initialLandingWindow = 32;
  static const double maximumLandingWindow = 53;
  static const double perfectAngleWindow = 0.15;
  static const double feverPerfectAngleWindow = 0.23;
  static const int feverPerfectsRequired = 5;
  static const Duration feverDuration = Duration(seconds: 8);
  static const double dangerRisePixelsPerSecond = 39;
  static const double maximumOrbitWaitSeconds = 20;
  static const double nearMissSlowMotionSeconds = 0.42;
  static const double nearMissSlowMotionScale = 0.38;
  static const int zoneLength = 25;
  static const int zoneCount = 6;
  static const int starCount = 68;
  static const int maximumParticles = 150;
  static const int minimumFpsTarget = 60;

  // Currency and daily rewards.
  static const int landingCoins = 3;
  static const int perfectBonusCoins = 4;
  static const int firstRunCoins = 15;
  static const int reviveCoins = 0;
  static const int dailyChestCoins = 100;
  static const int dailyChallengeBonusCoins = 20;
  static const int dailyChallengeBonusGems = 1;
  static const List<int> dailyCoinRewards = <int>[30, 40, 0, 60, 75, 100, 200];
  static const List<int> dailyGemRewards = <int>[0, 0, 1, 0, 0, 0, 1];
  static const int dailyChallengeMinimumRunSeconds = 10;
  static const int missionRewardCoins = 75;
  static const int missionRewardXp = 35;
  static const int xpPerPlanet = 2;
  static const int xpPerPerfect = 3;
  static const int xpPerRun = 8;
  static const int xpPerDailyChallenge = 20;

  // Upgrade prices are indexed by the level being purchased (levels 1-5).
  static const Map<String, List<int>> upgradeCosts = <String, List<int>>{
    'coinMagnet': <int>[120, 260, 480, 780, 1150],
    'landingZone': <int>[150, 300, 520, 820, 1200],
    'feverTime': <int>[180, 350, 600, 900, 1300],
    'runShield': <int>[220, 450, 750, 1100, 1550],
    'startingScore': <int>[300, 600, 950, 1400, 2000],
  };
  static const int maxUpgradeLevel = 5;
  static const double coinMagnetRadiusPerLevel = 16;
  static const double landingZoneBonusPerLevel = 3.5;
  static const double feverSecondsPerLevel = 0.8;
  static const int freeShieldUsesPerRun = 1;
  static const int startingScorePerLevel = 1;

  // Ad policy. No banner inventory is defined intentionally.
  static const int interstitialFirstSessionsExcluded = 3;
  static const int interstitialMinimumRunsBetween = 3;
  static const Duration interstitialMinimumGap = Duration(seconds: 90);
  static const int rewardedRevivesPerRun = 1;
  static const int rewardedDoubleCoinsPerRun = 1;
  static const int rewardedFreeChestsPerDay = 1;
  static const bool useTestAds = true;
  static const String testAdMobApplicationId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String liveRewardedAdUnitId = '';
  static const String liveInterstitialAdUnitId = '';

  // Google Play product IDs and suggested US list prices in cents. Localized
  // storefront prices are always taken from ProductDetails.price at runtime.
  static const String productRemoveAds = 'orbit_remove_ads';
  static const String productGems = 'orbit_gems_25';
  static const String productStarterBundle = 'orbit_starter_bundle';
  static const Map<String, int> suggestedPriceCents = <String, int>{
    productRemoveAds: 299,
    productGems: 299,
    productStarterBundle: 199,
  };
  static const Map<String, int> productGemRewards = <String, int>{
    productGems: 25,
    productStarterBundle: 5,
  };
  static const String purchaseVerificationEndpoint = String.fromEnvironment(
    'ORBIT_PURCHASE_VERIFICATION_ENDPOINT',
    defaultValue: '',
  );
  static const String playBestScoreLeaderboardId = '';
  static const String playDailyLeaderboardId = '';

  // A six-palette loop. Difficulty keeps increasing after the sixth zone.
  static const List<ZonePalette> zones = <ZonePalette>[
    ZonePalette('Moonlight', 0xFF8DEBFF, 0xFF91A7FF, 0xFF14172D),
    ZonePalette('Saffron', 0xFFFFD36E, 0xFFFF8D7E, 0xFF26192E),
    ZonePalette('Verdant', 0xFF72FFD2, 0xFF9DFF91, 0xFF102824),
    ZonePalette('Violet', 0xFFD6A6FF, 0xFF8D7DFF, 0xFF1E1533),
    ZonePalette('Tidal', 0xFF69DAFF, 0xFF4E91FF, 0xFF101D38),
    ZonePalette('Solar', 0xFFFFAB77, 0xFFFF5E9A, 0xFF2B1325),
  ];

  static double difficultyFor(int reachedPlanets) {
    final int score = math.max(0, reachedPlanets).toInt();
    final int loops = score ~/ (zoneLength * zoneCount);
    final int zoneProgress = score % (zoneLength * zoneCount);
    return (zoneProgress / (zoneLength * zoneCount)) + loops * 0.55;
  }

  static double planetRadiusAt(int score) => math.max(
        minimumPlanetRadius,
        initialPlanetRadius - math.min(12, math.max(0, score) * 0.17),
      ).toDouble();

  static double spinAt(int score) => math.min(
        maximumOrbitSpin,
        initialOrbitSpin + math.max(0, score) * 0.025,
      ).toDouble();

  static double launchSpeedAt(int score) => math.min(
        maximumLaunchSpeed,
        initialLaunchSpeed + math.max(0, score) * 2.2,
      ).toDouble();

  static int zoneIndexAt(int score) => (math.max(0, score).toInt() ~/ zoneLength) % zoneCount;
}

class ZonePalette {
  const ZonePalette(this.name, this.accentArgb, this.secondaryArgb, this.backgroundArgb);

  final String name;
  final int accentArgb;
  final int secondaryArgb;
  final int backgroundArgb;
}
