// lib/screens/user/inicio/pantalla_home.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors_primary.dart';
import 'package:mobile/theme/app_colors_support.dart';
import 'package:provider/provider.dart';

import '../../../config/rutas.dart';
import '../../../controllers/user/home_controller.dart';
import '../../../controllers/user/perfil_controller.dart';
import '../../../models/producto_model.dart';
import '../../../providers/notificaciones_provider.dart';
import '../../../providers/proveedor_carrito.dart';
import '../../../services/auth_service.dart';
import '../../../services/session_cleanup.dart';
import '../../../services/toast_service.dart';
import '../../../widgets/cards/jp_product_card.dart';
import '../../../widgets/common/jp_shimmer.dart';
import '../../../widgets/util/add_to_cart_debounce.dart';
import '../busqueda/pantalla_busqueda.dart';
import 'widgets/inicio/home_app_bar.dart';

class PantallaHome extends StatefulWidget {
  const PantallaHome({super.key});

  @override
  State<PantallaHome> createState() => _PantallaHomeState();
}

class _PantallaHomeState extends State<PantallaHome> {
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _homeController.cargarDatos();
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
    return ChangeNotifierProvider.value(
      value: _homeController,
      child: Scaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        floatingActionButton: const _CarritoFAB(),
        body: _HomeBody(
          onAgregarCarrito: _agregarProductoAlCarrito,
          onLogout: () => _cerrarSesion(context),
        ),
      ),
    );
  }

  Future<void> _agregarProductoAlCarrito(
    BuildContext context,
    dynamic producto,
  ) async {
    final productoId = producto is ProductoModel
        ? producto.id.toString()
        : producto.id?.toString() ?? '';

    // Debounce check
    if (!AddToCartDebounce.canAdd(productoId)) {
      ToastService().showInfo(context, 'Por favor espera un momento');
      return;
    }

    final carrito = context.read<ProveedorCarrito>();
    final success = await carrito.agregarProducto(producto);
    if (!mounted) return;

    final nombre = producto is ProductoModel ? producto.nombre : 'producto';

    if (success) {
      if (!context.mounted) return;
      ToastService().showSuccess(
        context,
        '$nombre agregado',
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

  Future<void> _cerrarSesion(BuildContext ctx) async {
    try {
      await SessionCleanup.clearProviders(ctx);
      await AuthService().logout();
    } catch (_) {}
    if (!ctx.mounted) return;
    await Rutas.irAYLimpiar(ctx, Rutas.login, rootNavigator: true);
  }
}

class _HomeBody extends StatelessWidget {
  final Function(BuildContext, dynamic) onAgregarCarrito;
  final VoidCallback onLogout;

  const _HomeBody({required this.onAgregarCarrito, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificacionesProvider>();

    return Consumer<HomeController>(
      builder: (context, controller, _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: controller.refrescar),
            // AppBar con logo, título, notificaciones y logout
            HomeAppBar(
              unreadCount: inbox.noLeidas.length,
              onNotificationTap: () => Rutas.irANotificaciones(context),
              onSearchTap: () => _mostrarBusqueda(context),
              onLogoutTap: onLogout,
              logoAssetPath: 'assets/images/Beta.png',
            ),

            // Categorías
            SliverToBoxAdapter(
              child: _SeccionCategorias(
                categorias: controller.categorias,
                loading: controller.loading,
                onCategoriaTap: (cat) =>
                    Rutas.irACategoriaDetalle(context, cat),
                onVerTodo: () => Rutas.irATodasCategorias(context),
              ),
            ),

            // Promociones destacadas
            if (controller.promociones.isNotEmpty || controller.loading)
              SliverToBoxAdapter(
                child: _SeccionPromociones(
                  promociones: controller.promociones,
                  loading: controller.loading,
                  onPromoTap: (promo) =>
                      Rutas.irAPromocionDetalle(context, promo),
                ),
              ),

            // Ofertas
            if (controller.productosEnOferta.isNotEmpty || controller.loading)
              SliverToBoxAdapter(
                child: _SeccionProductos(
                  titulo: 'Ofertas del día',
                  icono: CupertinoIcons.flame_fill,
                  iconoColor: CupertinoColors.systemRed,
                  productos: controller.productosEnOferta,
                  loading: controller.loading,
                  badgeType: _BadgeType.oferta,
                  onProductoTap: (p) => Rutas.irAProductoDetalle(context, p),
                  onAgregar: (p) => onAgregarCarrito(context, p),
                ),
              ),

            // Populares
            if (controller.productosMasPopulares.isNotEmpty ||
                controller.loading)
              SliverToBoxAdapter(
                child: _SeccionProductos(
                  titulo: 'Los más pedidos',
                  icono: CupertinoIcons.star_fill,
                  iconoColor: CupertinoColors.systemOrange,
                  productos: controller.productosMasPopulares,
                  loading: controller.loading,
                  badgeType: _BadgeType.popular,
                  onProductoTap: (p) => Rutas.irAProductoDetalle(context, p),
                  onAgregar: (p) => onAgregarCarrito(context, p),
                ),
              ),

            // Novedades
            if (controller.productosNovedades.isNotEmpty || controller.loading)
              SliverToBoxAdapter(
                child: _SeccionProductos(
                  titulo: 'Recién llegados',
                  icono: CupertinoIcons.sparkles,
                  iconoColor: CupertinoColors.systemGreen,
                  productos: controller.productosNovedades,
                  loading: controller.loading,
                  badgeType: _BadgeType.nuevo,
                  onProductoTap: (p) => Rutas.irAProductoDetalle(context, p),
                  onAgregar: (p) => onAgregarCarrito(context, p),
                ),
              ),

            // Espacio para el FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  void _mostrarBusqueda(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const PantallaBusqueda(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════════════

class _SeccionCategorias extends StatelessWidget {
  final List<dynamic> categorias;
  final bool loading;
  final Function(dynamic) onCategoriaTap;
  final VoidCallback onVerTodo;

  const _SeccionCategorias({
    required this.categorias,
    required this.loading,
    required this.onCategoriaTap,
    required this.onVerTodo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColorsSupport.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: onVerTodo,
                child: const Text(
                  'Ver todo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColorsPrimary.main,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: loading
              ? _buildLoading(context)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categorias.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    return _CategoriaChip(
                      categoria: cat,
                      onTap: () => onCategoriaTap(cat),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const JPShimmerList.horizontal(
      itemCount: 5,
      itemWidth: 72,
      itemHeight: 100,
      spacing: 12,
      borderRadius: 20,
      padding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final dynamic categoria;
  final VoidCallback onTap;

  const _CategoriaChip({required this.categoria, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre = categoria.nombre?.toString() ?? 'Categoría';
    final icono = categoria.icono?.toString();
    final imagen = categoria.imagenUrl?.toString();

    // Determine color based on category data if available or default
    final Color baseColor = AppColorsPrimary.light;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (imagen != null && imagen.isNotEmpty)
                    ? Colors.white
                    : baseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20), // Squaricle
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildContent(context, imagen, icono, baseColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColorsSupport.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String? imagen,
    String? icono,
    Color baseColor,
  ) {
    if (imagen != null && imagen.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imagen,
        fit: BoxFit.cover,
        placeholder: (_, _) => const CupertinoActivityIndicator(),
        errorWidget: (_, _, _) => _buildIconFallback(context, icono, baseColor),
      );
    }
    return _buildIconFallback(context, icono, baseColor);
  }

  Widget _buildIconFallback(
    BuildContext context,
    String? icono,
    Color baseColor,
  ) {
    if (icono != null && icono.isNotEmpty) {
      return Center(child: Text(icono, style: const TextStyle(fontSize: 28)));
    }
    return Center(
      child: Icon(
        Icons.category_outlined, // Default icon
        color: AppColorsPrimary.main,
        size: 30,
      ),
    );
  }
}

class _SeccionPromociones extends StatelessWidget {
  final List<dynamic> promociones;
  final bool loading;
  final Function(dynamic) onPromoTap;

  const _SeccionPromociones({
    required this.promociones,
    required this.loading,
    required this.onPromoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (promociones.isEmpty && !loading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: const Text(
            'Promociones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsSupport.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: loading
              ? _buildLoading(context)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: promociones.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final promo = promociones[index];
                    return _PromoCard(
                      promo: promo,
                      onTap: () => onPromoTap(promo),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const JPShimmerList.horizontal(
      itemCount: 2,
      itemWidth: 280,
      itemHeight: 140,
      spacing: 12,
      borderRadius: 16,
      padding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final dynamic promo;
  final VoidCallback onTap;

  const _PromoCard({required this.promo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titulo = promo.titulo?.toString() ?? 'Promoción';
    final imagen = promo.imagenUrl?.toString();
    final descuento = promo.descuento?.toString();

    // Determine colors
    // Use consistent blue/purple gradient if no color provided, or use brand logic if desired.
    // Assuming iOS-like vibrant gradient.

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (imagen != null && imagen.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imagen,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                    placeholder: (_, _) => const CupertinoActivityIndicator(),
                    errorWidget: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (descuento != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        descuento,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
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
}

enum _BadgeType { oferta, popular, nuevo }

String _badgeTypeToString(_BadgeType type) {
  switch (type) {
    case _BadgeType.oferta:
      return 'oferta';
    case _BadgeType.popular:
      return 'popular';
    case _BadgeType.nuevo:
      return 'nuevo';
  }
}

class _SeccionProductos extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color iconoColor;
  final List<dynamic> productos;
  final bool loading;
  final _BadgeType badgeType;
  final Function(dynamic) onProductoTap;
  final Function(dynamic) onAgregar;

  const _SeccionProductos({
    required this.titulo,
    required this.icono,
    required this.iconoColor,
    required this.productos,
    required this.loading,
    required this.badgeType,
    required this.onProductoTap,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            children: [
              Icon(icono, color: iconoColor, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColorsSupport.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: loading
              ? _buildLoading(context)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: productos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final nombre = (producto is ProductoModel)
                        ? producto.nombre
                        : (producto.nombre ?? 'Producto');
                    final precioVal = (producto is ProductoModel)
                        ? producto.precio
                        : (producto.precio ?? 0);
                    final precio = (precioVal is num)
                        ? precioVal.toDouble()
                        : 0.0;
                    final imagen = producto.imagenUrl?.toString();
                    final ratingVal = (producto is ProductoModel)
                        ? producto.rating
                        : (producto.rating ?? 0);
                    final rating = (ratingVal is num)
                        ? ratingVal.toDouble()
                        : 0.0;
                    final porcentaje = producto.porcentajeDescuento;

                    return JPProductCard(
                      nombre: nombre,
                      precio: precio,
                      imagenUrl: imagen,
                      rating: rating,
                      badgeType: _badgeTypeToString(badgeType),
                      porcentajeDescuento: porcentaje,
                      onTap: () => onProductoTap(producto),
                      onAddToCart: () => onAgregar(producto),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const JPShimmerList.horizontal(
      itemCount: 3,
      itemWidth: 160,
      itemHeight: 220,
      spacing: 14,
      borderRadius: 16,
      padding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}

/// FAB del Carrito estilo iOS
class _CarritoFAB extends StatelessWidget {
  const _CarritoFAB();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProveedorCarrito>(
      builder: (context, carrito, _) {
        final cantidad = carrito.cantidadTotal;

        return GestureDetector(
          onTap: () => Rutas.irACarrito(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono del carrito con badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      CupertinoIcons.cart_fill,
                      color: AppColorsPrimary.main,
                      size: 24,
                    ),
                    if (cantidad > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          child: Text(
                            cantidad > 9 ? '9+' : '$cantidad',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Texto "Mi Pedido"
                Text(
                  'Mi Pedido',
                  style: TextStyle(
                    color: AppColorsPrimary.main,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
