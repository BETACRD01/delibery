// lib/screens/delivery/pantalla_datos_bancarios.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/jp_theme.dart' hide JPSnackbar;
import '../../services/repartidor_datos_bancarios_service.dart';
import '../../models/datos_bancarios.dart';
import '../../widgets/jp_snackbar.dart';

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
        JPSnackbar.error(context, 'Error al cargar datos: $e');
      }
    }
  }

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) return;

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
        JPSnackbar.success(
            context, 'Datos bancarios actualizados correctamente');
        setState(() => _modoEdicion = false);
        await _cargarDatos();
      }
    } catch (e) {
      if (mounted) {
        JPSnackbar.error(context, 'Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        title: const Text('Datos Bancarios'),
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_datosActuales?.estanCompletos == true && !_modoEdicion)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _modoEdicion = true),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: JPColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _modoEdicion || !(_datosActuales?.estanCompletos ?? false)
          ? _buildFormulario()
          : _buildVisualizacion(),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Banco
          _buildTextField(
            controller: _bancoNombreController,
            label: 'Nombre del banco',
            hint: 'Ej: Banco Pichincha',
            icon: Icons.account_balance,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El nombre del banco es requerido';
              }
              if (value.length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Tipo de cuenta
          _buildTipoCuentaDropdown(),
          const SizedBox(height: 16),

          // Número de cuenta
          _buildTextField(
            controller: _numeroCuentaController,
            label: 'Número de cuenta',
            hint: 'Ej: 1234567890',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El número de cuenta es requerido';
              }
              if (value.length < 8) {
                return 'El número debe tener al menos 8 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Titular
          _buildTextField(
            controller: _titularController,
            label: 'Titular de la cuenta',
            hint: 'Ej: Juan Pérez',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El nombre del titular es requerido';
              }
              if (value.length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cédula del titular
          _buildTextField(
            controller: _cedulaTitularController,
            label: 'Cédula del titular',
            hint: 'Ej: 1234567890',
            icon: Icons.badge,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La cédula es requerida';
              }
              if (value.length != 10) {
                return 'La cédula debe tener 10 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Botones
          Row(
            children: [
              if (_modoEdicion && _datosActuales?.estanCompletos == true)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() => _modoEdicion = false);
                            _cargarDatos();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              if (_modoEdicion && _datosActuales?.estanCompletos == true)
                const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarDatos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JPColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _modoEdicion ? 'Actualizar' : 'Guardar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizacion() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de la cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: JPColors.textPrimary,
              ),
            ),
            const Divider(height: 24),
            _buildDatoRow('Banco', _datosActuales!.bancoNombre!),
            _buildDatoRow('Tipo de cuenta',
                _datosActuales!.tipoCuentaDisplay ?? _datosActuales!.bancoTipoCuenta!),
            _buildDatoRow('Número de cuenta', _datosActuales!.bancoNumeroCuenta!),
            _buildDatoRow('Titular', _datosActuales!.bancoTitular!),
            _buildDatoRow('Cédula', _datosActuales!.bancoCedulaTitular!),
          ],
        ),
      ),
    );
  }

  Widget _buildDatoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: JPColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: JPColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
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
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildTipoCuentaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _tipoCuentaSeleccionada,
      decoration: InputDecoration(
        labelText: 'Tipo de cuenta',
        prefixIcon: const Icon(Icons.account_balance_wallet, size: 20),
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
      items: _tiposCuenta.map((tipo) {
        return DropdownMenuItem<String>(
          value: tipo['value'],
          child: Text(tipo['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _tipoCuentaSeleccionada = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona un tipo de cuenta';
        }
        return null;
      },
    );
  }

}
