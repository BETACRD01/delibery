// lib/screens/user/super/pantalla_detalle_restaurante.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/jp_theme.dart';
import '../../../models/proveedor.dart';
import '../../../models/producto_model.dart';
import '../../../services/productos/productos_service.dart';
import '../../../config/rutas.dart';

/// Pantalla de detalle de un restaurante/proveedor
/// Muestra información completa y catálogo de productos
class PantallaDetalleRestaurante extends StatefulWidget {
  const PantallaDetalleRestaurante({super.key});

  @override
  State<PantallaDetalleRestaurante> createState() =>
      _PantallaDetalleRestauranteState();
}

class _PantallaDetalleRestauranteState
    extends State<PantallaDetalleRestaurante> {
  final _productosService = ProductosService();
  List<ProductoModel> _productos = [];
  bool _loading = true;
  String? _error;
  ProveedorModel? _proveedor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_proveedor == null) {
      _proveedor = Rutas.obtenerArgumentos<ProveedorModel>(context);
      _cargarProductos();
    }
  }

  Future<void> _cargarProductos() async {
    if (_proveedor == null) {
      setState(() {
        _error = 'No se recibió información del restaurante';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Cargar productos del proveedor
      final productos = await _productosService.obtenerProductosPorProveedor(
        _proveedor!.id.toString(),
      );

      setState(() {
        _productos = productos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar productos: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRestaurante(),
                const SizedBox(height: 24),
                _buildHorarios(),
                const SizedBox(height: 24),
                _buildUbicacion(),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Título de productos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Menú',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: JPColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_productos.length} productos)',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Lista de productos
          _buildProductosList(),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: JPColors.textPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de portada
            Container(
              color: JPColors.background,
              child:
                  _proveedor!.logoUrl != null && _proveedor!.logoUrl!.isNotEmpty
                  ? Image.network(
                      _proveedor!.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),

            // Gradiente
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
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Badge de estado
            Positioned(top: 80, right: 16, child: _buildEstadoBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _proveedor!.nombre,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge() {
    final estaAbierto = _proveedor!.estaAbierto ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: estaAbierto ? Colors.green[600] : Colors.red[600],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              estaAbierto ? 'ABIERTO AHORA' : 'CERRADO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRestaurante() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre y verificado
          Row(
            children: [
              Expanded(
                child: Text(
                  _proveedor!.nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: JPColors.textPrimary,
                  ),
                ),
              ),
              if (_proveedor!.verificado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Verificado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Tipo de proveedor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: JPColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getTipoProveedorDisplay(_proveedor!.tipoProveedor),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: JPColors.primary,
              ),
            ),
          ),

          if (_proveedor!.descripcion != null &&
              _proveedor!.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _proveedor!.descripcion!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorarios() {
    if (_proveedor!.horarioApertura == null ||
        _proveedor!.horarioCierre == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: JPColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horario de atención',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: JPColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_proveedor!.horarioApertura} - ${_proveedor!.horarioCierre}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
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

  Widget _buildUbicacion() {
    if (_proveedor!.direccion == null && _proveedor!.ciudad == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: JPColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: JPColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_proveedor!.direccion != null)
                    Text(
                      _proveedor!.direccion!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  if (_proveedor!.ciudad != null)
                    Text(
                      _proveedor!.ciudad!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductosList() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(
          child: CupertinoActivityIndicator(radius: 14),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarProductos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_productos.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay productos disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final producto = _productos[index];
          return _ProductoCard(
            producto: producto,
            estaAbierto: _proveedor!.estaAbierto ?? false,
          );
        }, childCount: _productos.length),
      ),
    );
  }

  String _getTipoProveedorDisplay(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'restaurante':
        return 'Restaurante';
      case 'farmacia':
        return 'Farmacia';
      case 'supermercado':
        return 'Supermercado';
      case 'tienda':
        return 'Tienda';
      default:
        return 'Comercio';
    }
  }
}

/// Tarjeta de producto en el catálogo del restaurante
class _ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  final bool estaAbierto;

  const _ProductoCard({required this.producto, required this.estaAbierto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Rutas.irAProductoDetalle(context, producto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 100,
                height: 100,
                color: JPColors.background,
                child:
                    producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                    ? Image.network(
                        producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.fastfood_outlined,
                          color: JPColors.textHint,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.fastfood_outlined,
                        color: JPColors.textHint,
                        size: 32,
                      ),
              ),
            ),

            // Información del producto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: JPColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (producto.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        producto.descripcion,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          producto.precioFormateado,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: JPColors.primary,
                          ),
                        ),
                        const Spacer(),
                        if (producto.disponible && estaAbierto)
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: JPColors.primary,
                          )
                        else
                          Text(
                            'No disponible',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
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
    );
  }
}
