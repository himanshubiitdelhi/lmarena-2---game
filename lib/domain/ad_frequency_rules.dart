import '../config/game_config.dart';
import '../data/save_data.dart';

class AdFrequencyRules {
  AdFrequencyRules._();

  /// Call only after a user voluntarily leaves a completed run. Never call from
  /// an active-game screen or from lifecycle callbacks.
  static bool canShowInterstitial({
    required SaveData save,
    required DateTime now,
  }) {
    if (save.removeAdsOwned) return false;
    if (save.sessionCount <= GameConfig.interstitialFirstSessionsExcluded) return false;
    if (save.totalRuns - save.lastInterstitialRun < GameConfig.interstitialMinimumRunsBetween) {
      return false;
    }
    if (save.lastInterstitialAtMs > 0) {
      final int elapsed = now.toUtc().millisecondsSinceEpoch - save.lastInterstitialAtMs;
      if (elapsed < GameConfig.interstitialMinimumGap.inMilliseconds) return false;
    }
    return true;
  }

  static void recordInterstitial(SaveData save, DateTime now) {
    save.lastInterstitialAtMs = now.toUtc().millisecondsSinceEpoch;
    save.lastInterstitialRun = save.totalRuns;
  }
}
