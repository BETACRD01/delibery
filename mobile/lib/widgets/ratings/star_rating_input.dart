// lib/widgets/ratings/star_rating_input.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Widget interactivo para seleccionar una calificación de 1-5 estrellas
///
/// Características:
/// - Soporte para tap en cada estrella
/// - Haptic feedback al seleccionar
/// - Tamaño configurable
/// - Estado habilitado/deshabilitado
///
/// Ejemplo de uso:
/// ```dart
/// StarRatingInput(
///   initialValue: 4,
///   onChanged: (rating) => print('Rating: $rating'),
///   size: 32,
/// )
/// ```
class StarRatingInput extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRatingInput({
    super.key,
    this.initialValue = 0,
    required this.onChanged,
    this.enabled = true,
    this.size = 32.0,
    this.activeColor,
    this.inactiveColor,
  }) : assert(initialValue >= 0 && initialValue <= 5, 'Initial value must be between 0 and 5');

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialValue;
  }

  @override
  void didUpdateWidget(StarRatingInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        _currentRating = widget.initialValue;
      });
    }
  }

  void _onStarTap(int rating) {
    if (!widget.enabled) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentRating = rating;
    });

    widget.onChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? const Color(0xFFFFB800); // Amber
    final inactiveColor = widget.inactiveColor ?? CupertinoColors.systemGrey4;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        final isActive = starRating <= _currentRating;

        return GestureDetector(
          onTap: () => _onStarTap(starRating),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
            child: Icon(
              isActive ? CupertinoIcons.star_fill : CupertinoIcons.star,
              size: widget.size,
              color: widget.enabled
                  ? (isActive ? activeColor : inactiveColor)
                  : CupertinoColors.systemGrey3,
            ),
          ),
        );
      }),
    );
  }
}
