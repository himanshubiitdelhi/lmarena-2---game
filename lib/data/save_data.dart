import 'dart:convert';

import '../config/game_config.dart';

/// One versioned profile. Persistent values are intentionally plain JSON so
/// recovery and migrations can be inspected without platform-specific tooling.
class SaveData {
  SaveData({
    this.coins = 0,
    this.gems = 0,
    this.experience = 0,
    this.totalRuns = 0,
    this.bestScore = 0,
    this.lifetimePlanets = 0,
    this.lifetimePerfects = 0,
    this.lifetimeCoinsEarned = 0,
    this.lifetimeGemsEarned = 0,
    this.largestCombo = 0,
    this.sessionCount = 0,
    this.runsThisSession = 0,
    this.dailyStreak = 0,
    this.bestDailyStreak = 0,
    this.freeStreakFreezeAvailable = true,
    this.streakFreezeWeek = '',
    this.lastDailyRewardDate = '',
    this.dailyRewardDay = 0,
    this.lastDailyChestDate = '',
    this.lastDailyChallengeDate = '',
    this.dailyChallengeBest = 0,
    this.dailyChallengeRuns = 0,
    this.tutorialComplete = false,
    this.removeAdsOwned = false,
    this.starterBundleOwned = false,
    this.starterOfferSeen = false,
    List<String> ownedSkins = const <String>['comet'],
    List<String> ownedTrails = const <String>['stardust'],
    List<String> ownedThemes = const <String>['moonlight'],
    this.equippedSkin = 'comet',
    this.equippedTrail = 'stardust',
    this.equippedTheme = 'moonlight',
    Map<String, int> upgradeLevels = const <String, int>{},
    List<String> unlockedAchievements = const <String>[],
    this.missionDate = '',
    List<String> missionIds = const <String>[],
    Map<String, int> missionProgress = const <String, int>{},
    List<String> claimedMissionIds = const <String>[],
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.analyticsEnabled = false,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.languageCode = 'en',
    this.lastInterstitialAtMs = 0,
    this.lastInterstitialRun = -100,
    this.lastDoubleCoinsRunNumber = 0,
    List<String> processedPurchaseGrantIds = const <String>[],
    this.version = GameConfig.saveSchemaVersion,
  }) : ownedSkins = List<String>.of(ownedSkins),
       ownedTrails = List<String>.of(ownedTrails),
       ownedThemes = List<String>.of(ownedThemes),
       upgradeLevels = Map<String, int>.of(upgradeLevels),
       unlockedAchievements = List<String>.of(unlockedAchievements),
       missionIds = List<String>.of(missionIds),
       missionProgress = Map<String, int>.of(missionProgress),
       claimedMissionIds = List<String>.of(claimedMissionIds),
       processedPurchaseGrantIds = List<String>.of(processedPurchaseGrantIds);

  int coins;
  int gems;
  int experience;
  int totalRuns;
  int bestScore;
  int lifetimePlanets;
  int lifetimePerfects;
  int lifetimeCoinsEarned;
  int lifetimeGemsEarned;
  int largestCombo;
  int sessionCount;
  int runsThisSession;
  int dailyStreak;
  int bestDailyStreak;
  bool freeStreakFreezeAvailable;
  String streakFreezeWeek;
  String lastDailyRewardDate;
  int dailyRewardDay;
  String lastDailyChestDate;
  String lastDailyChallengeDate;
  int dailyChallengeBest;
  int dailyChallengeRuns;
  bool tutorialComplete;
  bool removeAdsOwned;
  bool starterBundleOwned;
  bool starterOfferSeen;
  List<String> ownedSkins;
  List<String> ownedTrails;
  List<String> ownedThemes;
  String equippedSkin;
  String equippedTrail;
  String equippedTheme;
  Map<String, int> upgradeLevels;
  List<String> unlockedAchievements;
  String missionDate;
  List<String> missionIds;
  Map<String, int> missionProgress;
  List<String> claimedMissionIds;
  bool soundEnabled;
  bool musicEnabled;
  bool analyticsEnabled;
  bool hapticsEnabled;
  bool reducedMotion;
  String languageCode;
  int lastInterstitialAtMs;
  int lastInterstitialRun;
  int lastDoubleCoinsRunNumber;
  List<String> processedPurchaseGrantIds;
  int version;

  int upgradeLevel(String key) => upgradeLevels[key] ?? 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'version': GameConfig.saveSchemaVersion,
        'coins': coins,
        'gems': gems,
        'experience': experience,
        'totalRuns': totalRuns,
        'bestScore': bestScore,
        'lifetimePlanets': lifetimePlanets,
        'lifetimePerfects': lifetimePerfects,
        'lifetimeCoinsEarned': lifetimeCoinsEarned,
        'lifetimeGemsEarned': lifetimeGemsEarned,
        'largestCombo': largestCombo,
        'sessionCount': sessionCount,
        'runsThisSession': runsThisSession,
        'dailyStreak': dailyStreak,
        'bestDailyStreak': bestDailyStreak,
        'freeStreakFreezeAvailable': freeStreakFreezeAvailable,
        'streakFreezeWeek': streakFreezeWeek,
        'lastDailyRewardDate': lastDailyRewardDate,
        'dailyRewardDay': dailyRewardDay,
        'lastDailyChestDate': lastDailyChestDate,
        'lastDailyChallengeDate': lastDailyChallengeDate,
        'dailyChallengeBest': dailyChallengeBest,
        'dailyChallengeRuns': dailyChallengeRuns,
        'tutorialComplete': tutorialComplete,
        'removeAdsOwned': removeAdsOwned,
        'starterBundleOwned': starterBundleOwned,
        'starterOfferSeen': starterOfferSeen,
        'ownedSkins': ownedSkins,
        'ownedTrails': ownedTrails,
        'ownedThemes': ownedThemes,
        'equippedSkin': equippedSkin,
        'equippedTrail': equippedTrail,
        'equippedTheme': equippedTheme,
        'upgradeLevels': upgradeLevels,
        'unlockedAchievements': unlockedAchievements,
        'missionDate': missionDate,
        'missionIds': missionIds,
        'missionProgress': missionProgress,
        'claimedMissionIds': claimedMissionIds,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'analyticsEnabled': analyticsEnabled,
        'hapticsEnabled': hapticsEnabled,
        'reducedMotion': reducedMotion,
        'languageCode': languageCode,
        'lastInterstitialAtMs': lastInterstitialAtMs,
        'lastInterstitialRun': lastInterstitialRun,
        'lastDoubleCoinsRunNumber': lastDoubleCoinsRunNumber,
        'processedPurchaseGrantIds': processedPurchaseGrantIds,
      };

  String encode() => jsonEncode(toJson());

  factory SaveData.fromJson(Map<String, Object?> json) {
    final int storedVersion = _readInt(json['version'], 1);
    if (storedVersion > GameConfig.saveSchemaVersion || storedVersion < 1) {
      throw FormatException('Unsupported save version $storedVersion');
    }

    // Version 1 had only the core currency/score/settings keys. Missing fields
    // intentionally inherit the safe current defaults as a forward migration.
    final SaveData data = SaveData(
      coins: _readInt(json['coins'], 0).clamp(0, 2000000000).toInt(),
      gems: _readInt(json['gems'], 0).clamp(0, 2000000000).toInt(),
      experience: _readInt(json['experience'], 0).clamp(0, 2000000000).toInt(),
      totalRuns: _readInt(json['totalRuns'], 0).clamp(0, 2000000000).toInt(),
      bestScore: _readInt(json['bestScore'], 0).clamp(0, 2000000000).toInt(),
      lifetimePlanets: _readInt(json['lifetimePlanets'], 0).clamp(0, 2000000000).toInt(),
      lifetimePerfects: _readInt(json['lifetimePerfects'], 0).clamp(0, 2000000000).toInt(),
      lifetimeCoinsEarned: _readInt(json['lifetimeCoinsEarned'], 0).clamp(0, 2000000000).toInt(),
      lifetimeGemsEarned: _readInt(json['lifetimeGemsEarned'], 0).clamp(0, 2000000000).toInt(),
      largestCombo: _readInt(json['largestCombo'], 0).clamp(0, 1000000).toInt(),
      sessionCount: _readInt(json['sessionCount'], 0).clamp(0, 2000000000).toInt(),
      runsThisSession: _readInt(json['runsThisSession'], 0).clamp(0, 2000000000).toInt(),
      dailyStreak: _readInt(json['dailyStreak'], 0).clamp(0, 1000000).toInt(),
      bestDailyStreak: _readInt(json['bestDailyStreak'], 0).clamp(0, 1000000).toInt(),
      freeStreakFreezeAvailable: _readBool(json['freeStreakFreezeAvailable'], true),
      streakFreezeWeek: _readString(json['streakFreezeWeek'], ''),
      lastDailyRewardDate: _readString(json['lastDailyRewardDate'], ''),
      dailyRewardDay: _readInt(json['dailyRewardDay'], 0).clamp(0, 6).toInt(),
      lastDailyChestDate: _readString(json['lastDailyChestDate'], ''),
      lastDailyChallengeDate: _readString(json['lastDailyChallengeDate'], ''),
      dailyChallengeBest: _readInt(json['dailyChallengeBest'], 0).clamp(0, 2000000000).toInt(),
      dailyChallengeRuns: _readInt(json['dailyChallengeRuns'], 0).clamp(0, 2000000000).toInt(),
      tutorialComplete: _readBool(json['tutorialComplete'], false),
      removeAdsOwned: _readBool(json['removeAdsOwned'], false),
      starterBundleOwned: _readBool(json['starterBundleOwned'], false),
      starterOfferSeen: _readBool(json['starterOfferSeen'], false),
      ownedSkins: _readStringList(json['ownedSkins'], <String>['comet']),
      ownedTrails: _readStringList(json['ownedTrails'], <String>['stardust']),
      ownedThemes: _readStringList(json['ownedThemes'], <String>['moonlight']),
      equippedSkin: _readString(json['equippedSkin'], 'comet'),
      equippedTrail: _readString(json['equippedTrail'], 'stardust'),
      equippedTheme: _readString(json['equippedTheme'], 'moonlight'),
      upgradeLevels: _readIntMap(json['upgradeLevels']),
      unlockedAchievements: _readStringList(json['unlockedAchievements'], <String>[]),
      missionDate: _readString(json['missionDate'], ''),
      missionIds: _readStringList(json['missionIds'], <String>[]),
      missionProgress: _readIntMap(json['missionProgress']),
      claimedMissionIds: _readStringList(json['claimedMissionIds'], <String>[]),
      soundEnabled: _readBool(json['soundEnabled'], true),
      musicEnabled: _readBool(json['musicEnabled'], true),
      analyticsEnabled: _readBool(json['analyticsEnabled'], false),
      hapticsEnabled: _readBool(json['hapticsEnabled'], true),
      reducedMotion: _readBool(json['reducedMotion'], false),
      languageCode: _readString(json['languageCode'], 'en'),
      lastInterstitialAtMs: _readInt(json['lastInterstitialAtMs'], 0),
      lastInterstitialRun: _readInt(json['lastInterstitialRun'], -100),
      lastDoubleCoinsRunNumber: _readInt(json['lastDoubleCoinsRunNumber'], 0),
      processedPurchaseGrantIds: _readStringList(
        json['processedPurchaseGrantIds'] ?? json['processedPurchaseTokens'],
        <String>[],
      ),
      version: GameConfig.saveSchemaVersion,
    );
    data.sanitizeEquippedItems();
    return data;
  }

  factory SaveData.decode(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Save root must be an object');
    }
    return SaveData.fromJson(decoded.cast<String, Object?>());
  }

  void sanitizeEquippedItems() {
    if (!ownedSkins.contains(equippedSkin)) equippedSkin = 'comet';
    if (!ownedTrails.contains(equippedTrail)) equippedTrail = 'stardust';
    if (!ownedThemes.contains(equippedTheme)) equippedTheme = 'moonlight';
    if (!<String>['en', 'hi', 'es', 'pt', 'id'].contains(languageCode)) {
      languageCode = 'en';
    }
    missionProgress.updateAll((String key, int value) => value.clamp(0, 10000000).toInt());
    if (processedPurchaseGrantIds.length > 256) {
      processedPurchaseGrantIds.removeRange(0, processedPurchaseGrantIds.length - 256);
    }
    for (final String key in <String>[
      'coinMagnet',
      'landingZone',
      'feverTime',
      'runShield',
      'startingScore',
    ]) {
      upgradeLevels[key] = (upgradeLevels[key] ?? 0).clamp(0, GameConfig.maxUpgradeLevel).toInt();
    }
  }
}

int _readInt(Object? value, int fallback) => value is num ? value.toInt() : fallback;
bool _readBool(Object? value, bool fallback) => value is bool ? value : fallback;
String _readString(Object? value, String fallback) => value is String ? value : fallback;

List<String> _readStringList(Object? value, List<String> fallback) {
  if (value is! List) return List<String>.of(fallback);
  return value.whereType<String>().toSet().toList(growable: true);
}

Map<String, int> _readIntMap(Object? value) {
  if (value is! Map) return <String, int>{};
  final Map<String, int> output = <String, int>{};
  for (final MapEntry<Object?, Object?> entry in value.entries) {
    if (entry.key is String && entry.value is num) {
      output[entry.key! as String] = (entry.value! as num).toInt();
    }
  }
  return output;
}
