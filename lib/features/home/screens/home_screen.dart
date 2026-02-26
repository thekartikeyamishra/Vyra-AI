/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// Core Services & Theme
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_theme.dart';

// Features Logic
import '../services/database_service.dart';
import '../../rewards/reward_controller.dart';
import '../../image_generation/image_model.dart'; // Ensure ImageModel is imported

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // --- STATE: Passive Revenue (Banner Ad) ---
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize Banner Ad immediately for passive impression revenue
    _loadBanner();
  }

  void _loadBanner() {
    final adService = ref.read(adServiceProvider);
    _bannerAd = adService.createBannerAd();
    _bannerAd!.load().then((_) {
      if (mounted) {
        setState(() => _isBannerReady = true);
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Prevent memory leaks
    super.dispose();
  }

  // --- LOGIC: Social Quest (Follow Developer) ---
  // Psychological Trick: Immediate dopamine hit (Reward) for a low-effort action.
  Future<void> _handleSocialQuest(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // OPTIMISTIC UPDATE (Psychology: Trust the user -> Reciprocity)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verifying... (+50 XP Awarded!)"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Grant Rewards securely via Database Service
          final db = ref.read(databaseServiceProvider);
          await db.updateUserField('isFollowingDev', true); // Hide the quest card
          await db.updateUserField('xp', 50); // Give XP
        }
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Could not open link. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH: Real-time Data Streams
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    // Note: Ensure your database_service.dart exports 'itemsStreamProvider' returning List<ImageModel>
    final generationsAsync = ref.watch(itemsStreamProvider); 

    // 2. LISTEN: Reward Controller (Active Revenue Errors)
    ref.listen<AsyncValue<void>>(rewardControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad Error: ${next.error}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- A. PASSIVE INCOME (Banner Ad) ---
          if (_isBannerReady && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              color: Colors.white,
              child: AdWidget(ad: _bannerAd!),
            ),

          // --- B. DASHBOARD CONTENT ---
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 1. Stats & Quests
                SliverToBoxAdapter(
                  child: userProfileAsync.when(
                    data: (user) => Column(
                      children: [
                        _buildStatsCard(context, ref, user.dailyGenerationCount, user.xp),
                        // Only show quest if not completed
                        if (!user.isFollowingDev)
                          _buildSocialQuestCard(),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => const SizedBox(), 
                  ),
                ),

                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      "Recent Creations", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),

                // 2. Adaptive Grid of Creations
                generationsAsync.when(
                  data: (images) {
                    if (images.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_mosaic, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "Your studio is empty.\nCreate something viral!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // Adaptive Grid: Fits more items on larger screens automatically
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200, // Max width per card
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8, // Taller cards for images
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final image = images[index];
                            return _buildGenerationCard(context, ref, image);
                          },
                          childCount: images.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => SliverToBoxAdapter(child: Center(child: Text("Error: $e"))),
                ),
                
                // Bottom Padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Creation Tab (Index 1) via Router or Key
          // For now, we assume the user knows to click the 'Viral Studio' tab
          // Or we can show a hint
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Go to 'Viral Studio' tab to create! 🚀")),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Create"),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildGenerationCard(BuildContext context, WidgetRef ref, ImageModel image) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Fixed Deprecation
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: image.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          
          // Delete Button Overlay
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.white.withValues(alpha: 0.8), // Fixed Deprecation
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  // Correct Method: deleteGeneration (matches DatabaseService update)
                  ref.read(databaseServiceProvider).deleteGeneration(image.id);
                },
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                ),
              ),
            ),
          ),
          
          // Prompt Text Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent
                  ],
                ),
              ),
              child: Text(
                image.prompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, int credits, int xp) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Fixed Deprecation
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Available Credits", "$credits", Icons.bolt_rounded, AppTheme.rewardColor),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              _statItem("XP Level", "$xp", Icons.star_rounded, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 20),
          
          // ACTIVE REVENUE BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text("Refill Credits (+5 XP)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Trigger Active Revenue (Reward Ad)
                ref.read(rewardControllerProvider.notifier).showAdToEarnCredit();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialQuestCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Join the Inner Circle",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Follow Dev on X for +50 XP",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _handleSocialQuest("https://x.com/kartikeyahere"),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1), // Fixed Deprecation
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text("FOLLOW"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// Core
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_theme.dart';

// Features
import '../services/database_service.dart';
import '../../rewards/reward_controller.dart';
import '../../image_generation/image_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final adService = ref.read(adServiceProvider);
    _bannerAd = adService.createBannerAd();
    _bannerAd!.load().then((_) {
      if (mounted) setState(() => _isBannerReady = true);
    });
  }

  Future<void> _handleSocialQuest(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ref.read(databaseServiceProvider).updateUserField('isFollowingDev', true);
        ref.read(databaseServiceProvider).updateUserField('xp', 50);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verified! +50 XP"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileStreamProvider);
    final itemsAsync = ref.watch(itemsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text("Dashboard"), elevation: 0),
      body: Column(
        children: [
          if (_isBannerReady && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: userAsync.when(
                    data: (user) => Column(
                      children: [
                        _buildStatsCard(context, ref, user.dailyGenerationCount, user.xp),
                        if (!user.isFollowingDev) _buildSocialQuestCard(),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const SizedBox(),
                  ),
                ),
                
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text("Recent Creations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                itemsAsync.when(
                  data: (images) {
                    if (images.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: Text("No art yet. Start creating!", style: TextStyle(color: Colors.grey))),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildImageCard(images[index]),
                          childCount: images.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => SliverToBoxAdapter(child: Text("Error: $e")),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Provide a hint to use the bottom nav
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Tap 'Viral Studio' below to create!")),
           );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildImageCard(ImageModel image) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: image.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_,__) => Container(color: Colors.grey[200]),
            errorWidget: (_,__,___) => const Icon(Icons.error),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withValues(alpha: 0.6),
              child: Text(
                image.prompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => ref.read(databaseServiceProvider).deleteGeneration(image.id),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, int credits, int xp) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Credits", "$credits", Icons.bolt, AppTheme.rewardColor),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              _statItem("XP", "$xp", Icons.star, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_fill),
              label: const Text("Refill Credits (+1)"),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              onPressed: () => ref.read(rewardControllerProvider.notifier).showAdToEarnCredit(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialQuestCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Join the Inner Circle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Follow Dev on X for +50 XP", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleSocialQuest("https://x.com/kartikeyahere"),
            style: TextButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
            child: const Text("FOLLOW"),
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}