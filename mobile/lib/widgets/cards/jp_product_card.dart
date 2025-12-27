// lib/widgets/cards/jp_product_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile/theme/app_colors_primary.dart';
import 'package:mobile/theme/app_colors_secondary.dart';
import 'package:mobile/theme/app_colors_support.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🛍️ PRODUCT CARD - Card de producto unificada estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

class JPProductCard extends StatefulWidget {
  final String nombre;
  final double precio;
  final String? imagenUrl;
  final String? badgeType; // 'oferta', 'nuevo', 'popular'
  final int? porcentajeDescuento;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const JPProductCard({
    super.key,
    required this.nombre,
    required this.precio,
    this.imagenUrl,
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
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con badges
              _buildImageWithBadges(context),
              // Info del producto - Expanded para tomar el espacio restante
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nombre - con Expanded para que tome espacio disponible
                      Expanded(
                        child: Text(
                          widget.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColorsSupport.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Precio y botón
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              '\$${widget.precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColorsSupport
                                    .price, // Updated price color
                                letterSpacing: -0.5,
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
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColorsPrimary.main.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.cart_fill_badge_plus,
                                  color: AppColorsPrimary.main,
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: widget.imagenUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.imagenUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColorsSupport.surface,
                      child: const CupertinoActivityIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColorsSupport.surface,
                      child: const Icon(
                        CupertinoIcons.photo,
                        size: 40,
                        color: AppColorsSupport.textHint,
                      ),
                    ),
                  )
                : Container(
                    color: AppColorsSupport.surface,
                    child: const Icon(
                      CupertinoIcons.photo,
                      size: 40,
                      color: AppColorsSupport.textHint,
                    ),
                  ),
          ),
        ),
        // Badge tipo (oferta/nuevo/popular) - top left
        if (widget.badgeType != null)
          Positioned(top: 8, left: 8, child: _buildTypeBadge(context)),
      ],
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (widget.badgeType) {
      case 'oferta':
        bgColor = const Color(0xFFFF5252);
        textColor = CupertinoColors.white;
        text = widget.porcentajeDescuento != null
            ? '-${widget.porcentajeDescuento}%'
            : 'OFERTA';
        break;
      case 'nuevo':
        bgColor = const Color(0xFF4CAF50);
        textColor = CupertinoColors.white;
        text = 'NUEVO';
        break;
      case 'popular':
        bgColor = AppColorsSecondary.main; // Orange
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
        borderRadius: BorderRadius.circular(8),
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
}
