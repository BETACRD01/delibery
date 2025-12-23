// lib/theme/jp_theme.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors_primary.dart';
import 'app_colors_secondary.dart';
import 'app_colors_support.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 COLORES JP EXPRESS
// ══════════════════════════════════════════════════════════════════════════════

class JPColors {
  // ✅ MARCA PRINCIPAL
  static const primary = AppColorsPrimary.main; // Azul Principal
  static const primaryLight = AppColorsPrimary.light; // Azul claro
  static const secondary = AppColorsSecondary.main; // Naranja Acción

  // FONDOS NEUTROS
  static const background = AppColorsSupport.background; // Gris muy claro
  static const surface = AppColorsSupport.surface; // Blanco puro
  static const inputBg = AppColorsSupport.inputBg; // Fondo inputs

  // TEXTOS
  static const textPrimary = AppColorsSupport.textPrimary;
  static const textSecondary = AppColorsSupport.textSecondary;
  static const textHint = AppColorsSupport.textHint;

  // ESTADOS
  static const success = AppColorsSupport.success;
  static const warning = AppColorsSupport.warning;
  static const error = AppColorsSupport.error;
  static const info = AppColorsSupport.info;
}

// ══════════════════════════════════════════════════════════════════════════════
// 📝 ESTILOS DE TEXTO
// ══════════════════════════════════════════════════════════════════════════════

class JPTextStyles {
  static const h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: JPColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: JPColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: JPColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 15,
    color: JPColors.textPrimary,
    height: 1.5,
  );

  static const bodySecondary = TextStyle(
    fontSize: 14,
    color: JPColors.textSecondary,
    height: 1.4,
  );

  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 TEMA COMPLETO (MATERIAL 3 – MIGRADO)
// ══════════════════════════════════════════════════════════════════════════════

class JPTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 🎨 ColorScheme corregido (background eliminado → usar surface)
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: JPColors.primary,
            primary: JPColors.primary,
            secondary: JPColors.secondary,
            surface: JPColors.surface,
            error: JPColors.error,
          ).copyWith(
            // Surface principal
            surface: JPColors.surface,
            surfaceContainerLowest: JPColors.background,
          ),

      scaffoldBackgroundColor: JPColors.background,

      // ███ APPBAR ███
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: JPColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: JPColors.textPrimary),
        titleTextStyle: TextStyle(
          color: JPColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        scrolledUnderElevation: 0,
      ),

      // ███ TARJETAS ███
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),

      // ███ BOTONES ███
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: JPColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: JPTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ███ INPUTS ███
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: JPColors.inputBg,
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
          borderSide: const BorderSide(color: JPColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: JPColors.error),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🧩 WIDGETS COMPARTIDOS (OPTIMIZADOS)
// ══════════════════════════════════════════════════════════════════════════════

/// Avatar profesional
class JPAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const JPAvatar({super.key, this.imageUrl, this.radius = 40, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: JPColors.surface,
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: ClipOval(child: _buildImage()),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Icon(Icons.person, size: radius, color: JPColors.textHint);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, _) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, _, _) => const Icon(Icons.error),
    );
  }
}

/// Snackbar moderno
class JPSnackbar {
  static void show(
    BuildContext context,
    String message, {
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      color: JPColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  static void error(BuildContext context, String message) {
    show(context, message, color: JPColors.error, icon: Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      color: const Color.fromARGB(255, 59, 159, 226),
      icon: Icons.info_outline,
    );
  }
}

/// Badge minimalista
class JPBadge extends StatelessWidget {
  final String label;
  final Color color;

  const JPBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Loading minimalista
class JPLoading extends StatelessWidget {
  const JPLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(JPColors.primary),
        strokeWidth: 2,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 CONSTANTES iOS
// ══════════════════════════════════════════════════════════════════════════════

/// Constantes de diseño iOS siguiendo Human Interface Guidelines
class JPConstants {
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
    // Adaptar la opacidad según el brillo del contexto
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

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 COLORES CUPERTINO ADAPTIVOS
// ══════════════════════════════════════════════════════════════════════════════

/// Helpers de colores Cupertino adaptativos para dark mode
class JPCupertinoColors {
  // FONDOS
  static Color background(BuildContext context) =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);

  static Color surface(BuildContext context) =>
      CupertinoColors.systemBackground.resolveFrom(context);

  static Color secondarySurface(BuildContext context) =>
      CupertinoColors.secondarySystemBackground.resolveFrom(context);

  static Color tertiarySurface(BuildContext context) =>
      CupertinoColors.tertiarySystemBackground.resolveFrom(context);

  // TEXTOS
  static Color label(BuildContext context) =>
      CupertinoColors.label.resolveFrom(context);

  static Color secondaryLabel(BuildContext context) =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  static Color tertiaryLabel(BuildContext context) =>
      CupertinoColors.tertiaryLabel.resolveFrom(context);

  static Color quaternaryLabel(BuildContext context) =>
      CupertinoColors.quaternaryLabel.resolveFrom(context);

  static Color placeholder(BuildContext context) =>
      CupertinoColors.placeholderText.resolveFrom(context);

  // SEPARADORES
  static Color separator(BuildContext context) =>
      CupertinoColors.separator.resolveFrom(context);

  static Color opaqueSeparator(BuildContext context) =>
      CupertinoColors.opaqueSeparator.resolveFrom(context);

  // GRISES DEL SISTEMA
  static Color systemGrey(BuildContext context) =>
      CupertinoColors.systemGrey.resolveFrom(context);

  static Color systemGrey2(BuildContext context) =>
      CupertinoColors.systemGrey2.resolveFrom(context);

  static Color systemGrey3(BuildContext context) =>
      CupertinoColors.systemGrey3.resolveFrom(context);

  static Color systemGrey4(BuildContext context) =>
      CupertinoColors.systemGrey4.resolveFrom(context);

  static Color systemGrey5(BuildContext context) =>
      CupertinoColors.systemGrey5.resolveFrom(context);

  static Color systemGrey6(BuildContext context) =>
      CupertinoColors.systemGrey6.resolveFrom(context);

  // COLORES DEL SISTEMA
  static Color systemBlue(BuildContext context) =>
      CupertinoColors.systemBlue.resolveFrom(context);

  static Color systemGreen(BuildContext context) =>
      CupertinoColors.systemGreen.resolveFrom(context);

  static Color systemRed(BuildContext context) =>
      CupertinoColors.systemRed.resolveFrom(context);

  static Color systemOrange(BuildContext context) =>
      CupertinoColors.systemOrange.resolveFrom(context);

  static Color systemYellow(BuildContext context) =>
      CupertinoColors.systemYellow.resolveFrom(context);

  static Color systemPink(BuildContext context) =>
      CupertinoColors.systemPink.resolveFrom(context);

  static Color systemPurple(BuildContext context) =>
      CupertinoColors.systemPurple.resolveFrom(context);

  static Color systemTeal(BuildContext context) =>
      CupertinoColors.systemTeal.resolveFrom(context);

  static Color systemIndigo(BuildContext context) =>
      CupertinoColors.systemIndigo.resolveFrom(context);

  // COLORES DE MARCA (adaptados para dark mode)
  static Color primary(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      const CupertinoDynamicColor.withBrightness(
        color: JPColors.primary,
        darkColor: Color(0xFF64D2FF), // Más claro para dark mode
      ),
      context,
    );
  }

  static Color secondary(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      const CupertinoDynamicColor.withBrightness(
        color: JPColors.secondary,
        darkColor: Color(0xFFFF9933), // Más claro para dark mode
      ),
      context,
    );
  }

  static Color destructive(BuildContext context) =>
      CupertinoColors.destructiveRed.resolveFrom(context);

  static Color success(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      const CupertinoDynamicColor.withBrightness(
        color: JPColors.success,
        darkColor: Color(0xFF48D77D), // Más claro para dark mode
      ),
      context,
    );
  }

  static Color warning(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      const CupertinoDynamicColor.withBrightness(
        color: JPColors.warning,
        darkColor: Color(0xFFFF8C3A), // Más claro para dark mode
      ),
      context,
    );
  }

  static Color error(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      const CupertinoDynamicColor.withBrightness(
        color: JPColors.error,
        darkColor: Color(0xFFFF6B6B), // Más claro para dark mode
      ),
      context,
    );
  }
}
