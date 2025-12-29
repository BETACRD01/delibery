// lib/widgets/common/jp_empty_state.dart

import 'package:flutter/cupertino.dart';
import '../../theme/jp_theme.dart';
import 'jp_cupertino_button.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🎭 EMPTY STATE - Estado vacío elegante estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

/// Estado vacío mejorado con estilo iOS
///
/// Características:
/// - Icono grande en contenedor circular con fondo translúcido
/// - Título y mensaje descriptivo
/// - Botón de acción opcional
/// - Espaciado consistente estilo iOS
/// - Colores adaptativos a dark mode
class JPEmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customAction;

  const JPEmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 14,
        color: JPCupertinoColors.label(context),
        decoration: TextDecoration.none,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(JPConstants.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono en círculo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: iconColor),
              ),
              const SizedBox(height: JPConstants.spacingSection),
              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: JPCupertinoColors.label(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: JPConstants.spacingSmall),
              // Mensaje
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: JPCupertinoColors.secondaryLabel(context),
                  height: 1.4,
                ),
              ),
              // Botón de acción
              if (customAction != null) ...[
                const SizedBox(height: JPConstants.spacingSection),
                customAction!,
              ] else if (actionText != null && onAction != null) ...[
                const SizedBox(height: JPConstants.spacingSection),
                JPCupertinoButton.filled(
                  text: actionText,
                  onPressed: onAction,
                  backgroundColor: iconColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ⚠️ ERROR STATE - Estado de error
// ══════════════════════════════════════════════════════════════════════════════

/// Estado de error predefinido
class JPErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final String? actionText;
  final VoidCallback? onRetry;

  const JPErrorState({
    super.key,
    this.title,
    this.message,
    this.actionText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return JPEmptyState(
      icon: CupertinoIcons.exclamationmark_circle,
      iconColor: JPCupertinoColors.systemRed(context),
      title: title ?? 'Algo salió mal',
      message:
          message ??
          'Ocurrió un error inesperado. Por favor, intenta de nuevo.',
      actionText: actionText ?? 'Reintentar',
      onAction: onRetry,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📡 NO CONNECTION STATE - Sin conexión
// ══════════════════════════════════════════════════════════════════════════════

/// Estado de sin conexión predefinido
class JPNoConnectionState extends StatelessWidget {
  final String? title;
  final String? message;
  final String? actionText;
  final VoidCallback? onRetry;

  const JPNoConnectionState({
    super.key,
    this.title,
    this.message,
    this.actionText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return JPEmptyState(
      icon: CupertinoIcons.wifi_slash,
      iconColor: JPCupertinoColors.systemGrey(context),
      title: title ?? 'Sin conexión',
      message: message ?? 'Revisa tu conexión a internet e intenta de nuevo.',
      actionText: actionText ?? 'Reintentar',
      onAction: onRetry,
    );
  }
}
