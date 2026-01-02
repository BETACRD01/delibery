// lib/theme/primary_colors.dart
// ══════════════════════════════════════════════════════════════════════════════
// 🎨 COLORES PRIMARIOS - IDENTIDAD DE MARCA
// ══════════════════════════════════════════════════════════════════════════════
// Estos colores representan la identidad visual de la empresa.
// NO mezclar con colores utilitarios.

import 'package:flutter/material.dart';

class PrimaryColors {
  PrimaryColors._();

  // ══════════════════════════════════════════════════════════════════════════
  // IDENTIDAD DE MARCA
  // ══════════════════════════════════════════════════════════════════════════

  /// Color principal de la marca - Azul/Celeste
  static const Color brandPrimary = Color(0xFF0cb7f2);

  /// Variante clara del color principal
  static const Color brandPrimaryLight = Color(0xFFC7EBFD);

  /// Color secundario corporativo - Naranja
  static const Color brandSecondary = Color(0xFFFF8C00);

  /// Color de acento/CTA - Naranja vibrante
  static const Color brandAccent = Color(0xFFFF7B00);

  // ══════════════════════════════════════════════════════════════════════════
  // FONDOS PRINCIPALES
  // ══════════════════════════════════════════════════════════════════════════

  /// Fondo principal de la aplicación
  static const Color background = Color(0xFFF8F9FA);

  /// Fondo de superficies elevadas (cards, modals)
  static const Color surface = Colors.white;

  /// Fondo de inputs
  static const Color inputBackground = Color(0xFFFAFAFA);

  // ══════════════════════════════════════════════════════════════════════════
  // ALIASES (compatibilidad con código existente)
  // ══════════════════════════════════════════════════════════════════════════

  /// @deprecated Use brandPrimary instead
  static const Color main = brandPrimary;

  /// @deprecated Use brandPrimaryLight instead
  static const Color light = brandPrimaryLight;

  /// @deprecated Use brandSecondary instead
  static const Color secondary = brandSecondary;
}

// Mantener compatibilidad con AppColorsPrimary
typedef AppColorsPrimary = PrimaryColors;
