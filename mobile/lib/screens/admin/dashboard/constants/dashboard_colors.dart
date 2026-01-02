// lib/screens/admin/dashboard/constants/dashboard_colors.dart
// ══════════════════════════════════════════════════════════════════════════════
// COLORES DEL DASHBOARD - Aliases hacia el sistema centralizado
// ══════════════════════════════════════════════════════════════════════════════

import '../../../../theme/primary_colors.dart';
import '../../../../theme/secondary_colors.dart';

/// Colores específicos del Dashboard Admin
/// Todos los colores son aliases hacia el sistema centralizado en theme/
class DashboardColors {
  DashboardColors._();

  // MARCA
  static const morado = PrimaryColors.brandPrimary;
  static const moradoOscuro = PrimaryColors.brandPrimary;

  // ESTADOS
  static const verde = SecondaryColors.success;
  static const azul = SecondaryColors.info;
  static const naranja = SecondaryColors.warning;
  static const rojo = SecondaryColors.error;

  // NEUTRALES
  static const gris = SecondaryColors.grayMedium;
  static const grisClaro = SecondaryColors.grayLight;
}
