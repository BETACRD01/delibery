// lib/widgets/ratings/dialogo_calificar_pedido.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/pedido_model.dart';
import '../../services/pedidos/pedido_service.dart';
import 'star_rating_input.dart';

/// Diálogo para calificar todos los productos de un pedido
///
/// LÓGICA:
/// - Cliente califica TODOS los productos a la vez
/// - El promedio de productos = calificación del proveedor
/// - Se envía todo en una sola petición
///
/// Uso:
/// ```dart
/// final result = await showCupertinoModalPopup<bool>(
///   context: context,
///   builder: (context) => DialogoCalificarPedido(
///     pedidoId: 123,
///     proveedorNombre: 'Restaurant XYZ',
///     items: pedido.items,
///   ),
/// );
/// ```
class DialogoCalificarPedido extends StatefulWidget {
  final int pedidoId;
  final String proveedorNombre;
  final List<ItemPedido> items;

  const DialogoCalificarPedido({
    super.key,
    required this.pedidoId,
    required this.proveedorNombre,
    required this.items,
  });

  @override
  State<DialogoCalificarPedido> createState() => _DialogoCalificarPedidoState();
}

class _DialogoCalificarPedidoState extends State<DialogoCalificarPedido> {
  final _pedidoService = PedidoService();
  final Map<int, int> _ratingsProductos = {}; // productoId -> estrellas
  final Map<int, TextEditingController> _comentarios = {};
  final _comentarioProveedorCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores de texto para cada item
    for (var item in _itemsCalificables) {
      _comentarios[item.producto] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _comentarios.values) {
      controller.dispose();
    }
    _comentarioProveedorCtrl.dispose();
    super.dispose();
  }

  List<ItemPedido> get _itemsCalificables {
    return widget.items.where((item) => item.puedeCalificarProducto).toList();
  }

  /// Calcula el promedio de calificaciones de productos (esto será la calificación del proveedor)
  double get _promedioProductos {
    if (_ratingsProductos.isEmpty) return 0.0;

    final total = _ratingsProductos.values.fold<int>(
      0,
      (sum, rating) => sum + rating,
    );
    return total / _ratingsProductos.length;
  }

  int get _productosCalificados =>
      _ratingsProductos.values.where((r) => r > 0).length;

  Future<void> _enviarCalificaciones() async {
    // Validar que al menos un producto esté calificado
    if (_productosCalificados == 0) {
      _mostrarError('Por favor califica al menos un producto');
      return;
    }

    setState(() => _enviando = true);

    try {
      // Enviar calificación de cada producto
      for (var item in _itemsCalificables) {
        final rating = _ratingsProductos[item.producto];
        if (rating != null && rating > 0) {
          await _pedidoService.calificarProducto(
            pedidoId: widget.pedidoId,
            productoId: item.producto,
            itemId: item.id,
            estrellas: rating,
            comentario: _comentarios[item.producto]?.text.trim().isEmpty ?? true
                ? null
                : _comentarios[item.producto]!.text.trim(),
          );
        }
      }

      // Enviar calificación del proveedor (promedio de productos)
      if (_promedioProductos > 0) {
        await _pedidoService.calificarProveedor(
          pedidoId: widget.pedidoId,
          estrellas: _promedioProductos.round(),
          comentario: _comentarioProveedorCtrl.text.trim().isEmpty
              ? null
              : _comentarioProveedorCtrl.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        _mostrarExito();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        _mostrarError('Error al enviar calificaciones: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarExito() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF38A169),
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Gracias'),
          ],
        ),
        content: const Text('Tus calificaciones han sido enviadas'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_itemsCalificables.isEmpty) {
      return Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const Text('No hay productos para calificar'),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Calificar Pedido',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.proveedorNombre,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(CupertinoIcons.xmark_circle_fill),
                        ),
                      ],
                    ),
                  ),

                  // Resumen de progreso
                  if (_promedioProductos > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0cb7f2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0cb7f2).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            color: Color(0xFFFFB800),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Calificación promedio: ${_promedioProductos.toStringAsFixed(1)} ⭐',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '$_productosCalificados/${_itemsCalificables.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 1),

                  // Lista de productos
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título sección productos
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Califica cada producto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Productos
                          ..._itemsCalificables.map(
                            (item) => _buildProductoCard(item),
                          ),

                          const SizedBox(height: 24),

                          // Comentario general del proveedor
                          const Text(
                            'Comentario general (opcional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: _comentarioProveedorCtrl,
                            placeholder:
                                'Cuéntanos sobre tu experiencia con ${widget.proveedorNombre}',
                            placeholderStyle: TextStyle(
                              color: CupertinoColors.placeholderText
                                  .resolveFrom(context),
                            ),
                            maxLines: 3,
                            maxLength: 500,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.systemGrey4.resolveFrom(
                                  context,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          const SizedBox(
                            height: 80,
                          ), // Espacio para el botón fijo
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Botón flotante de enviar
              _buildBotonEnviar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductoCard(ItemPedido item) {
    final rating = _ratingsProductos[item.producto] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rating > 0
              ? const Color(0xFF0cb7f2).withValues(alpha: 0.3)
              : CupertinoColors.systemGrey4.resolveFrom(context),
          width: rating > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Producto info
          Row(
            children: [
              if (item.productoImagen != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.productoImagen!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  ),
                )
              else
                _buildPlaceholderImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productoNombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Cantidad: ${item.cantidad}',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Estrellas
          Row(
            children: [
              StarRatingInput(
                initialValue: rating,
                onChanged: (newRating) {
                  setState(() => _ratingsProductos[item.producto] = newRating);
                },
                size: 28,
              ),
              if (rating > 0) ...[
                const SizedBox(width: 8),
                Text(
                  _getRatingText(rating),
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ],
          ),

          // Comentario individual (opcional, colapsable)
          if (rating > 0) ...[
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _comentarios[item.producto],
              placeholder: 'Comentario (opcional)',
              placeholderStyle: TextStyle(
                fontSize: 13,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              maxLength: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(CupertinoIcons.cube_box, size: 24),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excelente 🌟';
      case 4:
        return 'Muy bueno 👍';
      case 3:
        return 'Bueno 👌';
      case 2:
        return 'Regular 😐';
      case 1:
        return 'Malo 👎';
      default:
        return '';
    }
  }

  // Botón flotante de enviar (se puede agregar con Stack en el build principal)
  Widget _buildBotonEnviar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: CupertinoButton(
            color: const Color(0xFF0cb7f2),
            onPressed: _enviando ? null : _enviarCalificaciones,
            child: _enviando
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(
                    'Enviar Calificaciones ($_productosCalificados/${_itemsCalificables.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
