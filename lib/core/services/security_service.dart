import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- PROVIDER ---
// Global access to security checks
final securityServiceProvider = Provider<SecurityService>((ref) => SecurityService());

class SecurityService {
  // --- CONFIGURATION ---
  // Limit: 5 Requests per 60 seconds (Adjust based on your budget)
  static const int _maxRequestsPerMinute = 5;
  static const Duration _windowDuration = Duration(minutes: 1);
  
  // Storage Keys
  static const String _requestKey = 'security_request_timestamps';

  /// **1. RATE LIMITER (Exploitation Protection)**
  /// Checks if the user is spamming the API.
  /// Returns `true` if safe to proceed, `false` if blocked.
  /// Automatically records the request if allowed.
  Future<bool> isSafeToProceed() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 1. Get history of request timestamps
    List<String> timestamps = prefs.getStringList(_requestKey) ?? [];
    
    // 2. Filter: Keep only requests within the last minute (sliding window)
    // We parse the string timestamps back to integers for comparison
    timestamps = timestamps.where((ts) {
      final time = int.tryParse(ts) ?? 0;
      return now - time < _windowDuration.inMilliseconds;
    }).toList();

    // 3. Check Limit
    if (timestamps.length >= _maxRequestsPerMinute) {
      if (kDebugMode) {
        print("⚠️ SECURITY ALERT: Rate limit exceeded. Blocked to save API costs.");
      }
      return false; // BLOCKED
    }

    // 4. Record this new valid request
    timestamps.add(now.toString());
    await prefs.setStringList(_requestKey, timestamps);
    
    return true; // ALLOWED
  }

  /// **2. COST OPTIMIZATION (Local Caching)**
  /// Checks if we already have a result for a specific prompt/key locally.
  /// This saves both AI Tokens and Database Reads.
  Future<bool> hasCachedData(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    // In a full app, you might check if the cache is expired here too
    return prefs.containsKey("cache_$cacheKey");
  }

  /// **3. SAVE TO CACHE**
  /// Stores a result locally for future use.
  Future<void> cacheResult(String cacheKey, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("cache_$cacheKey", data);
  }
}