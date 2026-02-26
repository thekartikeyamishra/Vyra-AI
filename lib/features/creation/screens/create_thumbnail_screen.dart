/*
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Controllers & Services
import '../controllers/creation_controller.dart';
import '../../rewards/reward_controller.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_theme.dart';

class CreateThumbnailScreen extends ConsumerStatefulWidget {
  const CreateThumbnailScreen({super.key});

  @override
  ConsumerState<CreateThumbnailScreen> createState() => _CreateThumbnailScreenState();
}

class _CreateThumbnailScreenState extends ConsumerState<CreateThumbnailScreen> {
  // --- UI STATE ---
  final _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // Selection Defaults
  String _selectedStyle = "Realistic";
  String _selectedMood = "Excited";
  String _selectedRatio = "16:9";
  File? _userFaceImage;
  bool _isPremiumMode = false;
  
  // Tutorial State
  bool _showTutorial = false;

  // --- DATA LISTS ---
  final List<String> _styles = [
    "Realistic", "3D Render", "Anime", "Cyberpunk", 
    "Minimalist", "Oil Painting", "Comic Book", "Cinematic"
  ];
  
  final List<String> _moods = [
    "Excited", "Shocked", "Dark/Scary", "Professional", 
    "Funny", "Mysterious", "Happy", "Epic"
  ];

  final Map<String, IconData> _ratioIcons = {
    "16:9": Icons.tv,
    "9:16": Icons.phone_android,
    "1:1": Icons.square,
  };

  // --- AD STATE ---
  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
    _loadBanner();
  }

  // --- INITIALIZATION LOGIC ---

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Show tutorial if key 'seen_studio_tutorial' is NOT true
    if (prefs.getBool('seen_studio_tutorial') != true) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_studio_tutorial', true);
    setState(() => _showTutorial = false);
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
    _scrollController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _userFaceImage = File(image.path);
          _isPremiumMode = true; 
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _userFaceImage = null;
      _isPremiumMode = false; 
    });
  }

  void _generate() {
    FocusScope.of(context).unfocus();

    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a basic idea first!")),
      );
      // Scroll to top to show error field
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    // Call the NEW "No-Skill" Controller Method
    ref.read(creationControllerProvider.notifier).generateWithStyles(
      rawConcept: _promptController.text.trim(),
      style: _selectedStyle,
      mood: _selectedMood,
      ratio: _selectedRatio,
      faceImage: _userFaceImage, // Pass image if available (triggers premium flow internally)
    );
  }

  void _handleShare(String imageUrl) {
    ref.read(adServiceProvider).showInterstitial(
      onComplete: () => ref.read(creationControllerProvider.notifier).shareImage(imageUrl),
    );
  }

  void _handleSave(String imageUrl) {
    ref.read(adServiceProvider).showInterstitial(
      onComplete: () async {
        await ref.read(creationControllerProvider.notifier).saveImageToGallery(imageUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✨ Saved to Gallery!"), backgroundColor: Colors.green),
          );
        }
      },
    );
  }

  void _showLowCreditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Fuel Low! ⚡"),
        content: Text(
          _isPremiumMode 
            ? "Premium generation (Face Insert) costs 5 credits. You need more fuel."
            : "Standard generation costs 2 credits. Refill for free?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_fill),
            label: const Text("Refill Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor, 
              foregroundColor: Colors.white
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(rewardControllerProvider.notifier).showAdToEarnCredit();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(creationControllerProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Listen for Errors
    ref.listen(creationControllerProvider, (prev, next) {
      if (next.hasError) {
        final error = next.error.toString();
        if (error.contains("LOW_CREDITS")) {
          _showLowCreditDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.replaceAll('Exception:', '')),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    });

    return Stack(
      children: [
        // --- MAIN SCAFFOLD ---
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Viral Studio"), 
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  // Adaptive Padding: Center content on tablets
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? size.width * 0.15 : 20, 
                    vertical: 20
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. IDEA INPUT (Simplified) ---
                      _buildSectionHeader("1. What's the concept?", Icons.lightbulb_outline),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promptController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "e.g. A cat eating pizza in space...",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- 2. STYLE CHIPS (Visual) ---
                      _buildSectionHeader("2. Choose a Style", Icons.palette_outlined),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _styles.map((style) {
                          final isSelected = _selectedStyle == style;
                          return ChoiceChip(
                            label: Text(style),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedStyle = style),
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            elevation: isSelected ? 2 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // --- 3. MOOD CHIPS ---
                      _buildSectionHeader("3. Set the Mood", Icons.emoji_emotions_outlined),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _moods.map((mood) {
                          final isSelected = _selectedMood == mood;
                          return ChoiceChip(
                            label: Text(mood),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedMood = mood),
                            selectedColor: AppTheme.secondaryColor, // Teal for mood
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            elevation: isSelected ? 2 : 0,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // --- 4. FORMAT ---
                      _buildSectionHeader("4. Format", Icons.aspect_ratio),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _ratioIcons.entries.map((entry) {
                            final isSelected = _selectedRatio == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: InkWell(
                                onTap: () => setState(() => _selectedRatio = entry.key),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(entry.value, size: 20, color: isSelected ? Colors.white : Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.key, 
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[800],
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- 5. FACE SWAP (Premium) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader("5. Add Face (Optional)", Icons.face_retouching_natural),
                          if (_isPremiumMode)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                              child: const Text("PREMIUM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_userFaceImage == null)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text("Upload Selfie (+3 Credits)", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_userFaceImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: CircleAvatar(
                                radius: 14, backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  onPressed: _removeImage,
                                ),
                              ),
                            )
                          ],
                        ),
                      
                      const SizedBox(height: 32),

                      // --- GENERATE BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: creationState.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            creationState.isLoading 
                                ? "Designing..." 
                                : "Generate (${_isPremiumMode ? '5' : '2'} Credits)",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPremiumMode ? Colors.black87 : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          onPressed: creationState.isLoading ? null : _generate,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- RESULT AREA ---
                      if (creationState.hasValue && creationState.value != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 40),
                            const Text("Your Masterpiece:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(creationState.value!, fit: BoxFit.cover),
                            ),
                            
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.share),
                                    label: const Text("Share"),
                                    onPressed: () => _handleShare(creationState.value!),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text("Save"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: () => _handleSave(creationState.value!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // --- BANNER AD ---
              if (_isBannerReady && _bannerAd != null)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  color: Colors.grey[50],
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),

        // --- GUIDED TUTORIAL OVERLAY ---
        if (_showTutorial)
          _buildTutorialOverlay(),
      ],
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTutorialOverlay() {
    return Stack(
      children: [
        // Dim Background
        ModalBarrier(
          color: Colors.black.withOpacity(0.85),
          dismissible: false,
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Animation
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_fix_high, color: AppTheme.rewardColor, size: 64),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  "Welcome to Viral Studio!",
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "You don't need prompt skills here.\n\n1️⃣ Pick a Style & Mood\n2️⃣ Type a simple idea (e.g. 'A Cat')\n3️⃣ Get a Viral Masterpiece",
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _completeTutorial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                    ),
                    child: const Text("Let's Create!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
*/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/creation_controller.dart';
import '../../rewards/reward_controller.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_theme.dart';

class CreateThumbnailScreen extends ConsumerStatefulWidget {
  const CreateThumbnailScreen({super.key});

  @override
  ConsumerState<CreateThumbnailScreen> createState() => _CreateThumbnailScreenState();
}

class _CreateThumbnailScreenState extends ConsumerState<CreateThumbnailScreen> {
  final _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedStyle = "Realistic";
  String _selectedMood = "Excited";
  String _selectedRatio = "16:9";
  File? _userFaceImage;
  bool _showTutorial = false;

  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  final List<String> _styles = ["Realistic", "3D Render", "Anime", "Cyberpunk", "Oil Painting", "Minimalist"];
  final List<String> _moods = ["Excited", "Spooky", "Professional", "Funny", "Mysterious", "Epic"];

  @override
  void initState() {
    super.initState();
    _checkTutorial();
    _loadBanner();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seen_studio_tutorial') != true) {
      setState(() => _showTutorial = true);
      await prefs.setBool('seen_studio_tutorial', true);
    }
  }

  void _loadBanner() {
    final adService = ref.read(adServiceProvider);
    _bannerAd = adService.createBannerAd();
    _bannerAd!.load().then((_) {
      if (mounted) setState(() => _isBannerReady = true);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _userFaceImage = File(image.path));
  }

  void _generate() {
    FocusScope.of(context).unfocus();
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a basic idea first!")));
      return;
    }

    ref.read(creationControllerProvider.notifier).generateWithStyles(
      rawConcept: _promptController.text.trim(),
      style: _selectedStyle,
      mood: _selectedMood,
      ratio: _selectedRatio,
      faceImage: _userFaceImage,
    );
  }

  void _handleSave(String url) {
    ref.read(adServiceProvider).showInterstitial(
      onComplete: () async {
        await ref.read(creationControllerProvider.notifier).saveImageToGallery(url);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved!"), backgroundColor: Colors.green));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(creationControllerProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    ref.listen(creationControllerProvider, (prev, next) {
      if (next.hasError) {
        if (next.error.toString().contains("LOW_CREDITS")) {
          ref.read(rewardControllerProvider.notifier).showAdToEarnCredit();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${next.error}")));
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: const Text("Viral Studio"), elevation: 0),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? size.width * 0.15 : 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. IDEA
                      const Text("1. Basic Idea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _promptController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "e.g. A cat flying in space...",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. STYLE
                      const Text("2. Style", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _styles.map((s) => ChoiceChip(
                          label: Text(s),
                          selected: _selectedStyle == s,
                          onSelected: (_) => setState(() => _selectedStyle = s),
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(color: _selectedStyle == s ? Colors.white : Colors.black),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 3. MOOD
                      const Text("3. Mood", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _moods.map((m) => ChoiceChip(
                          label: Text(m),
                          selected: _selectedMood == m,
                          onSelected: (_) => setState(() => _selectedMood = m),
                          selectedColor: AppTheme.secondaryColor,
                          labelStyle: TextStyle(color: Colors.black),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 4. FACE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("4. Add Face (Premium)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_userFaceImage != null)
                            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _userFaceImage = null))
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 100, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100], borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            image: _userFaceImage != null ? DecorationImage(image: FileImage(_userFaceImage!), fit: BoxFit.cover) : null,
                          ),
                          child: _userFaceImage == null 
                              ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo), Text("Upload Face (+3 Credits)")]) 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 5. GENERATE
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton.icon(
                          onPressed: creationState.isLoading ? null : _generate,
                          icon: creationState.isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                              : const Icon(Icons.auto_awesome),
                          label: Text(creationState.isLoading ? "Creating..." : "Generate Artwork"),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                        ),
                      ),

                      // 6. RESULT
                      if (creationState.hasValue && creationState.value != null)
                        Column(
                          children: [
                            const SizedBox(height: 32),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(creationState.value!),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _handleSave(creationState.value!),
                              icon: const Icon(Icons.download),
                              label: const Text("Save to Gallery"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                            )
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (_isBannerReady && _bannerAd != null)
                SizedBox(height: _bannerAd!.size.height.toDouble(), width: _bannerAd!.size.width.toDouble(), child: AdWidget(ad: _bannerAd!)),
            ],
          ),
        ),
        
        if (_showTutorial)
          _buildTutorialOverlay(),
      ],
    );
  }

  Widget _buildTutorialOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, color: Colors.white, size: 64),
              const SizedBox(height: 24),
              const Text("Welcome to Viral Studio!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("No prompts needed.\n\n1. Pick a Style\n2. Pick a Mood\n3. Type a simple idea\n\nWe handle the rest!", style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () => setState(() => _showTutorial = false), child: const Text("Let's Go!"))
            ],
          ),
        ),
      ),
    );
  }
}