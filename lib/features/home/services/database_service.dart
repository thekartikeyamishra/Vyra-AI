import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../../auth/models/user_model.dart';
import '../../image_generation/image_model.dart';

// --- PROVIDERS ---

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) throw Exception("User not authenticated");
  return DatabaseService(uid: uid);
});

// Fix: Expose this stream correctly for the Home Screen
final itemsStreamProvider = StreamProvider.autoDispose<List<ImageModel>>((ref) {
  return ref.watch(databaseServiceProvider).generationsStream;
});

final userProfileStreamProvider = StreamProvider.autoDispose<UserModel>((ref) {
  return ref.watch(databaseServiceProvider).userStream;
});

// --- SERVICE CLASS ---

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  DatabaseService({required this.uid});

  // 1. User Profile Stream
  Stream<UserModel> get userStream {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      return UserModel.fromFirestore(snapshot);
    });
  }

  // 2. Generations Stream (Replaces old 'items')
  // Queries the secure 'generations' collection
  Stream<List<ImageModel>> get generationsStream {
    return _db.collection('generations')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20) // Optimization: limit load size
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ImageModel.fromFirestore(doc)).toList());
  }

  // 3. Delete Logic
  Future<void> deleteGeneration(String docId) async {
    await _db.collection('generations').doc(docId).delete();
  }

  // 4. Update User Fields (for Rewards/Quests)
  Future<void> updateUserField(String field, dynamic value) async {
    await _db.collection('users').doc(uid).update({field: value});
  }
  
  // Note: 'addItem' is removed as Generations are created via the CreationController now.
}