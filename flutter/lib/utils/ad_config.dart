import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages fetching ad unit IDs from Firebase and caching them locally.
///
/// Firebase Realtime Database structure (under "ads" node):
/// {
///   "ads": {
///     "rewarded_id":     "ca-app-pub-XXXX/YYYY",
///     "interstitial_id": "ca-app-pub-XXXX/ZZZZ"
///   }
/// }
class AdConfig {
  static AdConfig? _instance;
  static AdConfig get instance => _instance ??= AdConfig._();
  AdConfig._();

  // SharedPreferences keys
  static const String _keyRewardedId     = 'ad_rewarded_id';
  static const String _keyInterstitialId = 'ad_interstitial_id';

  // Fallback test IDs (used only if Firebase fetch fails AND no local cache)
  static const String _fallbackRewardedId     = 'ca-app-pub-3940256099942544/5224354917';
  static const String _fallbackInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  String _rewardedId     = _fallbackRewardedId;
  String _interstitialId = _fallbackInterstitialId;

  String get rewardedId     => _rewardedId;
  String get interstitialId => _interstitialId;

  /// Call this from the splash screen.
  Future<void> loadAndSync() async {
    final prefs = await SharedPreferences.getInstance();

    // Step 1 — Load from local cache first
    _rewardedId     = prefs.getString(_keyRewardedId)     ?? _fallbackRewardedId;
    _interstitialId = prefs.getString(_keyInterstitialId) ?? _fallbackInterstitialId;

    print('════════════════════════════════════════');
    print('📦 AdConfig — CACHE');
    print('   Rewarded ID     : $_rewardedId');
    print('   Interstitial ID : $_interstitialId');
    print('════════════════════════════════════════');

    // Step 2 — Try fetching from Firebase
    print('🔥 AdConfig — Fetching from Firebase...');
    try {
      final snapshot = await FirebaseDatabase.instance.ref('ads').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final fetchedRewarded     = data['rewarded_id']     as String?;
        final fetchedInterstitial = data['interstitial_id'] as String?;

        print('════════════════════════════════════════');
        print('✅ AdConfig — FIREBASE RESPONSE');
        print('   rewarded_id     : $fetchedRewarded');
        print('   interstitial_id : $fetchedInterstitial');
        print('════════════════════════════════════════');

        bool changed = false;

        // Step 3 — Compare and update cache only if changed
        if (fetchedRewarded != null && fetchedRewarded != _rewardedId) {
          _rewardedId = fetchedRewarded;
          await prefs.setString(_keyRewardedId, _rewardedId);
          changed = true;
          print('🔄 AdConfig: Rewarded ID CHANGED → $_rewardedId');
        }

        if (fetchedInterstitial != null && fetchedInterstitial != _interstitialId) {
          _interstitialId = fetchedInterstitial;
          await prefs.setString(_keyInterstitialId, _interstitialId);
          changed = true;
          print('🔄 AdConfig: Interstitial ID CHANGED → $_interstitialId');
        }

        if (!changed) {
          print('✅ AdConfig: IDs unchanged — cache is up to date');
        }

        print('════════════════════════════════════════');
        print('🎯 AdConfig — FINAL IDs IN USE');
        print('   Rewarded ID     : $_rewardedId');
        print('   Interstitial ID : $_interstitialId');
        print('════════════════════════════════════════');

      } else {
        print('⚠️  AdConfig: "ads" node NOT found in Firebase!');
        print('   Make sure you added the node as instructed.');
        print('   Using cached/fallback IDs instead.');
      }
    } catch (e) {
      print('❌ AdConfig: Firebase fetch FAILED!');
      print('   Error: $e');
      print('   Using cached/fallback IDs instead.');
    }
  }
}
