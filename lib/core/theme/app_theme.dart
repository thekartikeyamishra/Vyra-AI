import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // --- BRAND PALETTE (Psychological Strategy) ---
  
  // PRIMARY: Deep Purple
  // Psychology: Associated with wisdom, creativity, and premium quality.
  // Usage: Main headers, primary buttons, branding.
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  
  // SECONDARY: Teal
  // Psychology: Freshness, calm, and renewal.
  // Usage: Floating Action Buttons, success states, accents.
  static const Color secondaryColor = Color(0xFF03DAC6);
  
  // REWARD: Gold / Amber
  // Psychology: Wealth, achievement, and dopamine hits.
  // Usage: XP bars, Credit counts, "Premium" badges.
  static const Color rewardColor = Color(0xFFFFD700);
  
  // FUNCTIONAL COLORS
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFF5F5F9); // Light Blue-Grey (Easy on eyes)
  static const Color surfaceColor = Colors.white;

  // --- LIGHT THEME DEFINITION ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // 1. GLOBAL COLOR SCHEME
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
    ),

    // 2. SCAFFOLD (Background)
    scaffoldBackgroundColor: backgroundColor,

    // 3. TYPOGRAPHY (Modern & Readable)
    fontFamily: 'Roboto', 
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87), // Default text
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54), // Subtitles
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0), // Buttons
    ),

    // 4. APP BAR (Clean & Branded)
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light, // White status bar icons
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),

    // 5. CARDS (Standardized "Lifted" Look)
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),

    // 6. INPUT FIELDS (Trustworthy Forms)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Default Border
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      // Enabled (Idle) Border
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      // Focused (Active) Border - Highlights with Primary Color
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      // Error Border
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      hintStyle: TextStyle(color: Colors.grey.shade400),
    ),

    // 7. ELEVATED BUTTONS (Primary Calls to Action)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    // 8. OUTLINED BUTTONS (Secondary Actions)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    // 9. TEXT BUTTONS (Low Emphasis)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // 10. FLOATING ACTION BUTTON
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.black, // High contrast on Teal
      elevation: 4,
    ),

    // 11. ICON THEME
    iconTheme: const IconThemeData(
      color: Colors.black87,
      size: 24,
    ),
    
    // 12. BOTTOM NAVIGATION BAR
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: primaryColor.withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}