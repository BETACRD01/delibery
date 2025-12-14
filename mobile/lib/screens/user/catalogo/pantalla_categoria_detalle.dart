// lib/screens/user/catalogo/pantalla_categoria_detalle.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../providers/proveedor_carrito.dart';
import '../../../models/categoria_model.dart';
import '../../../models/producto_model.dart';
import '../../../../../services/productos_service.dart';

/// Pantalla que muestra todos los productos de una categoría específica
class PantallaCategoriaDetalle extends StatefulWidget {
  const PantallaCategoriaDetalle({super.key});

  @override
  State<PantallaCategoriaDetalle> createState() => _PantallaCategoriaDetalleState();
}

class _PantallaCategoriaDetalleState extends State<PantallaCategoriaDetalle> {
  final _productosService = ProductosService();
  
  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  bool _loading = true;
  String _error = '';
  
  // Filtros
  String _busqueda = '';
  String _ordenamiento = 'nombre';
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final categoria = Rutas.obtenerArgumentos<CategoriaModel>(context);
    
    if (categoria == null) {
      setState(() {
        _error = 'Categoría no encontrada';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Llamada real al backend
      _productos = await _productosService.obtenerProductosPorCategoria(categoria.id);
      _productosFiltrados = List.from(_productos);
      
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar productos: $e';
        _loading = false;
      });
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        if (_busqueda.isNotEmpty) {
          final nombreLower = producto.nombre.toLowerCase();
          final busquedaLower = _busqueda.toLowerCase();
          if (!nombreLower.contains(busquedaLower)) {
            return false;
          }
        }
        return true;
      }).toList();

      switch (_ordenamiento) {
        case 'precio_asc':
          _productosFiltrados.sort((a, b) => a.precio.compareTo(b.precio));
          break;
        case 'precio_desc':
          _productosFiltrados.sort((a, b) => b.precio.compareTo(a.precio));
          break;
        case 'rating':
          _productosFiltrados.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'nombre':
        default:
          _productosFiltrados.sort((a, b) => a.nombre.compareTo(b.nombre));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoria = Rutas.obtenerArgumentos<CategoriaModel>(context);

    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        title: Text(categoria?.nombre ?? 'Categoría'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _mostrarBusqueda,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: _buildBody(categoria),
    );
  }

  Widget _buildBody(CategoriaModel? categoria) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: JPColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarProductos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_productosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron productos',
              style: TextStyle(color: JPColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarProductos,
      child: Column(
        children: [
          // Header con información de la categoría
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_dp(context, 16)),
            decoration: BoxDecoration(
              color: JPColors.primary.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                // Imagen circular de la categoría
                Container(
                  width: _dp(context, 50),
                  height: _dp(context, 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipOval(
                    child: categoria?.tieneImagen == true
                        ? Image.network(
                            categoria!.imagenUrl!,
                            fit: BoxFit.cover,
                            width: _dp(context, 50),
                            height: _dp(context, 50),
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.category,
                              color: Colors.grey[400],
                              size: _dp(context, 24),
                            ),
                          )
                        : Icon(
                            Icons.category,
                            color: Colors.grey[400],
                            size: _dp(context, 24),
                          ),
                  ),
                ),
                SizedBox(width: _dp(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria?.nombre ?? '',
                        style: TextStyle(
                          fontSize: _sp(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_productosFiltrados.length} productos disponibles',
                        style: TextStyle(
                          color: JPColors.textSecondary,
                          fontSize: _sp(context, 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(_dp(context, 16)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: _dp(context, 16),
                mainAxisSpacing: _dp(context, 16),
              ),
              itemCount: _productosFiltrados.length,
              itemBuilder: (context, index) {
                return _ProductoCard(producto: _productosFiltrados[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarBusqueda() {
    showDialog(
      context: context,
      builder: (context) {
        String busquedaTemp = _busqueda;
        return AlertDialog(
          title: const Text('Buscar producto'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nombre del producto...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => busquedaTemp = value,
            onSubmitted: (value) {
              setState(() => _busqueda = value);
              _aplicarFiltros();
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _busqueda = busquedaTemp);
                _aplicarFiltros();
                Navigator.pop(context);
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(_dp(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: _sp(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: _dp(context, 16)),
              _OpcionOrdenamiento(
                titulo: 'Nombre (A-Z)',
                valor: 'nombre',
                seleccionado: _ordenamiento == 'nombre',
                onTap: () {
                  setState(() => _ordenamiento = 'nombre');
                  _aplicarFiltros();
                  Navigator.pop(context);
                },
              ),
              _OpcionOrdenamiento(
                titulo: 'Precio: Menor a Mayor',
                valor: 'precio_asc',
                seleccionado: _ordenamiento == 'precio_asc',
                onTap: () {
                  setState(() => _ordenamiento = 'precio_asc');
                  _aplicarFiltros();
                  Navigator.pop(context);
                },
              ),
              _OpcionOrdenamiento(
                titulo: 'Precio: Mayor a Menor',
                valor: 'precio_desc',
                seleccionado: _ordenamiento == 'precio_desc',
                onTap: () {
                  setState(() => _ordenamiento = 'precio_desc');
                  _aplicarFiltros();
                  Navigator.pop(context);
                },
              ),
              _OpcionOrdenamiento(
                titulo: 'Mejor Calificación',
                valor: 'rating',
                seleccionado: _ordenamiento == 'rating',
                onTap: () {
                  setState(() => _ordenamiento = 'rating');
                  _aplicarFiltros();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _ProductoCard extends StatelessWidget {
  final ProductoModel producto;

  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Rutas.irAProductoDetalle(context, producto),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_dp(context, 12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, _dp(context, 4)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(_dp(context, 12))),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(_dp(context, 12))),
                        child: _buildProductoImagen(context),
                      ),
                    ),
                    if (!producto.disponible)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(_dp(context, 12)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'NO DISPONIBLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: _sp(context, 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Información del producto
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(_dp(context, 8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _sp(context, 12),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: _dp(context, 2)),
                    _buildProveedorBadge(context),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          producto.precioFormateado,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _sp(context, 14),
                            color: JPColors.primary,
                          ),
                        ),
                        if (producto.disponible)
                          GestureDetector(
                            onTap: () => _agregarAlCarrito(context),
                            child: Container(
                              padding: EdgeInsets.all(_dp(context, 5)),
                              decoration: const BoxDecoration(
                                color: JPColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                size: _dp(context, 14),
                                color: Colors.white,
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
        )
      ),
    );
  }

  Widget _buildProductoImagen(BuildContext context) {
    final url = producto.imagenUrl;
    if (url == null || url.isEmpty) {
      return Center(
        child: Icon(
          Icons.restaurant_menu,
          size: _dp(context, 48),
          color: Colors.grey[400],
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: _dp(context, 36),
          color: Colors.grey[400],
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  void _agregarAlCarrito(BuildContext context) async {
    final carrito = context.read<ProveedorCarrito>();

    final success = await carrito.agregarProducto(producto);

    // Solo mostrar mensaje en caso de error
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(carrito.error ?? 'Error al agregar producto'),
          backgroundColor: JPColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildProveedorBadge(BuildContext context) {
    final tieneLogo = producto.proveedorLogoUrl != null && producto.proveedorLogoUrl!.isNotEmpty;
    final tieneNombre = (producto.proveedorNombre ?? '').isNotEmpty;
    if (!tieneLogo && !tieneNombre) return const SizedBox.shrink();

    return Row(
      children: [
        CircleAvatar(
          radius: _dp(context, 9),
          backgroundColor: Colors.grey[200],
          backgroundImage: tieneLogo ? NetworkImage(producto.proveedorLogoUrl!) : null,
          child: !tieneLogo
              ? Icon(Icons.storefront_outlined, size: _dp(context, 11), color: Colors.grey)
              : null,
        ),
        if (tieneNombre) ...[
          SizedBox(width: _dp(context, 6)),
          Expanded(
            child: Text(
              producto.proveedorNombre!,
              style: TextStyle(
                fontSize: _sp(context, 10.5),
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

class _OpcionOrdenamiento extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionOrdenamiento({
    required this.titulo,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        titulo,
        style: TextStyle(fontSize: _sp(context, 14)),
      ),
      trailing: seleccionado
          ? const Icon(Icons.check, color: JPColors.primary)
          : null,
      selected: seleccionado,
      onTap: onTap,
    );
  }
}

// ===================================================================
// Helpers de adaptación responsive (dp/sp)
// ===================================================================
double _baseScale(BuildContext context) {
  final shortest = MediaQuery.of(context).size.shortestSide;
  return (shortest / 375).clamp(0.85, 1.2);
}

double _dp(BuildContext context, double base) {
  return base * _baseScale(context);
}

double _sp(BuildContext context, double base) {
  final scaler = MediaQuery.textScalerOf(context);
  final baseScaled = base * _baseScale(context);
  final scaled = scaler.scale(baseScaled).clamp(baseScaled * 0.85, baseScaled * 1.3);
  return scaled;
}
