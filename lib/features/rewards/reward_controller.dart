import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ad_service.dart';
import '../auth/providers/auth_state_provider.dart';

// 1. Provider Definition
// We use AsyncNotifierProvider for robust, modern state management (Riverpod 2.0)
final rewardControllerProvider = AsyncNotifierProvider<RewardController, void>(RewardController.new);

// 2. Controller Class
class RewardController extends AsyncNotifier<void> {
  
  @override
  FutureOr<void> build() {
    // Automatically attempt to load an ad when this controller is initialized.
    // This ensures an ad is likely ready by the time the user clicks the button.
    ref.read(adServiceProvider).loadRewardAd();
    return null; // Initial state is idle (null)
  }

  /// **Main Action: Show Ad -> Grant Reward**
  /// This is called when the user clicks "Watch Ad for +5 XP & Credit"
  Future<void> showAdToEarnCredit() async {
    // 1. Get the Ad Service instance
    final adService = ref.read(adServiceProvider);

    // 2. Set state to loading (prevents double tapping in UI)
    state = const AsyncValue.loading();

    // 3. Show Ad with Callbacks
    adService.showRewardAd(
      onReward: () async {
        // User finished watching -> Grant Credit logic
        await _grantCredit();
      },
      onError: (message) {
        // If ad fails to show, return the error to the UI state
        // This will trigger the SnackBar in the UI
        state = AsyncValue.error(message, StackTrace.current);
      },
    );
  }

  /// **Internal: Securely update Firestore**
  /// Grants +1 Credit and +5 XP via Atomic Transaction.
  Future<void> _grantCredit() async {
    // We wrap the logic in AsyncValue.guard to handle try/catch automatically
    state = await AsyncValue.guard(() async {
      
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) throw Exception("User not logged in");

      final userRef = FirebaseFirestore.instance
          .collection('users') 
          .doc(uid);

      // **Using a Transaction ensures data integrity**
      // This prevents race conditions if the user somehow triggers this twice instantly.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        if (!snapshot.exists) {
          throw Exception("User record does not exist!");
        }

        // Logic: 
        // 1. 'dailyGenerationCount' is the User's Credit Balance.
        // 2. We INCREMENT it by 1. 
        //    (Since cost is 2 credits/image, watching 2 ads earns 1 generation).
        
        transaction.update(userRef, {
          'dailyGenerationCount': FieldValue.increment(1), 
          'xp': FieldValue.increment(5), // Bonus XP for watching ads (Gamification)
        });
      });
      
      // Reload ad for next time immediately after rewarding
      ref.read(adServiceProvider).loadRewardAd();
    });
  }
}