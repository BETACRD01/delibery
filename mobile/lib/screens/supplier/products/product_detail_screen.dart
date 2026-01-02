import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/products/producto_model.dart';
import '../../../services/productos/productos_service.dart';
import '../../../theme/primary_colors.dart';
import 'product_edit_sheet.dart';
import 'product_reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductoModel> _futureProducto;
  final ProductosService _service = ProductosService();

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  void _cargarProducto() {
    setState(() {
      _futureProducto = _service.obtenerDetalleProductoProveedor(
        widget.productId,
      );
    });
  }

  void _abrirEdicion(ProductoModel producto) async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditSheet(producto: producto),
    );

    if (resultado == true) {
      _cargarProducto();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado exitosamente')),
      );
    }
  }

  void _confirmarEliminar(ProductoModel producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${producto.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      // Mostrar indicador de carga
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(radius: 14),
                    SizedBox(height: 16),
                    Text('Eliminando producto...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      try {
        // Importar el controller
        final controller = context.read<SupplierController>();
        await controller.eliminarProducto(producto.id);

        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar loader
        Navigator.of(context).pop(); // Volver a la lista

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${producto.nombre}" eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar loader

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirImagenCompleta(BuildContext context, String? imagenUrl) {
    if (imagenUrl == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imagenUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      body: FutureBuilder<ProductoModel>(
        future: _futureProducto,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return _buildError('Producto no encontrado');
          }

          final producto = snapshot.data!;
          return CustomScrollView(
            slivers: [
              _buildAppBar(producto),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoSection(producto),
                      const SizedBox(height: 16),
                      // _buildMetricsSection(producto), // REMOVIDO: Cuadro de rendimiento
                      // const SizedBox(height: 16),
                      _buildReviewsSection(producto),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Error al cargar: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _cargarProducto,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ProductoModel producto) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      foregroundColor: CupertinoColors.label.resolveFrom(context),
      actions: [
        IconButton(
          onPressed: () => _abrirEdicion(producto),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorsPrimary.main,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColorsPrimary.main.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          ),
        ),
        IconButton(
          onPressed: () => _confirmarEliminar(producto),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade400.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
          child: GestureDetector(
            onTap: () => _abrirImagenCompleta(context, producto.imagenUrl),
            child: Hero(
              tag: 'producto-${producto.id}',
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: producto.imagenUrl != null
                      ? Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoSection(ProductoModel producto) {
    return _CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusChip(
                label: producto.disponible ? 'Activo' : 'Pausado',
                color: producto.disponible ? Colors.green : Colors.orange,
              ),
              if (producto.stock != null)
                Text(
                  'Stock: ${producto.stock}',
                  style: TextStyle(
                    color: (producto.stock ?? 0) < 5 ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            producto.nombre,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            producto.precioFormateado,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            producto.descripcion,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductoModel p) {
    if (p.resenasPreview.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reseñas recientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductReviewsScreen(
                        productoId: p.id,
                        productoNombre: p.nombre,
                      ),
                    ),
                  );
                },
                child: const Text('Ver todas'),
              ),
            ],
          ),
        ),
        ...p.resenasPreview.map((r) => _ReviewItem(resena: r)),
      ],
    );
  }
}

class _CardBase extends StatelessWidget {
  final Widget child;
  const _CardBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ResenaPreview resena;
  const _ReviewItem({required this.resena});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  resena.usuario[0].toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                resena.usuario,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${resena.estrellas} ★',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (resena.comentario != null && resena.comentario!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              resena.comentario!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatFecha(resena.fecha),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String isoDate) {
    // Simple parser for demonstration
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
