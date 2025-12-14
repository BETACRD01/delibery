// lib/screens/user/inicio/widgets/seccion_destacados.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../models/producto_model.dart';

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
        _buildHeader(),
        const SizedBox(height: 12),
        if (loading)
          _buildLoadingState()
        else if (productos.isEmpty)
          _buildEmptyState()
        else
          _buildProductosList(),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Más Populares',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: JPColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProductosList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ProductoCard(
          producto: productos[index],
          onTap: () => onProductoPressed?.call(productos[index]),
          onAgregarCarrito: () => onAgregarCarrito?.call(productos[index]),
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 104,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          'No hay productos destacados',
          style: TextStyle(color: JPColors.textSecondary),
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
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen del producto (OPTIMIZADA)
              _buildProductImage(),
              const SizedBox(width: 16),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: JPColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildProveedorBadge(),
                    const SizedBox(height: 4),
                    Text(
                      producto.descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: JPColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          producto.precioFormateado,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: JPColors.primary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: JPColors.secondary,
                            ),
                            Text(
                              ' ${producto.ratingFormateado}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: JPColors.textPrimary,
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
              if (onAgregarCarrito != null && producto.disponible) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onAgregarCarrito,
                  icon: const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: JPColors.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: JPColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO Y OPTIMIZADO
  Widget _buildProductImage() {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          producto.imagenUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          
          // 🚀 OPTIMIZACIÓN DE MEMORIA
          // Esto evita que la app intente cargar una imagen 4K completa en RAM
          // La reduce a un tamaño manejable (200px de ancho) antes de mostrarla
          cacheWidth: 200,
          
          // Manejo de errores de carga
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              color: JPColors.background,
              child: const Icon(
                Icons.broken_image_outlined,
                color: JPColors.textHint,
                size: 24,
              ),
            );
          },
        ),
      );
    }

    // Fallback si no hay URL (producto sin imagen)
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: JPColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.fastfood_outlined,
        color: JPColors.textHint,
        size: 32,
      ),
    );
  }

  Widget _buildProveedorBadge() {
    final tieneLogo = producto.proveedorLogoUrl != null && producto.proveedorLogoUrl!.isNotEmpty;
    final tieneNombre = (producto.proveedorNombre ?? '').isNotEmpty;
    if (!tieneLogo && !tieneNombre) return const SizedBox.shrink();

    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.grey[200],
          backgroundImage: tieneLogo ? NetworkImage(producto.proveedorLogoUrl!) : null,
          child: !tieneLogo
              ? const Icon(Icons.storefront_outlined, size: 12, color: Colors.grey)
              : null,
        ),
        if (tieneNombre) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              producto.proveedorNombre!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
