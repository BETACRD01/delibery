// lib/theme/secondary_colors.dart
// ══════════════════════════════════════════════════════════════════════════════
// 🎨 COLORES SECUNDARIOS - SOPORTE UI
// ══════════════════════════════════════════════════════════════════════════════
// Colores de apoyo para la experiencia visual.
// NO representan la identidad de marca.

import 'package:flutter/material.dart';

class SecondaryColors {
  SecondaryColors._();

  // ══════════════════════════════════════════════════════════════════════════
  // NEUTRALES
  // ══════════════════════════════════════════════════════════════════════════

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  /// Gris muy claro - fondos sutiles
  static const Color grayLightest = Color(0xFFFAFAFA);

  /// Gris claro - fondos secundarios
  static const Color grayLight = Color(0xFFF5F5F5);

  /// Gris medio - iconos deshabilitados
  static const Color grayMedium = Color(0xFF9E9E9E);

  /// Gris oscuro - textos secundarios
  static const Color grayDark = Color(0xFF424242);

  /// Gris muy oscuro - textos principales
  static const Color grayDarkest = Color(0xFF212121);

  // ══════════════════════════════════════════════════════════════════════════
  // TEXTOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Texto principal
  static const Color textPrimary = Color(0xFF4A5568);

  /// Texto secundario
  static const Color textSecondary = Color(0xFF718096);

  /// Texto placeholder/hint
  static const Color textHint = Color(0xFFA0AEC0);

  /// Precios
  static const Color textPrice = Color(0xFFEF5350);

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Éxito - Verde
  static const Color success = Color(0xFF38A169);
  static const Color successLight = Color(0xFFE6F4EA);

  /// Advertencia - Naranja
  static const Color warning = Color(0xFFDD6B20);
  static const Color warningLight = Color(0xFFFFF3E0);

  /// Error - Rojo
  static const Color error = Color(0xFFE53E3E);
  static const Color errorLight = Color(0xFFFDEAEA);

  /// Información - Azul
  static const Color info = Color(0xFF3182CE);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ══════════════════════════════════════════════════════════════════════════
  // ELEMENTOS UI
  // ══════════════════════════════════════════════════════════════════════════

  /// Bordes
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);

  /// Divisores
  static const Color divider = Color(0xFFEEEEEE);

  /// Elementos deshabilitados
  static const Color disabled = Color(0xFFBDBDBD);

  /// Overlay oscuro (para modals)
  static const Color overlay = Color(0x80000000);

  /// Sombras
  static const Color shadow = Color(0x1A000000);

  // ══════════════════════════════════════════════════════════════════════════
  // COLORES ESPECÍFICOS (Dashboard Admin)
  // ══════════════════════════════════════════════════════════════════════════

  /// Morado dashboard
  static const Color purple = Color(0xFF7C3AED);

  /// Verde dashboard
  static const Color green = Color(0xFF10B981);

  /// Rojo dashboard
  static const Color red = Color(0xFFEF4444);

  /// Gris dashboard
  static const Color gray = Color(0xFF6B7280);

  /// Gris claro dashboard
  static const Color grayLightDashboard = Color(0xFFF3F4F6);

  // ══════════════════════════════════════════════════════════════════════════
  // ALIASES (compatibilidad con código existente)
  // ══════════════════════════════════════════════════════════════════════════

  /// @deprecated Use textPrice instead
  static const Color price = textPrice;

  /// @deprecated Use grayLightest instead
  static const Color inputBg = grayLightest;
}

// Mantener compatibilidad con AppColorsSecondary y AppColorsSupport
typedef AppColorsSecondary = SecondaryColors;
typedef AppColorsSupport = SecondaryColors;
