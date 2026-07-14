import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'ad_config.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  // IDs are now fetched dynamically from AdConfig (Firebase + local cache)
  // No hardcoded IDs here anymore.

  // ── Rewarded Ad ───────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool get isReady => _rewardedAd != null;

  // ── Interstitial Ad ───────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  bool get isInterstitialReady => _interstitialAd != null;

  /// Initialize the Mobile Ads SDK — call once in main()
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Load a rewarded ad. Call this after AdConfig.loadAndSync() completes.
  void loadRewardedAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    final adUnitId = AdConfig.instance.rewardedId;
    debugPrint('📺 Loading rewarded ad with ID: $adUnitId');

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded ad loaded');
          _rewardedAd = ad;
          _isLoading = false;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd(); // preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded ad failed to load: $error');
          _isLoading = false;
          Future.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  /// Show the rewarded ad.
  /// [onRewarded] is called with the reward amount when the user earns it.
  /// [onFailed] is called if the ad is not ready.
  void showRewardedAd({
    required void Function(int amount) onRewarded,
    required void Function() onFailed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready yet');
      onFailed();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        debugPrint('🎁 User earned reward: ${reward.amount} ${reward.type}');
        onRewarded(50);
      },
    );
  }

  // ── Interstitial Ad methods ───────────────────────────────────────────────

  /// Load an interstitial ad. Call this after AdConfig.loadAndSync() completes.
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    final adUnitId = AdConfig.instance.interstitialId;
    debugPrint('📺 Loading interstitial ad with ID: $adUnitId');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialLoading = false;

          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _isInterstitialLoading = false;
          Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }

  /// Show the interstitial ad.
  /// [onDone] is always called after ad is dismissed or if ad is not ready.
  void showInterstitialAd({required void Function() onDone}) {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Interstitial ad not ready, skipping');
      onDone();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Interstitial failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDone();
      },
    );

    _interstitialAd!.show();
  }
}
