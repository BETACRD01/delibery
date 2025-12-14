// lib/screens/user/perfil/configuracion/seguridad/dialogo_cambiar_password.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart' hide JPSnackbar;
import '../../../../../services/auth_service.dart';
import '../../../../../widgets/jp_snackbar.dart';

class DialogoCambiarPassword extends StatefulWidget {
  const DialogoCambiarPassword({super.key});

  @override
  State<DialogoCambiarPassword> createState() => _DialogoCambiarPasswordState();
}

class _DialogoCambiarPasswordState extends State<DialogoCambiarPassword> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmacionController = TextEditingController();

  bool _obscurePasswordNueva = true;
  bool _obscurePasswordConfirmacion = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordNuevaController.dispose();
    _passwordConfirmacionController.dispose();
    super.dispose();
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.cambiarPassword(
        passwordActual: '', // No se requiere contraseña actual
        nuevaPassword: _passwordNuevaController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        JPSnackbar.success(context, 'Contraseña actualizada correctamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        JPSnackbar.error(context, 'Error al cambiar contraseña: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: JPColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: JPColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cambiar Contraseña',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: JPColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu nueva contraseña',
                style: TextStyle(
                  fontSize: 13,
                  color: JPColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Contraseña Nueva
              Text(
                'Nueva Contraseña',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordNuevaController,
                obscureText: _obscurePasswordNueva,
                decoration: InputDecoration(
                  hintText: 'Mínimo 5 caracteres',
                  prefixIcon: const Icon(Icons.lock_open_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordNueva ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePasswordNueva = !_obscurePasswordNueva),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: JPColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La nueva contraseña es requerida';
                  }
                  if (value.length < 5) {
                    return 'La contraseña debe tener al menos 5 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirmar Contraseña
              Text(
                'Confirmar Contraseña',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordConfirmacionController,
                obscureText: _obscurePasswordConfirmacion,
                decoration: InputDecoration(
                  hintText: 'Repite la nueva contraseña',
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordConfirmacion ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePasswordConfirmacion = !_obscurePasswordConfirmacion),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: JPColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma tu nueva contraseña';
                  }
                  if (value != _passwordNuevaController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JPColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: JPColors.info.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: JPColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tu contraseña debe tener al menos 5 caracteres.',
                        style: TextStyle(
                          fontSize: 12,
                          color: JPColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: JPColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cambiarPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JPColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Cambiar Contraseña',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
