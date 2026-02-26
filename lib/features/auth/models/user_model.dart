import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // --- 1. Identity & Profile ---
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? username; // New Field for Unique Identity

  // --- 2. Economy (The Ad Engine) ---
  final int dailyGenerationCount; // Credits available (Lower usage count = more credits)
  final int xp;                   // Experience Points (Gamification)
  final bool isPremium;           // Logic for future subscriptions

  // --- 3. Growth & Viral Loop ---
  final String? referralCode;     // The unique code this user shares
  final String? referredBy;       // The code of the person who invited them

  // --- 4. Gamification & Engagement ---
  final int streakCount;          // Current daily login streak
  final bool isFollowingDev;      // "Social Quest" status (Follow on X/LinkedIn)

  // --- 5. Metadata ---
  final DateTime? lastLogin;
  final DateTime? createdAt;

  // Constructor
  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.username, // Init
    this.dailyGenerationCount = 0,
    this.xp = 0,
    this.isPremium = false,
    this.referralCode,
    this.referredBy,
    this.streakCount = 0,
    this.isFollowingDev = false,
    this.lastLogin,
    this.createdAt,
  });

  // --- FACTORY: Safe Firestore Parsing ---
  // Converts a raw Firestore document into a strong Dart object.
  // Includes "Fail-Safe" logic to prevent app crashes if data is missing or wrong type.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      // Fallback if document doesn't exist yet (prevents red screen of death)
      return UserModel(uid: doc.id);
    }

    return UserModel(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      username: data['username'], // Parse new field
      
      // Parse Numbers Safely (Handles int, double, or String numbers)
      dailyGenerationCount: (data['dailyGenerationCount'] as num?)?.toInt() ?? 0,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      streakCount: (data['streakCount'] as num?)?.toInt() ?? 0,
      
      // Booleans with default false
      isPremium: data['isPremium'] ?? false,
      isFollowingDev: data['isFollowingDev'] ?? false,
      
      // Strings (Nullable)
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
      
      // Timestamps (Convert Firestore Timestamp -> Dart DateTime)
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // --- METHOD: Serialization ---
  // Converts the object back to a Map for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'username': username, // Serialize new field
      'dailyGenerationCount': dailyGenerationCount,
      'xp': xp,
      'streakCount': streakCount,
      'isPremium': isPremium,
      'isFollowingDev': isFollowingDev,
      'referralCode': referralCode,
      'referredBy': referredBy,
      // Convert DateTime back to Firestore Timestamp
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // --- METHOD: Immutability Helper ---
  // Allows updating specific fields without mutating the original object.
  // Essential for Riverpod state updates (e.g., when a user watches an ad and gains XP).
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? username,
    int? dailyGenerationCount,
    int? xp,
    int? streakCount,
    bool? isFollowingDev,
    DateTime? lastLogin,
    // Note: referralCode and referredBy are permanent once set, so typically not in copyWith
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
      dailyGenerationCount: dailyGenerationCount ?? this.dailyGenerationCount,
      xp: xp ?? this.xp,
      streakCount: streakCount ?? this.streakCount,
      isPremium: isPremium,
      referralCode: referralCode,
      referredBy: referredBy,
      isFollowingDev: isFollowingDev ?? this.isFollowingDev,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt,
    );
  }
}