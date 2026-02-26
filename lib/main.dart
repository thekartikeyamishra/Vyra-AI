import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- CONFIGURATION ---
import 'firebase_options.dart';
import 'config/env_config.dart';

// --- THEME ---
import 'core/theme/app_theme.dart';

// --- FEATURES & SCREENS ---
import 'features/auth/auth_controller.dart'; // Added for Auto-Login Action
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/home/screens/main_wrapper.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/providers/auth_state_provider.dart';

// --- NEW ROUTES (Referral, Developer, Legal) ---
import 'features/referral/screens/referral_screen.dart';
import 'features/developer/secret_screen.dart';
import 'features/legal/legal_screen.dart';

// --- GLOBAL PROVIDERS ---
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('seen_onboarding') ?? false;
});

void main() async {
  // 1. Ensure Flutter Engine is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load Fail-safe Environment Configuration
  try {
    await EnvConfig.load();
  } catch (e) {
    debugPrint("⚠️ Warning: Could not load .env file: $e");
  }

  // 3. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("❌ CRITICAL: Firebase Initialization Failed: $e");
  }

  // 4. Initialize Mobile Ads SDK
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("⚠️ Warning: AdMob Initialization Failed: $e");
  }

  // 5. Run App
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vyra',
      debugShowCheckedModeBanner: false,

      // Theme (Deep Purple & Gold - Psychology of Trust & Value)
      theme: AppTheme.lightTheme,

      // --- UPDATED ROUTES ---
      // Registered for Deep Linking & Easy Navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const MainWrapper(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/referral': (context) => const ReferralScreen(),
        '/secret': (context) => const SecretScreen(),
        '/legal': (context) => const LegalScreen(),
      },

      // Root Logic
      home: const AuthWrapper(),
    );
  }
}

// --- REACTIVE NAVIGATION WRAPPER (ZERO FRICTION) ---
// Decides between Onboarding, Home, or Auto-Login
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingSeenProvider);
    final authState = ref.watch(authStateProvider);
    
    // We watch the controller to handle Loading/Error states of the Auto-Login action
    final authControllerState = ref.watch(authControllerProvider);

    return onboardingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Startup Error: $e'))),
      data: (seenOnboarding) {
        // 1. Onboarding Check
        if (!seenOnboarding) {
          return const OnboardingScreen();
        }

        // 2. Auth Check
        return authState.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          // If the auth stream itself fails, show Login Screen as fallback
          error: (e, st) => const LoginScreen(),
          data: (user) {
            // A. USER LOGGED IN -> GO TO HOME
            if (user != null) {
              return const MainWrapper();
            }

            // B. USER NOT LOGGED IN -> START AUTO-LOGIN
            
            // If Auto-Login failed (e.g. Network Error), show Manual Login Screen
            if (authControllerState.hasError) {
              return const LoginScreen();
            }

            // If we are not currently loading, trigger the Anonymous Sign-In
            if (!authControllerState.isLoading) {
              // Trigger in microtask to avoid build-phase side effects
              Future.microtask(() {
                ref.read(authControllerProvider.notifier).signInAnonymously();
              });
            }

            // C. SHOW "SETTING UP" LOADER (While Auto-Login runs)
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Setting up your studio...",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}