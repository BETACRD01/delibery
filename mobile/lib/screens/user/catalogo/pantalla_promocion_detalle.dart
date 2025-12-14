// lib/screens/user/catalogo/pantalla_promocion_detalle.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../config/rutas.dart';
import '../../../../../providers/proveedor_carrito.dart';
import '../../../../../services/productos_service.dart';
import '../../../models/promocion_model.dart';
import '../../../models/producto_model.dart';
import 'dart:async';

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
        throw Exception("No se recibieron datos de la promoción");
      }

      // Cargar productos en oferta del backend
      final productosService = ProductosService();
      final productosReales = await productosService.obtenerProductosEnOferta();

      if (mounted) {
        setState(() {
          // Limitamos a los primeros 6 productos para no saturar la pantalla
          _productosIncluidos = productosReales.take(6).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando productos de promoción: $e");
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
        body: const Center(
          child: Text('Promoción no encontrada'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: JPColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(promocion),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(promocion),
                if (promocion.fechaFin != null && _tiempoRestante > Duration.zero)
                  _buildContador(),
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
      bottomNavigationBar: _buildBottomBar(promocion),
    );
  }

  Widget _buildSliverAppBar(PromocionModel promocion) {
    // Usamos el color de la promoción directamente, asumiendo que es objeto Color
    final promoColor = promocion.color; 

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: promoColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. IMAGEN DE FONDO (si existe)
            if (promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: promocion.imagenUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: promoColor,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: promoColor,
                ),
              )
            else
              // Fondo con color de la promoción si no hay imagen
              Container(color: promoColor),

            // 2. GRADIENTE OSCURO para mejorar legibilidad del texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // 3. CONTENIDO CENTRADO
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge de descuento
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      promocion.descuento,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: promoColor,
                        letterSpacing: 1,
                      ),
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
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            promocion.descripcion,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContador() {
    return const SizedBox.shrink();
  }

  Widget _buildDescripcion(PromocionModel promocion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la promoción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
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
                _InfoRow(
                  icono: Icons.discount_outlined,
                  titulo: 'Descuento',
                  texto: promocion.descuento,
                ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
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
                  TextButton(
                    onPressed: _cargarProductosIncluidos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (_productosIncluidos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.fastfood_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Esta promoción aplica a todo el catálogo\no no tiene productos específicos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: JPColors.textSecondary),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
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
                _TerminoItem(
                  texto: 'Promoción válida solo durante el periodo especificado.',
                ),
                _TerminoItem(
                  texto: 'Descuento aplicable únicamente a productos incluidos.',
                ),
                _TerminoItem(
                  texto: 'No acumulable con otras promociones activas.',
                ),
                _TerminoItem(
                  texto: 'Sujeto a disponibilidad de stock en el momento de la compra.',
                ),
              ],
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
    final precioOriginal = _productosIncluidos.fold<double>(
      0,
      (sum, p) => sum + p.precio,
    );
    final ahorro = precioOriginal - precioTotal;
    
    // Si no hay productos específicos, mostramos botón simple
    final mostrarTotales = _productosIncluidos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: JPColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Ahorras \$${ahorro.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: JPColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: \$${precioTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: JPColors.primary,
                        ),
                      ),
                    ],
                  )
                else
                  const Expanded(
                    child: Text(
                      "¡Aprovecha esta oferta!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: JPColors.textSecondary,
                      ),
                    ),
                  ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: promocion.esVigente 
                        ? _agregarPromocionAlCarrito
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JPColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      mostrarTotales ? 'Agregar Combo' : 'Ver Catálogo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
    final carrito = context.read<ProveedorCarrito>();
    final promocion = Rutas.obtenerArgumentos<PromocionModel>(context);

    if (promocion == null) return;

    // Si hay productos específicos, agregamos la promoción completa
    if (_productosIncluidos.isNotEmpty) {
      final success = await carrito.agregarPromocion(
        promocion,
        _productosIncluidos,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡${promocion.titulo} agregada al carrito!'),
            backgroundColor: JPColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } else {
      // Si es una promo general, llevamos al catálogo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Explora el catálogo para aplicar esta promoción'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: JPColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 20, color: JPColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: JPColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductoPromoCard extends StatelessWidget {
  final ProductoModel producto;

  const _ProductoPromoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final tieneDescuento = producto.enOferta && producto.precioAnterior != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen del producto
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[100],
              child: producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: producto.imagenUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JPColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.fastfood_outlined,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(
                      Icons.fastfood_outlined,
                      size: 30,
                      color: Colors.grey[400],
                    ),
            ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: JPColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  producto.descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tieneDescuento) ...[
                      Text(
                        '\$${producto.precioAnterior!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '\$${producto.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: JPColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: JPColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
