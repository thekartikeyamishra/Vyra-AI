import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Internal Logic & Theme
// Make sure these paths match where you placed the controllers earlier
import '../creation/controllers/creation_controller.dart';
import '../../features/rewards/reward_controller.dart';
import '../../core/services/ad_service.dart';
import '../../core/theme/app_theme.dart';

class GeneratePage extends ConsumerStatefulWidget {
  const GeneratePage({super.key});

  @override
  ConsumerState<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends ConsumerState<GeneratePage> {
  final _promptController = TextEditingController();
  String _selectedRatio = "16:9";
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    _promptController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _generate() {
    FocusScope.of(context).unfocus();
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Describe your vision first!")),
      );
      return;
    }

    // Logic: The Controller handles the Spelling/Language correction internally
    // via the prompt engineering we set up earlier.
    ref.read(creationControllerProvider.notifier).generateThumbnail(
          prompt: _promptController.text.trim(),
          ratio: _selectedRatio,
        );
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(creationControllerProvider);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    // Listen for Low Credits Error
    ref.listen(creationControllerProvider, (prev, next) {
      if (next.hasError && next.error.toString().contains("LOW_CREDITS")) {
        _showLowCreditDialog();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Vyra AI Studio"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // Adaptive Padding: More horizontal space on tablets to center content
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? size.width * 0.15 : 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Psychological & Functional Hook
                      _buildProTipCard(),
                      const SizedBox(height: 24),
                      
                      // 2. Input Section
                      const Text(
                        "1. Idea & Text",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.translate, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            "Auto-correction active for spelling & 50+ languages.",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: _promptController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "E.g. A futuristic city with neon sign text '2050'...",
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Settings Section
                      const Text(
                        "2. Select Canvas Ratio",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      _buildAdaptiveRatioSelector(),
                      
                      const SizedBox(height: 32),
                      
                      // 4. Action Section
                      _buildGenerateButton(creationState),
                      
                      const SizedBox(height: 32),
                      
                      // 5. Result Section
                      if (creationState.hasValue && creationState.value != null)
                        _buildAdaptiveResultArea(creationState.value!),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Passive Income: Persistent Banner Ad at Bottom
          if (_isBannerReady && _bannerAd != null)
            _buildAdContainer(),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildProTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_fix_high, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Our Neural Engine ensures text clarity and correct spelling. Just type freely!",
              style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveRatioSelector() {
    final List<Map<String, dynamic>> options = [
      {"id": "16:9", "icon": Icons.tv, "label": "YouTube"},
      {"id": "9:16", "icon": Icons.phone_android, "label": "Shorts"},
      {"id": "1:1", "icon": Icons.square_outlined, "label": "Post"},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        final isSelected = _selectedRatio == opt['id'];
        return ChoiceChip(
          avatar: Icon(opt['icon'], size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
          label: Text(opt['label']),
          selected: isSelected,
          onSelected: (val) => setState(() => _selectedRatio = opt['id']),
          selectedColor: AppTheme.primaryColor,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateButton(AsyncValue<String?> state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: state.isLoading ? null : _generate,
        icon: state.isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.bolt_rounded),
        label: Text(
          state.isLoading ? "Refining Content..." : "Generate Mastery (2 Credits)",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildAdaptiveResultArea(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        
        // Image Container
        Container(
          constraints: const BoxConstraints(maxHeight: 400), // Prevent overflow on small screens
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ref.read(creationControllerProvider.notifier).shareImage(url),
                icon: const Icon(Icons.share_rounded),
                label: const Text("Viral Share"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleGallerySave(url),
                icon: const Icon(Icons.download_done_rounded),
                label: const Text("Save HQ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _handleGallerySave(String url) {
    // Monetization: Interstitial Ad "Payment"
    ref.read(adServiceProvider).showInterstitial(
      onComplete: () async {
        await ref.read(creationControllerProvider.notifier).saveImageToGallery(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚀 Saved to your Gallery!"), backgroundColor: Colors.green),
          );
        }
      },
    );
  }

  Widget _buildAdContainer() {
    return Container(
      color: Colors.white,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }

  void _showLowCreditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Credits Exhausted"),
        content: const Text("Refill your credits instantly by watching a short video."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe Later")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(rewardControllerProvider.notifier).showAdToEarnCredit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text("Refill Now"),
          ),
        ],
      ),
    );
  }
}