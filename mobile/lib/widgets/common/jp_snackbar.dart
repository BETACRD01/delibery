// lib/widgets/jp_snackbar.dart

import 'package:flutter/material.dart';
import '../../theme/jp_theme.dart'; // Ajusta esta ruta según dónde tengas tu jp_theme.dart

class JPSnackbar {
  /// Método base privado para construir el SnackBar
  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    int durationSeconds = 3,
  }) {
    // Limpiar SnackBars previos para evitar colas largas
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors
            .transparent, // Transparente para usar nuestro propio contenedor
        duration: Duration(seconds: durationSeconds),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🟢 ÉXITO
  // ════════════════════════════════════════════════════════════════════════
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: JPColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔴 ERROR
  // ════════════════════════════════════════════════════════════════════════
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: JPColors.error,
      icon: Icons.error_rounded,
      durationSeconds: 4, // Los errores duran un poco más para poder leerlos
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🟠 ADVERTENCIA
  // ════════════════════════════════════════════════════════════════════════
  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: JPColors.warning,
      icon: Icons.warning_rounded,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔵 INFORMACIÓN
  // ════════════════════════════════════════════════════════════════════════
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: JPColors.info,
      icon: Icons.info_rounded,
    );
  }
}
