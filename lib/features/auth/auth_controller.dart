import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/env_config.dart';

// 1. Provider Definition
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

// 2. Controller Class
class AuthController extends AsyncNotifier<void> {
  
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  FutureOr<void> build() {
    return null;
  }

  // --- 1. SIGN UP (Robust: Auth First -> DB Validation) ---
  /// Registers a new user. Creates Auth credentials first to satisfy security rules,
  /// then validates username uniqueness. Rolls back if validation fails.
  Future<void> signUp({
    required String email, 
    required String password, 
    required String username
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // A. Create Authentication User (Get ID Token)
      // We do this FIRST so the user is authenticated to read the 'users' collection.
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception("This email is already registered. Please Login.");
        }
        rethrow;
      }

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed.");

      // B. Validate Username & Initialize DB
      try {
        // Check Uniqueness
        final usernameQuery = await _db.collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        
        if (usernameQuery.docs.isNotEmpty) {
          // ROLLBACK: Delete the auth user if username is taken
          await user.delete(); 
          throw Exception("Username '$username' is already taken. Please try another.");
        }

        // Success: Create Profile
        await _ensureUserDocumentExists(user, username: username);

      } catch (e) {
        // Cleanup: If DB write fails (and we haven't already deleted the user), 
        // try to delete the Auth user to keep state clean.
        if (userCredential.user != null) {
           try { await user.delete(); } catch (_) {} 
        }
        rethrow;
      }
    });
  }

  // --- 2. LOGIN (Self-Healing) ---
  /// Signs in and ensures the Firestore document exists.
  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Self-Healing: Use set(merge: true) to create the doc if it's missing
      // This prevents the app from crashing if a user exists in Auth but not Firestore.
      if (_auth.currentUser != null) {
         await _db.collection('users').doc(_auth.currentUser!.uid).set({
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  // --- 3. FORGOT PASSWORD ---
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.sendPasswordResetEmail(email: email);
    });
  }

  // --- 4. ANONYMOUS AUTH ---
  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        if (EnvConfig.debugMode) {
          print("DEBUG: User signed in anonymously: ${user.uid}");
        }
        await _ensureUserDocumentExists(user);
      }
    });
  }

  // --- 5. SIGN OUT ---
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signOut();
    });
  }

  // --- DATABASE INITIALIZATION HELPER ---
  Future<void> _ensureUserDocumentExists(User user, {String? username}) async {
    final userRef = _db.collection('users').doc(user.uid);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        // --- NEW USER SETUP ---
        final referralCode = _generateReferralCode();

        final newUserData = {
          // Identity
          'uid': user.uid,
          'email': user.email,
          'displayName': username ?? "Anonymous Creator", 
          'username': username, 
          'photoUrl': null,
          
          // Metadata
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'platform': 'mobile',
          
          // Economy (THE HOOK)
          // 6 Credits = 3 Standard Generations (2 credits each).
          // This allows users to test the app 3 times before hitting a paywall/adwall.
          'dailyGenerationCount': 6, 
          
          'xp': 0,
          'isPremium': false,

          // Growth & Viral Loop
          'referralCode': referralCode,
          'referredBy': null,         
          
          // Gamification
          'streakCount': 0,
          'isFollowingDev': false,    
        };

        transaction.set(userRef, newUserData);
        if (EnvConfig.debugMode) print("DEBUG: New user profile created with 6 credits.");
      } else {
        // Just update login time
        transaction.update(userRef, {
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}