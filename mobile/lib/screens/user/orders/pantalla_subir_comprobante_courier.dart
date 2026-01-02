// lib/screens/user/pedidos/pantalla_subir_comprobante_courier.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../theme/app_colors_primary.dart';
import '../../../theme/jp_theme.dart';
import '../../../services/pago/pago_service.dart';
import '../../../models/payments/datos_bancarios.dart';
import '../../../services/core/toast_service.dart';

/// Pantalla para subir el comprobante de transferencia - Específica para Encargos (Courier)
class PantallaSubirComprobanteCourier extends StatefulWidget {
  final int pagoId;
  final DatosBancariosParaPago datosBancarios;

  const PantallaSubirComprobanteCourier({
    super.key,
    required this.pagoId,
    required this.datosBancarios,
  });

  @override
  State<PantallaSubirComprobanteCourier> createState() =>
      _PantallaSubirComprobanteCourierState();
}

class _PantallaSubirComprobanteCourierState
    extends State<PantallaSubirComprobanteCourier> {
  final PagoService _pagoService = PagoService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _imagenComprobante;
  bool _isLoading = false;
  bool _datosModificados = false;

  Future<bool> _confirmarSalida() async {
    if (!_datosModificados && _imagenComprobante == null) {
      return true;
    }

    final resultado = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('¿Salir sin enviar?'),
        content: const Text(
          'Si sales ahora, perderás la imagen y los datos ingresados. El comprobante debe ser enviado inmediatamente para procesar el encargo.',
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Quedarme'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir sin enviar'),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _imagenComprobante = File(pickedFile.path);
          _datosModificados = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, 'Error al seleccionar imagen');
      }
    }
  }

  Future<void> _subirComprobante() async {
    if (_imagenComprobante == null) {
      ToastService().showWarning(
        context,
        'Debes seleccionar una imagen del comprobante',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _pagoService.subirComprobante(
        pagoId: widget.pagoId,
        imagenComprobante: _imagenComprobante!,
      );

      if (mounted) {
        ToastService().showSuccess(
          context,
          'Comprobante de encargo subido exitosamente',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ToastService().showError(context, 'Error al subir comprobante');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) => CupertinoActionSheet(
        title: const Text(
          'Seleccionar imagen',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        message: const Text('Elige cómo quieres agregar el comprobante'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _seleccionarImagen(ImageSource.camera);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  CupertinoIcons.camera_fill,
                  color: AppColorsPrimary.main,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Tomar foto', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _seleccionarImagen(ImageSource.gallery);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  CupertinoIcons.photo_fill,
                  color: AppColorsPrimary.main,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Seleccionar de galería',
                  style: TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final bool shouldPop = await _confirmarSalida();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: JPCupertinoColors.background(context),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: JPCupertinoColors.surface(context),
          middle: const Text(
            'Comprobante Encargo',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              final bool shouldPop = await _confirmarSalida();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Icon(
              CupertinoIcons.back,
              color: AppColorsPrimary.main,
              size: 28,
            ),
          ),
          border: null,
        ),
        child: SafeArea(
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 16,
              color: JPCupertinoColors.label(context),
              fontFamily: '.SF Pro Text',
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _buildDatosBancariosCard(),
                      const SizedBox(height: 24),
                      _buildSeccionComprobante(),
                      const SizedBox(height: 32),
                      _buildBotonSubir(),
                      const SizedBox(height: 16),
                    ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: JPCupertinoColors.separator(context).withValues(alpha: 0.2),
          width: 0.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColorsPrimary.main,
                      AppColorsPrimary.main.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColorsPrimary.main.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.building_2_fill,
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Datos del Repartidor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: JPCupertinoColors.label(context),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemGrey6(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: <Widget>[
                _DatoRow(
                  label: 'Banco',
                  value: widget.datosBancarios.banco,
                  icon: CupertinoIcons.building_2_fill,
                ),
                const SizedBox(height: 14),
                _DatoRow(
                  label: 'Tipo de cuenta',
                  value: widget.datosBancarios.tipoCuentaDisplay,
                  icon: CupertinoIcons.creditcard,
                ),
                const SizedBox(height: 14),
                _DatoRow(
                  label: 'Número de cuenta',
                  value: widget.datosBancarios.numeroCuenta,
                  icon: CupertinoIcons.number,
                ),
                const SizedBox(height: 14),
                _DatoRow(
                  label: 'Titular',
                  value: widget.datosBancarios.titular,
                  icon: CupertinoIcons.person_fill,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColorsPrimary.main.withValues(alpha: 0.12),
                  AppColorsPrimary.main.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColorsPrimary.main.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  color: AppColorsPrimary.main,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Monto a pagar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: JPCupertinoColors.label(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: Text(
                    '\$${widget.datosBancarios.montoATransferir}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColorsPrimary.main,
                      letterSpacing: -1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionComprobante() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorsPrimary.main.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.doc_text_fill,
                  size: 18,
                  color: AppColorsPrimary.main,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comprobante de pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: JPCupertinoColors.label(context),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        _buildImagenSelector(),
        if (_imagenComprobante != null) ...<Widget>[
          const SizedBox(height: 16),
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColorsPrimary.main.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(14),
                onPressed: _mostrarOpcionesImagen,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.arrow_2_circlepath,
                      size: 20,
                      color: AppColorsPrimary.main,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Cambiar imagen',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColorsPrimary.main,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagenSelector() {
    return GestureDetector(
      onTap: _mostrarOpcionesImagen,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: _imagenComprobante != null ? 340 : 220,
          minHeight: 220,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _imagenComprobante != null
                ? CupertinoColors.transparent
                : JPCupertinoColors.systemGrey6(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _imagenComprobante != null
                  ? AppColorsPrimary.main.withValues(alpha: 0.4)
                  : JPCupertinoColors.separator(context).withValues(alpha: 0.3),
              width: _imagenComprobante != null ? 2.5 : 1.5,
            ),
            boxShadow: _imagenComprobante != null
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColorsPrimary.main.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: _imagenComprobante != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.file(_imagenComprobante!, fit: BoxFit.cover),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                JPCupertinoColors.systemGreen(context),
                                JPCupertinoColors.systemGreen(
                                  context,
                                ).withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: CupertinoColors.black.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                CupertinoIcons.checkmark_alt_circle_fill,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Listo',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColorsPrimary.main.withValues(alpha: 0.15),
                          AppColorsPrimary.main.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColorsPrimary.main.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.camera_fill,
                      size: 52,
                      color: AppColorsPrimary.main,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBotonSubir() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: !_isLoading
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColorsPrimary.main.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          color: _isLoading
              ? JPCupertinoColors.systemGrey4(context)
              : AppColorsPrimary.main,
          disabledColor: JPCupertinoColors.systemGrey4(context),
          onPressed: _isLoading ? null : _subirComprobante,
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                      radius: 11,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Subiendo...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.cloud_upload_fill,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Datos de Transferencia',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Widget auxiliar para las filas de datos con iconos
class _DatoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DatoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: JPCupertinoColors.systemGrey(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: JPCupertinoColors.secondaryLabel(context),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: JPCupertinoColors.label(context),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
