import 'dart:math' as math;

import '../data/save_data.dart';
import 'economy.dart';

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.goal,
    this.coinReward = 50,
    this.gemReward = 0,
  });

  final String id;
  final String title;
  final String description;
  final String metric;
  final int goal;
  final int coinReward;
  final int gemReward;
}

class AchievementRules {
  AchievementRules._();

  static const List<AchievementDefinition> all = <AchievementDefinition>[
    AchievementDefinition(id: 'first_orbit', title: 'First Orbit', description: 'Reach your first new planet.', metric: 'bestScore', goal: 1, coinReward: 25),
    AchievementDefinition(id: 'score_10', title: 'Up We Go', description: 'Reach 10 planets in one run.', metric: 'bestScore', goal: 10, coinReward: 50),
    AchievementDefinition(id: 'zone_2', title: 'New Neighborhood', description: 'Visit the second color zone.', metric: 'bestScore', goal: 25, coinReward: 100),
    AchievementDefinition(id: 'score_50', title: 'Planet Collector', description: 'Reach 50 planets in one run.', metric: 'bestScore', goal: 50, coinReward: 150),
    AchievementDefinition(id: 'planets_100', title: 'Well Traveled', description: 'Reach 100 planets across all runs.', metric: 'lifetimePlanets', goal: 100, coinReward: 100),
    AchievementDefinition(id: 'planets_500', title: 'Galaxy Hopper', description: 'Reach 500 planets across all runs.', metric: 'lifetimePlanets', goal: 500, coinReward: 200, gemReward: 1),
    AchievementDefinition(id: 'perfect_1', title: 'On the Mark', description: 'Land a perfect launch.', metric: 'lifetimePerfects', goal: 1, coinReward: 35),
    AchievementDefinition(id: 'perfect_25', title: 'Perfect Rhythm', description: 'Land 25 perfect launches.', metric: 'lifetimePerfects', goal: 25, coinReward: 125),
    AchievementDefinition(id: 'perfect_100', title: 'Orbit Artist', description: 'Land 100 perfect launches.', metric: 'lifetimePerfects', goal: 100, coinReward: 250, gemReward: 1),
    AchievementDefinition(id: 'combo_3', title: 'Three in a Row', description: 'Build a combo of 3 perfect launches.', metric: 'largestCombo', goal: 3, coinReward: 50),
    AchievementDefinition(id: 'combo_5', title: 'Hot Streak', description: 'Start Fever Mode.', metric: 'largestCombo', goal: 5, coinReward: 100),
    AchievementDefinition(id: 'combo_10', title: 'Unstoppable', description: 'Build a combo of 10 perfect launches.', metric: 'largestCombo', goal: 10, coinReward: 175, gemReward: 1),
    AchievementDefinition(id: 'runs_5', title: 'Again!', description: 'Play 5 runs.', metric: 'totalRuns', goal: 5, coinReward: 40),
    AchievementDefinition(id: 'runs_25', title: 'One More Try', description: 'Play 25 runs.', metric: 'totalRuns', goal: 25, coinReward: 100),
    AchievementDefinition(id: 'runs_100', title: 'Orbit Regular', description: 'Play 100 runs.', metric: 'totalRuns', goal: 100, coinReward: 250),
    AchievementDefinition(id: 'coins_500', title: 'Pocket Change', description: 'Earn 500 coins over time.', metric: 'lifetimeCoinsEarned', goal: 500, coinReward: 50),
    AchievementDefinition(id: 'coins_2500', title: 'Coin Comet', description: 'Earn 2,500 coins over time.', metric: 'lifetimeCoinsEarned', goal: 2500, coinReward: 175),
    AchievementDefinition(id: 'gems_5', title: 'Rare Find', description: 'Collect 5 gems over time.', metric: 'lifetimeGemsEarned', goal: 5, coinReward: 100, gemReward: 1),
    AchievementDefinition(id: 'fever_1', title: 'Feeling the Heat', description: 'Reach 5 perfects in one streak.', metric: 'largestCombo', goal: 5, coinReward: 75),
    AchievementDefinition(id: 'fever_10', title: 'Fever Dream', description: 'Build 10 perfect launches in a row.', metric: 'largestCombo', goal: 10, coinReward: 150, gemReward: 1),
    AchievementDefinition(id: 'zone_6', title: 'Sixth Sense', description: 'Reach the sixth color zone.', metric: 'bestScore', goal: 125, coinReward: 200, gemReward: 1),
    AchievementDefinition(id: 'daily_1', title: 'Same Sky', description: 'Play a Daily Challenge.', metric: 'dailyChallengeRuns', goal: 1, coinReward: 35),
    AchievementDefinition(id: 'daily_7', title: 'Daily Orbit', description: 'Play 7 Daily Challenges.', metric: 'dailyChallengeRuns', goal: 7, coinReward: 150),
    AchievementDefinition(id: 'streak_7', title: 'Seven Sunrises', description: 'Claim rewards on 7 consecutive days.', metric: 'bestDailyStreak', goal: 7, coinReward: 125),
    AchievementDefinition(id: 'streak_30', title: 'Monthly Moon', description: 'Build a 30-day daily reward streak.', metric: 'bestDailyStreak', goal: 30, coinReward: 300, gemReward: 2),
    AchievementDefinition(id: 'skin_collector', title: 'A Different Blob', description: 'Unlock 12 character skins.', metric: 'ownedSkins', goal: 12),
    AchievementDefinition(id: 'skin_master', title: 'Blob Fashion Week', description: 'Unlock all 24 character skins.', metric: 'ownedSkins', goal: 24),
    AchievementDefinition(id: 'trail_collector', title: 'Leave a Mark', description: 'Unlock all 12 trails.', metric: 'ownedTrails', goal: 12),
    AchievementDefinition(id: 'level_10', title: 'Double Digits', description: 'Reach player level 10.', metric: 'playerLevel', goal: 10, coinReward: 200, gemReward: 1),
    AchievementDefinition(id: 'gems_25', title: 'Gemologist', description: 'Collect 25 gems over time.', metric: 'lifetimeGemsEarned', goal: 25, coinReward: 250, gemReward: 2),
  ];

  static AchievementDefinition? byId(String id) {
    for (final AchievementDefinition definition in all) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  static Set<String> unlockedIdsFor(SaveData save) => save.unlockedAchievements.toSet();

  static List<AchievementDefinition> evaluate(SaveData save) {
    final Map<String, int> metrics = <String, int>{
      'bestScore': save.bestScore,
      'lifetimePlanets': save.lifetimePlanets,
      'lifetimePerfects': save.lifetimePerfects,
      'largestCombo': save.largestCombo,
      'totalRuns': save.totalRuns,
      'lifetimeCoinsEarned': save.lifetimeCoinsEarned,
      'lifetimeGemsEarned': save.lifetimeGemsEarned,
      'dailyChallengeRuns': save.dailyChallengeRuns,
      'bestDailyStreak': save.bestDailyStreak,
      'ownedSkins': save.ownedSkins.length,
      'ownedTrails': save.ownedTrails.length,
      'playerLevel': LevelRules.progressFor(save.experience).level,
    };
    final List<AchievementDefinition> unlocked = <AchievementDefinition>[];
    for (final AchievementDefinition item in all) {
      if (save.unlockedAchievements.contains(item.id)) continue;
      if ((metrics[item.metric] ?? 0) < item.goal) continue;
      save.unlockedAchievements.add(item.id);
      save.coins = math.min(2000000000, save.coins + item.coinReward).toInt();
      save.gems = math.min(2000000000, save.gems + item.gemReward).toInt();
      save.lifetimeCoinsEarned += item.coinReward;
      save.lifetimeGemsEarned += item.gemReward;
      unlocked.add(item);
    }
    return unlocked;
  }

  static bool isUnlocked(SaveData save, String? achievementId) =>
      achievementId == null || save.unlockedAchievements.contains(achievementId);
}
