import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/game_config.dart';
import '../data/save_data.dart';
import '../domain/ad_frequency_rules.dart';
import 'telemetry_service.dart';

/// UMP consent runs before ad initialization. If consent, network, or the SDK is
/// unavailable, the offline game keeps working and ad actions return false.
class AdService {
  AdService(this._analytics);

  final AnalyticsService _analytics;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _consentComplete = false;
  bool _canRequestAds = false;
  bool _mobileAdsInitialized = false;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;
  bool _privacyOptionsRequired = false;
  bool _disposed = false;

  bool get canRequestAds => _canRequestAds;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  bool get rewardedReady => _rewardedAd != null && _canRequestAds;
  bool get interstitialReady => _interstitialAd != null && _canRequestAds;
  bool get isReady => _mobileAdsInitialized && _canRequestAds;

  String get _rewardedUnitId => GameConfig.useTestAds
      ? GameConfig.testRewardedAdUnitId
      : GameConfig.liveRewardedAdUnitId;
  String get _interstitialUnitId => GameConfig.useTestAds
      ? GameConfig.testInterstitialAdUnitId
      : GameConfig.liveInterstitialAdUnitId;

  Future<void> initialize() async {
    if (_disposed) return;
    try {
      await MobileAds.instance.updateRequestConfiguration(
        const RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.t,
          ageRestrictedTreatment: AgeRestrictedTreatment.teen,
        ),
      );
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
              if (error != null) {
                _consentComplete = true;
              } else {
                _consentComplete = true;
              }
              unawaited(_finishConsentFlow());
            });
          } catch (_) {
            _consentComplete = true;
            unawaited(_finishConsentFlow());
          }
        },
        (FormError error) {
          _consentComplete = true;
          unawaited(_finishConsentFlow());
        },
      );
    } catch (_) {
      _consentComplete = true;
      await _finishConsentFlow();
    }
  }

  Future<void> _finishConsentFlow() async {
    if (!_consentComplete || _disposed) return;
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      final PrivacyOptionsRequirementStatus status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired = status == PrivacyOptionsRequirementStatus.required;
      if (!_canRequestAds) return;
      if (!_mobileAdsInitialized) {
        await MobileAds.instance.initialize();
        _mobileAdsInitialized = true;
      }
      _loadRewarded();
      _loadInterstitial();
    } catch (_) {
      _canRequestAds = false;
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error == null) unawaited(_finishConsentFlow());
      });
    } catch (_) {
      // The UMP SDK can report that a form is not required or unavailable.
    }
  }

  bool showRewarded({required void Function() onEarned, void Function()? onFinished}) {
    final RewardedAd? ad = _rewardedAd;
    if (ad == null || !_canRequestAds || _disposed) return false;
    _rewardedAd = null;
    bool rewardEarned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (RewardedAd shown) {
        unawaited(_analytics.log('ad_shown', <String, Object>{'format': 'rewarded'}));
      },
      onAdDismissedFullScreenContent: (RewardedAd dismissed) {
        dismissed.dispose();
        _loadRewarded();
        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd failed, AdError error) {
        failed.dispose();
        _loadRewarded();
        onFinished?.call();
      },
    );
    try {
      ad.show(onUserEarnedReward: (RewardedAd shown, RewardItem reward) {
        if (rewardEarned) return;
        rewardEarned = true;
        unawaited(_analytics.log('ad_rewarded', <String, Object>{'format': 'rewarded'}));
        onEarned();
      });
      return true;
    } catch (_) {
      ad.dispose();
      _loadRewarded();
      onFinished?.call();
      return false;
    }
  }

  bool showInterstitialIfAllowed({
    required SaveData save,
    required DateTime now,
    VoidCallback? onFinished,
    VoidCallback? onShown,
  }) {
    final InterstitialAd? ad = _interstitialAd;
    if (_showingInterstitial || ad == null || !_canRequestAds || _disposed ||
        !AdFrequencyRules.canShowInterstitial(save: save, now: now)) {
      return false;
    }
    _interstitialAd = null;
    _showingInterstitial = true;
    bool recorded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (InterstitialAd shown) {
        if (!recorded) {
          recorded = true;
          AdFrequencyRules.recordInterstitial(save, now);
          onShown?.call();
          unawaited(_analytics.log('ad_shown', <String, Object>{'format': 'interstitial'}));
        }
      },
      onAdDismissedFullScreenContent: (InterstitialAd dismissed) {
        dismissed.dispose();
        _showingInterstitial = false;
        _loadInterstitial();
        onFinished?.call();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd failed, AdError error) {
        failed.dispose();
        _showingInterstitial = false;
        _loadInterstitial();
        onFinished?.call();
      },
    );
    try {
      ad.show();
      return true;
    } catch (_) {
      _showingInterstitial = false;
      ad.dispose();
      _loadInterstitial();
      return false;
    }
  }

  void _loadRewarded() {
    final String unitId = _rewardedUnitId;
    if (!_canRequestAds || _loadingRewarded || _rewardedAd != null || _disposed || unitId.isEmpty) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _loadingRewarded = false;
          if (_disposed) {
            ad.dispose();
          } else {
            _rewardedAd = ad;
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _loadingRewarded = false;
        },
      ),
    );
  }

  void _loadInterstitial() {
    final String unitId = _interstitialUnitId;
    if (!_canRequestAds || _loadingInterstitial || _interstitialAd != null || _disposed || unitId.isEmpty) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _loadingInterstitial = false;
          if (_disposed) {
            ad.dispose();
          } else {
            _interstitialAd = ad;
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _loadingInterstitial = false;
        },
      ),
    );
  }

  void dispose() {
    _disposed = true;
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}
