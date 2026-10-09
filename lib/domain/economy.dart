import 'dart:math' as math;

import '../config/game_config.dart';
import '../data/save_data.dart';

enum UpgradeType { coinMagnet, landingZone, feverTime, runShield, startingScore }

enum EconomyResult { success, insufficientFunds, maxLevel, alreadyOwned, unknownItem }

extension UpgradeTypeInfo on UpgradeType {
  String get key => switch (this) {
        UpgradeType.coinMagnet => 'coinMagnet',
        UpgradeType.landingZone => 'landingZone',
        UpgradeType.feverTime => 'feverTime',
        UpgradeType.runShield => 'runShield',
        UpgradeType.startingScore => 'startingScore',
      };

  String get title => switch (this) {
        UpgradeType.coinMagnet => 'Coin magnet',
        UpgradeType.landingZone => 'Soft landing',
        UpgradeType.feverTime => 'Fever battery',
        UpgradeType.runShield => 'Pocket shield',
        UpgradeType.startingScore => 'Head start',
      };

  String get description => switch (this) {
        UpgradeType.coinMagnet => 'Pull nearby coins toward your blob.',
        UpgradeType.landingZone => 'Widen the safe landing window.',
        UpgradeType.feverTime => 'Keep Fever Mode going longer.',
        UpgradeType.runShield => 'Begin each run with one free shield.',
        UpgradeType.startingScore => 'Begin runs with bonus score.',
      };

  int get maxLevel => GameConfig.maxUpgradeLevel;
}

class EconomyRules {
  EconomyRules._();

  static int upgradeCost(UpgradeType type, int currentLevel) {
    if (currentLevel < 0 || currentLevel >= type.maxLevel) return 0;
    final List<int> costs = GameConfig.upgradeCosts[type.key]!;
    return costs[currentLevel];
  }

  static EconomyResult buyUpgrade(SaveData save, UpgradeType type) {
    final int level = save.upgradeLevel(type.key);
    if (level >= type.maxLevel) return EconomyResult.maxLevel;
    final int cost = upgradeCost(type, level);
    if (save.coins < cost) return EconomyResult.insufficientFunds;
    save.coins -= cost;
    save.upgradeLevels[type.key] = level + 1;
    return EconomyResult.success;
  }

  static EconomyResult buyCosmetic({
    required SaveData save,
    required String itemId,
    required int coinCost,
    required int gemCost,
    required List<String> ownedList,
  }) {
    if (ownedList.contains(itemId)) return EconomyResult.alreadyOwned;
    if (coinCost < 0 || gemCost < 0) return EconomyResult.unknownItem;
    if (save.coins < coinCost || save.gems < gemCost) {
      return EconomyResult.insufficientFunds;
    }
    save.coins -= coinCost;
    save.gems -= gemCost;
    ownedList.add(itemId);
    return EconomyResult.success;
  }

  static void grantRunRewards({
    required SaveData save,
    required int coins,
    required int gems,
    required int score,
    required int perfects,
    required int maxCombo,
    required bool dailyChallenge,
  }) {
    save.coins = (save.coins + math.max(0, coins)).clamp(0, 2000000000).toInt();
    save.gems = (save.gems + math.max(0, gems)).clamp(0, 2000000000).toInt();
    save.lifetimePlanets += math.max(0, score).toInt();
    save.lifetimePerfects += math.max(0, perfects).toInt();
    save.largestCombo = math.max(save.largestCombo, maxCombo).toInt();
    save.bestScore = math.max(save.bestScore, score).toInt();
    save.experience += GameConfig.xpPerRun +
        score * GameConfig.xpPerPlanet +
        perfects * GameConfig.xpPerPerfect +
        (dailyChallenge ? GameConfig.xpPerDailyChallenge : 0);
    if (dailyChallenge) {
      save.dailyChallengeBest = math.max(save.dailyChallengeBest, score).toInt();
    }
  }
}

class DailyRewardResult {
  const DailyRewardResult({
    required this.claimed,
    required this.usedFreeze,
    required this.coins,
    required this.gems,
    required this.dayIndex,
  });

  final bool claimed;
  final bool usedFreeze;
  final int coins;
  final int gems;
  final int dayIndex;
}

class DailyRewardRules {
  DailyRewardRules._();

  static String dateKey(DateTime date) {
    final DateTime utc = date.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDateKey(String value) {
    final List<String> parts = value.split('-');
    if (parts.length != 3) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    try {
      final DateTime parsed = DateTime.utc(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) return null;
      return parsed;
    } on ArgumentError {
      return null;
    }
  }

  static String weekKey(DateTime date) {
    final DateTime utc = date.toUtc();
    final DateTime thursday = utc.add(Duration(days: 4 - (utc.weekday % 7)));
    final int week = ((thursday.difference(DateTime.utc(thursday.year, 1, 1)).inDays +
                DateTime.utc(thursday.year, 1, 1).weekday -
                1) /
            7)
        .floor() +
        1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  static void refreshWeeklyFreeze(SaveData save, DateTime now) {
    final String currentWeek = weekKey(now);
    if (save.streakFreezeWeek != currentWeek) {
      save.streakFreezeWeek = currentWeek;
      save.freeStreakFreezeAvailable = true;
    }
  }

  static DailyRewardResult claim(SaveData save, DateTime now) {
    refreshWeeklyFreeze(save, now);
    final String today = dateKey(now);
    if (save.lastDailyRewardDate == today) {
      return DailyRewardResult(
        claimed: false,
        usedFreeze: false,
        coins: 0,
        gems: 0,
        dayIndex: save.dailyRewardDay,
      );
    }

    final DateTime utcNow = now.toUtc();
    final DateTime? lastDate = _parseDateKey(save.lastDailyRewardDate);
    final int dayGap = lastDate == null ? 0 :
        DateTime.utc(utcNow.year, utcNow.month, utcNow.day)
            .difference(DateTime.utc(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
    bool usedFreeze = false;
    if (lastDate == null || dayGap > 2 || dayGap < 1) {
      save.dailyStreak = 0;
      save.dailyRewardDay = 0;
    } else if (dayGap == 2) {
      if (save.freeStreakFreezeAvailable) {
        save.freeStreakFreezeAvailable = false;
        usedFreeze = true;
      } else {
        save.dailyStreak = 0;
        save.dailyRewardDay = 0;
      }
    }

    save.dailyStreak = math.min(1000000, save.dailyStreak + 1).toInt();
    save.bestDailyStreak = math.max(save.bestDailyStreak, save.dailyStreak).toInt();
    final int dayIndex = save.dailyRewardDay.clamp(0, 6).toInt();
    final int coins = GameConfig.dailyCoinRewards[dayIndex];
    final int gems = GameConfig.dailyGemRewards[dayIndex];
    save.coins += coins;
    save.gems += gems;
    save.lastDailyRewardDate = today;
    save.dailyRewardDay = (dayIndex + 1) % GameConfig.dailyCoinRewards.length;
    return DailyRewardResult(
      claimed: true,
      usedFreeze: usedFreeze,
      coins: coins,
      gems: gems,
      dayIndex: dayIndex,
    );
  }
}

class StableRandom {
  StableRandom(int seed) : _state = seed == 0 ? 0x6D2B79F5 : seed & 0xFFFFFFFF;

  int _state;

  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'Must be positive');
    _state ^= (_state << 13) & 0xFFFFFFFF;
    _state ^= _state >> 17;
    _state ^= (_state << 5) & 0xFFFFFFFF;
    _state &= 0xFFFFFFFF;
    return _state % max;
  }

  double nextDouble() => nextInt(0x7FFFFFFF) / 0x7FFFFFFF;

  double between(double min, double max) => min + (max - min) * nextDouble();
}

class DailyMissionDefinition {
  const DailyMissionDefinition({
    required this.id,
    required this.title,
    required this.goal,
    required this.metric,
  });

  final String id;
  final String title;
  final int goal;
  final String metric;
}

class DailyMissionRules {
  DailyMissionRules._();

  static const List<DailyMissionDefinition> all = <DailyMissionDefinition>[
    DailyMissionDefinition(id: 'planet_12', title: 'Reach 12 planets in total', goal: 12, metric: 'planets'),
    DailyMissionDefinition(id: 'planet_25', title: 'Reach 25 planets in total', goal: 25, metric: 'planets'),
    DailyMissionDefinition(id: 'perfect_4', title: 'Land 4 perfect launches', goal: 4, metric: 'perfects'),
    DailyMissionDefinition(id: 'perfect_8', title: 'Land 8 perfect launches', goal: 8, metric: 'perfects'),
    DailyMissionDefinition(id: 'coins_20', title: 'Collect 20 coins', goal: 20, metric: 'coins'),
    DailyMissionDefinition(id: 'coins_40', title: 'Collect 40 coins', goal: 40, metric: 'coins'),
    DailyMissionDefinition(id: 'combo_3', title: 'Build a combo of 3', goal: 3, metric: 'combo'),
    DailyMissionDefinition(id: 'score_10', title: 'Score 10 in one run', goal: 10, metric: 'bestRun'),
    DailyMissionDefinition(id: 'daily_1', title: 'Play today’s challenge', goal: 1, metric: 'daily'),
    DailyMissionDefinition(id: 'run_3', title: 'Play 3 runs', goal: 3, metric: 'runs'),
    DailyMissionDefinition(id: 'fever_1', title: 'Start Fever Mode once', goal: 1, metric: 'fevers'),
    DailyMissionDefinition(id: 'gems_1', title: 'Collect a rare gem', goal: 1, metric: 'gems'),
  ];

  static void ensureToday(SaveData save, DateTime now) {
    final String today = DailyRewardRules.dateKey(now);
    if (save.missionDate == today &&
        save.missionIds.length == 3 &&
        save.missionIds.toSet().length == 3 &&
        save.missionIds.every((String id) => all.any((DailyMissionDefinition mission) => mission.id == id))) {
      return;
    }
    final StableRandom random = StableRandom(dailySeed(now) ^ 0x4D495353);
    final List<DailyMissionDefinition> pool = List<DailyMissionDefinition>.of(all);
    final List<String> ids = <String>[];
    while (ids.length < 3 && pool.isNotEmpty) {
      ids.add(pool.removeAt(random.nextInt(pool.length)).id);
    }
    save.missionDate = today;
    save.missionIds = ids;
    save.missionProgress = <String, int>{for (final String id in ids) id: 0};
    save.claimedMissionIds = <String>[];
  }

  static List<DailyMissionDefinition> missionsFor(SaveData save) {
    final List<DailyMissionDefinition> result = <DailyMissionDefinition>[];
    for (final String id in save.missionIds) {
      for (final DailyMissionDefinition mission in all) {
        if (mission.id == id) {
          result.add(mission);
          break;
        }
      }
    }
    return result;
  }

  static void addProgress(SaveData save, String metric, int amount) {
    if (amount <= 0) return;
    for (final DailyMissionDefinition mission in missionsFor(save)) {
      if (mission.metric != metric) continue;
      final int before = save.missionProgress[mission.id] ?? 0;
      save.missionProgress[mission.id] = math.min(mission.goal, before + amount).toInt();
    }
  }

  static bool claim(SaveData save, String missionId) {
    DailyMissionDefinition? mission;
    for (final DailyMissionDefinition item in all) {
      if (item.id == missionId) {
        mission = item;
        break;
      }
    }
    if (mission == null || !save.missionIds.contains(missionId) ||
        save.claimedMissionIds.contains(missionId) ||
        (save.missionProgress[missionId] ?? 0) < mission.goal) {
      return false;
    }
    save.claimedMissionIds.add(missionId);
    save.coins += GameConfig.missionRewardCoins;
    save.experience += GameConfig.missionRewardXp;
    return true;
  }
}

int dailySeed(DateTime now) {
  final DateTime utc = now.toUtc();
  final int value = utc.year * 10000 + utc.month * 100 + utc.day;
  // Integer mixing keeps daily layouts identical on every Dart VM/device.
  return (value ^ 0x4F524249) & 0x7FFFFFFF;
}

class LevelProgress {
  const LevelProgress({required this.level, required this.currentXp, required this.nextLevelXp});

  final int level;
  final int currentXp;
  final int nextLevelXp;

  double get fraction => nextLevelXp <= 0 ? 1 : currentXp / nextLevelXp;
}

class LevelRules {
  LevelRules._();

  static int xpForNextLevel(int level) => 80 + (math.max(1, level).toInt() - 1) * 35;

  static LevelProgress progressFor(int totalXp) {
    int remaining = math.max(0, totalXp).toInt();
    int level = 1;
    while (remaining >= xpForNextLevel(level)) {
      remaining -= xpForNextLevel(level);
      level++;
    }
    return LevelProgress(level: level, currentXp: remaining, nextLevelXp: xpForNextLevel(level));
  }
}
