// lib/widgets/common/jp_shimmer.dart

import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 💫 SHIMMER iOS-like LOADING EFFECTS
// ══════════════════════════════════════════════════════════════════════════════

/// Widget shimmer base con estilo iOS adaptativo a dark mode
class JPShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const JPShimmer({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    // Colores adaptativos según dark mode
    final baseColor = JPCupertinoColors.systemGrey6(context);
    final highlightColor = JPCupertinoColors.systemGrey5(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📦 SHIMMER BOX - Contenedor shimmer simple
// ══════════════════════════════════════════════════════════════════════════════

/// Contenedor shimmer simple con borderRadius personalizable
class JPShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;

  const JPShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = JPConstants.radiusCard,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return JPShimmer(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: JPCupertinoColors.systemGrey6(context),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📋 SHIMMER CARD - Card completa shimmer
// ══════════════════════════════════════════════════════════════════════════════

/// Card completa con efecto shimmer (simula una card real)
class JPShimmerCard extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const JPShimmerCard({
    super.key,
    this.width,
    this.height = 200,
    this.borderRadius = JPConstants.radiusCard,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(JPConstants.spacingItem),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: JPConstants.subtleShadow(context),
      ),
      child: JPShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen o header
            Container(
              height: height * 0.5,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(borderRadius - 4),
              ),
            ),
            const SizedBox(height: JPConstants.spacingItem),
            // Título
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: JPConstants.spacingSmall),
            // Subtítulo
            Container(
              width: double.infinity * 0.6,
              height: 12,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📜 SHIMMER LIST - Lista de shimmers (horizontal o vertical)
// ══════════════════════════════════════════════════════════════════════════════

/// Lista de contenedores shimmer (horizontal o vertical)
class JPShimmerList extends StatelessWidget {
  final int itemCount;
  final double? itemWidth;
  final double itemHeight;
  final double spacing;
  final double borderRadius;
  final EdgeInsets? padding;
  final Axis scrollDirection;

  const JPShimmerList({
    super.key,
    required this.itemCount,
    this.itemWidth,
    required this.itemHeight,
    this.spacing = JPConstants.spacingItem,
    this.borderRadius = JPConstants.radiusCard,
    this.padding,
    this.scrollDirection = Axis.vertical,
  });

  /// Variante horizontal conveniente
  const JPShimmerList.horizontal({
    super.key,
    required this.itemCount,
    required this.itemWidth,
    required this.itemHeight,
    this.spacing = JPConstants.spacingItem,
    this.borderRadius = JPConstants.radiusCard,
    this.padding,
  }) : scrollDirection = Axis.horizontal;

  /// Variante vertical conveniente
  const JPShimmerList.vertical({
    super.key,
    required this.itemCount,
    this.itemWidth,
    required this.itemHeight,
    this.spacing = JPConstants.spacingItem,
    this.borderRadius = JPConstants.radiusCard,
    this.padding,
  }) : scrollDirection = Axis.vertical;

  @override
  Widget build(BuildContext context) {
    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: itemHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding:
              padding ??
              const EdgeInsets.symmetric(
                horizontal: JPConstants.spacingHorizontal,
              ),
          itemCount: itemCount,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: (_, _) => JPShimmerBox(
            width: itemWidth ?? 160,
            height: itemHeight,
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    // Vertical
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(JPConstants.spacingHorizontal),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: (_, _) => JPShimmerBox(
        width: itemWidth ?? double.infinity,
        height: itemHeight,
        borderRadius: borderRadius,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎴 SHIMMER GRID - Grid de shimmers
// ══════════════════════════════════════════════════════════════════════════════

/// Grid de contenedores shimmer
class JPShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double itemHeight;
  final double spacing;
  final double borderRadius;
  final EdgeInsets? padding;

  const JPShimmerGrid({
    super.key,
    required this.itemCount,
    this.crossAxisCount = 2,
    required this.itemHeight,
    this.spacing = JPConstants.spacingItem,
    this.borderRadius = JPConstants.radiusCard,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(JPConstants.spacingHorizontal),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1 / (itemHeight / 160), // Aproximado
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => JPShimmerBox(
        width: double.infinity,
        height: itemHeight,
        borderRadius: borderRadius,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📝 SHIMMER TEXT - Líneas de texto shimmer
// ══════════════════════════════════════════════════════════════════════════════

/// Líneas de texto shimmer (para simular textos cargando)
class JPShimmerText extends StatelessWidget {
  final int lines;
  final double? width;
  final double lineHeight;
  final double spacing;

  const JPShimmerText({
    super.key,
    this.lines = 3,
    this.width,
    this.lineHeight = 12,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return JPShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          // Última línea más corta
          final lineWidth = index == lines - 1
              ? (width ?? double.infinity) * 0.6
              : (width ?? double.infinity);

          return Container(
            width: lineWidth,
            height: lineHeight,
            margin: index < lines - 1
                ? EdgeInsets.only(bottom: spacing)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemGrey6(context),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
