import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- NAVIGATION TARGET ---
// After onboarding, we check auth. Since they are new, they go to Login.
// The AuthWrapper in main.dart will handle the rest on next app restart.
import '../../auth/screens/login_screen.dart';

// --- THEME ---
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- CONTENT STRATEGY (Psychological Hooks) ---
  final List<Map<String, String>> _pages = [
    {
      "title": "Stay Ahead.\nInstantly.",
      "desc": "Get the latest trending viral styles before anyone else. No skills required—just tap and go.",
      "icon": "rocket_launch", 
    },
    {
      "title": "Your AI.\nYour Rules.",
      "desc": "Our AI replenishes automatically. Watch a quick ad to unlock pro-level features for FREE.",
      "icon": "auto_awesome", 
    },
    {
      "title": "Safe &\nSecure.",
      "desc": "We protect your data. By continuing, you agree to help us train smarter AI for you.",
      "icon": "security", 
    },
  ];

  // --- ACTIONS ---
  
  Future<void> _completeOnboarding() async {
    // 1. Save Consent & State Locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true); // App knows user is "acquired"
    await prefs.setBool('consent_given', true);   // LEGAL: User agreed to T&C
    
    // 2. Navigate to Login (Replace stack so they can't go back)
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- A. SLIDESHOW ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(
                  _pages[index]["title"]!,
                  _pages[index]["desc"]!,
                  _pages[index]["icon"]!,
                ),
              ),
            ),
            
            // --- B. CONTROLS ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? AppTheme.primaryColor 
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Main Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1 
                            ? "Get Started (Agree & Continue)" 
                            : "Next",
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Legal Footer (Only on last slide)
                  if (_currentPage == _pages.length - 1)
                     const Padding(
                       padding: EdgeInsets.only(top: 12.0),
                       child: Text(
                         "By tapping Get Started, you agree to our Terms & Privacy Policy.",
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey, fontSize: 10),
                       ),
                     ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER BUILDER ---
  Widget _buildPage(String title, String desc, String iconKey) {
    // Mapping string keys to Icons (Simple & Production Safe)
    IconData icon;
    switch (iconKey) {
      case 'rocket_launch': icon = Icons.rocket_launch; break;
      case 'auto_awesome': icon = Icons.auto_awesome; break;
      case 'security': icon = Icons.security; break;
      default: icon = Icons.star;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual Icon Circle
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 40),
          
          // Headline
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900, // Impactful font weight
              color: Colors.black87,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}