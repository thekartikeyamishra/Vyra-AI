import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env_config.dart';

// --- PROVIDER DEFINITION ---
final generationAgentProvider = Provider<GenerationAgent>((ref) => GenerationAgent());

// --- AGENT CLASS ---
class GenerationAgent {
  
  // --- ENDPOINTS ---
  // Google
  static const String _googleUrl = 'https://generativelanguage.googleapis.com/v1beta/models/imagen-3:generateImages';
  static const String _geminiFlashUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // OpenAI
  static const String _openAiImageUrl = 'https://api.openai.com/v1/images/generations';
  static const String _openAiChatUrl = 'https://api.openai.com/v1/chat/completions';

  /// **1. TEXT-TO-IMAGE GENERATION**
  /// Returns a Map {'url': string, 'model': string} to support Data Collection logic.
  Future<Map<String, dynamic>> generateImage({
    required String userPrompt,
    required String ratio,
  }) async {
    // Prompt Engineering layer
    final processedPrompt = _constructSystemPrompt(userPrompt);

    try {
      // A. PRIMARY: GOOGLE IMAGEN 3
      final url = await _generateWithGoogle(processedPrompt, ratio);
      return {'url': url, 'model': 'google-imagen-3'};
    } catch (googleError) {
      print("⚠️ Google Generation Failed: $googleError. Switching to OpenAI...");
      
      try {
        // B. FALLBACK: OPENAI DALL-E 3
        final url = await _generateWithOpenAI(processedPrompt, ratio);
        return {'url': url, 'model': 'openai-dall-e-3'};
      } catch (openAiError) {
        throw Exception("All AI engines are currently busy. Please try again later.");
      }
    }
  }

  /// **2. FACE-TO-IMAGE (Multimodal Pipeline)**
  /// Uses Vision models to analyze the face, then Image Gen models to recreate it.
  Future<Map<String, dynamic>> generateImageWithFace({
    required String userPrompt,
    required String ratio,
    required File faceImage,
  }) async {
    // Prepare Image Data
    final bytes = await faceImage.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // Instruction to the Vision Model (The "Eye")
    const visionPrompt = "Describe the person in this image in extreme detail, focusing on facial features, hair, age, ethnicity, and expression. Do not describe the background. The goal is to recreate this person in a new setting.";

    try {
      // A. PRIMARY PIPELINE: Gemini Vision -> Google Imagen
      // Step 1: See
      final description = await _describeImageWithGemini(base64Image, visionPrompt);
      
      // Step 2: Imagine
      final finalPrompt = "A photorealistic image of a person matching this description: $description. Context/Activity: $userPrompt. High quality, 8k, cinematic lighting.";
      
      final url = await _generateWithGoogle(finalPrompt, ratio);
      return {'url': url, 'model': 'gemini-vision-pipeline'};

    } catch (e) {
      print("⚠️ Gemini Face Pipeline Failed: $e. Switching to OpenAI...");
      
      try {
        // B. FALLBACK PIPELINE: GPT-4o Vision -> DALL-E 3
        // Step 1: See
        final description = await _describeImageWithGPT4o(base64Image, visionPrompt);
        
        // Step 2: Imagine
        final finalPrompt = "A photorealistic image of a person matching this description: $description. Context/Activity: $userPrompt. High quality, 8k, cinematic lighting.";
        
        final url = await _generateWithOpenAI(finalPrompt, ratio);
        return {'url': url, 'model': 'openai-vision-pipeline'};
      } catch (err) {
        throw Exception("Face generation failed across all providers. Please check your internet or credits.");
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 GOOGLE ENGINES (Primary)
  // ---------------------------------------------------------------------------

  Future<String> _generateWithGoogle(String prompt, String ratio) async {
    final apiKey = EnvConfig.imageGenApi;
    if (apiKey.isEmpty) throw Exception("Google API Key missing");

    final aspectParam = _mapRatioToGoogleParam(ratio);

    final response = await http.post(
      Uri.parse('$_googleUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "prompt": prompt,
        "aspectRatio": aspectParam,
        "personGeneration": "ALLOW_ADULT",
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"}
        ]
      }),
    ).timeout(const Duration(seconds: 50));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['images'] != null && (data['images'] as List).isNotEmpty) {
        // Imagen usually returns base64, but can return URL depending on cloud bucket config
        return data['images'][0]['url'] ?? data['images'][0]['image64'];
      }
      throw Exception("Google returned empty result.");
    } else {
      final error = jsonDecode(response.body);
      throw Exception("Google Error: ${error['error']['message']}");
    }
  }

  Future<String> _describeImageWithGemini(String base64Image, String prompt) async {
    final apiKey = EnvConfig.imageGenApi;
    final response = await http.post(
      Uri.parse('$_geminiFlashUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{
          "parts": [
            {"text": prompt},
            {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
          ]
        }]
      })
    );

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    throw Exception("Gemini Vision Failed: ${response.body}");
  }

  // ---------------------------------------------------------------------------
  // 🔸 OPENAI ENGINES (Fallback)
  // ---------------------------------------------------------------------------

  Future<String> _generateWithOpenAI(String prompt, String ratio) async {
    final apiKey = EnvConfig.openAiApiKey;
    if (apiKey.isEmpty) throw Exception("OpenAI API Key missing");

    final sizeParam = _mapRatioToOpenAISize(ratio);

    final response = await http.post(
      Uri.parse(_openAiImageUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": sizeParam,
        "quality": "standard",
        "response_format": "url"
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'][0]['url'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception("OpenAI Error: ${error['error']['message']}");
    }
  }

  Future<String> _describeImageWithGPT4o(String base64Image, String prompt) async {
    final apiKey = EnvConfig.openAiApiKey;
    final response = await http.post(
      Uri.parse(_openAiChatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": prompt},
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
            ]
          }
        ],
        "max_tokens": 300
      })
    );

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw Exception("GPT-4o Vision Failed");
  }

  // ---------------------------------------------------------------------------
  // 🛠️ HELPERS
  // ---------------------------------------------------------------------------

  String _constructSystemPrompt(String rawInput) {
    return """
    Create a high-quality, professional, viral-style social media image.
    
    CRITICAL INSTRUCTIONS:
    1. Correct any spelling errors in the user's text.
    2. Ensure text is legible, high-contrast, and modern.
    3. Style: Cinematic, Volumetric Lighting, 8k Resolution.
    
    USER REQUEST:
    $rawInput
    """;
  }

  /// Maps UI "16:9" to Google's Enum
  String _mapRatioToGoogleParam(String uiRatio) {
    switch (uiRatio) {
      case "16:9": return "ASPECT_RATIO_16_9";
      case "9:16": return "ASPECT_RATIO_9_16";
      case "1:1": return "ASPECT_RATIO_1_1";
      case "4:3": return "ASPECT_RATIO_4_3";
      case "3:4": return "ASPECT_RATIO_3_4";
      default: return "ASPECT_RATIO_16_9";
    }
  }

  /// Maps UI "16:9" to OpenAI's Resolutions
  String _mapRatioToOpenAISize(String uiRatio) {
    switch (uiRatio) {
      case "16:9": return "1792x1024"; 
      case "9:16": return "1024x1792"; 
      case "1:1": return "1024x1024";
      default: return "1792x1024";
    }
  }
}