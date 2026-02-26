import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart'; // Ensure share_plus is in pubspec.yaml

// Logic & Data
import '../referral_controller.dart';
import '../../home/services/database_service.dart';
import '../../../core/theme/app_theme.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _shareCode(String code) {
    // Viral Hook Message
    Share.share(
      "Use my secret code '$code' on Vyra to unlock 5 FREE AI credits instantly! 🚀\n\nDownload now: https://yourapplink.com",
    );
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Code copied to clipboard!"), backgroundColor: Colors.green),
    );
  }

  void _redeemCode() {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Trigger Controller
    ref.read(referralControllerProvider.notifier).redeemCode(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    // Watch User Data for "Your Code" display
    final userAsync = ref.watch(userProfileStreamProvider);

    // Listen for Redemption Success/Error
    ref.listen<AsyncValue<void>>(referralControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString().replaceAll("Exception: ", "")), backgroundColor: AppTheme.errorColor),
        );
      } else if (!next.isLoading && next.hasValue) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Success! Rewards added to your account."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isRedeeming = ref.watch(referralControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Deep Purple Background for "Premium" feel
      appBar: AppBar(
        title: const Text("Viral Growth"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
        data: (user) {
          final myCode = user.referralCode ?? "---";

          return Column(
            children: [
              // --- 1. HERO SECTION (The Hook) ---
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, size: 64, color: AppTheme.rewardColor),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Invite Friends.\nUnlock Pro Together.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "They get 5 Credits. You get 10 Credits + 100 XP.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. ACTION CARD (White Sheet) ---
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A. YOUR CODE
                        const Text("YOUR SECRET CODE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _copyToClipboard(myCode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  myCode,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                                const Icon(Icons.copy, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text("Share Code"),
                            onPressed: () => _shareCode(myCode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87, // Strong contrast
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // B. ENTER FRIEND'S CODE
                        const Text("HAVE A FRIEND'S CODE?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        
                        if (user.referredBy != null)
                           Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                             child: Row(
                               children: const [
                                 Icon(Icons.check_circle, color: Colors.green),
                                 SizedBox(width: 12),
                                 Text("You've already claimed your bonus!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                               ],
                             ),
                           )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter code...",
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9]")),
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 56, // Match TextField height
                                child: ElevatedButton(
                                  onPressed: isRedeeming ? null : _redeemCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isRedeeming 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text("Redeem"),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}