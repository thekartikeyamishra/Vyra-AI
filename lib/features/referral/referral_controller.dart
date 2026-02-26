import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers/auth_state_provider.dart';

// 1. Provider Definition
final referralControllerProvider = AsyncNotifierProvider<ReferralController, void>(ReferralController.new);

// 2. Controller Class
class ReferralController extends AsyncNotifier<void> {
  
  @override
  FutureOr<void> build() {
    return null; // Initial state is idle
  }

  /// **Redeem a Referral Code**
  /// - Validates code (exists, not self, not already redeemed).
  /// - Awards Credits to the Referrer (The person who invited).
  /// - Awards Bonus Credits/XP to the Referee (The current user).
  Future<void> redeemCode(String code) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final db = FirebaseFirestore.instance;
      final currentUserUid = ref.read(currentUserIdProvider);
      
      if (currentUserUid == null) throw Exception("You must be logged in.");
      
      final cleanCode = code.trim().toUpperCase();

      if (cleanCode.isEmpty) throw Exception("Please enter a code.");

      // --- TRANSACTION (Atomic Update) ---
      await db.runTransaction((transaction) async {
        // 1. Get Current User Data
        final userRef = db.collection('users').doc(currentUserUid);
        final userSnapshot = await transaction.get(userRef);
        
        if (!userSnapshot.exists) throw Exception("User profile not found.");
        
        // Validation: Has user already been referred?
        final currentReferredBy = userSnapshot.data()?['referredBy'];
        if (currentReferredBy != null) {
          throw Exception("You have already redeemed a referral code.");
        }

        // Validation: Self-referral
        final myCode = userSnapshot.data()?['referralCode'];
        if (myCode == cleanCode) {
          throw Exception("You cannot redeem your own code.");
        }

        // 2. Find the Referrer (The person who owns the code)
        final referrerQuery = await db.collection('users')
            .where('referralCode', isEqualTo: cleanCode)
            .limit(1)
            .get();

        if (referrerQuery.docs.isEmpty) {
          throw Exception("Invalid referral code.");
        }

        final referrerSnapshot = referrerQuery.docs.first;
        final referrerRef = referrerSnapshot.reference;

        // 3. EXECUTE REWARDS
        
        // A. Reward the Referrer (Inviter)
        // Give 10 Credits (decrease usage count) + 100 XP
        final referrerUsage = referrerSnapshot.data()['dailyGenerationCount'] ?? 0;
        final newReferrerUsage = referrerUsage > 10 ? referrerUsage - 10 : 0; // Ensure non-negative

        transaction.update(referrerRef, {
          'dailyGenerationCount': newReferrerUsage,
          'xp': FieldValue.increment(100),
        });

        // B. Reward the Referee (Current User)
        // Set 'referredBy' + Give 5 Bonus Credits + 50 XP
        final myUsage = userSnapshot.data()?['dailyGenerationCount'] ?? 0;
        final newMyUsage = myUsage > 5 ? myUsage - 5 : 0;

        transaction.update(userRef, {
          'referredBy': cleanCode, // Mark as referred so they can't do it again
          'dailyGenerationCount': newMyUsage,
          'xp': FieldValue.increment(50),
        });
      });
    });
  }
}