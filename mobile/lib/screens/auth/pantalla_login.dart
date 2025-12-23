// lib/screens/auth/pantalla_login.dart

import 'package:flutter/material.dart';

import '../../apis/helpers/api_exception.dart';
import '../../config/rutas.dart';
import '../../services/auth_service.dart';
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
  bool _obscurePassword = true;
  String? _error;
  int? _intentosRestantes;

  // ============================================
  // LÓGICA DE NEGOCIO (Intacta)
  // ============================================

  Future<void> _login() async {
    // Ocultar teclado
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

      // CORREGIDO: Usar pushReplacementNamed en lugar de MaterialPageRoute
      // Esto evita el doble push y usa el sistema de rutas correctamente
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

  void _mostrarDialogoBloqueado(int? tiempoEspera) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Acceso Bloqueado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Has excedido el número de intentos.'),
            if (tiempoEspera != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: JPColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Espera $tiempoEspera segundos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: JPColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
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

  // ============================================
  // UI OPTIMIZADA
  // ============================================
  @override
  Widget build(BuildContext context) {
    // Usamos un fondo blanco limpio para aspecto profesional
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildInputs(),
                  if (_error != null) _buildErrorMessage(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
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
        width: 190,
        height: 190,
        child: Image.asset(
          'assets/images/Beta.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: JPColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Bienvenido',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: JPColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ingresa a tu cuenta JP Express',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: JPColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        _buildTextField(
          controller: _usuarioController,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          isObscure: _obscurePassword,
          onToggleVisibility: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading ? null : _irARecuperarPassword,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(color: JPColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: inputType,
      enabled: !_loading,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: JPColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: JPColors.textSecondary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: JPColors.textSecondary,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        // Borde limpio y minimalista
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: JPColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA), // Gris muy claro para el input
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: JPColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: JPColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: JPColors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: JPColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (_intentosRestantes != null && _intentosRestantes! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Intentos restantes: $_intentosRestantes',
                style: const TextStyle(
                  fontSize: 12,
                  color: JPColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _loading
              ? JPColors.primary.withValues(alpha: 0.7)
              : JPColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'INICIAR SESIÓN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Nuevo en JP Express? ',
          style: TextStyle(color: JPColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: _loading ? null : _irARegistro,
          child: const Text(
            'Crear cuenta',
            style: TextStyle(
              color: JPColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaRegistro()),
    );
  }

  void _irARecuperarPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaRecuperarPassword()),
    );
  }
}
