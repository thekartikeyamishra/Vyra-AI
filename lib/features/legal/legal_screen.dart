import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Privacy & Terms"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HERO HEADER ---
            const Text(
              "Your Trust is Our Priority.",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "We built Vyra to help you create, not to track you. Here is a plain-English summary of how we handle your data and protect your rights.",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // --- SECTIONS ---
            
            _buildSection(
              icon: Icons.security,
              title: "1. Data Minimalism",
              body: "We only collect what is strictly necessary to make the app work:\n"
                  "• Your email (for authentication).\n"
                  "• Your generated images (stored securely in your private cloud).\n"
                  "• Basic usage stats (to improve the AI models).",
            ),

            _buildSection(
              icon: Icons.cloud_done,
              title: "2. You Own Your Creations",
              body: "Any image, thumbnail, or content you generate using Vyra belongs to you. "
                  "You verify that you have the rights to use the prompts you enter. "
                  "We do not claim copyright over your generated assets.",
            ),

            _buildSection(
              icon: Icons.ad_units,
              title: "3. Ads & Monetization",
              body: "To keep Vyra free, we show advertisements provided by Google AdMob. "
                  "AdMob may use your device identifier to show relevant ads. "
                  "We do not sell your personal data to third-party data brokers.",
            ),

            _buildSection(
              icon: Icons.delete_forever,
              title: "4. Your Right to Delete",
              body: "You are in control. If you wish to delete your account and all associated data, "
                  "you can do so at any time by contacting us. All data will be permanently wiped from our servers.",
            ),

            _buildSection(
              icon: Icons.verified_user,
              title: "5. Safe AI Usage",
              body: "Vyra uses advanced AI models. By using this app, you agree not to generate content that is:\n"
                  "• Illegal or harmful.\n"
                  "• Hateful, harassing, or explicit.\n"
                  "Violating this policy may result in account suspension.",
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // --- CONTACT FOOTER ---
            const Text(
              "Questions?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Contact the developer directly at:\nworkmailkartikeya@gmail.com",
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            
            const SizedBox(height: 48),
            
            // Version Info
            Center(
              child: Text(
                "Vyra v1.0.0 (Production Build)",
                style: TextStyle(color: Colors.grey[300], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET ---
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6, // Better readability
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}