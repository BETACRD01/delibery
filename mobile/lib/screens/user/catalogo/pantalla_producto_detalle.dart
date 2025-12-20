// lib/screens/user/catalogo/pantalla_producto_detalle.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../providers/proveedor_carrito.dart';
import '../../../models/producto_model.dart';
import '../../../services/productos_service.dart';
import '../../../services/toast_service.dart';
import '../../../widgets/util/add_to_cart_debounce.dart';
import '../../../widgets/ratings/star_rating_display.dart';

/// Pantalla de detalle completo de un producto
class PantallaProductoDetalle extends StatefulWidget {
  const PantallaProductoDetalle({super.key});

  @override
  State<PantallaProductoDetalle> createState() =>
      _PantallaProductoDetalleState();
}

class _PantallaProductoDetalleState extends State<PantallaProductoDetalle> {
  int _cantidad = 1;
  bool _loading = false; // ✅ AGREGADO
  final ProductosService _productosService = ProductosService();
  List<ProductoModel> _sugeridos = [];
  bool _cargandoSugeridos = false;
  bool _sugerenciasCargadas = false;
  String? _ultimoProductoId;

  @override
  Widget build(BuildContext context) {
    final producto = Rutas.obtenerArgumentos<ProductoModel>(context);

    if (producto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    // Cargar sugerencias al construir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSugerencias(producto);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
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
                const SizedBox(height: 20),
                _buildSugerencias(),
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
      expandedHeight: 280,
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
      child: Icon(Icons.restaurant_menu, size: 120, color: Colors.grey[400]),
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

          // Rating y reseñas
          StarRatingDisplay(
            rating: producto.rating,
            reviewCount: producto.totalResenas,
            size: 20,
            showCount: true,
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
          backgroundImage: (logo != null && logo.isNotEmpty)
              ? NetworkImage(logo)
              : null,
          child: (logo == null || logo.isEmpty)
              ? const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: Colors.grey,
                )
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
            onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
            iconSize: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _cantidad.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (producto.proveedorNombre != null)
            _InfoItem(
              icono: Icons.store,
              titulo: 'Proveedor',
              valor: producto.proveedorNombre!,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSugerencias() {
    if (_cargandoSugeridos) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'También te puede gustar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JPColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_sugeridos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'También te puede gustar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: JPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _sugeridos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final prod = _sugeridos[index];
                return Container(
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Rutas.productoDetalle,
                        arguments: prod,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child: SizedBox(
                            height: 86,
                            width: double.infinity,
                            child:
                                prod.imagenUrl != null &&
                                    prod.imagenUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: prod.imagenUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        Container(color: Colors.grey.shade200),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: JPColors.textHint,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.fastfood,
                                      color: JPColors.textHint,
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: JPColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prod.precioFormateado,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: JPColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductoModel producto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), // ✅ CORREGIDO
            blurRadius: 8,
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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

  // ✅ CORREGIDO - Método completo con toast iOS
  void _agregarAlCarrito(ProductoModel producto) async {
    if (_loading) return;

    // Debounce check
    if (!AddToCartDebounce.canAdd(producto.id.toString())) {
      ToastService().showInfo(context, 'Por favor espera un momento');
      return;
    }

    setState(() => _loading = true);

    final carrito = context.read<ProveedorCarrito>();

    final success = await carrito.agregarProducto(
      producto,
      cantidad: _cantidad,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (success) {
      // Resetear cantidad
      setState(() => _cantidad = 1);

      if (!context.mounted) return;
      ToastService().showSuccess(
        context,
        '${producto.nombre} agregado',
        actionLabel: 'Ver Carrito',
        onActionTap: () => Rutas.irACarrito(context),
      );
    } else {
      if (!context.mounted) return;
      ToastService().showError(
        context,
        carrito.error ?? 'Error al agregar producto',
      );
    }
  }

  Future<void> _cargarSugerencias(ProductoModel producto) async {
    final mismoProducto = _ultimoProductoId == producto.id;
    if (mismoProducto && _sugerenciasCargadas) return;
    _ultimoProductoId = producto.id;
    _sugerenciasCargadas = true;

    setState(() => _cargandoSugeridos = true);

    try {
      final List<ProductoModel> candidatos = [];

      if (producto.proveedorId != null && producto.proveedorId!.isNotEmpty) {
        final porProveedor = await _productosService.obtenerProductos(
          proveedorId: producto.proveedorId,
        );
        candidatos.addAll(porProveedor);
      }

      if (producto.categoriaId.isNotEmpty) {
        final porCategoria = await _productosService.obtenerProductos(
          categoriaId: producto.categoriaId,
        );
        candidatos.addAll(porCategoria);
      }

      // Complementar con populares/ofertas para cubrir otros proveedores
      final populares = await _productosService.obtenerProductosMasPopulares(
        random: true,
      );
      candidatos.addAll(populares);
      final ofertas = await _productosService.obtenerProductosEnOferta(
        random: true,
      );
      candidatos.addAll(ofertas);

      // Filtrar duplicados y el producto actual
      final seen = <String>{producto.id};
      final dedup = <ProductoModel>[];
      for (final p in candidatos) {
        if (p.id.isEmpty) continue;
        if (seen.contains(p.id)) continue;
        seen.add(p.id);
        dedup.add(p);
      }

      // Dar prioridad a disponibles y mezclar para variar el orden
      dedup.sort((a, b) {
        if (a.disponible == b.disponible) return 0;
        return a.disponible ? -1 : 1;
      });
      dedup.shuffle(Random());

      // Limitar a 8–10 sugerencias
      final lista = dedup.where((p) => p.disponible).take(10).toList();
      if (lista.length < 6) {
        // si faltan, permitir algunos no disponibles solo para completar la grilla
        final restantes = dedup.where((p) => !p.disponible).take(2);
        lista.addAll(restantes);
      }

      if (!mounted) return;
      setState(() {
        _sugeridos = lista;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sugeridos = []);
    } finally {
      if (mounted) {
        setState(() => _cargandoSugeridos = false);
      }
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

  const _InfoItem({
    required this.icono,
    required this.titulo,
    required this.valor,
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
            style: const TextStyle(color: JPColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: JPColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
