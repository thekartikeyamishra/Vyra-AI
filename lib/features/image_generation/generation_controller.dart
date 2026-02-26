import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
// Watermark Logic
import 'package:image/image.dart' as img;

// --- INTERNAL DEPENDENCIES ---
import '../../features/auth/providers/auth_state_provider.dart';
import 'generation_agent.dart';

// --- PROVIDER DEFINITION ---
final generationControllerProvider =
    AsyncNotifierProvider<GenerationController, String?>(
      GenerationController.new,
    );

// --- CONTROLLER CLASS ---
class GenerationController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() {
    return null; // Initial state is idle
  }

  /// **1. CORE GENERATION LOGIC**
  /// Coordinates: Credit Deduction -> AI Generation -> Error Handling -> Refund
  Future<void> generateImage({
    required String prompt,
    required String ratio,
  }) async {
    // A. Set Loading State
    state = const AsyncValue.loading();

    // B. Auth Check
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      state = AsyncValue.error("Authentication required.", StackTrace.current);
      return;
    }

    const int cost = 2; // AI Compute Cost per image

    try {
      // C. Transaction: Check & Deduct Credits
      await _handleCreditTransaction(uid, cost, isDeduction: true);

      // D. AI Agent Execution
      try {
        // The Agent returns a Map {'url': '...', 'model': '...'}
        final result = await ref
            .read(generationAgentProvider)
            .generateImage(userPrompt: prompt, ratio: ratio);

        // FIXED: Extract the URL string from the Map
        final imageUrl = result['url'] as String;

        // E. Success: Update State
        state = AsyncValue.data(imageUrl);
      } catch (aiError) {
        // F. Auto-Refund: If AI fails, give money back immediately.
        await _handleCreditTransaction(uid, cost, isDeduction: false);
        throw Exception(
          "AI Generation Failed. Credits have been refunded. Details: $aiError",
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// **2. GALLERY SAVE LOGIC (With Watermark)**
  Future<void> saveToGallery(String imageUrl) async {
    try {
      if (!await _requestPermissions()) {
        throw Exception(
          "Gallery permission denied. Please enable it in Settings.",
        );
      }

      // Download -> Watermark -> Save
      final originalPath = await _downloadToTemp(imageUrl);
      final watermarkedPath = await _addWatermark(originalPath);

      await Gal.putImage(watermarkedPath);

      // Cleanup
      _cleanupFile(originalPath);
      _cleanupFile(watermarkedPath);
    } catch (e) {
      throw Exception("Failed to save image: $e");
    }
  }

  /// **3. SHARE LOGIC (With Watermark)**
  Future<void> shareImage(String imageUrl) async {
    try {
      // Download -> Watermark -> Share
      final originalPath = await _downloadToTemp(imageUrl);
      final watermarkedPath = await _addWatermark(originalPath);

      await Share.shareXFiles([
        XFile(watermarkedPath),
      ], text: 'Created with Vyra AI ✨ #VyraStudio');

      // Cleanup
      _cleanupFile(originalPath);
      _cleanupFile(watermarkedPath);
    } catch (e) {
      throw Exception("Failed to share image: $e");
    }
  }

  // --- PRIVATE HELPERS ---

  /// **Helper: Safe Database Transaction**
  Future<void> _handleCreditTransaction(
    String uid,
    int amount, {
    required bool isDeduction,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) throw Exception("User profile not found.");

      final currentCredits = snapshot.data()?['dailyGenerationCount'] ?? 0;

      if (isDeduction) {
        if (currentCredits < amount) {
          throw Exception("LOW_CREDITS"); // Trigger Ad Nudge
        }
        transaction.update(userRef, {
          'dailyGenerationCount': currentCredits - amount,
        });
      } else {
        transaction.update(userRef, {
          'dailyGenerationCount': currentCredits + amount,
        });
      }
    });
  }

  /// **Helper: Download to Cache**
  Future<String> _downloadToTemp(String url) async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final fileName = "vyra_temp_${DateTime.now().millisecondsSinceEpoch}.png";
    final savePath = "${tempDir.path}/$fileName";

    await dio.download(url, savePath);
    return savePath;
  }

  /// **Helper: Add Watermark**
  Future<String> _addWatermark(String originalPath) async {
    try {
      // 1. Decode Image
      final bytes = await File(originalPath).readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return originalPath;

      // 2. Draw Text Watermark (Bottom Right)
      img.drawString(
        originalImage,
        'Made by Vyra',
        font: img.arial24,
        x: originalImage.width - 170, // Adjust based on font size
        y: originalImage.height - 50,
        color: img.ColorRgb8(255, 255, 255), // White
      );

      // 3. Save Watermarked File
      final tempDir = await getTemporaryDirectory();
      final watermarkPath =
          "${tempDir.path}/vyra_${DateTime.now().millisecondsSinceEpoch}.png";

      await File(watermarkPath).writeAsBytes(img.encodePng(originalImage));

      return watermarkPath;
    } catch (e) {
      print("Watermark Error: $e");
      return originalPath; // Fallback to non-watermarked if processing fails
    }
  }

  void _cleanupFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  /// **Helper: Permission Checker**
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ (SDK 33) check
      // Note: We use Permission.photos for new Androids, Storage for old.
      // Ideally, use device_info_plus here if you want exact version check,
      // but asking both usually works with permission_handler handling the logic.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();

      return statuses.values.any((status) => status.isGranted);
    } else {
      // iOS
      final status = await Permission.photosAddOnly.request();
      return status.isGranted || status.isLimited;
    }
  }
}
