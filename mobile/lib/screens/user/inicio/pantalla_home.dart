// lib/screens/user/inicio/pantalla_home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/jp_theme.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../controllers/user/perfil_controller.dart';
import '../../../config/rutas.dart';
import '../../../controllers/user/home_controller.dart';
import '../../../models/producto_model.dart';
import '../busqueda/pantalla_busqueda.dart';
import '../../../providers/notificaciones_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/inicio/home_app_bar.dart';

// Widgets de la UI
import 'widgets/inicio/seccion_categorias.dart';
import 'widgets/inicio/seccion_promociones.dart';

/// Pantalla Home del usuario
class PantallaHome extends StatefulWidget {
  const PantallaHome({super.key});

  @override
  State<PantallaHome> createState() => _PantallaHomeState();
}

// ════════════════════════════════════════════════════════════════════════════
// 📦 BLOQUE 1: Estado y Lógica Principal (_PantallaHomeState)
// ════════════════════════════════════════════════════════════════════════════

class _PantallaHomeState extends State<PantallaHome> {
  // 1. Uso de 'late final' para inicialización en initState
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    
    // 2. Cargamos datos y perfil después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ⚠️ CORRECCIÓN del LINTER: Verificación de 'mounted' antes de usar context.
      if (!mounted) return; 
      
      _homeController.cargarDatos();
      
      // Cargar perfil si es necesario (uso síncrono de read).
      final perfilController = context.read<PerfilController>();
      if (perfilController.perfil == null) {
        perfilController.cargarDatosCompletos();
      }
    });
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Inyección del HomeController y estructura de la pantalla.
    return ChangeNotifierProvider.value(
      value: _homeController,
      child: Scaffold(
        backgroundColor: JPColors.background,
        // Extracción del FAB
        floatingActionButton: const _CarritoFAB(),
        // Extracción del cuerpo principal, pasando el callback del carrito
        body: _HomeContent(
          onAgregarCarrito: _agregarProductoAlCarrito,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🛒 LÓGICA DE GESTIÓN DEL CARRITO (Se mantiene en el State por el SnackBar)
  // ════════════════════════════════════════════════════════════════════════════
  
  Future<void> _agregarProductoAlCarrito(BuildContext context, dynamic producto) async {
    // Lectura del Provider y ScaffoldMessenger ANTES del await
    final carrito = context.read<ProveedorCarrito>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await carrito.agregarProducto(producto);

    // Verificación de 'mounted' después del await
    if (!mounted) return;

    // Solo mostrar mensaje en caso de error
    if (!success) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(carrito.error ?? 'Error al agregar producto')),
            ],
          ),
          backgroundColor: JPColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 📦 BLOQUE 2: Contenido Principal (Body) - CORREGIDO
// ════════════════════════════════════════════════════════════════════════════

/// Widget que contiene el CustomScrollView y todas las secciones de la Home.
class _HomeContent extends StatelessWidget {
  // Callback para agregar producto al carrito (delega la lógica al State)
  final Function(BuildContext, dynamic) onAgregarCarrito;

  const _HomeContent({required this.onAgregarCarrito});

  // Método para mostrar el modal de búsqueda
  void _mostrarBusqueda(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        // Tamaño inicial del modal, ajustado para ser compacto
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            // CORRECCIÓN: Se revierte la línea problemática.
            // Si necesitas que el PantallaBusqueda use el scrollController,
            // debes añadirlo a su constructor en pantalla_busqueda.dart.
            child: const PantallaBusqueda(),
          );
        },
      ),
    );
  }

  // Método para mostrar diálogo de configuración de permisos
  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificacionesProvider>();
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        return RefreshIndicator(
          onRefresh: controller.refrescar,
          color: JPColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              HomeAppBar(
                unreadCount: inbox.noLeidas.length,
                onNotificationTap: () => Rutas.irANotificaciones(context),
                onSearchTap: () => _mostrarBusqueda(context),
                logoAssetPath: 'assets/images/Beta.png',
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: SeccionCategorias(
                    categorias: controller.categorias,
                    loading: controller.loading,
                    onCategoriaPressed: (cat) => Rutas.irACategoriaDetalle(context, cat),
                    onVerTodo: () => Rutas.irATodasCategorias(context),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: SeccionPromociones(
                    promociones: controller.promociones,
                    loading: controller.loading,
                    onPromocionPressed: (promo) => Rutas.irAPromocionDetalle(context, promo),
                  ),
                ),
              ),

              if (controller.productosEnOferta.isNotEmpty || controller.loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: _SeccionProductos(
                      titulo: '🔥 Ofertas Especiales',
                      productos: controller.productosEnOferta,
                      loading: controller.loading,
                      badgeType: 'oferta',
                      onProductoPressed: (prod) => Rutas.irAProductoDetalle(context, prod),
                      onAgregarCarrito: (prod) => onAgregarCarrito(context, prod),
                      onVerTodo: controller.productosEnOferta.length > 5
                          ? () => debugPrint('Ver todas ofertas')
                          : null,
                    ),
                  ),
                ),

              if (controller.productosMasPopulares.isNotEmpty || controller.loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: _SeccionProductos(
                      titulo: '⭐ Más Populares',
                      productos: controller.productosMasPopulares,
                      loading: controller.loading,
                      badgeType: 'popular',
                      onProductoPressed: (prod) => Rutas.irAProductoDetalle(context, prod),
                      onAgregarCarrito: (prod) => onAgregarCarrito(context, prod),
                      onVerTodo: controller.productosMasPopulares.length > 5
                          ? () => debugPrint('Ver todos populares')
                          : null,
                    ),
                  ),
                ),

              if (controller.productosNovedades.isNotEmpty || controller.loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 70),
                    child: _SeccionProductos(
                      titulo: '✨ Novedades',
                      productos: controller.productosNovedades,
                      loading: controller.loading,
                      badgeType: 'nuevo',
                      onProductoPressed: (prod) => Rutas.irAProductoDetalle(context, prod),
                      onAgregarCarrito: (prod) => onAgregarCarrito(context, prod),
                      onVerTodo: controller.productosNovedades.length > 5
                          ? () => debugPrint('Ver todas novedades')
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 📦 BLOQUE 4: Widget de Sección de Productos con Título (Sin cambios)
// ════════════════════════════════════════════════════════════════════════════

/// Widget que agrupa un título con lista de productos
class _SeccionProductos extends StatelessWidget {
  final String titulo;
  final List<dynamic> productos;
  final bool loading;
  final Function(dynamic)? onProductoPressed;
  final Function(dynamic)? onAgregarCarrito;
  final VoidCallback? onVerTodo;
  final String? badgeType; // 'oferta', 'popular', 'nuevo'

  const _SeccionProductos({
    required this.titulo,
    required this.productos,
    this.loading = false,
    this.onProductoPressed,
    this.onAgregarCarrito,
    this.onVerTodo,
    this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: JPColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lista de productos
        if (loading)
          _buildLoadingState(context)
        else if (productos.isEmpty)
          _buildEmptyState()
        else
          _buildProductosList(context),
      ],
    );
  }

  Widget _buildProductosList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = width >= 700 ? 14.0 : 10.0;
        final cardWidth = width < 400 ? 180.0 : (width < 800 ? 200.0 : 220.0);
        final cardHeight = cardWidth * 1.3;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: productos.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final producto = productos[index];
              return SizedBox(
                width: cardWidth,
                child: _ProductCard(
                  producto: producto,
                  badgeType: badgeType,
                  onTap: () => onProductoPressed?.call(producto),
                  onAdd: onAgregarCarrito != null ? () => onAgregarCarrito!(producto) : null,
                  cardWidth: cardWidth,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = width >= 700 ? 14.0 : 10.0;
        final cardWidth = width < 400 ? 180.0 : (width < 800 ? 200.0 : 220.0);
        final cardHeight = cardWidth * 1.3;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (_, __) {
              return Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text(
          'No hay productos en $titulo',
          style: const TextStyle(color: JPColors.textSecondary),
        ),
      ),
    );
  }

}

class _ProductCard extends StatelessWidget {
  final dynamic producto;
  final String? badgeType;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final double cardWidth;

  const _ProductCard({
    required this.producto,
    this.badgeType,
    this.onTap,
    this.onAdd,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = (producto is ProductoModel) ? producto.nombre : (producto.nombre ?? 'Producto');
    final precioValue = (producto is ProductoModel) ? producto.precio : (producto.precio ?? 0);
    final ratingValue = (producto is ProductoModel) ? producto.rating : (producto.rating ?? 0);
    final precio = (precioValue is num) ? precioValue.toDouble() : 0.0;
    final rating = (ratingValue is num) ? ratingValue.toDouble() : 0.0;
    final tiempoEntrega = (producto is ProductoModel)
        ? producto.tiempoEntregaFormateado()
        : '30-40 min';
    final proveedor = producto.proveedorNombre?.toString();
    final imageUrl = producto.imagenUrl?.toString();
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (cardWidth * dpr).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: cacheWidth,
                                placeholder: (_, __) => Container(color: JPColors.background),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.fastfood_outlined, color: JPColors.textHint, size: 34),
                                ),
                              )
                            : Container(
                                color: JPColors.background,
                                child: const Center(
                                  child: Icon(Icons.fastfood_outlined, color: JPColors.textHint, size: 34),
                                ),
                              ),
                      ),
                    ),
                    if (badgeType != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _buildBadgeWidget(producto, badgeType!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: JPColors.textPrimary,
              ),
            ),
            if (proveedor != null && proveedor.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                proveedor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '\$${precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: JPColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: JPColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.delivery_dining, size: 14, color: JPColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tiempoEntrega,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JPColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onAdd != null)
                  InkResponse(
                    onTap: onAdd,
                    radius: 18,
                    child: const Icon(Icons.add_circle, color: JPColors.primary, size: 22),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildBadgeWidget(dynamic producto, String type) {
  String text;
  Color bgColor;
  IconData? icon;

  switch (type) {
    case 'oferta':
      if (producto.enOferta && producto.porcentajeDescuento > 0) {
        text = '-${producto.porcentajeDescuento}%';
        bgColor = JPColors.error;
        icon = null;
      } else {
        return const SizedBox.shrink();
      }
      break;
    case 'popular':
      text = 'TOP';
      bgColor = const Color(0xFFFF9800); // Naranja
      icon = Icons.star;
      break;
    case 'nuevo':
      text = 'NUEVO';
      bgColor = const Color(0xFF4CAF50); // Verde
      icon = Icons.fiber_new;
      break;
    default:
      return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(76),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 2),
        ],
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// 📦 BLOQUE 3: Floating Action Button (FAB) (Sin cambios)
// ════════════════════════════════════════════════════════════════════════════

/// Floating Action Button para el Carrito
class _CarritoFAB extends StatelessWidget {
  const _CarritoFAB();

  @override
  Widget build(BuildContext context) {
    // Consumer para acceder al ProveedorCarrito
    return Consumer<ProveedorCarrito>(
      builder: (context, carritoProvider, _) {
        final cantidadTotal = carritoProvider.cantidadTotal;
        return FloatingActionButton.extended(
          heroTag: 'fab-carrito',
          onPressed: () => Rutas.irACarrito(context),
          backgroundColor: Colors.white,
          foregroundColor: JPColors.primary,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: JPColors.primary.withValues(alpha: 0.18)),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: JPColors.primary),
              if (cantidadTotal > 0)
                Positioned(
                  right: -10,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: JPColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: JPColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 22),
                    child: Text(
                      cantidadTotal > 9 ? '9+' : '$cantidadTotal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Mi Pedido',
              style: TextStyle(
                color: JPColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}
