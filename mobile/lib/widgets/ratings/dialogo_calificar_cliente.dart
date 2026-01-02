// lib/widgets/ratings/dialogo_calificar_cliente.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../apis/subapis/http_client.dart';
import '../../config/network/api_config.dart';
import 'star_rating_input.dart';

/// Diálogo para que el repartidor califique al cliente
///
/// Uso:
/// ```dart
/// final result = await showCupertinoModalPopup<bool>(
///   context: context,
///   builder: (context) => DialogoCalificarCliente(
///     pedidoId: 123,
///     clienteNombre: 'María González',
///   ),
/// );
/// ```
class DialogoCalificarCliente extends StatefulWidget {
  final int pedidoId;
  final String clienteNombre;
  final String? clienteFoto;

  const DialogoCalificarCliente({
    super.key,
    required this.pedidoId,
    required this.clienteNombre,
    this.clienteFoto,
  });

  @override
  State<DialogoCalificarCliente> createState() => _DialogoCalificarClienteState();
}

class _DialogoCalificarClienteState extends State<DialogoCalificarCliente> {
  final _comentarioController = TextEditingController();
  final _apiClient = ApiClient();
  int _rating = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    if (_rating == 0) {
      _mostrarError('Por favor selecciona una calificación');
      return;
    }

    setState(() => _enviando = true);

    try {
      // NOTA: Este endpoint debe ser implementado en el backend
      // Por ahora usamos el mismo endpoint de calificaciones rápidas
      await _apiClient.post(
        ApiConfig.calificacionesRapida,
        {
          'pedido_id': widget.pedidoId,
          'tipo': 'repartidor_a_cliente',
          'estrellas': _rating,
          if (_comentarioController.text.trim().isNotEmpty)
            'comentario': _comentarioController.text.trim(),
        },
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
            Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF38A169), size: 24),
            SizedBox(width: 8),
            Text('Gracias'),
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
                      const Text(
                        'Calificar Cliente',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(CupertinoIcons.xmark_circle_fill),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Foto y nombre del cliente
                  Column(
                    children: [
                      if (widget.clienteFoto != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(widget.clienteFoto!),
                        )
                      else
                        const CircleAvatar(
                          radius: 40,
                          child: Icon(CupertinoIcons.person_fill, size: 32),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        widget.clienteNombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Selector de estrellas
                  Column(
                    children: [
                      const Text(
                        '¿Cómo fue la entrega con este cliente?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      StarRatingInput(
                        initialValue: _rating,
                        onChanged: (rating) => setState(() => _rating = rating),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRatingText(_rating),
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Campo de comentario
                  CupertinoTextField(
                    controller: _comentarioController,
                    placeholder: 'Comentarios sobre la entrega (opcional)',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(context),
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

                  // Botón enviar
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.activeBlue,
                      onPressed: _enviando ? null : _enviarCalificacion,
                      child: _enviando
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text(
                              'Enviar Calificación',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Botón saltar (opcional)
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Saltar por ahora'),
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
        return 'Excelente cliente 🌟';
      case 4:
        return 'Muy buen cliente 👍';
      case 3:
        return 'Buen cliente 👌';
      case 2:
        return 'Regular 😐';
      case 1:
        return 'Complicado 👎';
      default:
        return 'Selecciona tu calificación';
    }
  }
}
