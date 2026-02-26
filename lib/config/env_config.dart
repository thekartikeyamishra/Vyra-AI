import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const bool debugMode = kDebugMode;

  /// Loads environment variables.
  /// GUARANTEES that dotenv is initialized to prevent app crashes.
  static Future<void> load() async {
    try {
      // 1. Attempt to load the real .env asset
      await dotenv.load(fileName: ".env");

      if (debugMode) {
        print("✅ EnvConfig: Loaded .env successfully.");
      }
    } catch (e) {
      // 2. FAIL-SAFE: If .env is missing (common in CI/CD, fresh clones, or first run),
      // we MUST initialize dotenv with test values/fallbacks.
      debugPrint(
        "⚠️ EnvConfig Error: .env not found. Initializing with Fallbacks to prevent crash.",
      );

      // Initialize with Safe Fallbacks (Test Ad IDs & Empty API Keys)
      await dotenv.load(
        mergeWith: {
          // AdMob Test IDs (Google Standard)
          'ADMOB_APP_ID_ANDROID': 'ca-app-pub-3940256099942544~3347511713',
          'ADMOB_APP_ID_IOS': 'ca-app-pub-3940256099942544~1458002511',
          
          'REWARD_AD_UNIT_ID_ANDROID': 'ca-app-pub-3940256099942544/5224354917',
          'REWARD_AD_UNIT_ID_IOS': 'ca-app-pub-3940256099942544/1712485313',
          
          'REWARD_INTERSTITIAL_AD_UNIT_ID_ANDROID': 'ca-app-pub-3940256099942544/1033173712',
          'REWARD_INTERSTITIAL_AD_UNIT_ID_IOS': 'ca-app-pub-3940256099942544/4411468910',
          
          'REWARD_BANNER_AD_UNIT_ID_ANDROID': 'ca-app-pub-3940256099942544/6300978111',
          'REWARD_BANNER_AD_UNIT_ID_IOS': 'ca-app-pub-3940256099942544/2934735716',
          
          // API Keys (Empty or Placeholders to prevent null errors)
          'IMAGE_GEN_API': '', 
          'OPENAI_API_KEY': '',
        },
      );
    }
  }

  // ===========================================================================
  // 🔐 SAFE GETTERS
  // Access variables via these getters to avoid "Magic String" typos in the app.
  // ===========================================================================

  /// Google / Imagen API Key
  static String get imageGenApi => dotenv.env['IMAGE_GEN_API'] ?? '';

  /// OpenAI API Key (For advanced text processing or fallback generation)
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // --- AdMob Configuration (Android) ---
  static String get admobAppIdAndroid => dotenv.env['ADMOB_APP_ID_ANDROID'] ?? '';
  static String get rewardAdUnitIdAndroid => dotenv.env['REWARD_AD_UNIT_ID_ANDROID'] ?? '';
  static String get interstitialAdUnitIdAndroid => dotenv.env['REWARD_INTERSTITIAL_AD_UNIT_ID_ANDROID'] ?? '';
  static String get bannerAdUnitIdAndroid => dotenv.env['REWARD_BANNER_AD_UNIT_ID_ANDROID'] ?? '';

  // --- AdMob Configuration (iOS) ---
  static String get admobAppIdiOS => dotenv.env['ADMOB_APP_ID_IOS'] ?? '';
  static String get rewardAdUnitIdiOS => dotenv.env['REWARD_AD_UNIT_ID_IOS'] ?? '';
  static String get interstitialAdUnitIdiOS => dotenv.env['REWARD_INTERSTITIAL_AD_UNIT_ID_IOS'] ?? '';
  static String get bannerAdUnitIdiOS => dotenv.env['REWARD_BANNER_AD_UNIT_ID_IOS'] ?? '';
}