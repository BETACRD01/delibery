// lib/screens/user/catalogo/pantalla_menu_completo.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../providers/proveedor_carrito.dart';
import '../../../../../services/productos/productos_service.dart';
import '../../../models/categoria_model.dart';
import '../../../models/producto_model.dart';

/// Pantalla del menú completo con tabs por categoría
class PantallaMenuCompleto extends StatefulWidget {
  const PantallaMenuCompleto({super.key});

  @override
  State<PantallaMenuCompleto> createState() => _PantallaMenuCompletoState();
}

class _PantallaMenuCompletoState extends State<PantallaMenuCompleto>
    with SingleTickerProviderStateMixin {
  final _productosService = ProductosService();
  TabController? _tabController;

  List<CategoriaModel> _categorias = [];
  final Map<String, List<ProductoModel>> _productosPorCategoria = {};

  bool _loading = true;
  String _error = '';
  String _busqueda = '';
  String _ordenamiento = 'nombre';
  double? _filtroPrecionMin;
  double? _filtroPrecioMax;
  double? _filtroRatingMin;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Cargar categorías del backend
      _categorias = await _productosService.obtenerCategorias();

      // Cargar productos por cada categoría
      for (var categoria in _categorias) {
        final productos = await _productosService.obtenerProductosPorCategoria(
          categoria.id,
        );
        _productosPorCategoria[categoria.id] = productos;
      }

      _tabController?.dispose();
      _tabController = TabController(length: _categorias.length, vsync: this);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el menú: $e';
        _loading = false;
      });
    }
  }

  List<ProductoModel> _obtenerProductosFiltrados() {
    if (_categorias.isEmpty || _tabController == null) return [];

    final categoriaActual = _categorias[_tabController!.index];
    var productos = _productosPorCategoria[categoriaActual.id] ?? [];

    // Aplicar búsqueda
    if (_busqueda.isNotEmpty) {
      productos = productos.where((p) {
        return p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
            p.descripcion.toLowerCase().contains(_busqueda.toLowerCase());
      }).toList();
    }

    // Aplicar filtros de precio
    if (_filtroPrecionMin != null) {
      productos = productos
          .where((p) => p.precio >= _filtroPrecionMin!)
          .toList();
    }
    if (_filtroPrecioMax != null) {
      productos = productos
          .where((p) => p.precio <= _filtroPrecioMax!)
          .toList();
    }

    // Aplicar filtro de rating
    if (_filtroRatingMin != null) {
      productos = productos
          .where((p) => p.rating >= _filtroRatingMin!)
          .toList();
    }

    // Aplicar ordenamiento
    switch (_ordenamiento) {
      case 'precio_asc':
        productos.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case 'precio_desc':
        productos.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case 'rating':
        productos.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'nombre':
      default:
        productos.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
    }

    return productos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Menú Completo'),
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
        bottom: _loading || _categorias.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                onTap: (_) => setState(() {}),
                tabs: _categorias.map((categoria) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (categoria.tieneImagen)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipOval(
                              child: Image.network(
                                categoria.imagenUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.category,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.category, size: 16),
                          ),
                        Text(categoria.nombre),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
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
              onPressed: _cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_categorias.isEmpty) {
      return const Center(child: Text('No hay categorías disponibles'));
    }

    return TabBarView(
      controller: _tabController,
      children: _categorias.map((categoria) {
        return _buildCategoriaContent(categoria);
      }).toList(),
    );
  }

  Widget _buildCategoriaContent(CategoriaModel categoria) {
    final productos = _obtenerProductosFiltrados();

    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron productos',
              style: TextStyle(color: JPColors.textSecondary),
            ),
            if (_busqueda.isNotEmpty ||
                _filtroPrecionMin != null ||
                _filtroPrecioMax != null ||
                _filtroRatingMin != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _busqueda = '';
                    _filtroPrecionMin = null;
                    _filtroPrecioMax = null;
                    _filtroRatingMin = null;
                  });
                },
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: productos.length,
        itemBuilder: (context, index) {
          return _ProductoListItem(producto: productos[index]);
        },
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
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double? precioMinTemp = _filtroPrecionMin;
            double? precioMaxTemp = _filtroPrecioMax;
            double? ratingMinTemp = _filtroRatingMin;
            String ordenamientoTemp = _ordenamiento;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros y Ordenamiento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            precioMinTemp = null;
                            precioMaxTemp = null;
                            ratingMinTemp = null;
                            ordenamientoTemp = 'nombre';
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Ordenamiento
                  const Text(
                    'Ordenar por',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FiltroChip(
                        label: 'Nombre',
                        selected: ordenamientoTemp == 'nombre',
                        onTap: () =>
                            setModalState(() => ordenamientoTemp = 'nombre'),
                      ),
                      _FiltroChip(
                        label: 'Precio ↑',
                        selected: ordenamientoTemp == 'precio_asc',
                        onTap: () => setModalState(
                          () => ordenamientoTemp = 'precio_asc',
                        ),
                      ),
                      _FiltroChip(
                        label: 'Precio ↓',
                        selected: ordenamientoTemp == 'precio_desc',
                        onTap: () => setModalState(
                          () => ordenamientoTemp = 'precio_desc',
                        ),
                      ),
                      _FiltroChip(
                        label: 'Rating',
                        selected: ordenamientoTemp == 'rating',
                        onTap: () =>
                            setModalState(() => ordenamientoTemp = 'rating'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filtro de precio
                  const Text(
                    'Rango de precio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            precioMinTemp = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            precioMaxTemp = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filtro de rating
                  const Text(
                    'Calificación mínima',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FiltroChip(
                        label: '⭐ 1+',
                        selected: ratingMinTemp == 1.0,
                        onTap: () => setModalState(() => ratingMinTemp = 1.0),
                      ),
                      _FiltroChip(
                        label: '⭐ 2+',
                        selected: ratingMinTemp == 2.0,
                        onTap: () => setModalState(() => ratingMinTemp = 2.0),
                      ),
                      _FiltroChip(
                        label: '⭐ 3+',
                        selected: ratingMinTemp == 3.0,
                        onTap: () => setModalState(() => ratingMinTemp = 3.0),
                      ),
                      _FiltroChip(
                        label: '⭐ 4+',
                        selected: ratingMinTemp == 4.0,
                        onTap: () => setModalState(() => ratingMinTemp = 4.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón aplicar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filtroPrecionMin = precioMinTemp;
                          _filtroPrecioMax = precioMaxTemp;
                          _filtroRatingMin = ratingMinTemp;
                          _ordenamiento = ordenamientoTemp;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JPColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Aplicar Filtros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _ProductoListItem extends StatelessWidget {
  final ProductoModel producto;

  const _ProductoListItem({required this.producto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Rutas.irAProductoDetalle(context, producto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Imagen
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                  if (!producto.disponible)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'NO\nDISPONIBLE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto.descripcion,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        producto.precioFormateado,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: JPColors.primary,
                        ),
                      ),
                      if (producto.disponible)
                        GestureDetector(
                          onTap: () => _agregarAlCarrito(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: JPColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? JPColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : JPColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
