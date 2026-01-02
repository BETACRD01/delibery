// lib/screens/user/perfil/configuracion/seguridad/dialogo_cambiar_password.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../theme/jp_theme.dart' hide JPSnackbar;
import '../../../../../theme/primary_colors.dart';
import '../../../../../services/auth/auth_service.dart';
import '../../../../../widgets/common/jp_snackbar.dart';

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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        JPSnackbar.error(
          context,
          'Error al cambiar contraseña: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con estilo iOS
            Container(
              padding: const EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Ícono circular estilo iOS
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: JPColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    child: const Icon(
                      CupertinoIcons.lock_circle,
                      color: JPColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cambiar Contraseña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ingresa tu nueva contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido con form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nueva Contraseña - Estilo iOS
                      Text(
                        'NUEVA CONTRASEÑA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemFill.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _passwordNuevaController,
                          obscureText: _obscurePasswordNueva,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mínimo 5 caracteres',
                            hintStyle: TextStyle(
                              color: CupertinoColors.placeholderText
                                  .resolveFrom(context),
                              fontSize: 17,
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.lock,
                              size: 20,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            suffixIcon: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(
                                () => _obscurePasswordNueva =
                                    !_obscurePasswordNueva,
                              ),
                              child: Icon(
                                _obscurePasswordNueva
                                    ? CupertinoIcons.eye_slash_fill
                                    : CupertinoIcons.eye_fill,
                                size: 20,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                      ),
                      const SizedBox(height: 20),

                      // Confirmar Contraseña - Estilo iOS
                      Text(
                        'CONFIRMAR CONTRASEÑA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemFill.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _passwordConfirmacionController,
                          obscureText: _obscurePasswordConfirmacion,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Repite la nueva contraseña',
                            hintStyle: TextStyle(
                              color: CupertinoColors.placeholderText
                                  .resolveFrom(context),
                              fontSize: 17,
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.checkmark_shield,
                              size: 20,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            suffixIcon: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(
                                () => _obscurePasswordConfirmacion =
                                    !_obscurePasswordConfirmacion,
                              ),
                              child: Icon(
                                _obscurePasswordConfirmacion
                                    ? CupertinoIcons.eye_slash_fill
                                    : CupertinoIcons.eye_fill,
                                size: 20,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                      ),
                      const SizedBox(height: 20),

                      // Info Box - Estilo iOS
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColorsPrimary.main.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              CupertinoIcons.info_circle_fill,
                              color: AppColorsPrimary.main,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tu contraseña debe tener al menos 5 caracteres.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColorsPrimary.main,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones estilo iOS
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: _isLoading
                              ? CupertinoColors.systemGrey
                              : AppColorsPrimary.main,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 44,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: _isLoading ? null : _cambiarPassword,
                      child: _isLoading
                          ? const CupertinoActivityIndicator()
                          : const Text(
                              'Cambiar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColorsPrimary.main,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
