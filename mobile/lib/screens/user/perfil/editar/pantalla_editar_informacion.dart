// lib/screens/user/perfil/editar/pantalla_editar_informacion.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:ui';
import '../../../../theme/jp_theme.dart';
import '../../../../services/usuarios_service.dart';
import '../../../../apis/helpers/api_exception.dart';
import '../../../../models/usuario.dart';

class PantallaEditarInformacion extends StatefulWidget {
  final PerfilModel perfil;

  const PantallaEditarInformacion({super.key, required this.perfil});

  @override
  State<PantallaEditarInformacion> createState() =>
      _PantallaEditarInformacionState();
}

class _PantallaEditarInformacionState extends State<PantallaEditarInformacion>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usuarioService = UsuarioService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;
  String _telefonoNumero = '';
  String _dialCode = '+593';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime? _fechaNacimiento;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    // Animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Lógica de respaldo para nombres vacíos
    String nombreInicial = widget.perfil.firstName;
    String apellidoInicial = widget.perfil.lastName;

    if (nombreInicial.isEmpty &&
        apellidoInicial.isEmpty &&
        widget.perfil.usuarioNombre.isNotEmpty) {
      final partes = widget.perfil.usuarioNombre.trim().split(' ');

      if (partes.isNotEmpty) {
        nombreInicial = partes[0];

        if (partes.length > 1) {
          apellidoInicial = partes.sublist(1).join(' ');
        }
      }
    }

    _nombreCtrl = TextEditingController(text: nombreInicial);
    _apellidoCtrl = TextEditingController(text: apellidoInicial);
    _emailCtrl = TextEditingController(text: widget.perfil.usuarioEmail);
    _telefonoCtrl = TextEditingController(
      text: _telefonoNacionalDesdePerfil(widget.perfil.telefono),
    );
    _telefonoNumero = _telefonoCtrl.text;
    _dialCode = _dialCodeDesdePerfil(widget.perfil.telefono);
    _fechaNacimiento = widget.perfil.fechaNacimiento;

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fechaActual = DateTime.now();
    final fechaMinima = DateTime(fechaActual.year - 100);
    final fechaMaxima = DateTime(fechaActual.year - 13);

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? fechaMaxima,
      firstDate: fechaMinima,
      lastDate: fechaMaxima,
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1C1C1E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF007AFF),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Color(0xFF007AFF),
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStatePropertyAll(Color(0xFF1C1C1E)),
              yearForegroundColor: WidgetStatePropertyAll(Color(0xFF1C1C1E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null && mounted) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  Future<void> _guardarCambios() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final datos = <String, dynamic>{};

      if (_nombreCtrl.text.trim() != widget.perfil.firstName) {
        datos['first_name'] = _nombreCtrl.text.trim();
      }

      if (_apellidoCtrl.text.trim() != widget.perfil.lastName) {
        datos['last_name'] = _apellidoCtrl.text.trim();
      }

      if (_emailCtrl.text.trim() != widget.perfil.usuarioEmail) {
        datos['email'] = _emailCtrl.text.trim();
      }

      final telefono = _telefonoParaGuardar();
      if (telefono != widget.perfil.telefono) {
        datos['telefono'] = telefono.isEmpty ? null : telefono;
      }

      if (_fechaNacimiento != widget.perfil.fechaNacimiento) {
        if (_fechaNacimiento != null) {
          final fechaStr =
              '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-'
              '${_fechaNacimiento!.month.toString().padLeft(2, '0')}-'
              '${_fechaNacimiento!.day.toString().padLeft(2, '0')}';
          datos['fecha_nacimiento'] = fechaStr;
        } else {
          datos['fecha_nacimiento'] = null;
        }
      }

      if (datos.isEmpty) {
        if (!mounted) return;
        JPSnackbar.info(context, 'No has realizado cambios');
        return;
      }

      await _usuarioService.actualizarPerfil(datos);
      final perfilActualizado =
          await _usuarioService.obtenerPerfil(forzarRecarga: true);

      if (!mounted) return;
      _nombreCtrl.text = perfilActualizado.firstName;
      _apellidoCtrl.text = perfilActualizado.lastName;
      _emailCtrl.text = perfilActualizado.usuarioEmail;
      _telefonoCtrl.text =
          _telefonoNacionalDesdePerfil(perfilActualizado.telefono);
      _telefonoNumero = _telefonoCtrl.text;
      _fechaNacimiento = perfilActualizado.fechaNacimiento;

      JPSnackbar.success(context, 'Información actualizada correctamente');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, e.getUserFriendlyMessage());
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error inesperado al actualizar');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildPersonalSection(),
                    const SizedBox(height: 24),
                    _buildContactSection(),
                    const SizedBox(height: 40),
                    _buildBotonGuardar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Editar Información',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: Color(0xFF1C1C1E),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Color(0xFF1C1C1E),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 3,
                    ),
                    image: widget.perfil.fotoPerfilUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.perfil.fotoPerfilUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.perfil.fotoPerfilUrl == null
                      ? Center(
                          child: Text(
                            widget.perfil.usuarioNombre.isNotEmpty
                                ? widget.perfil.usuarioNombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mantén tus datos actualizados',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Datos Personales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildIOSTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre',
                    placeholder: 'Tu nombre',
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIOSTextField(
                    controller: _apellidoCtrl,
                    label: 'Apellido',
                    placeholder: 'Tu apellido',
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIOSTextField(
              controller: _emailCtrl,
              label: 'Correo Electrónico',
              placeholder: 'tu@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: const Color(0xFF8E8E93).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cambiar tu correo podría cerrar tu sesión en otros dispositivos',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8E8E93).withValues(alpha: 0.8),
                        height: 1.3,
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

  Widget _buildContactSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.contact_phone,
                    color: Color(0xFF34C759),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Contacto y Detalles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildFechaField(),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: Color(0xFFC7C7CC),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFFF3B30)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'TELÉFONO CELULAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.5,
            ),
          ),
        ),
        IntlPhoneField(
          controller: _telefonoCtrl,
          initialCountryCode: _paisInicialDesdePerfil(widget.perfil.telefono),
          disableLengthCheck: true,
          decoration: InputDecoration(
            hintText: 'Número de celular',
            hintStyle: const TextStyle(
              color: Color(0xFFC7C7CC),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFFF3B30)),
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
          onChanged: (phone) {
            _telefonoNumero = phone.number;
          },
          onCountryChanged: (country) {
            final dial = country.dialCode.replaceAll(RegExp(r'\D'), '');
            _dialCode = dial.isEmpty ? '+593' : '+$dial';
          },
          validator: (phone) {
            final digits =
                phone?.number.replaceAll(RegExp(r'\D'), '') ?? '';
            if (digits.isEmpty) {
              return 'Requerido';
            }
            if (digits.length == 9 || digits.length == 10) {
              return null;
            }
            return 'Número inválido';
          },
        ),
      ],
    );
  }

  Widget _buildFechaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'FECHA DE NACIMIENTO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.5,
            ),
          ),
        ),
        InkWell(
          onTap: _seleccionarFecha,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fechaNacimiento != null
                      ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: _fechaNacimiento != null
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFC7C7CC),
                  ),
                ),
                Row(
                  children: [
                    if (_fechaNacimiento != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_calcularEdad(_fechaNacimiento!)} años',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Color(0xFF8E8E93),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonGuardar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _guardando
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _guardando ? null : _guardarCambios,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            disabledBackgroundColor: const Color(0xFFE5E5EA),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  String _calcularEdad(DateTime fecha) {
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad.toString();
  }

  String _telefonoNacionalDesdePerfil(String? telefono) {
    if (telefono == null || telefono.trim().isEmpty) return '';
    final limpio = telefono.trim();
    if (limpio.startsWith('+593')) {
      final local = limpio.replaceFirst('+593', '');
      if (local.startsWith('0')) return local;
      return '0$local';
    }
    if (limpio.startsWith('+')) {
      return limpio.replaceFirst(RegExp(r'^\+\d+'), '');
    }
    return limpio;
  }

  String _dialCodeDesdePerfil(String? telefono) {
    if (telefono == null || telefono.trim().isEmpty) return '+593';
    final limpio = telefono.trim();
    if (limpio.startsWith('+')) {
      final match = RegExp(r'^\+\d+').firstMatch(limpio);
      if (match != null) return match.group(0) ?? '+593';
    }
    return '+593';
  }

  String _paisInicialDesdePerfil(String? telefono) {
    if (telefono == null || telefono.trim().isEmpty) return 'EC';
    final limpio = telefono.trim();
    if (limpio.startsWith('+593')) return 'EC';
    return 'EC';
  }

  String _telefonoParaGuardar() {
    final numero = _telefonoNumero.trim().isNotEmpty
        ? _telefonoNumero.trim()
        : _telefonoCtrl.text.trim();
    if (numero.isEmpty) return '';

    var digits = numero.replaceAll(RegExp(r'\D'), '');
    final dial = _dialCode.replaceAll(RegExp(r'\D'), '');
    if (dial.isEmpty) return digits;

    // Ecuador: si viene con 0 inicial, lo removemos para construir +5939...
    if (dial == '593' && digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }

    return '+$dial$digits';
  }
}
