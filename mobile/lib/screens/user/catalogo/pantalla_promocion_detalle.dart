// lib/screens/user/catalogo/pantalla_promocion_detalle.dart
import 'package:flutter/cupertino.dart';

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../config/rutas.dart';
import '../../../../../providers/proveedor_carrito.dart';
import '../../../../../services/productos/productos_service.dart';
import '../../../../../theme/app_colors_secondary.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../models/producto_model.dart';
import '../../../models/promocion_model.dart';
import '../../../services/core/toast_service.dart';
import '../../../widgets/util/add_to_cart_debounce.dart';

/// Pantalla de detalle de una promoción
class PantallaPromocionDetalle extends StatefulWidget {
  const PantallaPromocionDetalle({super.key});

  @override
  State<PantallaPromocionDetalle> createState() => _PantallaPromocionDetalleState();
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
        for (final productoId in promocion.productosAsociadosIds) {
          try {
            final prod = await productosService.obtenerProducto(productoId);
            productosReales.add(prod);
          } catch (e) {
            // Error silenciado
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
      backgroundColor: JPColors.background,
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
                    if (promocion.fechaFin != null) _buildContador(),
                    const SizedBox(height: 24),
                    _buildDescripcion(promocion),
                    const SizedBox(height: 24),
                    _buildProductosIncluidos(),
                    const SizedBox(height: 24),
                    _buildTerminos(),
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
            child: SafeArea(
              child: _CarritoCircularButton(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(promocion),
    );
  }

  Widget _buildSliverAppBar(PromocionModel promocion) {
    final promoColor = promocion.color;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      foregroundColor: CupertinoColors.label.resolveFrom(context),
      elevation: 0,
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
                      colors: [
                        promoColor.withValues(alpha: 0.8),
                        promoColor,
                      ],
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
                    colors: [
                      promoColor.withValues(alpha: 0.8),
                      promoColor,
                    ],
                  ),
                ),
              ),

            // 2. GRADIENTE SUTIL para mejor legibilidad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),

            // 3. BADGE DE DESCUENTO - Posicionado abajo sutilmente
            Positioned(
              bottom: 24,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.tag_fill,
                      color: promoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      promocion.descuento,
                      style: TextStyle(
                        fontSize: 24,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: promocion.esVigente
                  ? JPColors.success.withValues(alpha: 0.1)
                  : JPColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  promocion.esVigente ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: promocion.esVigente ? JPColors.success : JPColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  promocion.esVigente ? 'ACTIVA' : 'EXPIRADA',
                  style: TextStyle(
                    color: promocion.esVigente ? JPColors.success : JPColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Título
          Text(
            promocion.titulo,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: JPColors.textPrimary, height: 1.1),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(promocion.descripcion, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: JPColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: JPColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tiempoRestante == Duration.zero
                    ? 'La promoción ha expirado'
                    : 'Termina en $dias d $horas h $minutos m',
                style: const TextStyle(fontWeight: FontWeight.w700, color: JPColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcion(PromocionModel promocion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la promoción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JPColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(icono: Icons.discount_outlined, titulo: 'Descuento', texto: promocion.descuento),
                const Divider(height: 24),
                if (promocion.fechaInicio != null)
                  _InfoRow(
                    icono: Icons.calendar_today_outlined,
                    titulo: 'Inicio',
                    texto: _formatearFecha(promocion.fechaInicio!),
                  ),
                if (promocion.fechaFin != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icono: Icons.event_busy_outlined,
                    titulo: 'Fin',
                    texto: _formatearFecha(promocion.fechaFin!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosIncluidos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Productos incluidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JPColors.textPrimary),
          ),
        ),
        const SizedBox(height: 12),

        if (_loading)
          const Center(
            child: Padding(padding: EdgeInsets.all(32), child: CupertinoActivityIndicator(radius: 14)),
          )
        else if (_error.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: JPColors.error.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: JPColors.textSecondary),
                  ),
                  TextButton(onPressed: _cargarProductosIncluidos, child: const Text('Reintentar')),
                ],
              ),
            ),
          )
        else if (_productosIncluidos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColorsSecondary.main.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      size: 40,
                      color: AppColorsSecondary.main,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Promoción General',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: JPColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta promoción aplica a todo el catálogo.\nExplora nuestros productos para aprovecharla.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
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
              return _ProductoPromoCard(
                producto: _productosIncluidos[index],
                onTap: () => Rutas.irAProductoDetalle(context, _productosIncluidos[index]),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTerminos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Términos y condiciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: JPColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TerminoItem(texto: 'Promoción válida solo durante el periodo especificado.'),
                _TerminoItem(texto: 'Descuento aplicable únicamente a productos incluidos.'),
                _TerminoItem(texto: 'No acumulable con otras promociones activas.'),
                _TerminoItem(texto: 'Sujeto a disponibilidad de stock en el momento de la compra.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PromocionModel promocion) {
    // Calculamos totales solo si hay productos específicos
    final precioTotal = _productosIncluidos.fold<double>(0, (sum, p) => sum + p.precio);
    final precioAnterior = _productosIncluidos.fold<double>(0, (sum, p) => sum + (p.precioAnterior ?? p.precio));
    final ahorro = (precioAnterior - precioTotal).clamp(0, double.infinity);

    // Si no hay productos específicos, mostramos botón simple
    final mostrarTotales = _productosIncluidos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 51, 223, 217).withValues(alpha: 0.1),
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
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.red),
                      ),
                    ],
                  )
                else
                  const Expanded(
                    child: Text(
                      '¡Aprovecha esta oferta!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JPColors.textSecondary),
                    ),
                  ),

                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: promocion.esVigente ? _agregarPromocionAlCarrito : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: promocion.esVigente ? AppColorsSecondary.main : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: promocion.esVigente ? 4 : 0,
                      shadowColor: AppColorsSecondary.main.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(
                      mostrarTotales ? Icons.shopping_cart_rounded : Icons.explore_rounded,
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
      final success = await carrito.agregarPromocion(promocion, _productosIncluidos);

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
        ToastService().showError(context, carrito.error ?? 'Error al agregar promoción');
      }
    } else {
      // Promo general: ir al home/catalogo
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;

  const _InfoRow({required this.icono, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: JPColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icono, size: 20, color: JPColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(
              texto,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: JPColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

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
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
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
                      color: Colors.grey[100],
                      child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: producto.imagenUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CupertinoActivityIndicator(radius: 14),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.fastfood_outlined, size: 30, color: Colors.grey[400]),
                            )
                          : Icon(Icons.fastfood_outlined, size: 30, color: Colors.grey[400]),
                    ),
                  ),
                  if (tieneDescuento)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            )
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: JPColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      producto.descripcion,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  color: AppColorsSecondary.main,
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

class _TerminoItem extends StatelessWidget {
  final String texto;

  const _TerminoItem({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: JPColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
          ),
        ],
      ),
    );
  }
}
