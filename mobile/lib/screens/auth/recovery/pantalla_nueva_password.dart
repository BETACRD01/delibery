// lib/screens/auth/pantalla_nueva_password.dart

import 'package:flutter/cupertino.dart';
import '../../../services/auth/auth_service.dart';
import '../../../config/routing/rutas.dart';
import 'package:mobile/services/core/api/api_exception.dart';
import '../../../services/core/validation/validators.dart';
import '../../../theme/jp_theme.dart';
import '../../../theme/primary_colors.dart';

/// Pantalla para establecer nueva contraseña
/// ✅ Última etapa del flujo de recuperación
class PantallaNuevaPassword extends StatefulWidget {
  const PantallaNuevaPassword({super.key});

  @override
  State<PantallaNuevaPassword> createState() => _PantallaNuevaPasswordState();
}

class _PantallaNuevaPasswordState extends State<PantallaNuevaPassword> {
  // ============================================
  // CONTROLADORES
  // ============================================
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _api = AuthService();

  // ============================================
  // ESTADO
  // ============================================
  String? _email;
  String? _codigo;
  bool _loading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _exitoso = false;

  // ============================================
  // CICLO DE VIDA
  // ============================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _obtenerArgumentos();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================
  // MÉTODOS
  // ============================================

  /// Obtiene email y código de los argumentos
  void _obtenerArgumentos() {
    final args = Rutas.obtenerArgumentos<Map<String, dynamic>>(context);
    if (args != null &&
        args.containsKey('email') &&
        args.containsKey('codigo')) {
      setState(() {
        _email = args['email'] as String;
        _codigo = args['codigo'] as String;
      });
    } else {
      // Si no hay datos, volver al inicio
      Rutas.irAYLimpiar(context, Rutas.login);
    }
  }

  /// ✅ Cambia la contraseña
  Future<void> _cambiarPassword() async {
    // Validación manual
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos');
      return;
    }

    final validacion = Validators.validarPassword(password);
    if (!validacion['valida']) {
      final errores = validacion['errores'] as List<String>;
      setState(() => _error = errores.first);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.resetPassword(
        email: _email!,
        codigo: _codigo!,
        nuevaPassword: password,
      );

      if (mounted) {
        setState(() {
          _exitoso = true;
          _loading = false;
        });

        // Esperar 2 segundos y volver al login
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await Rutas.completarRecuperacionPassword(context);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cambiar contraseña. Intenta nuevamente';
          _loading = false;
        });
      }
    }
  }
  // ============================================
  // UI - BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: !_exitoso
          ? CupertinoNavigationBar(
              backgroundColor: JPCupertinoColors.surface(context).withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: JPCupertinoColors.separator(context),
                  width: 0.5,
                ),
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.back,
                      color: AppColorsPrimary.main,
                      size: 28,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Atrás',
                      style: TextStyle(
                        color: AppColorsPrimary.main,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 17,
          color: JPCupertinoColors.label(context),
          fontFamily: '.SF Pro Text',
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _exitoso ? _buildExito() : _buildFormulario(),
            ),
          ),
        ),
      ),
    );
  }

  /// Formulario de nueva contraseña
  Widget _buildFormulario() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icono
        Container(
          height: 96,
          width: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsPrimary.main.withValues(alpha: 0.15),
                AppColorsPrimary.main.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.lock_open,
            size: 48,
            color: AppColorsPrimary.main,
          ),
        ),
        const SizedBox(height: 28),

        // Título
        Text(
          'Nueva Contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: JPCupertinoColors.label(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Descripción
        Text(
          'Crea una contraseña segura para tu cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: JPCupertinoColors.secondaryLabel(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        // Campo de contraseña
        Container(
          decoration: BoxDecoration(
            color: JPCupertinoColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JPCupertinoColors.separator(context),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lock,
                color: AppColorsPrimary.main,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'Nueva contraseña',
                  obscureText: !_passwordVisible,
                  placeholderStyle: TextStyle(
                    color: JPCupertinoColors.placeholder(context),
                    fontSize: 17,
                  ),
                  style: TextStyle(
                    color: JPCupertinoColors.label(context),
                    fontSize: 17,
                  ),
                  enabled: !_loading,
                  decoration: const BoxDecoration(),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    child: Icon(
                      _passwordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                      color: JPCupertinoColors.secondaryLabel(context),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Campo confirmar contraseña
        Container(
          decoration: BoxDecoration(
            color: JPCupertinoColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JPCupertinoColors.separator(context),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lock,
                color: AppColorsPrimary.main,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: _confirmPasswordController,
                  placeholder: 'Confirmar contraseña',
                  obscureText: !_confirmPasswordVisible,
                  placeholderStyle: TextStyle(
                    color: JPCupertinoColors.placeholder(context),
                    fontSize: 17,
                  ),
                  style: TextStyle(
                    color: JPCupertinoColors.label(context),
                    fontSize: 17,
                  ),
                  enabled: !_loading,
                  decoration: const BoxDecoration(),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                    child: Icon(
                      _confirmPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                      color: JPCupertinoColors.secondaryLabel(context),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Requisitos de contraseña
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JPCupertinoColors.secondarySurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: JPCupertinoColors.separator(context),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La contraseña debe tener:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: JPCupertinoColors.label(context),
                ),
              ),
              const SizedBox(height: 10),
              _buildRequisitoPassword('Al menos 8 caracteres'),
              _buildRequisitoPassword('Al menos una letra'),
              _buildRequisitoPassword('Al menos un número'),
              _buildRequisitoPassword('Sin espacios en blanco'),
            ],
          ),
        ),

        // Mensaje de error
        if (_error != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemRed(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: JPCupertinoColors.systemRed(context).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 22,
                  color: JPCupertinoColors.systemRed(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: JPCupertinoColors.systemRed(context),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Botón cambiar contraseña
        Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsPrimary.main,
                AppColorsPrimary.main.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColorsPrimary.main.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CupertinoButton(
            onPressed: _loading ? null : _cambiarPassword,
            color: CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(14),
            padding: EdgeInsets.zero,
            child: _loading
                ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                    radius: 12,
                  )
                : const Text(
                    'Cambiar Contraseña',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Widget para mostrar requisito de contraseña
  Widget _buildRequisitoPassword(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.checkmark_circle,
            size: 16,
            color: JPCupertinoColors.secondaryLabel(context),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: JPCupertinoColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla de éxito
  Widget _buildExito() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icono de éxito
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JPCupertinoColors.systemGreen(context).withValues(alpha: 0.2),
                JPCupertinoColors.systemGreen(context).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.checkmark_alt_circle_fill,
            size: 64,
            color: JPCupertinoColors.systemGreen(context),
          ),
        ),
        const SizedBox(height: 32),

        // Título
        Text(
          '¡Contraseña Cambiada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: JPCupertinoColors.label(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),

        // Descripción
        Text(
          'Tu contraseña ha sido actualizada exitosamente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: JPCupertinoColors.secondaryLabel(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Ahora puedes iniciar sesión con tu nueva contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: JPCupertinoColors.tertiaryLabel(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        // Indicador de carga
        const Center(child: CupertinoActivityIndicator(radius: 16)),
        const SizedBox(height: 16),
        Text(
          'Redirigiendo al login...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: JPCupertinoColors.secondaryLabel(context),
          ),
        ),
      ],
    );
  }
}
