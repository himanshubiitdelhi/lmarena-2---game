import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/game_config.dart';
import '../data/save_data.dart';
import '../data/save_repository.dart';
import '../domain/achievements.dart';
import '../domain/ad_frequency_rules.dart';
import '../domain/catalog.dart';
import '../domain/economy.dart';
import '../domain/game_models.dart';
import '../game/orbit_hop_game.dart';
import '../l10n/app_strings.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/play_games_service.dart';
import '../services/purchase_service.dart';
import '../services/share_card_service.dart';
import '../services/telemetry_service.dart';

class AppController extends ChangeNotifier {
  AppController._(this._repository)
      : analytics = AnalyticsService(),
        crashReporting = CrashReportingService(),
        audio = GameAudioService(),
        playGames = PlayGamesService(),
        shareCards = ShareCardService() {
    ads = AdService(analytics);
    purchases = PurchaseService(
      analytics: analytics,
      onVerified: _applyVerifiedPurchase,
      onMessage: showMessage,
      onChanged: _notifyPurchaseState,
    );
  }

  final SaveRepository _repository;
  final AnalyticsService analytics;
  final CrashReportingService crashReporting;
  final GameAudioService audio;
  final PlayGamesService playGames;
  final ShareCardService shareCards;
  late final AdService ads;
  late final PurchaseService purchases;

  SaveData save = SaveData();
  AppStrings get _strings => AppStrings(save.languageCode);
  OrbitHopGame? game;
  RunResult? lastRunResult;
  String currentPage = 'home';
  String message = '';
  bool isLoaded = false;
  bool isDailyGame = false;
  bool starterOfferAvailable = false;
  bool _disposed = false;
  bool _doubleRewardLoading = false;
  bool _chestRewardLoading = false;
  int gameKey = 0;
  final Set<int> _finishedRuns = <int>{};
  Future<void> _saveQueue = Future<void>.value();

  static Future<AppController> create() async {
    final SharedPreferencesStore preferences = await SharedPreferencesStore.create();
    final AppController controller = AppController._(SaveRepository(preferences));
    await controller.initialize();
    return controller;
  }

  Future<void> initialize() async {
    final SaveLoadResult loadResult = await _repository.load();
    save = loadResult.data;
    final DateTime now = DateTime.now().toUtc();
    save.sessionCount++;
    save.runsThisSession = 0;
    DailyRewardRules.refreshWeeklyFreeze(save, now);
    DailyMissionRules.ensureToday(save, now);
    save.sanitizeEquippedItems();
    isLoaded = true;
    unawaited(_persist());
    notifyListeners();

    // These SDKs are optional. None of them gate the first playable frame.
    unawaited(_initializeFirebase());
    unawaited(ads.initialize());
    unawaited(purchases.initialize());
    unawaited(audio.setPreferences(sound: save.soundEnabled, music: save.musicEnabled));
  }

  Future<void> _initializeFirebase() async {
    final bool ready = await FirebaseBootstrap.initializeSafely();
    analytics.setEnabled(ready && save.analyticsEnabled);
    await crashReporting.initialize(enabled: ready && save.analyticsEnabled);
  }

  void startGame({bool dailyChallenge = false}) {
    final DateTime now = DateTime.now().toUtc();
    if (dailyChallenge && save.lastDailyChallengeDate == DailyRewardRules.dateKey(now)) {
      showMessage(_strings.text('daily_already_played'));
      return;
    }
    isDailyGame = dailyChallenge;
    final int seed = dailyChallenge ? dailySeed(now) :
        (DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF);
    gameKey++;
    game = OrbitHopGame(
      seed: seed,
      runNumber: save.totalRuns + 1,
      isDailyChallenge: dailyChallenge,
      tutorialEnabled: !save.tutorialComplete,
      languageCode: save.languageCode,
      skin: save.equippedSkin,
      trail: save.equippedTrail,
      theme: save.equippedTheme,
      upgradeLevels: Map<String, int>.of(save.upgradeLevels),
      reducedMotion: save.reducedMotion,
      onRunStarted: _onRunStarted,
      onRunEnded: (RunResult result) => unawaited(_onRunEnded(result)),
      onTutorialCompleted: _onTutorialCompleted,
      onLanding: _onLanding,
      onLaunch: _onLaunch,
      onCoinCollected: _onPickupCollected,
      onFeverStarted: _onFeverStarted,
      onShieldSaved: _onShieldSaved,
      onDeath: _onDeath,
      onZoneChanged: _onZoneChanged,
    );
    currentPage = 'game';
    lastRunResult = null;
    notifyListeners();
  }

  void _onRunStarted(int runNumber, bool daily) {
    save.totalRuns++;
    save.runsThisSession++;
    DailyMissionRules.ensureToday(save, DateTime.now().toUtc());
    DailyMissionRules.addProgress(save, 'runs', 1);
    if (daily) {
      save.dailyChallengeRuns++;
      save.lastDailyChallengeDate = DailyRewardRules.dateKey(DateTime.now().toUtc());
      DailyMissionRules.addProgress(save, 'daily', 1);
      unawaited(analytics.log('daily_challenge_played', <String, Object>{'date_seed': dailySeed(DateTime.now().toUtc())}));
    }
    _evaluateAchievements();
    unawaited(analytics.runStarted(daily: daily, runNumber: runNumber));
    lastRunResult = null;
    starterOfferAvailable = false;
    unawaited(_persist());
    notifyListeners();
  }

  void _onLanding(bool perfect, int combo) {
    if (save.hapticsEnabled) unawaited(HapticFeedback.mediumImpact());
    unawaited(audio.playLanding(perfect: perfect, combo: combo));
  }

  void _onLaunch() {
    unawaited(audio.playLaunch());
    if (save.hapticsEnabled) unawaited(HapticFeedback.selectionClick());
  }

  void _onPickupCollected(PickupKind kind) {
    if (kind == PickupKind.coin) {
      unawaited(audio.playCoin());
      if (save.hapticsEnabled) unawaited(HapticFeedback.selectionClick());
    } else {
      DailyMissionRules.ensureToday(save, DateTime.now().toUtc());
      DailyMissionRules.addProgress(save, 'gems', 1);
      unawaited(_persist());
      if (save.hapticsEnabled) unawaited(HapticFeedback.lightImpact());
    }
  }

  void _onFeverStarted() {
    DailyMissionRules.ensureToday(save, DateTime.now().toUtc());
    DailyMissionRules.addProgress(save, 'fevers', 1);
    unawaited(_persist());
    unawaited(analytics.log('fever_start', <String, Object>{'score': game?.score ?? 0}));
    unawaited(audio.setFeverLayer(true));
    if (save.hapticsEnabled) unawaited(HapticFeedback.heavyImpact());
  }

  void _onShieldSaved() {
    if (save.hapticsEnabled) unawaited(HapticFeedback.mediumImpact());
    showMessage(_strings.text('shield_message'));
  }

  void _onDeath() {
    unawaited(audio.playDeath());
    if (save.hapticsEnabled) unawaited(HapticFeedback.heavyImpact());
  }

  void _onZoneChanged(int zone, bool fever) {
    if (fever) {
      unawaited(audio.setFeverLayer(true));
    } else {
      unawaited(audio.startMusic(zone, fever: false));
    }
  }

  void _onTutorialCompleted() {
    if (save.tutorialComplete) return;
    save.tutorialComplete = true;
    unawaited(analytics.log('tutorial_complete'));
    unawaited(_persist());
  }

  Future<void> _onRunEnded(RunResult result) async {
    if (!_finishedRuns.add(result.runNumber)) return;
    final DateTime now = DateTime.now().toUtc();
    final bool qualifiedDaily = result.isDailyChallenge &&
        result.duration.inSeconds >= GameConfig.dailyChallengeMinimumRunSeconds;
    final int bonusCoins = qualifiedDaily ? GameConfig.dailyChallengeBonusCoins : 0;
    final int bonusGems = qualifiedDaily ? GameConfig.dailyChallengeBonusGems : 0;
    final int coinTotal = result.coins + bonusCoins;
    final int gemTotal = result.gems + bonusGems;
    EconomyRules.grantRunRewards(
      save: save,
      coins: coinTotal,
      gems: gemTotal,
      score: result.score,
      perfects: result.perfects,
      maxCombo: result.maxCombo,
      dailyChallenge: qualifiedDaily,
    );
    save.lifetimeCoinsEarned += coinTotal;
    save.lifetimeGemsEarned += gemTotal;
    DailyMissionRules.ensureToday(save, now);
    DailyMissionRules.addProgress(save, 'planets', result.score);
    DailyMissionRules.addProgress(save, 'perfects', result.perfects);
    DailyMissionRules.addProgress(save, 'coins', coinTotal);
    DailyMissionRules.addProgress(save, 'combo', result.maxCombo);
    DailyMissionRules.addProgress(save, 'bestRun', result.score);
    final List<AchievementDefinition> unlocked = _evaluateAchievements();
    lastRunResult = result;
    if (save.totalRuns >= 5 && !save.starterOfferSeen) {
      starterOfferAvailable = true;
      save.starterOfferSeen = true;
    }
    await analytics.runEnded(
      score: result.score,
      duration: result.duration,
      cause: result.cause.name,
      daily: result.isDailyChallenge,
    );
    if (result.score >= save.bestScore && playGames.signedIn) {
      unawaited(playGames.submitScore(score: result.score, daily: false));
    }
    if (qualifiedDaily && playGames.signedIn) {
      unawaited(playGames.submitScore(score: result.score, daily: true));
    }
    if (unlocked.isNotEmpty) {
      final String first = _strings.achievementTitle(unlocked.first.id, unlocked.first.title);
      showMessage(_strings.text('achievement_unlocked', <String, Object>{'value': first}));
    }
    await _persist();
    notifyListeners();
  }

  List<AchievementDefinition> _evaluateAchievements() => AchievementRules.evaluate(save);

  void pauseGame() {
    final OrbitHopGame? current = game;
    if (current != null && current.phase != RunPhase.gameOver && current.phase != RunPhase.paused) {
      current.pauseRun();
    }
    unawaited(audio.pause());
  }

  void resumeGame() {
    final OrbitHopGame? current = game;
    if (current == null || current.phase != RunPhase.paused) return;
    current.resumeRun();
    unawaited(audio.resume());
  }

  void finishRun() {
    final OrbitHopGame? current = game;
    if (current == null) return;
    if (current.phase != RunPhase.gameOver) {
      current.finalizeRun(cause: DeathCause.quit);
    } else {
      current.finalizeRun();
    }
  }

  void leaveGame() {
    finishRun();
    unawaited(audio.pause());
    currentPage = 'home';
    notifyListeners();
  }

  void restartClassicRun() {
    final OrbitHopGame? current = game;
    if (current == null || current.phase != RunPhase.gameOver) {
      startGame(dailyChallenge: false);
      return;
    }
    if (current.isDaily) {
      showMessage(_strings.text('daily_finished'));
      leaveGame();
      return;
    }
    current.restart();
    notifyListeners();
  }

  bool reviveWithRewardedAd() {
    final OrbitHopGame? current = game;
    if (current == null || !current.hud.value.reviveAvailable) return false;
    return ads.showRewarded(onEarned: () {
      if (!current.revive()) return;
      unawaited(audio.playLaunch());
      showMessage(_strings.text('revive_success'));
      notifyListeners();
    });
  }

  bool doubleCoinsWithRewardedAd() {
    final RunResult? result = lastRunResult;
    if (result == null || _doubleRewardLoading || save.lastDoubleCoinsRunNumber == result.runNumber) {
      return false;
    }
    _doubleRewardLoading = true;
    final bool shown = ads.showRewarded(onEarned: () {
      _doubleRewardLoading = false;
      if (save.lastDoubleCoinsRunNumber == result.runNumber) return;
      save.lastDoubleCoinsRunNumber = result.runNumber;
      final int dailyBonus = result.isDailyChallenge &&
              result.duration.inSeconds >= GameConfig.dailyChallengeMinimumRunSeconds
          ? GameConfig.dailyChallengeBonusCoins
          : 0;
      final int doubledCoins = result.coins + dailyBonus;
      save.coins += doubledCoins;
      save.lifetimeCoinsEarned += doubledCoins;
      _evaluateAchievements();
      unawaited(_persist());
      showMessage(_strings.text('coins_doubled'));
      notifyListeners();
    }, onFinished: () {
      _doubleRewardLoading = false;
      notifyListeners();
    });
    if (!shown) _doubleRewardLoading = false;
    return shown;
  }

  bool claimFreeChestWithRewardedAd() {
    final String today = DailyRewardRules.dateKey(DateTime.now().toUtc());
    if (save.lastDailyChestDate == today || _chestRewardLoading) return false;
    _chestRewardLoading = true;
    final bool shown = ads.showRewarded(onEarned: () {
      if (save.lastDailyChestDate == today) return;
      save.lastDailyChestDate = today;
      save.coins += GameConfig.dailyChestCoins;
      save.lifetimeCoinsEarned += GameConfig.dailyChestCoins;
      _evaluateAchievements();
      unawaited(_persist());
      showMessage(_strings.text('chest_opened', <String, Object>{'value': GameConfig.dailyChestCoins}));
      notifyListeners();
    }, onFinished: () {
      _chestRewardLoading = false;
      notifyListeners();
    });
    if (!shown) _chestRewardLoading = false;
    return shown;
  }

  bool showInterstitialAfterGameOver({VoidCallback? onFinished}) => ads.showInterstitialIfAllowed(
        save: save,
        now: DateTime.now().toUtc(),
        onShown: () => unawaited(_persist()),
        onFinished: () {
          if (!_disposed) onFinished?.call();
        },
      );

  DailyRewardResult claimDailyReward() {
    final DailyRewardResult result = DailyRewardRules.claim(save, DateTime.now().toUtc());
    if (result.claimed) {
      save.lifetimeCoinsEarned += result.coins;
      save.lifetimeGemsEarned += result.gems;
      _evaluateAchievements();
      unawaited(_persist());
      notifyListeners();
    }
    return result;
  }

  bool get dailyRewardAvailable =>
      save.lastDailyRewardDate != DailyRewardRules.dateKey(DateTime.now().toUtc());

  bool get dailyChallengeAvailable =>
      save.lastDailyChallengeDate != DailyRewardRules.dateKey(DateTime.now().toUtc());

  bool get freeChestAvailable =>
      save.lastDailyChestDate != DailyRewardRules.dateKey(DateTime.now().toUtc());

  EconomyResult purchaseUpgrade(UpgradeType type) {
    final EconomyResult result = EconomyRules.buyUpgrade(save, type);
    if (result == EconomyResult.success) {
      unawaited(_persist());
      notifyListeners();
    }
    return result;
  }

  EconomyResult unlockSkin(String id) {
    final SkinDefinition? item = _findSkin(id);
    if (item == null) return EconomyResult.unknownItem;
    if (save.ownedSkins.contains(id)) return EconomyResult.alreadyOwned;
    if (!AchievementRules.isUnlocked(save, item.achievementId)) return EconomyResult.unknownItem;
    final EconomyResult result = EconomyRules.buyCosmetic(
      save: save,
      itemId: item.id,
      coinCost: item.coinCost,
      gemCost: item.gemCost,
      ownedList: save.ownedSkins,
    );
    if (result == EconomyResult.success) {
      unawaited(analytics.log('skin_unlocked', <String, Object>{'skin_id': id}));
      _evaluateAchievements();
      unawaited(_persist());
      notifyListeners();
    }
    return result;
  }

  EconomyResult unlockTrail(String id) {
    final TrailDefinition? item = _findTrail(id);
    if (item == null) return EconomyResult.unknownItem;
    if (save.ownedTrails.contains(id)) return EconomyResult.alreadyOwned;
    if (!AchievementRules.isUnlocked(save, item.achievementId)) return EconomyResult.unknownItem;
    final EconomyResult result = EconomyRules.buyCosmetic(
      save: save,
      itemId: item.id,
      coinCost: item.coinCost,
      gemCost: 0,
      ownedList: save.ownedTrails,
    );
    if (result == EconomyResult.success) {
      unawaited(_persist());
      notifyListeners();
    }
    return result;
  }

  EconomyResult unlockTheme(String id) {
    final ThemeDefinition? item = _findTheme(id);
    if (item == null) return EconomyResult.unknownItem;
    if (save.ownedThemes.contains(id)) return EconomyResult.alreadyOwned;
    if (!AchievementRules.isUnlocked(save, item.achievementId)) return EconomyResult.unknownItem;
    final EconomyResult result = EconomyRules.buyCosmetic(
      save: save,
      itemId: item.id,
      coinCost: item.coinCost,
      gemCost: 0,
      ownedList: save.ownedThemes,
    );
    if (result == EconomyResult.success) {
      unawaited(_persist());
      notifyListeners();
    }
    return result;
  }

  SkinDefinition? _findSkin(String id) {
    for (final SkinDefinition item in CosmeticCatalog.skins) {
      if (item.id == id) return item;
    }
    return null;
  }

  TrailDefinition? _findTrail(String id) {
    for (final TrailDefinition item in CosmeticCatalog.trails) {
      if (item.id == id) return item;
    }
    return null;
  }

  ThemeDefinition? _findTheme(String id) {
    for (final ThemeDefinition item in CosmeticCatalog.themes) {
      if (item.id == id) return item;
    }
    return null;
  }

  void equipSkin(String id) {
    if (!save.ownedSkins.contains(id)) return;
    save.equippedSkin = id;
    _persistAndNotify();
  }

  void equipTrail(String id) {
    if (!save.ownedTrails.contains(id)) return;
    save.equippedTrail = id;
    _persistAndNotify();
  }

  void equipTheme(String id) {
    if (!save.ownedThemes.contains(id)) return;
    save.equippedTheme = id;
    _persistAndNotify();
  }

  bool claimMission(String id) {
    final bool claimed = DailyMissionRules.claim(save, id);
    if (claimed) {
      save.lifetimeCoinsEarned += GameConfig.missionRewardCoins;
      _evaluateAchievements();
      _persistAndNotify();
    }
    return claimed;
  }

  Future<void> setSoundEnabled(bool value) async {
    save.soundEnabled = value;
    await audio.setPreferences(sound: save.soundEnabled, music: save.musicEnabled);
    await _persist();
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    save.musicEnabled = value;
    await audio.setPreferences(sound: save.soundEnabled, music: save.musicEnabled);
    await _persist();
    notifyListeners();
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    save.analyticsEnabled = value;
    analytics.setEnabled(value);
    await crashReporting.setEnabled(value);
    await _persist();
    notifyListeners();
  }

  void setHapticsEnabled(bool value) {
    save.hapticsEnabled = value;
    _persistAndNotify();
  }

  void setReducedMotion(bool value) {
    save.reducedMotion = value;
    _persistAndNotify();
  }

  void setLanguage(String value) {
    if (!<String>['en', 'hi', 'es', 'pt', 'id'].contains(value)) return;
    save.languageCode = value;
    _persistAndNotify();
  }

  Future<void> openPrivacyOptions() => ads.showPrivacyOptions();

  Future<void> restorePurchases() => purchases.restorePurchases();

  Future<void> buyProduct(String productId) async {
    if (productId == GameConfig.productStarterBundle && !save.starterBundleOwned && save.totalRuns < 5) {
      showMessage(_strings.text('starter_after_run5'));
      return;
    }
    await purchases.buy(productId);
  }

  Future<void> _applyVerifiedPurchase(VerifiedPurchase purchase) async {
    if (save.processedPurchaseGrantIds.contains(purchase.grantId)) return;
    if (purchase.removeAds || purchase.productId == GameConfig.productRemoveAds) {
      save.removeAdsOwned = true;
    }
    if (purchase.starterBundle || purchase.productId == GameConfig.productStarterBundle) {
      save.starterBundleOwned = true;
      if (!save.ownedSkins.contains('mango')) {
        save.ownedSkins.add('mango');
      }
    }
    if (purchase.isNewGrant &&
        (purchase.productId == GameConfig.productGems ||
            purchase.productId == GameConfig.productStarterBundle)) {
      // Paid currency is cosmetics-only: never grant gameplay coins from IAP.
      save.gems = math.min(2000000000, save.gems + purchase.gems).toInt();
    }
    save.processedPurchaseGrantIds.add(purchase.grantId);
    _evaluateAchievements();
    await _persist();
    notifyListeners();
  }

  Future<bool> signInToPlayGames() async {
    final bool signedIn = await playGames.signIn();
    if (!signedIn) showMessage(_strings.text('play_games_unavailable'));
    notifyListeners();
    return signedIn;
  }

  Future<void> showLeaderboard({bool daily = false}) async {
    if (!playGames.signedIn) {
      showMessage(_strings.text('play_games_signin'));
      return;
    }
    final bool shown = await playGames.showLeaderboard(daily: daily);
    if (!shown) showMessage(_strings.text('leaderboard_unconfigured'));
  }

  Future<bool> shareLastScore() async {
    final RunResult? result = lastRunResult;
    if (result == null) return false;
    final bool shared = await shareCards.shareScore(score: result.score, skinId: save.equippedSkin, languageCode: save.languageCode);
    if (!shared) showMessage(_strings.text('share_unavailable'));
    return shared;
  }

  Future<bool> showPrivacyPolicyInfo() async {
    showMessage(_strings.text('privacy_details'));
    return true;
  }

  void _notifyPurchaseState() {
    if (!_disposed) notifyListeners();
  }

  void showMessage(String text) {
    message = text;
    notifyListeners();
  }

  void clearMessage() {
    message = '';
    notifyListeners();
  }

  void _persistAndNotify() {
    unawaited(_persist());
    notifyListeners();
  }

  Future<void> _persist() {
    _saveQueue = _saveQueue.then((_) => _repository.save(save)).catchError((Object _) {});
    return _saveQueue;
  }

  void navigateTo(String page) {
    if (page == 'home' && currentPage == 'game') {
      leaveGame();
      return;
    }
    currentPage = page;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_persist());
    ads.dispose();
    unawaited(purchases.dispose());
    unawaited(audio.dispose());
    super.dispose();
  }
}
