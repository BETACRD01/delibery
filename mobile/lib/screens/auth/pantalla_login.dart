// lib/screens/auth/pantalla_login.dart

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../apis/helpers/api_exception.dart';
import '../../config/rutas.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/google_auth_service.dart';
import '../../theme/app_colors_primary.dart';
import '../../theme/jp_theme.dart';
import './pantalla_recuperar_password.dart';
import './pantalla_registro.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = AuthService();

  bool _loading = false;
  bool _loadingGoogle = false;
  bool _obscurePassword = true;
  String? _error;
  int? _intentosRestantes;

  @override
  void initState() {
    super.initState();
    // Listener para actualizar el botón cuando cambien los campos
    _usuarioController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_usuarioController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _intentosRestantes = null;
    });

    try {
      await _api.login(
        email: _usuarioController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        await Navigator.pushReplacementNamed(context, Rutas.router);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          if (e.statusCode == 400 || e.statusCode == 401) {
            _intentosRestantes = e.details?['intentos_restantes'];
          }
          if (e.statusCode == 429) {
            _mostrarDialogoBloqueado(e.details?['retry_after']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error de conexión con el servidor');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loadingGoogle = true;
      _error = null;
    });

    try {
      final result = await GoogleAuthService().signInWithGoogle();

      if (result == null) {
        // Usuario canceló
        if (mounted) setState(() => _loadingGoogle = false);
        return;
      }

      if (mounted) {
        await Navigator.pushReplacementNamed(context, Rutas.router);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error al conectar con Google');
      }
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  void _mostrarDialogoBloqueado(int? tiempoEspera) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Acceso Bloqueado',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Has excedido el número de intentos.'),
            if (tiempoEspera != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JPCupertinoColors.systemYellow(
                    context,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.timer,
                      size: 18,
                      color: JPCupertinoColors.systemYellow(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Espera $tiempoEspera segundos',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: JPCupertinoColors.systemYellow(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(
                color: AppColorsPrimary.main,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 17,
          color: JPCupertinoColors.label(context),
          fontFamily: '.SF Pro Text',
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 36),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildInputs(),
                    if (_error != null) _buildErrorMessage(),
                    const SizedBox(height: 32),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                    const SizedBox(height: 28),
                    _buildFooter(),
                    const SizedBox(height: 40),
                    _buildVersion(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Image.asset(
          'assets/images/Beta.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(
            CupertinoIcons.cube_box,
            size: 90,
            color: AppColorsPrimary.main,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Bienvenido',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: JPCupertinoColors.label(context),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ingresa a tu cuenta JP Express',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: JPCupertinoColors.secondaryLabel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        _buildCupertinoField(
          controller: _usuarioController,
          placeholder: 'Correo electrónico',
          icon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildCupertinoPasswordField(
          controller: _passwordController,
          placeholder: 'Contraseña',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: _loading ? null : _irARecuperarPassword,
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                color: _loading
                    ? JPCupertinoColors.quaternaryLabel(context)
                    : JPCupertinoColors.secondaryLabel(context),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCupertinoField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final hasError = _error != null;

    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? JPCupertinoColors.systemRed(context).withValues(alpha: 0.5)
              : JPCupertinoColors.separator(context),
          width: hasError ? 1.5 : 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: hasError
                ? JPCupertinoColors.systemRed(context)
                : AppColorsPrimary.main,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: TextStyle(
                color: JPCupertinoColors.placeholder(context),
                fontSize: 17,
              ),
              style: TextStyle(
                color: JPCupertinoColors.label(context),
                fontSize: 17,
              ),
              keyboardType: keyboardType,
              autocorrect: false,
              enabled: !_loading,
              decoration: const BoxDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final hasError = _error != null;

    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? JPCupertinoColors.systemRed(context).withValues(alpha: 0.5)
              : JPCupertinoColors.separator(context),
          width: hasError ? 1.5 : 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.lock,
            color: hasError
                ? JPCupertinoColors.systemRed(context)
                : AppColorsPrimary.main,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              obscureText: obscure,
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
                onPressed: onToggle,
                child: Icon(
                  obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  color: JPCupertinoColors.secondaryLabel(context),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: JPCupertinoColors.systemRed(
                context,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: JPCupertinoColors.systemRed(
                  context,
                ).withValues(alpha: 0.3),
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
          if (_intentosRestantes != null && _intentosRestantes! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    size: 14,
                    color: JPCupertinoColors.systemYellow(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Intentos restantes: $_intentosRestantes',
                    style: TextStyle(
                      fontSize: 13,
                      color: JPCupertinoColors.systemYellow(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final canLogin =
        _usuarioController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_loading;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: canLogin
            ? LinearGradient(
                colors: [
                  AppColorsPrimary.main,
                  AppColorsPrimary.main.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: canLogin
            ? [
                BoxShadow(
                  color: AppColorsPrimary.main.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: CupertinoButton(
        onPressed: canLogin ? _login : null,
        color: canLogin
            ? Colors.transparent
            : JPCupertinoColors.quaternaryLabel(context),
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.zero,
        child: _loading
            ? const CupertinoActivityIndicator(
                color: CupertinoColors.white,
                radius: 12,
              )
            : Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: canLogin
                      ? CupertinoColors.white
                      : JPCupertinoColors.tertiaryLabel(context),
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: JPCupertinoColors.separator(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              color: JPCupertinoColors.secondaryLabel(context),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: JPCupertinoColors.separator(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    final isDisabled = _loading || _loadingGoogle;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isDisabled
            ? JPCupertinoColors.quaternaryLabel(context)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JPCupertinoColors.separator(context),
          width: 1,
        ),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: CupertinoButton(
        onPressed: isDisabled ? null : _loginWithGoogle,
        padding: EdgeInsets.zero,
        child: _loadingGoogle
            ? const CupertinoActivityIndicator(radius: 12)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Logo Original
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: JPCupertinoColors.label(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Nuevo en JP Express? ',
          style: TextStyle(
            color: JPCupertinoColors.secondaryLabel(context),
            fontSize: 15,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _loading ? null : _irARegistro,
          child: Text(
            'Crear Cuenta',
            style: TextStyle(
              color: _loading
                  ? JPCupertinoColors.quaternaryLabel(context)
                  : AppColorsPrimary.main,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersion() {
    return Center(
      child: Text(
        'Versión 1.0.0',
        style: TextStyle(
          color: AppColorsPrimary.main, // Celeste empresarial
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _irARegistro() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaRegistro()),
    );
  }

  void _irARecuperarPassword() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaRecuperarPassword()),
    );
  }
}
