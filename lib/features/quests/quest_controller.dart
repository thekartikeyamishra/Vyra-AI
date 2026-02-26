import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/providers/auth_state_provider.dart';

// 1. Provider Definition
final questControllerProvider = AsyncNotifierProvider<QuestController, void>(
  QuestController.new,
);

// 2. Controller Class
class QuestController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null; // Initial state is idle
  }

  /// **Execute Social Quest**
  /// 1. Launches the external Social Media App/Browser.
  /// 2. "Verifies" the action (Optimistic trust-based verification).
  /// 3. Grants the reward securely in the database.
  Future<void> completeSocialQuest({
    required String url,
    required String platformName, // e.g., 'X' or 'LinkedIn'
  }) async {
    state = const AsyncValue.loading();

    // A. Launch the URL
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);

    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      state = AsyncValue.error(
        "Could not launch $platformName app.",
        StackTrace.current,
      );
      return;
    }

    // B. Grant Reward (Secure Transaction)
    // We execute this immediately after launch. In a stricter app, you might wait for a callback
    // or deep link return, but for growth hacking, "Click = Reward" reduces friction significantly.
    state = await AsyncValue.guard(() async {
      final db = FirebaseFirestore.instance;
      final uid = ref.read(currentUserIdProvider);

      if (uid == null) throw Exception("User not authenticated.");

      final userRef = db.collection('users').doc(uid);

      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception("User profile missing.");

        // Check if already completed (Idempotency)
        // We use the boolean 'isFollowingDev' as the flag for this specific quest group.
        final isAlreadyFollowing = snapshot.data()?['isFollowingDev'] ?? false;

        if (isAlreadyFollowing) {
          // If they already did one social quest, we might not want to error out,
          // just acknowledge the click. But if you want to limit rewards to ONCE total:
          // return; // Or throw Exception("Reward already claimed!");

          // For this specific logic, we only grant the +50 XP ONCE.
          // If they click again, they just go to the link.
          return;
        }

        // C. Update Database
        transaction.update(userRef, {
          'isFollowingDev': true, // Mark quest as done
          'xp': FieldValue.increment(50), // Grant 50 XP Reward
          // You could also add Credits here if you want to be more generous:
          // 'dailyGenerationCount': FieldValue.increment(-1), // Give 1 Free Credit
        });
      });
    });
  }
}
