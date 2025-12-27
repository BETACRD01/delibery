// lib/widgets/ratings/dialogo_calificar_proveedor.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/pedidos/pedido_service.dart';
import 'star_rating_input.dart';

/// Diálogo para calificar al proveedor después de que el pedido fue finalizado
///
/// Este es el ÚNICO tipo de calificación permitida desde la app del cliente.
/// Ya NO se califican productos individuales.
///
/// Uso:
/// ```dart
/// final result = await showCupertinoModalPopup<bool>(
///   context: context,
///   builder: (context) => DialogoCalificarProveedor(
///     pedidoId: 123,
///     proveedorId: 456,
///     proveedorNombre: 'Restaurant XYZ',
///   ),
/// );
/// ```
class DialogoCalificarProveedor extends StatefulWidget {
  final int pedidoId;
  final int proveedorId;
  final String proveedorNombre;
  final String? proveedorFoto;

  const DialogoCalificarProveedor({
    super.key,
    required this.pedidoId,
    required this.proveedorId,
    required this.proveedorNombre,
    this.proveedorFoto,
  });

  @override
  State<DialogoCalificarProveedor> createState() =>
      _DialogoCalificarProveedorState();
}

class _DialogoCalificarProveedorState extends State<DialogoCalificarProveedor> {
  final _pedidoService = PedidoService();
  final _comentarioCtrl = TextEditingController();

  // Calificación
  int _estrellas = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    // Validar que haya seleccionado al menos estrellas
    if (_estrellas == 0) {
      _mostrarError('Por favor selecciona una calificación');
      return;
    }

    setState(() => _enviando = true);

    try {
      await _pedidoService.calificarProveedor(
        pedidoId: widget.pedidoId,
        proveedorId: widget.proveedorId,
        estrellas: _estrellas,
        comentario: _comentarioCtrl.text.trim().isEmpty
            ? null
            : _comentarioCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        _mostrarExito();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        _mostrarError('Error al enviar calificación: $e');
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
            Text('¡Gracias!'),
          ],
        ),
        content: const Text('Tu calificación ha sido enviada'),
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
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con foto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Foto del proveedor
                              if (widget.proveedorFoto != null &&
                                  widget.proveedorFoto!.isNotEmpty)
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.proveedorFoto!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CupertinoActivityIndicator(
                                          radius: 12,
                                        ),
                                    errorWidget: (context, url, error) =>
                                        const CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Color(0xFFFFE0B2),
                                          child: Icon(
                                            Icons.store,
                                            color: Colors.orange,
                                            size: 24,
                                          ),
                                        ),
                                  ),
                                )
                              else
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Color(0xFFFFE0B2),
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Calificar Proveedor',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.proveedorNombre,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Calificación general (obligatoria)
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            '¿Cómo fue tu experiencia?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StarRatingInput(
                            initialValue: _estrellas,
                            onChanged: (rating) {
                              setState(() => _estrellas = rating);
                            },
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          if (_estrellas > 0)
                            Text(
                              _getRatingText(_estrellas),
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Comentario
                    const Text(
                      'Comentario (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _comentarioCtrl,
                      placeholder:
                          'Cuéntanos sobre tu experiencia con ${widget.proveedorNombre}',
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
                          color: CupertinoColors.systemGrey4.resolveFrom(
                            context,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón flotante de enviar
              _buildBotonEnviar(),
            ],
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
        return '';
    }
  }

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
            color: _estrellas > 0
                ? const Color(0xFFFF7B00)
                : CupertinoColors.systemGrey,
            onPressed: (_enviando || _estrellas == 0)
                ? null
                : _enviarCalificacion,
            child: _enviando
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Enviar Calificación',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
