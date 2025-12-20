// lib/widgets/ratings/rating_summary_card.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'star_rating_display.dart';
import 'rating_breakdown.dart';

/// Tarjeta con resumen completo de calificaciones
///
/// Muestra:
/// - Promedio de calificación con estrellas grandes
/// - Total de reseñas
/// - Desglose por estrellas con barras de progreso
///
/// Reutilizable en perfiles de usuario, repartidor y proveedor
///
/// Ejemplo de uso:
/// ```dart
/// RatingSummaryCard(
///   averageRating: 4.8,
///   totalReviews: 234,
///   ratingBreakdown: {
///     5: 145,
///     4: 50,
///     3: 12,
///     2: 5,
///     1: 2,
///   },
/// )
/// ```
class RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;
  final VoidCallback? onViewAllTap;
  final bool showBreakdown;

  const RatingSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    this.onViewAllTap,
    this.showBreakdown = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Promedio y total
          Row(
            children: [
              // Número grande del promedio
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StarRatingDisplay(
                    rating: averageRating,
                    size: 16,
                    showCount: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews ${totalReviews == 1 ? 'reseña' : 'reseñas'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Breakdown de estrellas
              if (showBreakdown && ratingBreakdown.isNotEmpty)
                Expanded(
                  child: RatingBreakdown(
                    ratings: ratingBreakdown,
                    barHeight: 6,
                  ),
                ),
            ],
          ),

          // Botón "Ver todas las reseñas"
          if (onViewAllTap != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: onViewAllTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver todas las reseñas',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Versión compacta del summary card (sin breakdown)
class CompactRatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final String? subtitle;
  final VoidCallback? onTap;

  const CompactRatingSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.star_fill,
                    size: 20,
                    color: Color(0xFFFFB800),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle ?? '$totalReviews ${totalReviews == 1 ? 'reseña' : 'reseñas'}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
