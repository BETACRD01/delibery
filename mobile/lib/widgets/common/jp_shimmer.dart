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

// ══════════════════════════════════════════════════════════════════════════════
// 🛒 SHIMMER PRODUCT CARD - Card de producto shimmer
// ══════════════════════════════════════════════════════════════════════════════

/// Shimmer que simula una card de producto
class JPShimmerProductCard extends StatelessWidget {
  final double width;
  final double height;

  const JPShimmerProductCard({super.key, this.width = 160, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: JPConstants.subtleShadow(context),
      ),
      child: JPShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Container(
              height: height * 0.55,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            // Info del producto
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: JPCupertinoColors.systemGrey6(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Título segunda línea
                  Container(
                    width: width * 0.6,
                    height: 14,
                    decoration: BoxDecoration(
                      color: JPCupertinoColors.systemGrey6(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Precio
                  Container(
                    width: width * 0.4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: JPCupertinoColors.systemGrey6(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de shimmers de productos horizontal
class JPShimmerProductList extends StatelessWidget {
  final int itemCount;
  final double itemWidth;
  final double itemHeight;

  const JPShimmerProductList({
    super.key,
    this.itemCount = 4,
    this.itemWidth = 160,
    this.itemHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) =>
            JPShimmerProductCard(width: itemWidth, height: itemHeight),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📁 SHIMMER CATEGORY - Shimmer de categoría
// ══════════════════════════════════════════════════════════════════════════════

/// Shimmer que simula un chip de categoría
class JPShimmerCategoryItem extends StatelessWidget {
  const JPShimmerCategoryItem({super.key});

  @override
  Widget build(BuildContext context) {
    return JPShimmer(
      child: Column(
        children: [
          // Círculo de la categoría
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemGrey6(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          // Nombre
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemGrey6(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de shimmers de categorías horizontal
class JPShimmerCategoryList extends StatelessWidget {
  final int itemCount;

  const JPShimmerCategoryList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, _) => const JPShimmerCategoryItem(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 📦 SHIMMER ORDER CARD - Card de pedido shimmer
// ══════════════════════════════════════════════════════════════════════════════

/// Shimmer que simula una card de pedido
class JPShimmerOrderCard extends StatelessWidget {
  const JPShimmerOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: JPConstants.subtleShadow(context),
      ),
      child: JPShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: número de pedido + estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: JPCupertinoColors.systemGrey6(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: JPCupertinoColors.systemGrey6(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Línea de info
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Segunda línea
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Footer: precio
            Container(
              width: 80,
              height: 18,
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
// 📄 SHIMMER DETAIL SCREEN - Shimmer para pantalla de detalle
// ══════════════════════════════════════════════════════════════════════════════

/// Shimmer que simula una pantalla de detalle de producto
class JPShimmerProductDetail extends StatelessWidget {
  const JPShimmerProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: JPShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal
            Container(
              width: screenWidth,
              height: screenWidth * 0.8,
              color: JPCupertinoColors.systemGrey6(context),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Container(
                    width: screenWidth * 0.8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: JPCupertinoColors.systemGrey6(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Precio
                  Container(
                    width: 100,
                    height: 28,
                    decoration: BoxDecoration(
                      color: JPCupertinoColors.systemGrey6(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Descripción
                  ...List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: i == 3 ? screenWidth * 0.6 : double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: JPCupertinoColors.systemGrey6(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
