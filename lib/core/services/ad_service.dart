import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Global Provider for Dependency Injection
final adServiceProvider = Provider<AdService>((ref) => AdService());

class AdService {
  // --- STATE VARIABLES ---
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isRewardLoading = false;
  bool _isInterstitialLoading = false;

  // --- AD UNIT ID GETTERS (Fail-safe) ---

  // 1. Banner Ad ID
  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['REWARD_BANNER_AD_UNIT_ID_ANDROID'] ??
          'ca-app-pub-3940256099942544/6300978111'; // Fallback: Test ID
    } else if (Platform.isIOS) {
      return dotenv.env['REWARD_BANNER_AD_UNIT_ID_IOS'] ??
          'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError("Unsupported Platform");
  }

  // 2. Interstitial Ad ID (Triggered on Save/Share)
  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['REWARD_INTERSTITIAL_AD_UNIT_ID_ANDROID'] ??
          'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return dotenv.env['REWARD_INTERSTITIAL_AD_UNIT_ID_IOS'] ??
          'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError("Unsupported Platform");
  }

  // 3. Rewarded Ad ID (Triggered for Credits)
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['REWARD_AD_UNIT_ID_ANDROID'] ??
          'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return dotenv.env['REWARD_AD_UNIT_ID_IOS'] ??
          'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError("Unsupported Platform");
  }

  // --- INITIALIZATION ---

  /// Initialize the Mobile Ads SDK and preload ads
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      // Preload ads so they are ready when the user needs them
      _loadInterstitial();
      loadRewardAd();

      if (kDebugMode) {
        print("✅ AdMob Initialized with Production Keys (or Fallbacks)");
      }
    } catch (e) {
      debugPrint("⚠️ AdMob Init Failed: $e");
    }
  }

  // --- 1. BANNER AD LOGIC ---

  /// Creates a Banner Ad Widget.
  /// The UI is responsible for loading it (.load()) and disposing it (.dispose()).
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner failed to load: $error');
          ad.dispose();
        },
        onAdLoaded: (ad) => debugPrint('✅ Banner Loaded'),
      ),
    );
  }

  // --- 2. INTERSTITIAL AD LOGIC (For Transitions) ---

  void _loadInterstitial() {
    if (_isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial Ad Loaded');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Shows the Interstitial Ad.
  /// [onComplete] is called whether the ad shows successfully, fails, or is dismissed.
  /// This ensures the app flow (e.g., Save/Share) never gets "stuck".
  void showInterstitial({required Function onComplete}) {
    if (_interstitialAd == null) {
      debugPrint("⚠️ Interstitial not ready. Proceeding anyway.");
      onComplete(); // Don't block the user
      _loadInterstitial(); // Try loading for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("Interstitial dismissed");
        ad.dispose();
        _loadInterstitial(); // Auto-reload
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("❌ Failed to show Interstitial: $error");
        ad.dispose();
        _loadInterstitial();
        onComplete();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // --- 3. REWARDED AD LOGIC (For Credits) ---

  void loadRewardAd() {
    if (_isRewardLoading) return;
    _isRewardLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded Ad Loaded');
          _rewardedAd = ad;
          _isRewardLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded Ad failed to load: $error');
          _rewardedAd = null;
          _isRewardLoading = false;
        },
      ),
    );
  }

  /// Shows the Reward Ad.
  /// [onReward] is called ONLY if the user finishes the video.
  /// [onError] is called if the ad isn't ready or fails to show.
  void showRewardAd({
    required Function onReward,
    required Function(String) onError,
  }) {
    if (_rewardedAd == null) {
      onError("Ad is loading. Please wait 5 seconds and try again.");
      loadRewardAd(); // Retry load
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardAd(); // Auto-reload for next time
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onError("Ad failed to play: $error");
        loadRewardAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        debugPrint(
          "💰 User earned reward: ${rewardItem.amount} ${rewardItem.type}",
        );
        onReward();
      },
    );

    _rewardedAd = null;
  }
}
