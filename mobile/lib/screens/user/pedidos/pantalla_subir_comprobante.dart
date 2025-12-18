// lib/screens/user/pedidos/pantalla_subir_comprobante.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/jp_theme.dart' hide JPSnackbar;
import '../../../services/pago_service.dart';
import '../../../models/datos_bancarios.dart';
import '../../../widgets/jp_snackbar.dart';

/// Pantalla para subir el comprobante de transferencia
class PantallaSubirComprobante extends StatefulWidget {
  final int pagoId;
  final DatosBancariosParaPago datosBancarios;

  const PantallaSubirComprobante({
    super.key,
    required this.pagoId,
    required this.datosBancarios,
  });

  @override
  State<PantallaSubirComprobante> createState() =>
      _PantallaSubirComprobanteState();
}

class _PantallaSubirComprobanteState extends State<PantallaSubirComprobante> {
  final _formKey = GlobalKey<FormState>();
  final _bancoOrigenController = TextEditingController();
  final _numeroOperacionController = TextEditingController();
  final _pagoService = PagoService();
  final _imagePicker = ImagePicker();

  File? _imagenComprobante;
  bool _isLoading = false;
  bool _datosModificados = false;

  @override
  void initState() {
    super.initState();
    _bancoOrigenController.addListener(_marcarComoModificado);
    _numeroOperacionController.addListener(_marcarComoModificado);
  }

  void _marcarComoModificado() {
    if (!_datosModificados) {
      setState(() => _datosModificados = true);
    }
  }

  Future<bool> _confirmarSalida() async {
    if (!_datosModificados && _imagenComprobante == null) {
      return true; // No hay datos, puede salir sin confirmar
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin enviar?'),
        content: const Text(
          'Si sales ahora, perderás la imagen y los datos ingresados. El comprobante debe ser enviado inmediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Quedarme'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Salir sin enviar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  @override
  void dispose() {
    _bancoOrigenController.removeListener(_marcarComoModificado);
    _numeroOperacionController.removeListener(_marcarComoModificado);
    _bancoOrigenController.dispose();
    _numeroOperacionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagenComprobante = File(pickedFile.path);
          _datosModificados = true;
        });
      }
    } catch (e) {
      if (mounted) {
        JPSnackbar.error(context, 'Error al seleccionar imagen: $e');
      }
    }
  }

  Future<void> _subirComprobante() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagenComprobante == null) {
      JPSnackbar.warning(
        context,
        'Debe seleccionar una imagen del comprobante',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _pagoService.subirComprobante(
        pagoId: widget.pagoId,
        imagenComprobante: _imagenComprobante!,
        bancoOrigen: _bancoOrigenController.text.trim().isNotEmpty
            ? _bancoOrigenController.text.trim()
            : null,
        numeroOperacion: _numeroOperacionController.text.trim().isNotEmpty
            ? _numeroOperacionController.text.trim()
            : null,
      );

      if (mounted) {
        JPSnackbar.success(context, 'Comprobante subido exitosamente');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        JPSnackbar.error(context, 'Error al subir comprobante: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: JPColors.primary),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: JPColors.primary),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _confirmarSalida();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: JPColors.background,
        appBar: AppBar(
          title: const Text('Subir Comprobante'),
          backgroundColor: JPColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de cuenta bancaria
                _buildDatosBancariosCard(),
                const SizedBox(height: 24),

                // Instrucciones
                _buildInstruccionesCard(),
                const SizedBox(height: 24),

                // Selección de imagen
                const Text(
                  'Comprobante de transferencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: JPColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildImagenSelector(),
                const SizedBox(height: 24),

                // Datos opcionales
                const Text(
                  'Información adicional (opcional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: JPColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBancoOrigenField(),
                const SizedBox(height: 16),
                _buildNumeroOperacionField(),
                const SizedBox(height: 32),

                // Botón de enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _subirComprobante,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JPColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Subir Comprobante',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatosBancariosCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JPColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: JPColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Datos para transferencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: JPColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDatoRow('Banco', widget.datosBancarios.banco),
            _buildDatoRow(
              'Tipo de cuenta',
              widget.datosBancarios.tipoCuentaDisplay,
            ),
            _buildDatoRow(
              'Número de cuenta',
              widget.datosBancarios.numeroCuenta,
            ),
            _buildDatoRow('Titular', widget.datosBancarios.titular),
            _buildDatoRow('Cédula', widget.datosBancarios.cedulaTitular),
            const Divider(height: 24),
            _buildDatoRow(
              'Monto a transferir',
              '\$${widget.datosBancarios.montoATransferir}',
              destacado: true,
            ),
            _buildDatoRow(
              'Referencia',
              widget.datosBancarios.referenciaPago,
              destacado: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatoRow(String label, String value, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: JPColors.textSecondary,
                fontWeight: destacado ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: destacado ? JPColors.primary : JPColors.textPrimary,
                fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruccionesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JPColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: JPColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Instrucciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: JPColors.info.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstruccionItem(
            'Realiza la transferencia a la cuenta indicada',
          ),
          _buildInstruccionItem('Toma una foto clara del comprobante'),
          _buildInstruccionItem('Sube la imagen usando el botón de abajo'),
          _buildInstruccionItem(
            'El repartidor verificará el comprobante antes de la entrega',
          ),
        ],
      ),
    );
  }

  Widget _buildInstruccionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: JPColors.info.withValues(alpha: 0.8),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: JPColors.info.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenSelector() {
    return GestureDetector(
      onTap: _mostrarOpcionesImagen,
      child: Container(
        width: double.infinity,
        height: _imagenComprobante != null ? 300 : 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imagenComprobante != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imagenComprobante!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Toca para seleccionar imagen',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBancoOrigenField() {
    return TextFormField(
      controller: _bancoOrigenController,
      decoration: InputDecoration(
        labelText: 'Banco de origen',
        hintText: 'Ej: Banco Pichincha',
        prefixIcon: const Icon(Icons.account_balance, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildNumeroOperacionField() {
    return TextFormField(
      controller: _numeroOperacionController,
      decoration: InputDecoration(
        labelText: 'Número de operación',
        hintText: 'Ej: 1234567890',
        prefixIcon: const Icon(Icons.confirmation_number, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
