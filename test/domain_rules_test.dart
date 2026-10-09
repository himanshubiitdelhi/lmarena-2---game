import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_hop/config/game_config.dart';
import 'package:orbit_hop/data/save_data.dart';
import 'package:orbit_hop/data/save_repository.dart';
import 'package:orbit_hop/domain/ad_frequency_rules.dart';
import 'package:orbit_hop/domain/catalog.dart';
import 'package:orbit_hop/domain/economy.dart';
import 'package:orbit_hop/domain/game_models.dart';
import 'package:orbit_hop/l10n/app_strings.dart';

void main() {
  group('ORBIT HOP domain rules', () {
    test('score, combo, and rewards have bounded readable rules', () {
      expect(ScoreRules.scoreAfterLanding(0), 1);
      expect(ScoreRules.scoreAfterLanding(-4), 1);
      expect(ScoreRules.comboAfterLanding(4, perfect: true), 5);
      expect(ScoreRules.comboAfterLanding(4, perfect: false), 0);
      expect(ScoreRules.multiplierForCombo(0), 1);
      expect(ScoreRules.multiplierForCombo(9), 4);
      expect(ScoreRules.multiplierForCombo(200), 10);
      expect(ScoreRules.applyMultiplier(3, 6), 9);
      expect(ScoreRules.applyMultiplier(3, 6, fever: true), 18);
    });

    test('daily course and mission seeds are stable for UTC dates', () {
      final DateTime first = DateTime.utc(2026, 10, 8, 0, 2);
      final DateTime later = DateTime.utc(2026, 10, 8, 23, 58);
      expect(dailySeed(first), dailySeed(later));
      final SaveData left = SaveData();
      final SaveData right = SaveData();
      DailyMissionRules.ensureToday(left, first);
      DailyMissionRules.ensureToday(right, later);
      expect(left.missionIds, right.missionIds);
      expect(left.missionIds.length, 3);
      expect(left.missionIds.toSet().length, 3);
    });

    test('daily reward is once a day and weekly freeze protects one missed day', () {
      final SaveData save = SaveData();
      final DailyRewardResult first = DailyRewardRules.claim(save, DateTime.utc(2026, 10, 8, 8));
      expect(first.claimed, isTrue);
      expect(first.coins, GameConfig.dailyCoinRewards[0]);
      expect(save.dailyStreak, 1);
      expect(DailyRewardRules.claim(save, DateTime.utc(2026, 10, 8, 22)).claimed, isFalse);

      final DailyRewardResult freeze = DailyRewardRules.claim(save, DateTime.utc(2026, 10, 10, 9));
      expect(freeze.claimed, isTrue);
      expect(freeze.usedFreeze, isTrue);
      expect(save.dailyStreak, 2);
      expect(save.freeStreakFreezeAvailable, isFalse);

      final DailyRewardResult missed = DailyRewardRules.claim(save, DateTime.utc(2026, 10, 13, 9));
      expect(missed.claimed, isTrue);
      expect(missed.usedFreeze, isFalse);
      expect(save.dailyStreak, 1);
    });

    test('cosmetic lists in a fresh save are mutable and upgrades spend earned coins', () {
      final SaveData save = SaveData(coins: 500);
      save.ownedSkins.add('mango');
      expect(save.ownedSkins, contains('mango'));
      expect(EconomyRules.buyUpgrade(save, UpgradeType.coinMagnet), EconomyResult.success);
      expect(save.upgradeLevel('coinMagnet'), 1);
      expect(save.coins, 380);
    });

    test('save repository recovers from a bad primary using the backup', () async {
      final MemoryKeyValueStore store = MemoryKeyValueStore();
      store.values[SaveRepository.primaryKey] = '{bad-json';
      store.values[SaveRepository.backupKey] = SaveData(coins: 321, gems: 7).encode();
      final SaveLoadResult result = await SaveRepository(store).load();
      expect(result.recovered, isTrue);
      expect(result.corruptDataDiscarded, isTrue);
      expect(result.data.coins, 321);
      expect(result.data.gems, 7);
      expect(store.values[SaveRepository.primaryKey], result.data.encode());
    });

    test('interstitial windows obey session, run, and wall-clock guardrails', () {
      final SaveData save = SaveData(sessionCount: 3, totalRuns: 20);
      final DateTime now = DateTime.utc(2026, 10, 8, 12);
      expect(AdFrequencyRules.canShowInterstitial(save: save, now: now), isFalse);

      save.sessionCount = 4;
      expect(AdFrequencyRules.canShowInterstitial(save: save, now: now), isTrue);
      AdFrequencyRules.recordInterstitial(save, now);
      expect(AdFrequencyRules.canShowInterstitial(save: save, now: now.add(const Duration(seconds: 89))), isFalse);
      save.totalRuns += 2;
      expect(AdFrequencyRules.canShowInterstitial(save: save, now: now.add(const Duration(seconds: 91))), isFalse);
      save.totalRuns++;
      expect(AdFrequencyRules.canShowInterstitial(save: save, now: now.add(const Duration(seconds: 91))), isTrue);

      save.removeAdsOwned = true;
      expect(AdFrequencyRules.canShowInterstitial(save: save, now: now.add(const Duration(minutes: 2))), isFalse);
    });

    test('five supported locales provide a share card message and localized game labels', () {
      for (final String locale in <String>['en', 'hi', 'es', 'pt', 'id']) {
        final AppStrings strings = AppStrings(locale);
        expect(strings.text('app_name'), isNotEmpty);
        expect(strings.text('planets_reached'), isNotEmpty);
        expect(strings.text('share_tagline'), isNotEmpty);
        expect(strings.text('share_message', <String, Object>{'value': 7}), contains('7'));
      }
      expect(AppStrings('hi').translatedDeathLines, isNotEmpty);
      expect(AppStrings('es').translatedDeathLines, isNotEmpty);
      expect(GameConfig.maximumOrbitWaitSeconds, greaterThan(0));
    });

    test('cosmetic catalog has all launch targets and paid currency is cosmetic', () {
      expect(CosmeticCatalog.skins, hasLength(24));
      expect(CosmeticCatalog.trails, hasLength(12));
      expect(CosmeticCatalog.themes, hasLength(6));
      expect(
        GameConfig.suggestedPriceCents.keys.toSet(),
        <String>{GameConfig.productRemoveAds, GameConfig.productGems, GameConfig.productStarterBundle},
      );
      expect(GameConfig.productGemRewards[GameConfig.productGems], 25);
    });
  });
}
