import 'package:flutter/material.dart';

import '../../../../config/rutas.dart';
import '../../../../services/auth_service.dart';
import '../../dashboard/constants/dashboard_colors.dart';
import '../../../../apis/helpers/api_exception.dart';

class PantallaCambiarPasswordAdmin extends StatefulWidget {
  const PantallaCambiarPasswordAdmin({super.key});

  @override
  State<PantallaCambiarPasswordAdmin> createState() => _PantallaCambiarPasswordAdminState();
}

class _PantallaCambiarPasswordAdminState extends State<PantallaCambiarPasswordAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;
  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _mostrarConfirm = false;

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.cambiarPassword(
        passwordActual: _passwordActualController.text,
        nuevaPassword: _passwordNuevaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente'),
            backgroundColor: DashboardColors.verde,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo actualizar la contraseña. Intenta de nuevo.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
        backgroundColor: Colors.white,
        foregroundColor: DashboardColors.morado,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Por seguridad, ingresa tu contraseña actual y una nueva.',
                style: TextStyle(fontSize: 14, color: DashboardColors.gris),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                label: 'Contraseña actual',
                controller: _passwordActualController,
                obscure: !_mostrarActual,
                onToggle: () => setState(() => _mostrarActual = !_mostrarActual),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'Nueva contraseña',
                controller: _passwordNuevaController,
                obscure: !_mostrarNueva,
                onToggle: () => setState(() => _mostrarNueva = !_mostrarNueva),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                  if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'Confirmar nueva contraseña',
                controller: _passwordConfirmController,
                obscure: !_mostrarConfirm,
                onToggle: () => setState(() => _mostrarConfirm = !_mostrarConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirma la nueva contraseña';
                  if (v != _passwordNuevaController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: DashboardColors.rojo),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_reset),
                  label: Text(_loading ? 'Actualizando...' : 'Actualizar contraseña'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.morado,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading ? null : _cambiarPassword,
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        Rutas.irA(context, Rutas.recuperarPassword);
                      },
                child: const Text('¿Olvidaste tu contraseña? Recuperar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
