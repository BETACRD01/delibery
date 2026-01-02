// lib/screens/auth/forms/registro_usuario_form.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../services/auth/auth_service.dart';
import '../../../apis/helpers/api_exception.dart';
import '../../../widgets/legal/pantalla_documento_legal.dart';
import '../../../theme/app_colors_primary.dart';
import '../../../theme/jp_theme.dart';

class RegistroUsuarioForm extends StatefulWidget {
  const RegistroUsuarioForm({super.key});

  @override
  State<RegistroUsuarioForm> createState() => _RegistroUsuarioFormState();
}

class _RegistroUsuarioFormState extends State<RegistroUsuarioForm> {
  final _api = AuthService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  // Variable para guardar el número limpio (+59399...)
  String _celularCompleto = '';

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmar = true;
  bool _aceptaTerminos = false;
  DateTime? _fechaNacimiento;
  String? _error;

  // Validaciones en tiempo real
  String? _nombreError;
  String? _apellidoError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmarPasswordError;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColorsPrimary.main,
              onPrimary: CupertinoColors.white,
              onSurface: CupertinoColors.black,
              surface: CupertinoColors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: CupertinoColors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColorsPrimary.main,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: CupertinoColors.white,
              headerBackgroundColor: AppColorsPrimary.main,
              headerForegroundColor: CupertinoColors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
              headerHelpStyle: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.white,
              ),
              dayStyle: const TextStyle(fontSize: 13),
              weekdayStyle: TextStyle(
                fontSize: 12,
                color: AppColorsPrimary.main,
                fontWeight: FontWeight.w600,
              ),
              yearStyle: const TextStyle(fontSize: 14),
              todayBorder: BorderSide(color: AppColorsPrimary.main, width: 1),
              todayForegroundColor: WidgetStateProperty.all(
                AppColorsPrimary.main,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(0.9), // Texto más pequeño
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  int _calcularEdad() {
    if (_fechaNacimiento == null) return 0;
    final hoy = DateTime.now();
    int edad = hoy.year - _fechaNacimiento!.year;
    if (hoy.month < _fechaNacimiento!.month ||
        (hoy.month == _fechaNacimiento!.month &&
            hoy.day < _fechaNacimiento!.day)) {
      edad--;
    }
    return edad;
  }

  String _formatearFechaParaMostrar() {
    if (_fechaNacimiento == null) return 'Selecciona tu fecha de nacimiento';
    return '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}';
  }

  String _formatearFechaParaBackend() {
    return '${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}';
  }

  bool _validarCampos() {
    bool esValido = true;

    // Validar nombre
    if (_nombreController.text.trim().isEmpty) {
      setState(() => _nombreError = 'El nombre es requerido');
      esValido = false;
    } else {
      setState(() => _nombreError = null);
    }

    // Validar apellido
    if (_apellidoController.text.trim().isEmpty) {
      setState(() => _apellidoError = 'El apellido es requerido');
      esValido = false;
    } else {
      setState(() => _apellidoError = null);
    }

    // Validar username
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _usernameError = 'El usuario es requerido');
      esValido = false;
    } else {
      setState(() => _usernameError = null);
    }

    // Validar email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'El correo es requerido');
      esValido = false;
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'Correo inválido');
      esValido = false;
    } else {
      setState(() => _emailError = null);
    }

    // Validar celular
    if (_celularCompleto.isEmpty || _celularCompleto.length < 8) {
      setState(() => _error = 'Ingresa un número de celular válido');
      esValido = false;
    }

    // Validar fecha
    if (_fechaNacimiento == null) {
      setState(() => _error = 'Ingresa tu fecha de nacimiento');
      esValido = false;
    } else if (_calcularEdad() < 18) {
      setState(() => _error = 'Debes ser mayor de 18 años');
      esValido = false;
    }

    // Validar contraseñas
    final password = _passwordController.text.trim();
    final password2 = _confirmarPasswordController.text.trim();

    if (password.isEmpty) {
      setState(() => _passwordError = 'La contraseña es requerida');
      esValido = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Mínimo 8 caracteres');
      esValido = false;
    } else {
      setState(() => _passwordError = null);
    }

    if (password2.isEmpty) {
      setState(() => _confirmarPasswordError = 'Confirma tu contraseña');
      esValido = false;
    } else if (password != password2) {
      setState(() => _confirmarPasswordError = 'Las contraseñas no coinciden');
      esValido = false;
    } else {
      setState(() => _confirmarPasswordError = null);
    }

    // Validar términos
    if (!_aceptaTerminos) {
      setState(() => _error = 'Debes aceptar los términos y condiciones');
      esValido = false;
    }

    return esValido;
  }

  Future<void> _registrar() async {
    setState(() => _error = null);

    if (!_validarCampos()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final data = {
        'first_name': _nombreController.text.trim(),
        'last_name': _apellidoController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'celular': _celularCompleto,
        'fecha_nacimiento': _formatearFechaParaBackend(),
        'password': _passwordController.text.trim(),
        'password2': _confirmarPasswordController.text.trim(),
        'terminos_aceptados': _aceptaTerminos,
        'rol': 'USUARIO',
      };

      await _api.register(data);

      if (mounted) {
        // Mostrar mensaje de éxito
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: AppColorsPrimary.main,
              size: 48,
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                '¡Registro exitoso!\n\nAhora puedes iniciar sesión con tu cuenta.',
                style: TextStyle(fontSize: 15),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Iniciar Sesión'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );

        // Volver al login
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error de conexión');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Muestra la pantalla de términos y condiciones estilo iPhone
  void _mostrarTerminos() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) =>
            const PantallaDocumentoLegal(tipo: TipoDocumento.terminos),
      ),
    );
  }

  /// Muestra la pantalla de política de privacidad estilo iPhone
  void _mostrarPrivacidad() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) =>
            const PantallaDocumentoLegal(tipo: TipoDocumento.privacidad),
      ),
    );
  }

  // ================== iOS-STYLE PHONE FIELD ==================
  Widget _buildCampoCelularInternacional() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(CupertinoIcons.phone, color: AppColorsPrimary.main, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IntlPhoneField(
                    controller: _celularController,
                    decoration: InputDecoration(
                      hintText: '991234567',
                      hintStyle: TextStyle(
                        color: JPCupertinoColors.placeholder(context),
                        fontSize: 17,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: false,
                    ),
                    initialCountryCode: 'EC',
                    languageCode: 'es',
                    showCountryFlag: true,
                    flagsButtonPadding: const EdgeInsets.only(right: 8),
                    dropdownIconPosition: IconPosition.trailing,
                    dropdownIcon: Icon(
                      CupertinoIcons.chevron_down,
                      color: JPCupertinoColors.secondaryLabel(context),
                      size: 16,
                    ),
                    dropdownTextStyle: TextStyle(
                      fontSize: 17,
                      color: JPCupertinoColors.label(context),
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      color: JPCupertinoColors.label(context),
                      height: 1.2,
                    ),
                    disableLengthCheck: false,
                    invalidNumberMessage: 'Número inválido',
                    onChanged: (phone) {
                      String numeroUsuario = phone.number;
                      if (numeroUsuario.startsWith('0')) {
                        numeroUsuario = numeroUsuario.substring(1);
                      }
                      setState(() {
                        _celularCompleto = '${phone.countryCode}$numeroUsuario';
                      });
                    },
                    onCountryChanged: (country) {
                      _celularController.clear();
                      _celularCompleto = '';
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 17,
        color: JPCupertinoColors.secondaryLabel(context),
        fontFamily: '.SF Pro Text',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de información personal
          _buildSectionHeader('INFORMACIÓN PERSONAL'),
          const SizedBox(height: 8),
          _buildGroupedSection([
            _buildCupertinoField(
              controller: _nombreController,
              placeholder: 'Nombre',
              icon: CupertinoIcons.person,
              error: _nombreError,
              onChanged: (_) => setState(() => _nombreError = null),
            ),
            _buildDivider(),
            _buildCupertinoField(
              controller: _apellidoController,
              placeholder: 'Apellido',
              icon: CupertinoIcons.person_fill,
              error: _apellidoError,
              onChanged: (_) => setState(() => _apellidoError = null),
            ),
          ]),

          const SizedBox(height: 24),

          // Sección de cuenta
          _buildSectionHeader('CUENTA'),
          const SizedBox(height: 8),
          _buildGroupedSection([
            _buildCupertinoField(
              controller: _usernameController,
              placeholder: 'Usuario',
              icon: CupertinoIcons.at,
              error: _usernameError,
              onChanged: (_) => setState(() => _usernameError = null),
            ),
            _buildDivider(),
            _buildCupertinoField(
              controller: _emailController,
              placeholder: 'Correo electrónico',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
              error: _emailError,
              onChanged: (_) => setState(() => _emailError = null),
            ),
          ]),

          const SizedBox(height: 24),

          // Sección de contacto
          _buildSectionHeader('CONTACTO'),
          const SizedBox(height: 8),
          _buildGroupedSection([_buildCampoCelularInternacional()]),

          const SizedBox(height: 24),

          // Sección de fecha de nacimiento
          _buildSectionHeader('FECHA DE NACIMIENTO'),
          const SizedBox(height: 8),
          _buildGroupedSection([_buildCampoFecha()]),

          const SizedBox(height: 24),

          // Sección de seguridad
          _buildSectionHeader('SEGURIDAD'),
          const SizedBox(height: 8),
          _buildGroupedSection([
            _buildCupertinoPasswordField(
              controller: _passwordController,
              placeholder: 'Contraseña',
              obscure: _obscurePassword,
              error: _passwordError,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onChanged: (_) => setState(() => _passwordError = null),
            ),
            _buildDivider(),
            _buildCupertinoPasswordField(
              controller: _confirmarPasswordController,
              placeholder: 'Confirmar contraseña',
              obscure: _obscureConfirmar,
              error: _confirmarPasswordError,
              onToggle: () =>
                  setState(() => _obscureConfirmar = !_obscureConfirmar),
              onChanged: (_) => setState(() => _confirmarPasswordError = null),
            ),
          ]),

          const SizedBox(height: 24),

          // Términos y condiciones
          _buildTerminos(),

          // Error general
          if (_error != null) _buildError(),

          const SizedBox(height: 24),

          // Botón de registro
          _buildBoton(),
        ],
      ),
    );
  }

  // ================== iOS-STYLE SECTION HEADER ==================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColorsPrimary.main, // Celeste empresarial
          letterSpacing: -0.08,
        ),
      ),
    );
  }

  // ================== iOS-STYLE GROUPED SECTION ==================
  Widget _buildGroupedSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: JPCupertinoColors.separator(context),
          width: 1.0,
        ),
      ),
      child: Column(children: children),
    );
  }

  // ================== iOS-STYLE DIVIDER ==================
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Container(
        height: 0.5,
        color: JPCupertinoColors.separator(context),
      ),
    );
  }

  // ================== iOS-STYLE TEXT FIELD ==================
  Widget _buildCupertinoField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? error,
    Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColorsPrimary.main, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoTextField(
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
                  decoration: const BoxDecoration(),
                  keyboardType: keyboardType,
                  enabled: !_loading,
                  onChanged: onChanged,
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: TextStyle(
                      color: JPCupertinoColors.systemRed(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== iOS-STYLE PASSWORD FIELD ==================
  Widget _buildCupertinoPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscure,
    required VoidCallback onToggle,
    String? error,
    Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(CupertinoIcons.lock, color: AppColorsPrimary.main, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoTextField(
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
                  decoration: const BoxDecoration(),
                  enabled: !_loading,
                  onChanged: onChanged,
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
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: TextStyle(
                      color: JPCupertinoColors.systemRed(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== iOS-STYLE DATE PICKER FIELD ==================
  Widget _buildCampoFecha() {
    return GestureDetector(
      onTap: _loading ? null : _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: JPCupertinoColors.surface(context),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              color: AppColorsPrimary.main,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatearFechaParaMostrar(),
                style: TextStyle(
                  fontSize: 17,
                  color: _fechaNacimiento == null
                      ? JPCupertinoColors.placeholder(context)
                      : JPCupertinoColors.label(context),
                ),
              ),
            ),
            if (_fechaNacimiento != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _calcularEdad() >= 18
                      ? JPCupertinoColors.systemGreen(
                          context,
                        ).withValues(alpha: 0.15)
                      : JPCupertinoColors.systemRed(
                          context,
                        ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_calcularEdad()} años',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _calcularEdad() >= 18
                        ? JPCupertinoColors.systemGreen(context)
                        : JPCupertinoColors.systemRed(context),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              color: JPCupertinoColors.separator(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ================== iOS-STYLE TERMS & CONDITIONS ==================
  Widget _buildTerminos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JPCupertinoColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: JPCupertinoColors.separator(context),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              value: _aceptaTerminos,
              activeTrackColor: AppColorsPrimary.main,
              onChanged: _loading
                  ? null
                  : (v) => setState(() => _aceptaTerminos = v),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: JPCupertinoColors.label(context),
                    height: 1.5,
                    fontFamily: '.SF Pro Text',
                  ),
                  children: [
                    const TextSpan(
                      text: 'Acepto los ',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Términos y Condiciones',
                      style: TextStyle(
                        color: AppColorsPrimary.main,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColorsPrimary.main.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _mostrarTerminos,
                    ),
                    const TextSpan(
                      text: ' y la ',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Política de Privacidad',
                      style: TextStyle(
                        color: AppColorsPrimary.main,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColorsPrimary.main.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _mostrarPrivacidad,
                    ),
                    const TextSpan(
                      text: '.',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== iOS-STYLE ERROR MESSAGE ==================
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JPCupertinoColors.systemRed(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: JPCupertinoColors.systemRed(context).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            color: JPCupertinoColors.systemRed(context),
            size: 22,
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
    );
  }

  // ================== iOS-STYLE BUTTON ==================
  Widget _buildBoton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: _loading
            ? null
            : LinearGradient(
                colors: [
                  AppColorsPrimary.main,
                  AppColorsPrimary.main.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _loading
            ? null
            : [
                BoxShadow(
                  color: AppColorsPrimary.main.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: CupertinoButton(
        onPressed: _loading ? null : _registrar,
        color: _loading
            ? JPCupertinoColors.quaternaryLabel(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.zero,
        child: _loading
            ? const CupertinoActivityIndicator(
                color: CupertinoColors.white,
                radius: 12,
              )
            : const Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
