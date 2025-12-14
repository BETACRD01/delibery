// lib/theme/jp_theme.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 COLORES JP EXPRESS
// ══════════════════════════════════════════════════════════════════════════════

class JPColors {
  // ✅ MARCA PRINCIPAL
  static const primary = Color(0xFF0cb7f2);      // Azul Principal
  static const primaryLight = Color(0xFFC7EBFD); // Azul claro
  static const secondary = Color(0xFFFF7B00);    // Naranja Acción

  // FONDOS NEUTROS
  static const background = Color(0xFFF8F9FA); // Gris muy claro
  static const surface = Colors.white;         // Blanco puro
  static const inputBg = Color(0xFFFAFAFA);    // Fondo inputs

  // TEXTOS
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF718096);
  static const textHint = Color(0xFFA0AEC0);

  // ESTADOS
  static const success = Color(0xFF38A169);
  static const warning = Color(0xFFDD6B20);
  static const error = Color(0xFFE53E3E);
  static const info = Color(0xFF3182CE);
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
      colorScheme: ColorScheme.fromSeed(
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
          side: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
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

  const JPAvatar({
    super.key,
    this.imageUrl,
    this.radius = 40,
    this.onTap,
  });

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
    show(context, message, color: JPColors.success, icon: Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    show(context, message, color: JPColors.error, icon: Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    show(context, message, color: JPColors.info, icon: Icons.info_outline);
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
