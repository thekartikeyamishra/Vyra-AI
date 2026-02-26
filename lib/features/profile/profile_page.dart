import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_controller.dart';

// Define a simple User Model locally or in core/models
class UserStats {
  final bool isPremium;
  final int dailyGenerationCount;
  final int xp;
  final int totalGenerations;

  UserStats({
    this.isPremium = false,
    this.dailyGenerationCount = 0,
    this.xp = 0,
    this.totalGenerations = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      isPremium: data['isPremium'] ?? false,
      dailyGenerationCount: data['dailyGenerationCount'] ?? 0,
      xp: data['xp'] ?? 0,
      totalGenerations: data['totalGenerations'] ?? 0,
    );
  }
}

// Stream provider for live updates
final userStatsProvider = StreamProvider<UserStats>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(UserStats());

  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((snapshot) => UserStats.fromMap(snapshot.data() ?? {}));
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (stats) {
          final limit = stats.isPremium 
              ? PricingConstants.premiumDailyLimit 
              : PricingConstants.freeDailyLimit;
          final remaining = limit - stats.dailyGenerationCount;
          final progress = remaining / limit;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. User Header
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.purpleAccent,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Creator", // Replace with name if available
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Credits Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4834D4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text("Daily Credits",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      "$remaining / $limit",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.black26,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Stats Grid
              Row(
                children: [
                  _StatBox(
                    label: "XP Level", 
                    value: "${(stats.xp / 100).floor()}", 
                    icon: Icons.star
                  ),
                  const SizedBox(width: 16),
                  _StatBox(
                    label: "Total Arts", 
                    value: "${stats.totalGenerations}", 
                    icon: Icons.image
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 4. Settings Options
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                title: const Text("Upgrade to Premium"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to Subscription Page
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.purpleAccent),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}