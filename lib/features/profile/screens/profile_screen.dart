import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// Controllers & Services
import '../controllers/profile_controller.dart';
import '../../auth/auth_controller.dart';
import '../../home/services/database_service.dart';

// Screens (Dependencies)
import '../../referral/screens/referral_screen.dart'; 
import '../../developer/secret_screen.dart';          
import '../../legal/legal_screen.dart';               

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _secretCodeController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  // 1. Secret Code Logic (Easter Egg: 'VPMSMKM')
  void _handleSecretCode(String code) {
    if (code.trim() == 'VPMSMKM') {
      _secretCodeController.clear();
      // Navigate to the Hidden Developer Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SecretScreen()),
      );
    } else if (code.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access Denied. Invalid Code.")),
      );
    }
  }

  // 2. Social Link Handler (Quest Logic)
  Future<void> _launchSocial(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Psychological Reinforcement: Immediate positive feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Opening... Don't forget to follow for +XP!"),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open link. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Real-time User Data (XP, Credits, Streaks)
    final userAsync = ref.watch(userProfileStreamProvider);

    // Listen for Profile Update Feedback (Success/Error)
    ref.listen<AsyncValue<void>>(profileControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!next.isLoading && next.hasValue && _isEditingName) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity Updated Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for clean look
      appBar: AppBar(
        title: const Text("Command Center"),
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Data Sync Error: $e")),
        data: (user) {
          // Pre-fill name if not actively editing
          if (!_isEditingName) {
            _nameController.text = user.displayName ?? "Anonymous Creator";
          }

          // ADAPTIVE LAYOUT: Center content on Tablets/Web
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    // --- SECTION A: IDENTITY ---
                    _buildIdentityHeader(user.photoUrl),
                    const SizedBox(height: 24),
                    _buildNameField(),
                    
                    const SizedBox(height: 32),

                    // --- SECTION B: GAMIFICATION STATS ---
                    _buildStatsRow(user.xp, user.dailyGenerationCount, user.streakCount),

                    const SizedBox(height: 32),

                    // --- SECTION C: VIRAL GROWTH ENGINE (Referral) ---
                    _buildReferralCard(context),

                    const SizedBox(height: 32),

                    // --- SECTION D: SOCIAL QUESTS (Psychological Nudge) ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Join the Inner Circle",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Quest 1: X (Twitter)
                    _buildSocialTile(
                      title: "Follow Developer on X",
                      subtitle: "Get insider updates & secret codes",
                      icon: Icons.alternate_email,
                      color: Colors.black,
                      onTap: () => _launchSocial("https://x.com/kartikeyahere"),
                    ),
                    
                    // Quest 2: LinkedIn
                    _buildSocialTile(
                      title: "Connect on LinkedIn",
                      subtitle: "Professional networking & opportunities",
                      icon: Icons.business,
                      color: const Color(0xFF0077B5),
                      onTap: () => _launchSocial("https://www.linkedin.com/in/thekartikeyamishra"),
                    ),

                    const SizedBox(height: 32),

                    // --- SECTION E: SYSTEM & SECRETS ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "System & Secrets",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Secret Code Input Field
                    TextField(
                      controller: _secretCodeController,
                      decoration: InputDecoration(
                        labelText: "Redeem Secret Code",
                        prefixIcon: const Icon(Icons.vpn_key, color: Colors.deepPurple),
                        hintText: "Enter code here...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _handleSecretCode(_secretCodeController.text),
                        ),
                      ),
                      onSubmitted: _handleSecretCode,
                    ),
                    
                    const SizedBox(height: 16),

                    // Legal & Policy Link
                    ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.shield_outlined, color: Colors.grey),
                      title: const Text("Privacy & Safe Data Policy"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                    ),

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red.shade200),
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.logout, color: Colors.red.shade700),
                        label: Text("Sign Out", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildIdentityHeader(String? photoUrl) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60, // Increased for better visibility
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null 
                ? const Icon(Icons.person, size: 60, color: Colors.deepPurple) 
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Icon(Icons.verified, color: Colors.blue, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      enabled: _isEditingName,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        // Shows underline only when editing
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurple, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(_isEditingName ? Icons.check_circle : Icons.edit, 
                    color: _isEditingName ? Colors.green : Colors.grey),
          onPressed: () {
            if (_isEditingName) {
              // Save changes to Database via Controller
              ref.read(profileControllerProvider.notifier).updateDisplayName(_nameController.text);
            } else {
              // Start editing mode
              setState(() => _isEditingName = true);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(int xp, int credits, int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("XP Level", "$xp", Icons.star_rounded, Colors.amber),
          _verticalDivider(),
          _statItem("Credits", "$credits", Icons.bolt_rounded, Colors.orange),
          _verticalDivider(),
          _statItem("Streak", "$streak🔥", Icons.local_fire_department_rounded, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(height: 40, width: 1, color: Colors.grey.shade200);

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the Referral Screen
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF3700B3)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6200EE).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.group_add, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Invite Friends & Earn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 4),
                  Text("Get 10 Credits for every friend!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        trailing: Icon(Icons.open_in_new, size: 20, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}