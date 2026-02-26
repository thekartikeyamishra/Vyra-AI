import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/providers/auth_state_provider.dart';

// --- PROVIDER ---
// Global access to the data collector
final dataCollectionServiceProvider = Provider<DataCollectionService>((ref) {
  return DataCollectionService(ref);
});

// --- SERVICE CLASS ---
class DataCollectionService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DataCollectionService(this._ref);

  /// **1. LOG GENERATION EVENT (The Training Dataset)**
  /// Captures the "Prompt-to-Image" pair and user intent.
  /// This is your raw material for fine-tuning future AI models.
  Future<void> logGenerationEvent({
    required String rawPrompt,
    required String style,
    required String mood,
    required String finalPrompt,
    required String aiModelUsed,
    required bool isFaceIntegrated,
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    try {
      final uid = _ref.read(currentUserIdProvider) ?? 'anonymous';
      
      // We store this in a separate 'slm_training_data' collection.
      // This keeps your app logic (generations) separate from your ML data.
      await _db.collection('slm_training_data').add({
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        
        // --- INPUT FEATURES (X) ---
        'raw_concept': rawPrompt,       // What the user typed (Intent)
        'style_tag': style,             // Selected Style
        'mood_tag': mood,               // Selected Mood
        'has_face_reference': isFaceIntegrated,
        
        // --- ENGINEERED PROMPT (Y - The Secret Sauce) ---
        // This allows you to train a model to convert (Concept -> Pro Prompt) later.
        'engineered_prompt': finalPrompt, 
        
        // --- SYSTEM METADATA ---
        'ai_provider': aiModelUsed,     // e.g., 'google-imagen-3', 'dall-e-3'
        'status': isSuccess ? 'success' : 'failed',
        'error_log': errorMessage,
        'platform': defaultTargetPlatform.toString(),
        
        // --- PSYCHOLOGY METRICS (Inferred) ---
        // Default score is 1 (Action taken). 
        // If they share/save later, we can increment this via logPositiveReinforcement.
        'engagement_score': 1, 
      });
      
      if (kDebugMode) {
        print("📊 Data Point Logged: $rawPrompt ($style)");
      }

    } catch (e) {
      // CRITICAL: Silently fail. 
      // Never let analytics or logging crash the user's creative flow.
      debugPrint("⚠️ Data Collection Error (Ignored): $e");
    }
  }

  /// **2. LOG ENGAGEMENT (Reinforcement Learning)**
  /// Call this when a user Saves or Shares an image.
  /// This signals that the generated result was "High Quality".
  Future<void> logPositiveReinforcement({
    required String imageUrl,
    required String actionType, // 'save', 'share', 'copy'
  }) async {
    try {
      final uid = _ref.read(currentUserIdProvider) ?? 'anonymous';

      // We log a separate event that can be joined by 'imageUrl' or 'userId' + 'time' 
      // in your data warehouse (BigQuery) later.
      await _db.collection('slm_engagement_events').add({
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'action': actionType,
        'target_image_url': imageUrl,
        'weight': actionType == 'share' ? 5 : 3, // Sharing is a stronger signal than saving
      });

    } catch (e) {
      debugPrint("⚠️ Engagement Log Error (Ignored): $e");
    }
  }
}