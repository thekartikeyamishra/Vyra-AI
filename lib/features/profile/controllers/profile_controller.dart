import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_state_provider.dart';

// 1. Provider Definition
// We use AsyncNotifierProvider for modern, robust state management (Riverpod 2.0)
final profileControllerProvider = AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

// 2. Controller Class
class ProfileController extends AsyncNotifier<void> {
  
  @override
  FutureOr<void> build() {
    // Initial state is idle (null). No data needs to be loaded on startup 
    // for this specific controller (data comes from the stream).
    return null;
  }

  /// **Update Display Name**
  /// - Validates input (checks for empty strings).
  /// - Sets loading state to update UI.
  /// - securely updates the 'displayName' field in Firestore.
  /// - Handles errors automatically via AsyncValue.guard.
  Future<void> updateDisplayName(String newName) async {
    // 1. Set Loading State (UI shows spinner/disabled button)
    state = const AsyncValue.loading();
    
    // 2. Execute Logic safely
    state = await AsyncValue.guard(() async {
      // Input Validation
      if (newName.trim().isEmpty) {
        throw Exception("Display name cannot be empty.");
      }

      if (newName.trim().length < 3) {
        throw Exception("Name must be at least 3 characters long.");
      }

      // Get Current User ID safely
      final uid = ref.read(currentUserIdProvider);
      if (uid == null) {
        throw Exception("User not logged in.");
      }

      // Perform Database Update
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': newName.trim(),
        // Optional: specific metadata like 'lastUpdated'
      });
    });
  }
}