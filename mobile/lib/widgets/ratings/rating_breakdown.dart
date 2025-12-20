// lib/widgets/ratings/rating_breakdown.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Widget que muestra la distribución de calificaciones por estrellas
///
/// Muestra barras horizontales con el porcentaje y conteo de cada nivel
///
/// Ejemplo de uso:
/// ```dart
/// RatingBreakdown(
///   ratings: {
///     5: 145,
///     4: 50,
///     3: 12,
///     2: 5,
///     1: 2,
///   },
/// )
/// ```
class RatingBreakdown extends StatelessWidget {
  final Map<int, int> ratings;
  final double barHeight;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingBreakdown({
    super.key,
    required this.ratings,
    this.barHeight = 8.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = ratings.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final activeColor = this.activeColor ?? const Color(0xFFFFB800);
    final inactiveColor = this.inactiveColor ?? CupertinoColors.systemGrey5.resolveFrom(context);

    return Column(
      children: [5, 4, 3, 2, 1].map((stars) {
        final count = ratings[stars] ?? 0;
        final percentage = total > 0 ? (count / total) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Número de estrellas
              SizedBox(
                width: 16,
                child: Text(
                  '$stars',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Icono estrella
              Icon(
                CupertinoIcons.star_fill,
                size: 12,
                color: activeColor,
              ),
              const SizedBox(width: 8),

              // Barra de progreso
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: inactiveColor,
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: barHeight,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Porcentaje
              SizedBox(
                width: 42,
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),

              // Conteo
              SizedBox(
                width: 36,
                child: Text(
                  '($count)',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
