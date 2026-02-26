import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 
/// 1. Auth State Provider (Stream)
/// This provider listens to the Firebase Authentication stream.
/// It yields a [User] object if logged in, or [null] if logged out.
/// Usage: ref.watch(authStateProvider)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 2. Current User ID Provider
/// A convenience provider to quickly access the User ID (UID).
/// It watches the [authStateProvider] above.
/// Usage: ref.watch(currentUserIdProvider) -> Returns String? or null
final currentUserIdProvider = Provider<String?>((ref) {
  // We get the AsyncValue from the authStateProvider
  final authState = ref.watch(authStateProvider);
  
  // We extract the data safely. If loading or error, this returns null.
  return authState.asData?.value?.uid;
});

/// 3. Current User Email Provider
/// A convenience provider to access the User's Email.
/// Usage: ref.watch(currentUserEmailProvider)
final currentUserEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value?.email;
});