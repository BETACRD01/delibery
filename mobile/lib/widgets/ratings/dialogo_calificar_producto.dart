// lib/widgets/ratings/dialogo_calificar_producto.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/pedido_model.dart';
import '../../services/pedido_service.dart';
import 'star_rating_input.dart';

/// Diálogo para calificar productos después de un pedido
///
/// Permite calificar uno o múltiples productos del pedido
///
/// Uso:
/// ```dart
/// final result = await showCupertinoModalPopup<bool>(
///   context: context,
///   builder: (context) => DialogoCalificarProducto(
///     pedidoId: 123,
///     items: pedido.items,
///   ),
/// );
/// ```
class DialogoCalificarProducto extends StatefulWidget {
  final int pedidoId;
  final List<ItemPedido> items;

  const DialogoCalificarProducto({
    super.key,
    required this.pedidoId,
    required this.items,
  });

  @override
  State<DialogoCalificarProducto> createState() =>
      _DialogoCalificarProductoState();
}

class _DialogoCalificarProductoState extends State<DialogoCalificarProducto> {
  final _pedidoService = PedidoService();
  final Map<int, int> _ratings = {};
  final Map<int, TextEditingController> _comentarios = {};
  bool _enviando = false;
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores de texto para cada item
    for (var item in widget.items) {
      if (item.puedeCalificarProducto) {
        _comentarios[item.producto] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _comentarios.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<ItemPedido> get _itemsCalificables {
    return widget.items.where((item) => item.puedeCalificarProducto).toList();
  }

  ItemPedido get _itemActual => _itemsCalificables[_indiceActual];

  Future<void> _enviarCalificacion() async {
    final rating = _ratings[_itemActual.producto];

    if (rating == null || rating == 0) {
      _mostrarError('Por favor selecciona una calificación');
      return;
    }

    setState(() => _enviando = true);

    try {
      await _pedidoService.calificarProducto(
        pedidoId: widget.pedidoId,
        productoId: _itemActual.producto,
        itemId: _itemActual.id,
        estrellas: rating,
        comentario:
            _comentarios[_itemActual.producto]?.text.trim().isEmpty ?? true
            ? null
            : _comentarios[_itemActual.producto]!.text.trim(),
      );

      if (mounted) {
        // Si hay más productos, pasar al siguiente
        if (_indiceActual < _itemsCalificables.length - 1) {
          setState(() {
            _indiceActual++;
            _enviando = false;
          });
        } else {
          // Si ya calificamos todos, cerrar
          Navigator.pop(context, true);
          _mostrarExito();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        _mostrarError('Error al enviar calificación: $e');
      }
    }
  }

  void _saltarProducto() {
    if (_indiceActual < _itemsCalificables.length - 1) {
      setState(() => _indiceActual++);
    } else {
      Navigator.pop(context);
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

    final item = _itemActual;
    final progreso = '${_indiceActual + 1} de ${_itemsCalificables.length}';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Calificar Producto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_itemsCalificables.length > 1)
                            Text(
                              progreso,
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(CupertinoIcons.xmark_circle_fill),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Foto y nombre del producto
                  Row(
                    children: [
                      if (item.productoImagen != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.productoImagen!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 60,
                              height: 60,
                              color: CupertinoColors.systemGrey5.resolveFrom(
                                context,
                              ),
                              child: const Icon(CupertinoIcons.cube_box),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(CupertinoIcons.cube_box),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productoNombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Cantidad: ${item.cantidad}',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Selector de estrellas
                  Column(
                    children: [
                      const Text(
                        '¿Qué te pareció este producto?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StarRatingInput(
                        initialValue: _ratings[item.producto] ?? 0,
                        onChanged: (rating) =>
                            setState(() => _ratings[item.producto] = rating),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRatingText(_ratings[item.producto] ?? 0),
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Campo de comentario
                  CupertinoTextField(
                    controller: _comentarios[item.producto],
                    placeholder:
                        'Cuéntanos tu experiencia con este producto (opcional)',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(
                        context,
                      ),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.systemGrey4.resolveFrom(context),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      if (_itemsCalificables.length > 1)
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: _saltarProducto,
                            child: const Text('Saltar'),
                          ),
                        ),
                      if (_itemsCalificables.length > 1)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CupertinoButton(
                          color: CupertinoColors.activeBlue,
                          onPressed: _enviando ? null : _enviarCalificacion,
                          child: _enviando
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : Text(
                                  _indiceActual < _itemsCalificables.length - 1
                                      ? 'Siguiente'
                                      : 'Enviar',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        return 'Selecciona tu calificación';
    }
  }
}
