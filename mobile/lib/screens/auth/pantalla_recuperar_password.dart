// lib/screens/auth/pantalla_recuperar_password.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/rutas.dart';
import '../../config/api_config.dart';
import '../../apis/helpers/api_exception.dart';
import '../../apis/helpers/api_validators.dart';
import '../../theme/jp_theme.dart'; // Asegúrate de importar tu tema

class PantallaRecuperarPassword extends StatefulWidget {
  const PantallaRecuperarPassword({super.key});

  @override
  State<PantallaRecuperarPassword> createState() =>
      _PantallaRecuperarPasswordState();
}

class _PantallaRecuperarPasswordState extends State<PantallaRecuperarPassword> {
  // ============================================
  // CONTROLADORES Y VARIABLES
  // ============================================
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _api = AuthService();

  bool _loading = false;
  String? _error;
  bool _codigoEnviado = false;

  // Rate limiting
  int? _tiempoEspera;
  int? _intentosRestantes;
  bool _bloqueadoTemporalmente = false;

  // ============================================
  // LÓGICA (Intacta)
  // ============================================

  Future<void> _enviarCodigo() async {
    FocusScope.of(context).unfocus(); // Ocultar teclado

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _tiempoEspera = null;
      _intentosRestantes = null;
      _bloqueadoTemporalmente = false;
    });

    try {
      // ✅ CORRECTO
      await _api.solicitarRecuperacion(
      email: _emailController.text.trim(),
     );
      if (mounted) {
      setState(() {
      _codigoEnviado = true;
      _loading = false;
    });

    // Pequeña pausa para que el usuario vea el éxito antes de cambiar
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Rutas.irAVerificarCodigo(context, _emailController.text.trim());
    }
  }
} on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.statusCode == 429) {
            _bloqueadoTemporalmente = true;
            _tiempoEspera = e.retryAfter ?? 60;
            _error = e.message;
            _mostrarDialogoBloqueado();
          } else {
            _error = e.message;
            _intentosRestantes = e.intentosRestantes;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error de conexión. Intenta nuevamente';
          _loading = false;
        });
      }
    }
  }

  void _mostrarDialogoBloqueado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Acceso Limitado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Has excedido el número de intentos permitidos.'),
            if (_tiempoEspera != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: JPColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: JPColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Espera ${AuthService.formatearTiempoEspera(_tiempoEspera!)}',
                        style: const TextStyle(
                          color: JPColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
    _emailController.dispose();
    super.dispose();
  }

  // ============================================
  // UI OPTIMIZADA
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: JPColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _codigoEnviado
                  ? _buildCodigoEnviadoExito()
                  : _buildFormularioRecuperacion(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioRecuperacion() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderIcon(),
          const SizedBox(height: 32),
          
          const Text(
            'Recuperar Contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: JPColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingresa tu correo electrónico y te enviaremos un código de verificación de 6 dígitos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: JPColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          _buildEmailInput(),
          
          if (_error != null) _buildErrorMessage(),
          
          const SizedBox(height: 24),
          
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_reset_outlined,
          size: 40,
          color: JPColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enabled: !_loading && !_bloqueadoTemporalmente,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ingresa tu correo';
        if (!ApiValidators.esEmailValido(value)) return 'Correo inválido';
        return null;
      },
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        labelStyle: const TextStyle(color: JPColors.textSecondary),
        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: JPColors.textSecondary),
        // Estilo Minimalista Clean
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        fillColor: _bloqueadoTemporalmente 
            ? const Color(0xFFF5F5F5) 
            : const Color(0xFFFAFAFA),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: JPColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: JPColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 20, color: JPColors.error),
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
                style: const TextStyle(fontSize: 12, color: JPColors.warning),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: (_loading || _bloqueadoTemporalmente) ? null : _enviarCodigo,
        style: ElevatedButton.styleFrom(
          backgroundColor: JPColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _bloqueadoTemporalmente ? 'BLOQUEADO' : 'ENVIAR CÓDIGO',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  // ============================================
  // UI - PANTALLA ÉXITO (Simplificada)
  // ============================================
  
  Widget _buildCodigoEnviadoExito() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: JPColors.success,
        ),
        const SizedBox(height: 24),
        
        const Text(
          '¡Código enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: JPColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              const Text(
                'Hemos enviado las instrucciones a:',
                style: TextStyle(color: JPColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _emailController.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: JPColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Nota de expiración discreta
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 6),
            Text(
              'Expira en ${ApiConfig.codigoExpiracionMinutos} minutos',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }
}