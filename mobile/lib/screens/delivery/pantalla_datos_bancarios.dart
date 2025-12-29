// lib/screens/delivery/pantalla_datos_bancarios.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../services/repartidor/repartidor_datos_bancarios_service.dart';
import '../../models/datos_bancarios.dart';

/// Pantalla para gestionar los datos bancarios del repartidor
class PantallaDatosBancarios extends StatefulWidget {
  const PantallaDatosBancarios({super.key});

  @override
  State<PantallaDatosBancarios> createState() => _PantallaDatosBancariosState();
}

class _PantallaDatosBancariosState extends State<PantallaDatosBancarios> {
  final _formKey = GlobalKey<FormState>();
  final _bancoNombreController = TextEditingController();
  final _numeroCuentaController = TextEditingController();
  final _titularController = TextEditingController();
  final _cedulaTitularController = TextEditingController();
  final _datosService = RepartidorDatosBancariosService();

  String? _tipoCuentaSeleccionada;
  DatosBancarios? _datosActuales;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _modoEdicion = false;

  static const Color _accent = Color(0xFF0CB7F2); // Celeste corporativo
  static const Color _success = Color(0xFF34C759);
  static const Color _errorColor = Color(0xFFFF3B30);

  // Dynamic Colors
  Color get _surface =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardBg =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _textPrimary => CupertinoColors.label.resolveFrom(context);
  Color get _textSecondary =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  final List<Map<String, String>> _tiposCuenta = [
    {'value': 'ahorros', 'label': 'Ahorros'},
    {'value': 'corriente', 'label': 'Corriente'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _bancoNombreController.dispose();
    _numeroCuentaController.dispose();
    _titularController.dispose();
    _cedulaTitularController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final datos = await _datosService.obtenerDatosBancarios();
      if (!mounted) return;
      setState(() {
        _datosActuales = datos;
        _isLoading = false;

        // Si hay datos, llenar los controladores
        if (datos.bancoNombre != null) {
          _bancoNombreController.text = datos.bancoNombre!;
          _numeroCuentaController.text = datos.bancoNumeroCuenta!;
          _titularController.text = datos.bancoTitular!;
          _cedulaTitularController.text = datos.bancoCedulaTitular!;
          _tipoCuentaSeleccionada = datos.bancoTipoCuenta;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarToast(
          _extraerMensajeError(e),
          color: _errorColor,
          icono: CupertinoIcons.exclamationmark_circle_fill,
        );
      }
    }
  }

  String _extraerMensajeError(dynamic e) {
    String mensajeError = 'Error al cargar datos';
    if (e.toString().contains('ApiException:')) {
      final match = RegExp(r'ApiException: (.+?) \|').firstMatch(e.toString());
      if (match != null) {
        mensajeError = match.group(1) ?? mensajeError;
      }
    } else {
      mensajeError = e.toString();
    }
    return mensajeError;
  }

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoCuentaSeleccionada == null) {
      _mostrarToast('Selecciona el tipo de cuenta', color: _errorColor);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _datosService.actualizarDatosBancarios(
        bancoNombre: _bancoNombreController.text.trim(),
        bancoTipoCuenta: _tipoCuentaSeleccionada!,
        bancoNumeroCuenta: _numeroCuentaController.text.trim(),
        bancoTitular: _titularController.text.trim(),
        bancoCedulaTitular: _cedulaTitularController.text.trim(),
      );

      if (mounted) {
        _mostrarToast(
          'Datos actualizados',
          icono: CupertinoIcons.checkmark_circle_fill,
        );
        setState(() => _modoEdicion = false);
        await _cargarDatos();
      }
    } catch (e) {
      if (mounted) {
        _mostrarToast(
          _extraerMensajeError(e),
          color: _errorColor,
          icono: CupertinoIcons.exclamationmark_circle_fill,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _mostrarToast(String mensaje, {IconData? icono, Color? color}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color ?? _success,
                borderRadius: BorderRadius.circular(12),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Datos Bancarios'),
          backgroundColor: _cardBg,
          border: const Border(
            bottom: BorderSide(color: Color(0x4D000000), width: 0.0),
          ),
          trailing: _datosActuales?.estanCompletos == true && !_modoEdicion
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Editar', style: TextStyle(color: _accent)),
                  onPressed: () => setState(() => _modoEdicion = true),
                )
              : null,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Detalles de tu cuenta para recibir pagos.',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      ),
                      _modoEdicion || !(_datosActuales?.estanCompletos ?? false)
                          ? _buildFormulario()
                          : _buildVisualizacion(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CupertinoFormSection.insetGrouped(
            header: const Text('INFORMACIÓN BANCARIA'),
            children: [
              CupertinoTextFormFieldRow(
                controller: _bancoNombreController,
                prefix: const Icon(
                  CupertinoIcons.building_2_fill,
                  color: CupertinoColors.systemGrey,
                ),
                placeholder: 'Nombre del banco',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length < 3) return 'Mín. 3 caracteres';
                  return null;
                },
              ),
              GestureDetector(
                onTap: _mostrarSelectorTipoCuenta,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.creditcard_fill,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _tipoCuentaSeleccionada == null
                              ? 'Tipo de cuenta'
                              : _tiposCuenta.firstWhere(
                                  (e) => e['value'] == _tipoCuentaSeleccionada,
                                )['label']!,
                          style: TextStyle(
                            fontSize: 17,
                            color: _tipoCuentaSeleccionada == null
                                ? CupertinoColors.placeholderText
                                : _textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_up_chevron_down,
                        size: 16,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ],
                  ),
                ),
              ),
              CupertinoTextFormFieldRow(
                controller: _numeroCuentaController,
                prefix: const Icon(
                  CupertinoIcons.number,
                  color: CupertinoColors.systemGrey,
                ),
                placeholder: 'Número de cuenta',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length < 8) return 'Mín. 8 dígitos';
                  return null;
                },
              ),
            ],
          ),
          CupertinoFormSection.insetGrouped(
            header: const Text('TITULAR'),
            children: [
              CupertinoTextFormFieldRow(
                controller: _titularController,
                prefix: const Icon(
                  CupertinoIcons.person_solid,
                  color: CupertinoColors.systemGrey,
                ),
                placeholder: 'Nombre del titular',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length < 3) return 'Mín. 3 caracteres';
                  return null;
                },
              ),
              CupertinoTextFormFieldRow(
                controller: _cedulaTitularController,
                prefix: const Icon(
                  CupertinoIcons.person_badge_plus_fill,
                  color: CupertinoColors.systemGrey,
                ),
                placeholder: 'Cédula / Documento',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length != 10) return 'Debe tener 10 dígitos';
                  return null;
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _isSaving ? null : _guardarDatos,
                    borderRadius: BorderRadius.circular(12),
                    child: _isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(_modoEdicion ? 'Actualizar' : 'Guardar'),
                  ),
                ),
                if (_modoEdicion && _datosActuales?.estanCompletos == true) ...[
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() => _modoEdicion = false);
                            _cargarDatos();
                          },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: _errorColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorTipoCuenta() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _tipoCuentaSeleccionada = _tiposCuenta[index]['value'];
                  });
                },
                children: _tiposCuenta.map((e) => Text(e['label']!)).toList(),
              ),
            ),
            CupertinoButton(
              child: const Text('Listo'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizacion() {
    return Column(
      children: [
        CupertinoFormSection.insetGrouped(
          header: const Text('CUENTA CONFIRMADA'),
          children: [
            _buildInfoRow('Banco', _datosActuales!.bancoNombre!),
            _buildInfoRow(
              'Tipo',
              _datosActuales!.tipoCuentaDisplay ??
                  _datosActuales!.bancoTipoCuenta!,
            ),
            _buildInfoRow('Número', _datosActuales!.bancoNumeroCuenta!),
          ],
        ),
        CupertinoFormSection.insetGrouped(
          header: const Text('TITULAR'),
          children: [
            _buildInfoRow('Nombre', _datosActuales!.bancoTitular!),
            _buildInfoRow('Documento', _datosActuales!.bancoCedulaTitular!),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textSecondary)),
          Text(
            value,
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
