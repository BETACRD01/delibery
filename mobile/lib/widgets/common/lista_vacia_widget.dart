// lib/widgets/common/lista_vacia_widget.dart

import 'package:flutter/material.dart';
import '../../theme/jp_theme.dart';

/// Widget reutilizable para mostrar estado de lista vacía
/// Unifica el diseño en toda la aplicación
class ListaVaciaWidget extends StatelessWidget {
  final String mensaje;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;
  final String? subtitulo;
  final Color? iconColor;

  const ListaVaciaWidget({
    super.key,
    required this.mensaje,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
    this.subtitulo,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? JPColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? JPColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              mensaje,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: JPColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitulo!,
                style: const TextStyle(
                  fontSize: 14,
                  color: JPColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JPColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
