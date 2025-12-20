// lib/widgets/cards/jp_category_card.dart

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/jp_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 🏷️ CATEGORY CARD - Card de categoría unificada estilo iOS
// ══════════════════════════════════════════════════════════════════════════════

/// Card de categoría con estilo iOS consistente
///
/// Características:
/// - BorderRadius 16px
/// - Sombra sutil adaptativa
/// - Imagen header con overlay de color
/// - Icono badge redondeado
/// - Título y descripción
/// - Badge contador opcional
/// - Scale animation al presionar (sin ripple)
class JPCategoryCard extends StatefulWidget {
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;
  final IconData icono;
  final Color color;
  final int? totalItems;
  final VoidCallback? onTap;

  const JPCategoryCard({
    super.key,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    required this.icono,
    required this.color,
    this.totalItems,
    this.onTap,
  });

  /// Variante compacta para listas horizontales (ej: pantalla_home)
  /// Muestra solo imagen, icono y nombre en formato vertical
  const JPCategoryCard.compact({
    super.key,
    required this.nombre,
    this.imagenUrl,
    required this.icono,
    required this.color,
    this.onTap,
  })  : descripcion = null,
        totalItems = null;

  @override
  State<JPCategoryCard> createState() => _JPCategoryCardState();
}

class _JPCategoryCardState extends State<JPCategoryCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
    // Determinar si es variante compacta (sin descripción ni totalItems)
    final isCompact = widget.descripcion == null && widget.totalItems == null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: JPCupertinoColors.surface(context),
            borderRadius: BorderRadius.circular(JPConstants.radiusLarge),
            boxShadow: JPConstants.cardShadow(context),
          ),
          child: isCompact ? _buildCompactContent(context) : _buildFullContent(context),
        ),
      ),
    );
  }

  /// Contenido completo (pantalla_super)
  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen header con overlay de color
        _buildImageHeader(context, height: 92),
        // Contenido
        Padding(
          padding: const EdgeInsets.all(JPConstants.spacingItem),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono circular + nombre
              Row(
                children: [
                  _buildIconBadge(context, size: JPConstants.iconContainerSize),
                  const SizedBox(width: JPConstants.spacingSmall),
                  Expanded(
                    child: Text(
                      widget.nombre,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: JPCupertinoColors.label(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (widget.descripcion != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.descripcion!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: JPCupertinoColors.secondaryLabel(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: JPConstants.spacingSmall - 2),
              // Footer con contador y chevron
              Row(
                children: [
                  if (widget.totalItems != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(JPConstants.radiusBadge),
                      ),
                      child: Text(
                        '${widget.totalItems} proveedor${widget.totalItems == 1 ? '' : 'es'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: JPCupertinoColors.systemGrey3(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Contenido compacto (pantalla_home - categorías horizontales)
  Widget _buildCompactContent(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen circular con icono superpuesto
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: widget.color.withValues(alpha: 0.1),
                ),
                child: widget.imagenUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: widget.imagenUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: widget.color.withValues(alpha: 0.1),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            widget.icono,
                            size: 32,
                            color: widget.color,
                          ),
                        ),
                      )
                    : Icon(
                        widget.icono,
                        size: 32,
                        color: widget.color,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Nombre
          Text(
            widget.nombre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: JPCupertinoColors.label(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Header de imagen con overlay de color tintado
  Widget _buildImageHeader(BuildContext context, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(JPConstants.radiusLarge),
        ),
      ),
      child: widget.imagenUrl != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(JPConstants.radiusLarge),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.imagenUrl!,
                    width: double.infinity,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: widget.color.withValues(alpha: 0.1),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: widget.color.withValues(alpha: 0.1),
                      child: Icon(
                        widget.icono,
                        size: 48,
                        color: widget.color,
                      ),
                    ),
                  ),
                ),
                // Overlay de color tintado
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.color.withValues(alpha: 0.3),
                        widget.color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(JPConstants.radiusLarge),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Icon(
                widget.icono,
                size: 48,
                color: widget.color,
              ),
            ),
    );
  }

  /// Badge de icono circular
  Widget _buildIconBadge(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(JPConstants.radiusButton),
      ),
      child: Icon(
        widget.icono,
        size: size * 0.6,
        color: widget.color,
      ),
    );
  }
}
