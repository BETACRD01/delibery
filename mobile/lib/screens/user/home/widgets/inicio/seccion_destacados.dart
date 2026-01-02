// lib/screens/user/inicio/widgets/seccion_destacados.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors_primary.dart';
import 'package:mobile/theme/app_colors_secondary.dart';
import 'package:mobile/theme/app_theme.dart';

import '../../../../../models/products/producto_model.dart';

/// Sección de productos destacados en la pantalla Home
class SeccionDestacados extends StatelessWidget {
  final List<ProductoModel> productos;
  final Function(ProductoModel)? onProductoPressed;
  final Function(ProductoModel)? onAgregarCarrito;
  final bool loading;

  const SeccionDestacados({
    super.key,
    required this.productos,
    this.onProductoPressed,
    this.onAgregarCarrito,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 12),
        if (loading)
          _buildLoadingState()
        else if (productos.isEmpty)
          _buildEmptyState(context)
        else
          _buildProductosList(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Más Populares',
        style: TextStyle(
          fontSize: 20, // Slightly larger for iOS feel
          fontWeight: FontWeight.bold,
          color: CupertinoColors.label.resolveFrom(context),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildProductosList() {
    return ListView.builder(
      // Use builder for clean index access
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Add vertical padding for shadows
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16), // Spacing between cards
          child: _ProductoCard(
            producto: productos[index],
            onTap: () => onProductoPressed?.call(productos[index]),
            onAgregarCarrito: () => onAgregarCarrito?.call(productos[index]),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          height: 104,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          'No hay productos destacados',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

/// Widget individual de producto
class _ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback? onTap;
  final VoidCallback? onAgregarCarrito;

  const _ProductoCard({
    required this.producto,
    this.onTap,
    this.onAgregarCarrito,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          boxShadow: AppConstants.cardShadow(context), // iOS-style shadow
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen del producto (OPTIMIZADA)
              _buildProductImage(context),
              const SizedBox(width: 16),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.label.resolveFrom(context),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildProveedorBadge(context),
                    const SizedBox(height: 6),
                    Text(
                      producto.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        height: 1.3,
                      ),
                      maxLines:
                          2, // Allow 2 lines for better description visibility
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          producto.precioFormateado,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CupertinoColors.label.resolveFrom(
                              context,
                            ), // Adaptive price
                          ),
                        ),
                        // Rating removed to clean up UI or moved, let's keep it minimal
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: AppColorsSecondary.main, // Orange
                            ),
                            Text(
                              ' ${producto.ratingFormateado}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón agregar al carrito
              const SizedBox(width: 12),
              if (onAgregarCarrito != null && producto.disponible)
                Hero(
                  tag: 'add_to_cart_${producto.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAgregarCarrito,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColorsPrimary.main.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.cart_fill_badge_plus, // iOS icon
                          color: AppColorsPrimary.main,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO Y OPTIMIZADO
  Widget _buildProductImage(BuildContext context) {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      return Hero(
        tag: 'product_image_${producto.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          child: Image.network(
            producto.imagenUrl!,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 90,
                height: 90,
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  size: 24,
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback si no hay URL (producto sin imagen)
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Icon(
        Icons.fastfood_outlined,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
        size: 32,
      ),
    );
  }

  Widget _buildProveedorBadge(BuildContext context) {
    final tieneLogo =
        producto.proveedorLogoUrl != null &&
        producto.proveedorLogoUrl!.isNotEmpty;
    final tieneNombre = (producto.proveedorNombre ?? '').isNotEmpty;
    if (!tieneLogo && !tieneNombre) return const SizedBox.shrink();

    return Row(
      children: [
        if (tieneLogo)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(producto.proveedorLogoUrl!),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(
              Icons.storefront_outlined,
              size: 16,
              color: Colors.grey,
            ),
          ),

        if (tieneNombre)
          Expanded(
            child: Text(
              producto.proveedorNombre!,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
