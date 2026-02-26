import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to auth state changes (User Logged In vs Out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // GET CURRENT USER ID
  String? get currentUserId => _auth.currentUser?.uid;

  // SIGN UP
  Future<String?> signUp({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Create a user document in Firestore immediately
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': result.user!.uid,
      });

      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message; // Return friendly error message
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  // SIGN IN
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}