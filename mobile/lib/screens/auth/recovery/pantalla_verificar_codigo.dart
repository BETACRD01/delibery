// lib/screens/auth/recuperacion/pantalla_verificar_codigo.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../services/auth/auth_service.dart';
import '../../../config/routing/rutas.dart';
import '../../../config/network/api_config.dart';
import '../../../apis/helpers/api_exception.dart';
import '../../../theme/jp_theme.dart';
import '../../../theme/app_colors_primary.dart';

/// Pantalla para verificar el código de 6 dígitos
/// ✅ Maneja rate limiting y bloqueos
class PantallaVerificarCodigo extends StatefulWidget {
  const PantallaVerificarCodigo({super.key});

  @override
  State<PantallaVerificarCodigo> createState() =>
      _PantallaVerificarCodigoState();
}

class _PantallaVerificarCodigoState extends State<PantallaVerificarCodigo> {
  // ============================================
  // CONTROLADORES
  // ============================================
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _api = AuthService();

  // ============================================
  // ESTADO
  // ============================================
  String? _email;
  bool _loading = false;
  String? _error;
  int? _intentosRestantes;
  bool _bloqueado = false;


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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ============================================
  // MÉTODOS LÓGICOS
  // ============================================

  /// Obtiene el email de los argumentos de navegación
  void _obtenerArgumentos() {
    final args = Rutas.obtenerArgumentos<Map<String, dynamic>>(context);
    if (args != null && args.containsKey('email')) {
      setState(() {
        _email = args['email'] as String;
      });
      // Auto-focus en el primer campo
      _focusNodes[0].requestFocus();
    } else {
      // Si no hay email, volver atrás
      Navigator.pop(context);
    }
  }

  /// Obtiene el código completo de los 6 campos
  String _obtenerCodigo() {
    return _controllers.map((c) => c.text).join();
  }

  /// Verifica si el código está completo
  bool _codigoCompleto() {
    return _obtenerCodigo().length == 6;
  }

  /// ✅ Verifica el código con el backend
  Future<void> _verificarCodigo() async {
    if (!_codigoCompleto()) {
      setState(() => _error = 'Por favor ingresa los 6 dígitos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final codigo = _obtenerCodigo();

      await _api.verificarCodigo(email: _email!, codigo: codigo);

      if (mounted) {
        // ✅ Código válido, ir a pantalla de nueva contraseña
        await Rutas.irANuevaPassword(context, email: _email!, codigo: codigo);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _intentosRestantes = e.intentosRestantes;
          _bloqueado = e.isCuentaBloqueada || e.statusCode == 429;
          _loading = false;
        });

        // Si está bloqueado, mostrar diálogo
        if (_bloqueado) {
          _mostrarDialogoBloqueado(e);
        }
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

  /// Solicita un nuevo código
  Future<void> _solicitarNuevoCodigo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.solicitarRecuperacion(email: _email!);

      if (mounted) {
        setState(() => _loading = false);

        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Código Enviado'),
              content: const Text('Nuevo código enviado a tu email'),
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
          ),
        );

        // Limpiar campos
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
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
          _error = 'Error al enviar nuevo código';
          _loading = false;
        });
      }
    }
  }

  // ============================================
  // HELPERS DE UI
  // ============================================

  /// Helper local para formatear el tiempo
  String _formatearTiempoEspera(int segundos) {
    final min = segundos ~/ 60;
    final sec = segundos % 60;
    return min > 0 ? '$min m $sec s' : '$sec s';
  }

  /// Muestra diálogo de cuenta bloqueada
  void _mostrarDialogoBloqueado(ApiException error) {
    final tiempoEspera = error.retryAfter ?? 900; // 15 minutos por defecto

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Código Bloqueado',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Has excedido el número máximo de intentos para verificar el código.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemYellow(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.timer,
                        size: 18,
                        color: JPCupertinoColors.systemYellow(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Espera ${_formatearTiempoEspera(tiempoEspera)}',
                        style: TextStyle(
                          color: JPCupertinoColors.systemYellow(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Por seguridad, deberás solicitar un nuevo código después de este tiempo.',
              style: TextStyle(
                fontSize: 13,
                color: JPCupertinoColors.secondaryLabel(context),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a recuperar password
            },
            child: Text(
              'Volver',
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

  /// Maneja el cambio de texto en los campos
  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      // Avanzar al siguiente campo
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Retroceder al campo anterior
      _focusNodes[index - 1].requestFocus();
    }

    // Si el código está completo, verificar automáticamente
    if (_codigoCompleto() && !_loading) {
      _verificarCodigo();
    }

    setState(() {}); // Actualizar UI
  }

  // ============================================
  // UI - BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
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
              child: Column(
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
                      CupertinoIcons.checkmark_shield,
                      size: 48,
                      color: AppColorsPrimary.main,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Título
                  Text(
                    'Verificar Código',
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
                  if (_email != null)
                    Text(
                      'Ingresa el código de 6 dígitos que enviamos a\n$_email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: JPCupertinoColors.secondaryLabel(context),
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 40),

                  // Campos de código
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 48,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _bloqueado
                              ? JPCupertinoColors.tertiarySurface(context)
                              : JPCupertinoColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: JPCupertinoColors.separator(context),
                            width: 0.5,
                          ),
                        ),
                        child: CupertinoTextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          enabled: !_loading && !_bloqueado,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: JPCupertinoColors.label(context),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const BoxDecoration(),
                          onChanged: (value) => _onChanged(index, value),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Mensaje de error
                  if (_error != null) ...[
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
                    const SizedBox(height: 12),
                  ],

                  // Intentos restantes
                  if (_intentosRestantes != null && _intentosRestantes! > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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

                  // Info de expiración
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

                  const SizedBox(height: 32),

                  // Botón verificar
                  if (!_loading)
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: _codigoCompleto() && !_bloqueado
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
                        boxShadow: _codigoCompleto() && !_bloqueado
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
                        onPressed: _codigoCompleto() && !_bloqueado ? _verificarCodigo : null,
                        color: _codigoCompleto() && !_bloqueado
                            ? CupertinoColors.transparent
                            : JPCupertinoColors.quaternaryLabel(context),
                        borderRadius: BorderRadius.circular(14),
                        padding: EdgeInsets.zero,
                        child: Text(
                          'Verificar Código',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _codigoCompleto() && !_bloqueado
                                ? CupertinoColors.white
                                : JPCupertinoColors.tertiaryLabel(context),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                  // Indicador de carga
                  if (_loading) ...[
                    const Center(child: CupertinoActivityIndicator(radius: 16)),
                    const SizedBox(height: 16),
                    Text(
                      'Verificando código...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: JPCupertinoColors.secondaryLabel(context),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Botón solicitar nuevo código
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: (_loading || _bloqueado) ? null : _solicitarNuevoCodigo,
                    child: Text(
                      '¿No recibiste el código? Solicitar uno nuevo',
                      style: TextStyle(
                        color: (_loading || _bloqueado)
                            ? JPCupertinoColors.quaternaryLabel(context)
                            : AppColorsPrimary.main,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
