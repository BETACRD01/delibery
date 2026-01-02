// lib/screens/auth/pantalla_recuperar_password.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/auth/auth_service.dart';
import '../../../config/routing/rutas.dart';
import '../../../config/network/api_config.dart';
import '../../../apis/helpers/api_exception.dart';
import '../../../services/core/validation/validators.dart';
import '../../../theme/jp_theme.dart';
import '../../../theme/app_colors_primary.dart';

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
  final _api = AuthService();

  bool _loading = false;
  String? _error;
  bool _codigoEnviado = false;

  // Rate limiting
  int? _tiempoEspera;
  int? _intentosRestantes;
  bool _bloqueadoTemporalmente = false;

  @override
  void initState() {
    super.initState();
    // Listener para actualizar el botón cuando cambie el email
    _emailController.addListener(() {
      setState(() {});
    });
  }

  // ============================================
  // LÓGICA
  // ============================================

  Future<void> _enviarCodigo() async {
    FocusScope.of(context).unfocus(); // Ocultar teclado

    // Validar email
    final email = _emailController.text.trim();
    if (email.isEmpty || !Validators.esEmailValido(email)) {
      setState(() => _error = 'Por favor ingresa un correo válido');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _tiempoEspera = null;
      _intentosRestantes = null;
      _bloqueadoTemporalmente = false;
    });

    try {
      await _api.solicitarRecuperacion(email: _emailController.text.trim());

      if (mounted) {
        setState(() {
          _codigoEnviado = true;
          _loading = false;
        });

        // Pequeña pausa para que el usuario vea el éxito antes de cambiar
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await Rutas.irAVerificarCodigo(context, _emailController.text.trim());
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

  // Helper local para formatear el tiempo (Antes estaba en AuthService)
  String _formatearTiempoEspera(int segundos) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    return min > 0 ? '$min m $sec s' : '$sec s';
  }

  void _mostrarDialogoBloqueado() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Acceso Limitado',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Has excedido el número de intentos permitidos.'),
            if (_tiempoEspera != null) ...[
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
                      'Espera ${_formatearTiempoEspera(_tiempoEspera!)}',
                      style: TextStyle(
                        color: JPCupertinoColors.systemYellow(context),
                        fontWeight: FontWeight.w600,
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
    _emailController.dispose();
    super.dispose();
  }

  // ============================================
  // UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(
          context,
        ).withValues(alpha: 0.95),
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
              Icon(CupertinoIcons.back, color: AppColorsPrimary.main, size: 28),
              const SizedBox(width: 4),
              Text(
                'Atrás',
                style: TextStyle(color: AppColorsPrimary.main, fontSize: 17),
              ),
            ],
          ),
        ),
      ),
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _codigoEnviado
                    ? _buildCodigoEnviadoExito()
                    : _buildFormularioRecuperacion(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioRecuperacion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderIcon(),
        const SizedBox(height: 28),

        Text(
          'Recuperar Contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: JPCupertinoColors.label(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ingresa tu correo electrónico y te enviaremos un código de verificación de 6 dígitos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: JPCupertinoColors.secondaryLabel(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        _buildEmailInput(),

        if (_error != null) _buildErrorMessage(),

        const SizedBox(height: 32),

        _buildSendButton(),
      ],
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
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
          CupertinoIcons.lock_shield,
          size: 48,
          color: AppColorsPrimary.main,
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    final hasError = _error != null && !_bloqueadoTemporalmente;

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
            CupertinoIcons.mail,
            color: hasError
                ? JPCupertinoColors.systemRed(context)
                : AppColorsPrimary.main,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: _emailController,
              placeholder: 'Correo electrónico',
              placeholderStyle: TextStyle(
                color: JPCupertinoColors.placeholder(context),
                fontSize: 17,
              ),
              style: TextStyle(
                color: JPCupertinoColors.label(context),
                fontSize: 17,
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !_loading && !_bloqueadoTemporalmente,
              decoration: const BoxDecoration(),
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

  Widget _buildSendButton() {
    // Validación del email
    final emailValid =
        _emailController.text.trim().isNotEmpty &&
        Validators.esEmailValido(_emailController.text.trim());
    final canSend = emailValid && !_loading && !_bloqueadoTemporalmente;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: canSend
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
        boxShadow: canSend
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
        onPressed: canSend ? _enviarCodigo : null,
        color: canSend
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
                _bloqueadoTemporalmente ? 'Bloqueado' : 'Enviar Código',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: canSend
                      ? CupertinoColors.white
                      : JPCupertinoColors.tertiaryLabel(context),
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildCodigoEnviadoExito() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 96,
          width: 96,
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
            CupertinoIcons.checkmark_alt_circle,
            size: 56,
            color: JPCupertinoColors.systemGreen(context),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          '¡Código Enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: JPCupertinoColors.label(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: JPCupertinoColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: JPCupertinoColors.separator(context),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Hemos enviado el código a:',
                style: TextStyle(
                  color: JPCupertinoColors.secondaryLabel(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _emailController.text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: JPCupertinoColors.label(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JPCupertinoColors.systemBlue(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 18,
                color: JPCupertinoColors.systemBlue(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Expira en ${ApiConfig.codigoExpiracionMinutos} minutos',
                style: TextStyle(
                  color: JPCupertinoColors.systemBlue(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),
        const Center(child: CupertinoActivityIndicator(radius: 16)),
      ],
    );
  }
}
