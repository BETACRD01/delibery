// lib/screens/user/catalogo/pantalla_promocion_detalle.dart
import 'package:flutter/cupertino.dart';

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/routing/rutas.dart';
import '../../../../../providers/cart/proveedor_carrito.dart';
import '../../../../../services/productos/productos_service.dart';
import '../../../../../theme/primary_colors.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../models/products/producto_model.dart';
import '../../../models/products/promocion_model.dart';
import '../../../services/core/ui/toast_service.dart';
import '../../../widgets/util/add_to_cart_debounce.dart';

/// Pantalla de detalle de una promoción
class PantallaPromocionDetalle extends StatefulWidget {
  const PantallaPromocionDetalle({super.key});

  @override
  State<PantallaPromocionDetalle> createState() =>
      _PantallaPromocionDetalleState();
}

class _PantallaPromocionDetalleState extends State<PantallaPromocionDetalle> {
  List<ProductoModel> _productosIncluidos = [];
  bool _loading = true;
  String _error = '';

  Timer? _timer;
  Duration _tiempoRestante = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarProductosIncluidos();
      _iniciarContador();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarContador() {
    final promocion = Rutas.obtenerArgumentos<PromocionModel>(context);
    if (promocion?.fechaFin != null) {
      _actualizarTiempoRestante(promocion!.fechaFin!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _actualizarTiempoRestante(promocion.fechaFin!);
        }
      });
    }
  }

  void _actualizarTiempoRestante(DateTime fechaFin) {
    setState(() {
      _tiempoRestante = fechaFin.difference(DateTime.now());
      if (_tiempoRestante.isNegative) {
        _tiempoRestante = Duration.zero;
        _timer?.cancel();
      }
    });
  }

  Future<void> _cargarProductosIncluidos() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final promocion = Rutas.obtenerArgumentos<PromocionModel>(context);

      if (promocion == null) {
        throw Exception('No se recibieron datos de la promoción');
      }

      final productosService = ProductosService();

      List<ProductoModel> productosReales = [];

      // 1) Productos asociados específicos (múltiples)
      if (promocion.productosAsociadosIds.isNotEmpty) {
        debugPrint(
          '🔍 Cargando ${promocion.productosAsociadosIds.length} productos asociados...',
        );
        for (final productoId in promocion.productosAsociadosIds) {
          try {
            debugPrint('  → Cargando producto ID: $productoId');
            final prod = await productosService.obtenerProducto(productoId);
            productosReales.add(prod);
            debugPrint('  ✓ Producto cargado: ${prod.nombre}');
          } catch (e) {
            debugPrint('  ✗ Error cargando producto $productoId: $e');
          }
        }
      }

      // 2) Productos de categoría asociada
      if ((promocion.categoriaAsociadaId ?? '').isNotEmpty) {
        try {
          final productosCat = await productosService.obtenerProductos(
            categoriaId: promocion.categoriaAsociadaId,
          );
          productosReales.addAll(productosCat);
        } catch (e) {
          // Error silenciado
        }
      }

      if (mounted) {
        setState(() {
          // Filtramos duplicados por id
          final vistos = <String>{};
          final depurados = <ProductoModel>[];
          for (final p in productosReales) {
            if (p.id.isEmpty || vistos.contains(p.id)) continue;
            vistos.add(p.id);
            depurados.add(p);
          }
          _productosIncluidos = depurados;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los productos. Intenta nuevamente.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final promocion = Rutas.obtenerArgumentos<PromocionModel>(context);

    if (promocion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Promoción no encontrada')),
      );
    }

    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(promocion),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(promocion),
                    if (promocion.fechaFin != null) ...[
                      const SizedBox(height: 16),
                      _buildContador(),
                    ],
                    const SizedBox(height: 16),
                    _buildProductosIncluidos(),
                    const SizedBox(height: 16),
                    // _buildTerminos(), // Removed inline terms
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          // FAB del carrito flotante - Versión circular compacta
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(child: _CarritoCircularButton()),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(promocion),
    );
  }

  Widget _buildSliverAppBar(PromocionModel promocion) {
    final promoColor = promocion.color;

    return SliverAppBar(
      expandedHeight: 240, // Reduced height
      pinned: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      foregroundColor: CupertinoColors.label.resolveFrom(context),
      elevation: 0,
      actions: [
        // Terms & Conditions Info Button
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 24),
            onPressed: () => _mostrarDialogoTerminos(context),
            tooltip: 'Términos y Condiciones',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. IMAGEN DE FONDO
            if (promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: promocion.imagenUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: promoColor.withValues(alpha: 0.1),
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 14),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [promoColor.withValues(alpha: 0.8), promoColor],
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [promoColor.withValues(alpha: 0.8), promoColor],
                  ),
                ),
              ),

            // 2. GRADIENTE SUTIL para mejor legibilidad de iconos
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // 3. BADGE DE DESCUENTO - Posicionado abajo
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.tag_fill, color: promoColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      promocion.descuento,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: promoColor,
                        letterSpacing: -0.5,
                      ),
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

  Widget _buildHeader(PromocionModel promocion) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: promocion.esVigente
                      ? JPColors.success.withValues(alpha: 0.1)
                      : JPColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      promocion.esVigente ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: promocion.esVigente
                          ? JPColors.success
                          : JPColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      promocion.esVigente ? 'ACTIVA' : 'EXPIRADA',
                      style: TextStyle(
                        color: promocion.esVigente
                            ? JPColors.success
                            : JPColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Could put something else here if needed
            ],
          ),
          const SizedBox(height: 10),

          // Título
          Text(
            promocion.titulo,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            promocion.descripcion,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContador() {
    final dias = _tiempoRestante.inDays;
    final horas = _tiempoRestante.inHours.remainder(24);
    final minutos = _tiempoRestante.inMinutes.remainder(60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: JPColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tiempoRestante == Duration.zero
                    ? 'La promoción ha expirado'
                    : 'Termina en $dias d $horas h $minutos m',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildDescripcion REMOVED (or integrated if needed, but "terms" logic moved)

  Widget _buildProductosIncluidos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Incluye:', // Shorter title
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(radius: 12),
            ),
          )
        else if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error,
              style: const TextStyle(
                color: JPColors.textSecondary,
                fontSize: 13,
              ),
            ),
          )
        else if (_productosIncluidos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 24,
                    color: PrimaryColors.main,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Promoción válida en todo el catálogo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _productosIncluidos.length,
            itemBuilder: (context, index) {
              return Padding(
                // Add tiny padding for separation
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProductoPromoCard(
                  producto: _productosIncluidos[index],
                  onTap: () => Rutas.irAProductoDetalle(
                    context,
                    _productosIncluidos[index],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // Replaces _buildTerminos
  void _mostrarDialogoTerminos(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.doc_text,
                size: 32,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Términos y Condiciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 24),
            // Default static terms for now, matching previous hardcoded ones
            _buildTerminoItem(
              'Promoción válida solo durante el periodo especificado.',
            ),
            _buildTerminoItem(
              'Descuento aplicable únicamente a productos incluidos.',
            ),
            _buildTerminoItem('No acumulable con otras promociones activas.'),
            _buildTerminoItem('Sujeto a disponibilidad de stock.'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: const Text('Entendido'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PromocionModel promocion) {
    // Calculamos totales solo si hay productos específicos
    final precioTotal = _productosIncluidos.fold<double>(
      0,
      (sum, p) => sum + p.precio,
    );
    final precioAnterior = _productosIncluidos.fold<double>(
      0,
      (sum, p) => sum + (p.precioAnterior ?? p.precio),
    );
    final ahorro = (precioAnterior - precioTotal).clamp(0, double.infinity);

    // Si no hay productos específicos, mostramos botón simple
    final mostrarTotales = _productosIncluidos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (mostrarTotales)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ahorro > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              51,
                              223,
                              217,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ahorras \$${ahorro.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 37, 192, 235),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: \$${precioTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  )
                else
                  const Expanded(
                    child: Text(
                      '¡Aprovecha esta oferta!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: JPColors.textSecondary,
                      ),
                    ),
                  ),

                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: promocion.esVigente
                        ? _agregarPromocionAlCarrito
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: promocion.esVigente
                          ? PrimaryColors.main
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: promocion.esVigente ? 4 : 0,
                      shadowColor: PrimaryColors.main.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      mostrarTotales
                          ? Icons.shopping_cart_rounded
                          : Icons.explore_rounded,
                      size: 22,
                    ),
                    label: Text(
                      mostrarTotales ? 'Agregar combo' : 'Explorar productos',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _agregarPromocionAlCarrito() async {
    final promocion = Rutas.obtenerArgumentos<PromocionModel>(context);
    if (promocion == null) return;

    // Debounce check
    if (!AddToCartDebounce.canAdd('promo_${promocion.id}')) {
      ToastService().showInfo(context, 'Por favor espera un momento');
      return;
    }

    final carrito = context.read<ProveedorCarrito>();

    // Si hay productos específicos, agregamos la promoción completa
    if (_productosIncluidos.isNotEmpty) {
      final success = await carrito.agregarPromocion(
        promocion,
        _productosIncluidos,
      );

      if (!mounted) return;

      if (success) {
        if (!context.mounted) return;
        ToastService().showSuccess(
          context,
          '${promocion.titulo} agregada',
          actionLabel: 'Ver Carrito',
          onActionTap: () {
            if (!mounted) return;
            Rutas.irACarrito(context);
          },
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        if (!context.mounted) return;
        ToastService().showError(
          context,
          carrito.error ?? 'Error al agregar promoción',
        );
      }
    } else {
      // Promo general: ir al home/catalogo
      if (mounted) Navigator.pop(context);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _ProductoPromoCard extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback? onTap;

  const _ProductoPromoCard({required this.producto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tieneDescuento = producto.enOferta && producto.precioAnterior != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen del producto con badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: CupertinoColors.tertiarySystemGroupedBackground
                          .resolveFrom(context),
                      child:
                          producto.imagenUrl != null &&
                              producto.imagenUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: producto.imagenUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CupertinoActivityIndicator(radius: 14),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.fastfood_outlined,
                                size: 30,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            )
                          : Icon(
                              Icons.fastfood_outlined,
                              size: 30,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                    ),
                  ),
                  if (tieneDescuento)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: CupertinoColors.label.resolveFrom(context),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      producto.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (tieneDescuento) ...[
                          Text(
                            '\$${producto.precioAnterior!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${producto.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.red,
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
      ),
    );
  }
}

/// Botón circular compacto del carrito para pantallas de detalle
class _CarritoCircularButton extends StatelessWidget {
  const _CarritoCircularButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProveedorCarrito>(
      builder: (context, carrito, _) {
        final cantidad = carrito.cantidadTotal;

        return GestureDetector(
          onTap: () => Rutas.irACarrito(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  color: PrimaryColors.main,
                  size: 28,
                ),
                if (cantidad > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        cantidad > 9 ? '9+' : '$cantidad',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
