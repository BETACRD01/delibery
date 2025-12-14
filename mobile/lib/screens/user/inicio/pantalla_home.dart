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

// Widgets de la UI
import 'widgets/inicio/home_app_bar.dart';
import 'widgets/inicio/banner_bienvenida.dart';
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
    // Consumer para acceder al HomeController
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        return RefreshIndicator(
          onRefresh: controller.refrescar,
          color: JPColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. AppBar
              HomeAppBar(
                notificacionesCount: 3,
                onNotificationTap: () => Rutas.irANotificaciones(context),
                onSearchTap: () => _mostrarBusqueda(context),
              ),

              // 2. Contenido de las Secciones
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // BANNER DE BIENVENIDA (Consumer anidado para Perfil)
                      Consumer<PerfilController>(
                        builder: (context, perfil, _) {
                          return BannerBienvenida(
                            nombreUsuario: perfil.perfil?.usuarioNombre ?? 'Hola',
                            onVerMenu: () => Rutas.irAMenuCompleto(context),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // SECCIÓN DE CATEGORÍAS
                      SeccionCategorias(
                        categorias: controller.categorias,
                        loading: controller.loading,
                        onCategoriaPressed: (cat) => Rutas.irACategoriaDetalle(context, cat),
                        onVerTodo: () => Rutas.irATodasCategorias(context),
                      ),
                      const SizedBox(height: 24),

                      // SECCIÓN DE PROMOCIONES
                      SeccionPromociones(
                        promociones: controller.promociones,
                        loading: controller.loading,
                        onPromocionPressed: (promo) => Rutas.irAPromocionDetalle(context, promo),
                      ),
                      const SizedBox(height: 24),

                      // SECCIÓN DE OFERTAS
                      if (controller.productosEnOferta.isNotEmpty || controller.loading)
                        Column(
                          children: [
                            _SeccionProductos(
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
                            const SizedBox(height: 24),
                          ],
                        ),

                      // SECCIÓN DE MÁS POPULARES
                      if (controller.productosMasPopulares.isNotEmpty || controller.loading)
                        Column(
                          children: [
                            _SeccionProductos(
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
                            const SizedBox(height: 24),
                          ],
                        ),

                      // SECCIÓN DE NOVEDADES
                      if (controller.productosNovedades.isNotEmpty || controller.loading)
                        Column(
                          children: [
                            _SeccionProductos(
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
                            const SizedBox(height: 24),
                          ],
                        ),
                    ],
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
          _buildLoadingState()
        else if (productos.isEmpty)
          _buildEmptyState()
        else
          _buildProductosList(),
      ],
    );
  }

  Widget _buildProductosList() {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: productos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final producto = productos[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () => onProductoPressed?.call(producto),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Imagen del producto con badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 100,
                              color: JPColors.background,
                              child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                                  ? Image.network(
                                      producto.imagenUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.fastfood_outlined,
                                          color: JPColors.textHint,
                                          size: 40,
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: JPColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.fastfood_outlined,
                                      color: JPColors.textHint,
                                      size: 40,
                                    ),
                            ),
                            // Badge según el tipo de sección
                            if (badgeType != null)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: _buildBadge(producto, badgeType!),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Información del producto
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              producto.nombre ?? 'Producto',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: JPColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildProveedorBadge(producto),
                            const SizedBox(height: 6),
                            // Precio oculto en Home - Solo visible en detalle
                            const SizedBox(height: 6),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.delivery_dining,
                                  size: 14,
                                  color: JPColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    producto is ProductoModel
                                        ? producto.tiempoEntregaFormateado()
                                        : '30-40 min',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: JPColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
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

  Widget _buildBadge(dynamic producto, String type) {
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
            color: Colors.black.withAlpha(76), // 0.3 * 255 ≈ 76
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

  Widget _buildProveedorBadge(dynamic producto) {
    final logo = producto.proveedorLogoUrl?.toString();
    final nombre = producto.proveedorNombre?.toString();
    final tieneLogo = logo != null && logo.isNotEmpty;
    final tieneNombre = nombre != null && nombre.isNotEmpty;
    if (!tieneLogo && !tieneNombre) return const SizedBox.shrink();

    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.grey[200],
          backgroundImage: tieneLogo ? NetworkImage(logo) : null,
          child: !tieneLogo
              ? const Icon(Icons.storefront_outlined, size: 12, color: Colors.grey)
              : null,
        ),
        if (tieneNombre) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nombre,
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
          onPressed: () => Rutas.irACarrito(context),
          backgroundColor: JPColors.primary,
          elevation: 4,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              if (cantidadTotal > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: JPColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cantidadTotal > 9 ? '9+' : '$cantidadTotal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: const Text(
            'Mi Pedido',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
