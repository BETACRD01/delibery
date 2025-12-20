// lib/widgets/ratings/star_rating_display.dart

import 'package:flutter/cupertino.dart';

/// Widget de solo lectura para mostrar calificaciones con estrellas
///
/// Características:
/// - Soporte para half-stars (rating 4.5 muestra 4.5 estrellas)
/// - Muestra contador de reseñas opcional
/// - Tamaño configurable
/// - Dos modos: compacto y expandido
///
/// Ejemplo de uso:
/// ```dart
/// StarRatingDisplay(
///   rating: 4.5,
///   reviewCount: 234,
///   size: 16,
///   showCount: true,
/// )
/// ```
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final bool showCount;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? textStyle;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 16.0,
    this.showCount = true,
    this.activeColor,
    this.inactiveColor,
    this.textStyle,
  }) : assert(rating >= 0 && rating <= 5, 'Rating must be between 0 and 5');

  @override
  Widget build(BuildContext context) {
    final activeColor = this.activeColor ?? const Color(0xFFFFB800); // Amber
    final inactiveColor = this.inactiveColor ?? CupertinoColors.systemGrey4.resolveFrom(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Estrellas
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Padding(
              padding: EdgeInsets.only(right: size * 0.1),
              child: _buildStar(index, activeColor, inactiveColor),
            );
          }),
        ),

        // Contador de reseñas
        if (showCount && reviewCount != null) ...[
          SizedBox(width: size * 0.4),
          Text(
            '($reviewCount)',
            style: textStyle ??
                TextStyle(
                  fontSize: size * 0.9,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
          ),
        ],

        // Solo rating numérico si no hay contador
        if (showCount && reviewCount == null) ...[
          SizedBox(width: size * 0.4),
          Text(
            rating.toStringAsFixed(1),
            style: textStyle ??
                TextStyle(
                  fontSize: size * 0.9,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int index, Color activeColor, Color inactiveColor) {
    final difference = rating - index;

    IconData icon;
    Color color;

    if (difference >= 1) {
      // Estrella completa
      icon = CupertinoIcons.star_fill;
      color = activeColor;
    } else if (difference > 0 && difference < 1) {
      // Media estrella
      icon = CupertinoIcons.star_lefthalf_fill;
      color = activeColor;
    } else {
      // Estrella vacía
      icon = CupertinoIcons.star;
      color = inactiveColor;
    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}

/// Variante compacta que solo muestra el número
class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double iconSize;
  final TextStyle? textStyle;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.iconSize = 14.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.star_fill,
          size: iconSize,
          color: const Color(0xFFFFB800),
        ),
        SizedBox(width: iconSize * 0.3),
        Text(
          rating.toStringAsFixed(1),
          style: textStyle ??
              TextStyle(
                fontSize: iconSize * 1.1,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (reviewCount != null) ...[
          SizedBox(width: iconSize * 0.2),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: iconSize * 0.95,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ],
    );
  }
}
