// lib/widgets/cards/jp_product_card.dart

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🛍️ PRODUCT CARD - Card de producto unificada estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

/// Card de producto con estilo iOS consistente
///
/// Características:
/// - Width fijo 160px, BorderRadius 16px
/// - Imagen superior con AspectRatio 1.2
/// - Badge dinámico top-left (oferta/nuevo/popular)
/// - Rating badge top-right con fondo semitransparente
/// - Info: nombre (max 2 lines), precio
/// - Botón "+" circular para agregar al carrito
/// - Scale animation al presionar
class JPProductCard extends StatefulWidget {
  final String nombre;
  final double precio;
  final String? imagenUrl;
  final double? rating;
  final String? badgeType; // 'oferta', 'nuevo', 'popular'
  final int? porcentajeDescuento;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const JPProductCard({
    super.key,
    required this.nombre,
    required this.precio,
    this.imagenUrl,
    this.rating,
    this.badgeType,
    this.porcentajeDescuento,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<JPProductCard> createState() => _JPProductCardState();
}

class _JPProductCardState extends State<JPProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: JPCupertinoColors.surface(context),
            borderRadius: BorderRadius.circular(JPConstants.radiusLarge),
            boxShadow: JPConstants.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen con badges
              _buildImageWithBadges(context),
              // Info del producto
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre
                      Text(
                        widget.nombre,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: JPCupertinoColors.label(context),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Precio y botón
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '\$${widget.precio.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: JPCupertinoColors.systemBlue(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Botón agregar al carrito
                          if (widget.onAddToCart != null)
                            GestureDetector(
                              onTap: widget.onAddToCart,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: JPCupertinoColors.systemBlue(context),
                                  borderRadius: BorderRadius.circular(
                                    JPConstants.radiusButton,
                                  ),
                                ),
                                child: const Icon(
                                  CupertinoIcons.add,
                                  color: CupertinoColors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithBadges(BuildContext context) {
    return Stack(
      children: [
        // Imagen principal
        AspectRatio(
          aspectRatio: 1.2,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(JPConstants.radiusLarge),
            ),
            child: widget.imagenUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.imagenUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: JPCupertinoColors.systemGrey6(context),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: JPCupertinoColors.systemGrey6(context),
                      child: Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: JPCupertinoColors.systemGrey3(context),
                      ),
                    ),
                  )
                : Container(
                    color: JPCupertinoColors.systemGrey6(context),
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 48,
                      color: JPCupertinoColors.systemGrey3(context),
                    ),
                  ),
          ),
        ),
        // Badge tipo (oferta/nuevo/popular) - top left
        if (widget.badgeType != null)
          Positioned(top: 8, left: 8, child: _buildTypeBadge(context)),
        // Badge rating - top right
        if (widget.rating != null && widget.rating! > 0)
          Positioned(top: 8, right: 8, child: _buildRatingBadge(context)),
      ],
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (widget.badgeType) {
      case 'oferta':
        bgColor = JPCupertinoColors.systemRed(context);
        textColor = CupertinoColors.white;
        text = widget.porcentajeDescuento != null
            ? '-${widget.porcentajeDescuento}%'
            : 'OFERTA';
        break;
      case 'nuevo':
        bgColor = JPCupertinoColors.systemGreen(context);
        textColor = CupertinoColors.white;
        text = 'NUEVO';
        break;
      case 'popular':
        bgColor = JPCupertinoColors.systemOrange(context);
        textColor = CupertinoColors.white;
        text = 'POPULAR';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(JPConstants.radiusBadge),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(JPConstants.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.star_fill,
            size: 11,
            color: Color(0xFFFFD700), // Gold
          ),
          const SizedBox(width: 3),
          Text(
            widget.rating!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
