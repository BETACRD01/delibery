// lib/screens/user/catalogo/pantalla_producto_detalle.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../providers/proveedor_carrito.dart';
import '../../../models/producto_model.dart';

/// Pantalla de detalle completo de un producto
class PantallaProductoDetalle extends StatefulWidget {
  const PantallaProductoDetalle({super.key});

  @override
  State<PantallaProductoDetalle> createState() => _PantallaProductoDetalleState();
}

class _PantallaProductoDetalleState extends State<PantallaProductoDetalle> {
  int _cantidad = 1;
  bool _loading = false; // ✅ AGREGADO

  @override
  Widget build(BuildContext context) {
    final producto = Rutas.obtenerArgumentos<ProductoModel>(context);

    if (producto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Producto no encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: JPColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen
          _buildSliverAppBar(producto),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(producto),
                const Divider(height: 32),
                _buildDescripcion(producto),
                const SizedBox(height: 24),
                _buildInformacionAdicional(producto),
                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(producto),
    );
  }

  Widget _buildSliverAppBar(ProductoModel producto) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: JPColors.textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen del producto
            Container(
              color: Colors.grey[100],
              child: producto.imagenUrl != null
                  ? Image.network(
                      producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),

            // Gradiente para mejorar legibilidad
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7), // ✅ CORREGIDO
                    ],
                  ),
                ),
              ),
            ),

            // Badge de disponibilidad
            if (!producto.disponible)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: JPColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NO DISPONIBLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.restaurant_menu,
        size: 120,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildHeader(ProductoModel producto) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del producto
          Text(
            producto.nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildProveedorBadge(producto),
          const SizedBox(height: 12),

          // Categoría
          if (producto.categoriaNombre != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: JPColors.primary.withValues(alpha: 0.1), // ✅ CORREGIDO
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                producto.categoriaNombre!,
                style: const TextStyle(
                  color: JPColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Rating y reseñas
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < producto.rating.floor()
                      ? Icons.star
                      : (index < producto.rating
                          ? Icons.star_half
                          : Icons.star_border),
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                producto.ratingFormateado,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Precio
          Row(
            children: [
              Text(
                producto.precioFormateado,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: JPColors.primary,
                ),
              ),
              const Spacer(),
              // Selector de cantidad
              _buildCantidadSelector(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProveedorBadge(ProductoModel producto) {
    final logo = producto.proveedorLogoUrl;
    final nombre = producto.proveedorNombre;
    if ((logo == null || logo.isEmpty) && (nombre == null || nombre.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey[200],
          backgroundImage: (logo != null && logo.isNotEmpty) ? NetworkImage(logo) : null,
          child: (logo == null || logo.isEmpty)
              ? const Icon(Icons.storefront_outlined, size: 16, color: Colors.grey)
              : null,
        ),
        if (nombre != null && nombre.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: JPColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCantidadSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _cantidad > 1
                ? () => setState(() => _cantidad--)
                : null,
            iconSize: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _cantidad.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _cantidad++),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcion(ProductoModel producto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.descripcion,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionAdicional(ProductoModel producto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información adicional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (producto.proveedorNombre != null)
            _InfoItem(
              icono: Icons.store,
              titulo: 'Proveedor',
              valor: producto.proveedorNombre!,
            ),
          _InfoItem(
            icono: Icons.category,
            titulo: 'Categoría',
            valor: producto.categoriaNombre ?? 'Sin categoría',
          ),
          _InfoItem(
            icono: producto.disponible
                ? Icons.check_circle
                : Icons.cancel,
            titulo: 'Estado',
            valor: producto.disponible ? 'Disponible' : 'No disponible',
            valorColor: producto.disponible
                ? JPColors.success
                : JPColors.error,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductoModel producto) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // ✅ CORREGIDO
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: JPColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${(producto.precio * _cantidad).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: JPColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón agregar al carrito
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: producto.disponible && !_loading
                    ? () => _agregarAlCarrito(producto)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JPColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.shopping_cart),
                label: Text(
                  _loading ? 'Agregando...' : 'Agregar al carrito',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CORREGIDO - Método completo
  void _agregarAlCarrito(ProductoModel producto) async {
    if (_loading) return;

    setState(() => _loading = true);

    final carrito = context.read<ProveedorCarrito>();
    
    final success = await carrito.agregarProducto(
      producto,
      cantidad: _cantidad,
    );

    setState(() => _loading = false);

    if (success && mounted) {
      // Resetear cantidad sin mostrar mensaje
      setState(() => _cantidad = 1);
    } else if (!success && mounted) {
      // Solo mostrar mensaje en caso de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(carrito.error ?? 'Error al agregar producto'),
          backgroundColor: JPColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _InfoItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color? valorColor;

  const _InfoItem({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, size: 20, color: JPColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            '$titulo:',
            style: const TextStyle(
              color: JPColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valorColor ?? JPColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
