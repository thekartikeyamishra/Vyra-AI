import 'package:cloud_firestore/cloud_firestore.dart';

class ImageModel {
  // --- 1. CORE DATA ---
  final String id;             // Unique ID (Firestore Document ID)
  final String userId;         // Owner of the image
  final String imageUrl;       // The actual image link (Google/Storage URL)
  
  // --- 2. GENERATION CONTEXT ---
  final String prompt;         // The original text the user typed
  final String aspectRatio;    // 16:9, 1:1, etc. (Crucial for Adaptive UI)
  
  // --- 3. METADATA ---
  final DateTime createdAt;    // For sorting (Newest first)
  final bool isSavedToGallery; // Local state tracking

  // Constructor
  const ImageModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.prompt,
    required this.aspectRatio,
    required this.createdAt,
    this.isSavedToGallery = false,
  });

  // --- FACTORY: Safe Firestore Parsing ---
  // Converts raw Database data into a strong Dart object.
  // Handles potential nulls or missing fields gracefully to prevent crashes.
  factory ImageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      // Fail-safe fallback
      throw Exception("Document ${doc.id} is empty");
    }

    return ImageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      prompt: data['prompt'] ?? 'Untitled Creation',
      aspectRatio: data['aspectRatio'] ?? '1:1', // Default to square if missing
      
      // Handle Timestamp conversion safely
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      // Optional boolean flag
      isSavedToGallery: data['isSavedToGallery'] ?? false,
    );
  }

  // --- METHOD: Serialization ---
  // Prepares the object to be saved to Firestore (History).
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'prompt': prompt,
      'aspectRatio': aspectRatio,
      // ServerTimestamp is better for consistency across timezones
      'createdAt': FieldValue.serverTimestamp(), 
      'isSavedToGallery': isSavedToGallery,
    };
  }

  // --- METHOD: Immutability Helper ---
  // Allows updating a single field (like 'isSavedToGallery') 
  // without rewriting the whole object.
  ImageModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? prompt,
    String? aspectRatio,
    DateTime? createdAt,
    bool? isSavedToGallery,
  }) {
    return ImageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      prompt: prompt ?? this.prompt,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      createdAt: createdAt ?? this.createdAt,
      isSavedToGallery: isSavedToGallery ?? this.isSavedToGallery,
    );
  }
}