// lib/screens/user/catalogo/pantalla_categoria_detalle.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Scaffold;
import 'package:provider/provider.dart';

import '../../../../../config/routing/rutas.dart';
import '../../../../../providers/cart/proveedor_carrito.dart';
import '../../../../../services/productos/productos_service.dart';
import '../../../../../theme/primary_colors.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../models/products/categoria_model.dart';
import '../../../models/products/producto_model.dart';
import '../../../services/core/ui/toast_service.dart';
import '../../../widgets/cards/jp_product_card.dart';
import '../../../widgets/common/carrito_floating_button.dart';
import '../../../widgets/util/add_to_cart_debounce.dart';

/// Pantalla que muestra todos los productos de una categoría específica
class PantallaCategoriaDetalle extends StatefulWidget {
  const PantallaCategoriaDetalle({super.key});

  @override
  State<PantallaCategoriaDetalle> createState() =>
      _PantallaCategoriaDetalleState();
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
      _productos = await _productosService.obtenerProductosPorCategoria(
        categoria.id,
      );
      _productosFiltrados = List.from(_productos);

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      backgroundColor: JPCupertinoColors.background(context),
      floatingActionButton: const CarritoFloatingButton(),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // AppBar iOS
            CupertinoSliverNavigationBar(
              backgroundColor: JPCupertinoColors.surface(context),
              largeTitle: Text(categoria?.nombre ?? 'Categoría'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _mostrarBusqueda,
                    child: Icon(
                      CupertinoIcons.search,
                      size: 22,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _mostrarFiltros,
                    child: Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: 22,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: JPCupertinoColors.separator(context),
                  width: 0.5,
                ),
              ),
            ),

            // Refresh Control iOS
            CupertinoSliverRefreshControl(onRefresh: _cargarProductos),

            // Body content
            _buildSliverBody(categoria),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBody(CategoriaModel? categoria) {
    if (_loading) {
      return SliverFillRemaining(
        child: Center(
          child: CupertinoActivityIndicator(
            radius: 14,
            color: JPCupertinoColors.systemGrey(context),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.wifi_slash,
                  size: 80,
                  color: JPCupertinoColors.systemRed(context),
                ),
                const SizedBox(height: 16),
                Text(
                  _error,
                  style: TextStyle(
                    color: JPCupertinoColors.secondaryLabel(context),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: _cargarProductos,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_productosFiltrados.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.bag,
                size: 80,
                color: JPCupertinoColors.systemGrey3(context),
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                style: TextStyle(
                  fontSize: 18,
                  color: JPCupertinoColors.secondaryLabel(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final producto = _productosFiltrados[index];
          return JPProductCard(
            nombre: producto.nombre,
            precio: producto.precio,
            imagenUrl: producto.imagenUrl,
            badgeType: producto.enOferta ? 'oferta' : null,
            porcentajeDescuento: producto.porcentajeDescuento.toInt(),
            onTap: () => Rutas.irAProductoDetalle(context, producto),
            onAddToCart: producto.disponible
                ? () => _agregarAlCarrito(context, producto)
                : null,
          );
        }, childCount: _productosFiltrados.length),
      ),
    );
  }

  Future<void> _agregarAlCarrito(
    BuildContext context,
    ProductoModel producto,
  ) async {
    // Debounce check
    if (!AddToCartDebounce.canAdd(producto.id.toString())) {
      ToastService().showInfo(context, 'Por favor espera un momento');
      return;
    }

    final carrito = context.read<ProveedorCarrito>();
    final success = await carrito.agregarProducto(producto);

    if (!context.mounted) return;

    if (success) {
      ToastService().showSuccess(
        context,
        '${producto.nombre} agregado',
        actionLabel: 'Ver Carrito',
        onActionTap: () => Rutas.irACarrito(context),
      );
    } else {
      ToastService().showError(
        context,
        carrito.error ?? 'Error al agregar producto',
      );
    }
  }

  void _mostrarBusqueda() {
    final searchController = TextEditingController(text: _busqueda);

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Buscar producto'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: searchController,
              autofocus: true,
              placeholder: 'Nombre del producto...',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.search, size: 20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGrey6(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                setState(() => _busqueda = searchController.text);
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Ordenar por', style: TextStyle(fontSize: 13)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _ordenamiento = 'nombre');
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Nombre (A-Z)'),
                if (_ordenamiento == 'nombre')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 18,
                      color: AppColorsPrimary.main,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _ordenamiento = 'precio_asc');
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Precio: Menor a Mayor'),
                if (_ordenamiento == 'precio_asc')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 18,
                      color: AppColorsPrimary.main,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _ordenamiento = 'precio_desc');
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Precio: Mayor a Menor'),
                if (_ordenamiento == 'precio_desc')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 18,
                      color: AppColorsPrimary.main,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _ordenamiento = 'rating');
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mejor Calificación'),
                if (_ordenamiento == 'rating')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.check_mark,
                      size: 18,
                      color: AppColorsPrimary.main,
                    ),
                  ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}
