// lib/widgets/common/app_toast.dart

import 'package:flutter/cupertino.dart';
import '../../theme/jp_theme.dart';
import '../../services/toast_service.dart';

/// Widget de toast unificado estilo iOS
///
/// Características:
/// - Diseño consistente con iOS Human Interface Guidelines
/// - Animaciones suaves de entrada/salida (scale + fade)
/// - Auto-dismiss después de duration especificado
/// - Soporte para botones de acción opcionales
/// - Colores adaptativos según tipo (success, error, info, warning)
/// - Posicionado en la parte inferior de la pantalla
/// - Sombra y blur para profundidad
class AppToast extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final VoidCallback onDismiss;

  const AppToast({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // Animate in
    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Obtiene el color de fondo según el tipo de toast
  Color _getBackgroundColor(BuildContext context) {
    switch (widget.type) {
      case ToastType.success:
        return JPCupertinoColors.systemGreen(context);
      case ToastType.error:
        return JPCupertinoColors.systemRed(context);
      case ToastType.warning:
        return JPCupertinoColors.systemOrange(context);
      case ToastType.info:
        return JPCupertinoColors.systemBlue(context);
    }
  }

  /// Obtiene el ícono según el tipo de toast
  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return CupertinoIcons.checkmark_circle_fill;
      case ToastType.error:
        return CupertinoIcons.xmark_circle_fill;
      case ToastType.warning:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case ToastType.info:
        return CupertinoIcons.info_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: _controller,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _getBackgroundColor(context),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _getBackgroundColor(context).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ícono
                  Icon(
                    _getIcon(),
                    color: CupertinoColors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),

                  // Mensaje
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Botón de acción (opcional)
                  if (widget.actionLabel != null && widget.onActionTap != null) ...[
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      color: CupertinoColors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        widget.onActionTap!();
                        widget.onDismiss();
                      },
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
