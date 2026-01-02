// lib/services/core/ui/toast_service.dart

import 'package:flutter/cupertino.dart';
import 'package:mobile/widgets/common/app_toast.dart';

enum ToastType { success, error, info, warning }

/// Servicio centralizado para mostrar notificaciones toast iOS-style
///
/// Características:
/// - Singleton pattern para acceso global
/// - Auto-dismiss con animaciones suaves
/// - Prevención de spam (dismiss previous toast)
/// - Soporte para botones de acción
/// - Diseño consistente iOS en toda la app
class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  final List<OverlayEntry> _activeToasts = [];

  /// Muestra toast de éxito
  ///
  /// Usado cuando una operación se completa exitosamente
  /// (ej: "Producto agregado al carrito")
  void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onActionTap,
    String? actionLabel,
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.success,
      duration: duration,
      onActionTap: onActionTap,
      actionLabel: actionLabel,
    );
  }

  /// Muestra toast de error
  ///
  /// Usado cuando una operación falla
  /// (ej: "Error al agregar producto")
  void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Muestra toast informativo
  ///
  /// Usado para información general o feedback
  /// (ej: "Por favor espera un momento")
  void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }

  /// Muestra toast de advertencia
  ///
  /// Usado para situaciones que requieren atención
  /// (ej: "Stock limitado")
  void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Método interno para mostrar toast
  void _showToast(
    BuildContext context, {
    required String message,
    required ToastType type,
    required Duration duration,
    VoidCallback? onActionTap,
    String? actionLabel,
  }) {
    // Prevenir spam - dismiss previous toasts
    _dismissAll();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => AppToast(
        message: message,
        type: type,
        duration: duration,
        onActionTap: onActionTap,
        actionLabel: actionLabel,
        onDismiss: () {
          entry.remove();
          _activeToasts.remove(entry);
        },
      ),
    );

    overlay.insert(entry);
    _activeToasts.add(entry);
  }

  /// Cierra todos los toasts activos
  void _dismissAll() {
    for (final toast in _activeToasts) {
      toast.remove();
    }
    _activeToasts.clear();
  }

  /// Cierra todos los toasts (método público)
  void dismissAll() {
    _dismissAll();
  }
}
