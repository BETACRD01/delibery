import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors_primary.dart';
import 'app_colors_secondary.dart';
import 'app_colors_support.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 📝 ESTILOS DE TEXTO
// ══════════════════════════════════════════════════════════════════════════════

class AppTextStyles {
  static const h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColorsSupport.textPrimary,
    letterSpacing: -0.5,
  );

  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColorsSupport.textPrimary,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColorsSupport.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 15,
    color: AppColorsSupport.textPrimary,
    height: 1.5,
  );

  static const bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColorsSupport.textSecondary,
    height: 1.4,
  );

  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 TEMA COMPLETO
// ══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColorsPrimary.main,
            primary: AppColorsPrimary.main,
            secondary: AppColorsSecondary.main,
            surface: AppColorsSupport.surface,
            error: AppColorsSupport.error,
          ).copyWith(
            surface: AppColorsSupport.surface,
            surfaceContainerLowest: AppColorsSupport.background,
          ),

      scaffoldBackgroundColor: AppColorsSupport.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColorsSupport.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColorsSupport.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColorsSupport.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsPrimary.main,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsSupport.inputBg,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColorsPrimary.main),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColorsSupport.error),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 CONSTANTES iOS
// ══════════════════════════════════════════════════════════════════════════════

class AppConstants {
  // BORDER RADIUS
  static const double radiusCard = 14.0;
  static const double radiusButton = 10.0;
  static const double radiusBadge = 8.0;
  static const double radiusIcon = 7.0;
  static const double radiusLarge = 16.0;
  static const double radiusSmall = 6.0;

  // SPACING
  static const double spacingSection = 24.0;
  static const double spacingItem = 12.0;
  static const double spacingHorizontal = 16.0;
  static const double spacingVertical = 20.0;
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 32.0;

  // ICON SIZES
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconContainerSize = 30.0;

  // SHADOWS
  static List<BoxShadow> cardShadow(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final opacity = brightness == Brightness.dark ? 0.12 : 0.06;

    return [
      BoxShadow(
        color: CupertinoColors.systemGrey
            .resolveFrom(context)
            .withValues(alpha: opacity),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> subtleShadow(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final opacity = brightness == Brightness.dark ? 0.08 : 0.04;

    return [
      BoxShadow(
        color: CupertinoColors.systemGrey
            .resolveFrom(context)
            .withValues(alpha: opacity),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
