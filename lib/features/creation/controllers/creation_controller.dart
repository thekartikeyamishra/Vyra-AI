import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
// Watermark Logic
import 'package:image/image.dart' as img; 

import '../../auth/providers/auth_state_provider.dart';
import '../../image_generation/generation_agent.dart';
import '../../image_generation/image_model.dart';
import '../../../core/services/data_collection_service.dart';

// --- STATE MANAGEMENT ---
final creationControllerProvider = 
    AsyncNotifierProvider<CreationController, String?>(CreationController.new);

class CreationController extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  // --- CONFIGURATION ---
  static const int _costStandard = 2;
  static const int _costPremium = 5;

  /// **1. NO-SKILL GENERATION (STYLES & MOODS)**
  /// Handles the "No-Skill" UI flow.
  Future<void> generateWithStyles({
    required String rawConcept,
    required String style,
    required String mood,
    required String ratio,
    File? faceImage, 
  }) async {
    // Fuse inputs for the AI Agent
    final masterPrompt = "A $style image of $rawConcept. Atmosphere: $mood.";

    if (faceImage != null) {
      // PREMIUM FLOW (Face Integrated)
      await _executeGenerationFlow(
        prompt: masterPrompt,
        ratio: ratio,
        cost: _costPremium,
        // Metadata for SLM Training
        rawConcept: rawConcept,
        style: style,
        mood: mood,
        faceImage: faceImage,
      );
    } else {
      // STANDARD FLOW
      await _executeGenerationFlow(
        prompt: masterPrompt,
        ratio: ratio,
        cost: _costStandard,
        // Metadata for SLM Training
        rawConcept: rawConcept,
        style: style,
        mood: mood,
      );
    }
  }

  /// **2. LEGACY GENERATION**
  /// Handles direct text input flow.
  Future<void> generateThumbnail({
    required String prompt,
    required String ratio,
  }) async {
    await _executeGenerationFlow(
      prompt: prompt,
      ratio: ratio,
      cost: _costStandard,
      // Metadata (Treat whole prompt as concept)
      rawConcept: prompt,
      style: "Manual",
      mood: "Custom",
    );
  }

  /// **CORE EXECUTION FLOW**
  /// Coordinates: Credits -> AI Agent -> History -> Data Collection -> Error Handling
  Future<void> _executeGenerationFlow({
    required String prompt,
    required String ratio,
    required int cost,
    // Data Collection Params
    required String rawConcept,
    required String style,
    required String mood,
    File? faceImage,
  }) async {
    state = const AsyncValue.loading();
    final uid = ref.read(currentUserIdProvider);
    final dataCollector = ref.read(dataCollectionServiceProvider);
    
    if (uid == null) {
      state = AsyncValue.error("Authentication required.", StackTrace.current);
      return;
    }

    try {
      // A. Deduct Credits (Transaction)
      await _handleCreditTransaction(uid, cost, isDeduction: true);

      // B. Call AI Agent
      try {
        Map<String, dynamic> result;

        if (faceImage != null) {
          result = await ref.read(generationAgentProvider).generateImageWithFace(
            userPrompt: prompt,
            ratio: ratio,
            faceImage: faceImage,
          );
        } else {
          result = await ref.read(generationAgentProvider).generateImage(
            userPrompt: prompt,
            ratio: ratio,
          );
        }

        final imageUrl = result['url'] as String;
        final modelUsed = result['model'] as String;
        
        // C. Save to History (Gallery/Dashboard)
        await _saveToHistory(
          uid: uid,
          imageUrl: imageUrl,
          prompt: prompt, 
          ratio: ratio,
        );

        // D. LOG DATA (SLM Training Success)
        // We silently record what worked so we can fine-tune later.
        dataCollector.logGenerationEvent(
          rawPrompt: rawConcept,
          style: style,
          mood: mood,
          finalPrompt: prompt,
          aiModelUsed: modelUsed,
          isFaceIntegrated: faceImage != null,
          isSuccess: true,
        );

        state = AsyncValue.data(imageUrl);

      } catch (agentError) {
        // E. Auto-Refund on Failure
        await _handleCreditTransaction(uid, cost, isDeduction: false);
        
        // F. LOG ERROR (SLM Training Failure)
        dataCollector.logGenerationEvent(
          rawPrompt: rawConcept,
          style: style,
          mood: mood,
          finalPrompt: prompt,
          aiModelUsed: 'failed',
          isFaceIntegrated: faceImage != null,
          isSuccess: false,
          errorMessage: agentError.toString(),
        );

        throw Exception("Generation failed. Credits refunded. ($agentError)");
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // --- ACTIONS: SAVE & SHARE ---

  Future<void> saveImageToGallery(String imageUrl) async {
    try {
      if (!await _requestGalleryPermissions()) {
        throw Exception("Gallery permission denied. Enable in Settings.");
      }
      // Download original -> Add Watermark -> Save
      final originalPath = await _downloadToCache(imageUrl);
      final watermarkedPath = await _addWatermark(originalPath);
      
      await Gal.putImage(watermarkedPath);
      _cleanupFile(originalPath);
      _cleanupFile(watermarkedPath);
    } catch (e) {
      throw Exception("Save failed: $e");
    }
  }

  Future<void> shareImage(String imageUrl) async {
    try {
      final originalPath = await _downloadToCache(imageUrl);
      final watermarkedPath = await _addWatermark(originalPath);
      
      await Share.shareXFiles(
        [XFile(watermarkedPath)], 
        text: 'Created with Vyra AI 🚀'
      );
      
      _cleanupFile(originalPath);
      _cleanupFile(watermarkedPath);
    } catch (e) {
      throw Exception("Share failed: $e");
    }
  }

  // --- PRIVATE HELPERS ---

  Future<void> _saveToHistory({
    required String uid,
    required String imageUrl,
    required String prompt,
    required String ratio,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('generations').doc();
    
    // Fixed: Using named parameters correctly
    final imageModel = ImageModel(
      id: docRef.id,
      userId: uid,
      imageUrl: imageUrl,
      prompt: prompt,
      aspectRatio: ratio,
      createdAt: DateTime.now(),
      isSavedToGallery: false,
    );

    await docRef.set(imageModel.toMap());
  }

  Future<void> _handleCreditTransaction(String uid, int amount, {required bool isDeduction}) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User profile missing.");
      final credits = snapshot.data()?['dailyGenerationCount'] ?? 0;

      if (isDeduction) {
        if (credits < amount) throw Exception("LOW_CREDITS");
        transaction.update(userRef, {'dailyGenerationCount': credits - amount});
      } else {
        transaction.update(userRef, {'dailyGenerationCount': credits + amount});
      }
    });
  }

  Future<String> _downloadToCache(String url) async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final path = "${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.png";
    await dio.download(url, path);
    return path;
  }

  // --- WATERMARK LOGIC ---
  Future<String> _addWatermark(String originalPath) async {
    try {
      // 1. Decode Image
      final originalImage = img.decodeImage(File(originalPath).readAsBytesSync());
      if (originalImage == null) return originalPath;

      // 2. Draw Text Watermark (Simple & Fast)
      img.drawString(
        originalImage,
        'Made by Vyra',
        font: img.arial24,
        x: originalImage.width - 160,
        y: originalImage.height - 40,
        color: img.ColorRgb8(255, 255, 255), // White Text
      );

      // 3. Save New File
      final tempDir = await getTemporaryDirectory();
      final watermarkPath = "${tempDir.path}/vyra_watermarked_${DateTime.now().millisecondsSinceEpoch}.png";
      File(watermarkPath).writeAsBytesSync(img.encodePng(originalImage));
      
      return watermarkPath;
    } catch (e) {
      print("Watermark failed: $e");
      return originalPath; // Fallback to original if processing fails
    }
  }

  void _cleanupFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  Future<bool> _requestGalleryPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.photos.request().isGranted;
      }
      return await Permission.storage.request().isGranted;
    }
    return await Permission.photosAddOnly.request().isGranted;
  }
}