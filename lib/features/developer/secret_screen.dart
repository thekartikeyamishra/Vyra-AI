import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:url_launcher/url_launcher.dart';

class SecretScreen extends StatefulWidget {
  const SecretScreen({super.key});

  @override
  State<SecretScreen> createState() => _SecretScreenState();
}

class _SecretScreenState extends State<SecretScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 1. Trigger Haptic Feedback (Physical Reward)
    HapticFeedback.heavyImpact();

    // 2. Setup Animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      HapticFeedback.lightImpact();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch link.")),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'workmailkartikeya@gmail.com',
      query: 'subject=Developer Access&body=Hello Kartikeya, I found the secret screen in Vyra!',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      // Fallback: Copy to clipboard
      await Clipboard.setData(const ClipboardData(text: "workmailkartikeya@gmail.com"));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email copied to clipboard")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // "Hacker" Theme specific to this screen
    const textColor = Color(0xFF00FF41); // Matrix Green
    const bgColor = Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: const Text(
          "// SYSTEM_OVERRIDE",
          style: TextStyle(
            color: textColor, 
            fontFamily: 'Courier', 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- AVATAR / ICON ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: textColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: textColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                      ]
                    ),
                    child: const Icon(Icons.code, size: 64, color: textColor),
                  ),
                  
                  const SizedBox(height: 32),

                  // --- TEXT HEADER ---
                  const Text(
                    "Hello, Traveler.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You've unlocked the developer channel.\nLet's build something extraordinary.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      height: 1.5,
                      fontFamily: 'Courier',
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- CONTACT CARDS ---
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    label: "Email Me",
                    subLabel: "workmailkartikeya@gmail.com",
                    color: Colors.redAccent,
                    onTap: _sendEmail,
                  ),
                  _buildContactCard(
                    icon: Icons.link, // LinkedIn Icon replacement
                    label: "LinkedIn",
                    subLabel: "/in/thekartikeyamishra",
                    color: const Color(0xFF0077B5),
                    onTap: () => _launchURL("https://linkedin.com/in/thekartikeyamishra/"),
                  ),
                  _buildContactCard(
                    icon: Icons.alternate_email, // X Icon replacement
                    label: "X (Twitter)",
                    subLabel: "@kartikeyahere",
                    color: Colors.white,
                    onTap: () => _launchURL("https://x.com/kartikeyahere"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subLabel,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[700], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}