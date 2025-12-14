// lib/widgets/common/loading_widget.dart

import 'package:flutter/material.dart';
import '../../theme/jp_theme.dart';

/// Widget reutilizable para estados de carga
class LoadingWidget extends StatelessWidget {
  final String? mensaje;
  final bool showMessage;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.mensaje,
    this.showMessage = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? JPColors.primary,
            strokeWidth: 3,
          ),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              mensaje ?? 'Cargando...',
              style: const TextStyle(
                fontSize: 14,
                color: JPColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de loading pequeño para usar en botones o cards
class LoadingSmall extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingSmall({
    super.key,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? JPColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}
