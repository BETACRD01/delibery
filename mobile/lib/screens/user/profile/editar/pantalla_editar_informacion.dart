// lib/screens/user/perfil/editar/pantalla_editar_informacion.dart

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../apis/helpers/api_exception.dart';
import '../../../../models/auth/usuario.dart';
import '../../../../services/usuarios/usuarios_service.dart';
import '../../../../theme/app_colors_primary.dart';
import '../../../../theme/jp_theme.dart';
import '../../../../widgets/util/phone_normalizer.dart';
import '../../../../widgets/util/image_orientation_fixer.dart';

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
  final _imagePicker = ImagePicker();

  // Estado de foto de perfil
  File? _imagenSeleccionada;
  String? _fotoActualUrl;
  bool _guardandoFoto = false;

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
    _fotoActualUrl = widget.perfil.fotoPerfilUrl;

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

  // ══════════════════════════════════════════════════════════════════════════
  // 📸 MÉTODOS DE FOTO DE PERFIL
  // ══════════════════════════════════════════════════════════════════════════

  void _mostrarOpcionesFoto() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Cambiar Foto de Perfil'),
        message: const Text('Elige una opción para actualizar tu foto'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _seleccionarDesdeGaleria();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, color: AppColorsPrimary.main),
                SizedBox(width: 10),
                Text('Seleccionar de Galería'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _tomarFoto();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, color: AppColorsPrimary.main),
                SizedBox(width: 10),
                Text('Tomar Foto'),
              ],
            ),
          ),
          if (_fotoActualUrl != null || _imagenSeleccionada != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _eliminarFoto();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.delete,
                    color: CupertinoColors.destructiveRed,
                  ),
                  SizedBox(width: 10),
                  Text('Eliminar Foto'),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _seleccionarDesdeGaleria() async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: true,
      );

      if (imagen != null && mounted) {
        // Corregir orientación
        final fixedImage = await ImageOrientationFixer.fixAndCompress(
          File(imagen.path),
        );

        setState(() => _imagenSeleccionada = fixedImage);
        await _guardarFoto();
      }
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error al seleccionar imagen');
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice:
            CameraDevice.front, // Cámara frontal para selfies
        requestFullMetadata: true,
      );

      if (imagen != null && mounted) {
        // Corregir orientación
        final fixedImage = await ImageOrientationFixer.fixAndCompress(
          File(imagen.path),
        );

        setState(() => _imagenSeleccionada = fixedImage);
        await _guardarFoto();
      }
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error al tomar foto');
    }
  }

  Future<void> _guardarFoto() async {
    if (_imagenSeleccionada == null) return;

    setState(() => _guardandoFoto = true);

    try {
      await _usuarioService.subirFotoPerfil(_imagenSeleccionada!);
      final perfilActualizado = await _usuarioService.obtenerPerfil(
        forzarRecarga: true,
      );

      if (!mounted) return;
      setState(() {
        _fotoActualUrl = perfilActualizado.fotoPerfilUrl;
        _imagenSeleccionada = null;
      });
      JPSnackbar.success(context, 'Foto actualizada exitosamente');
    } on ApiException catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, e.getUserFriendlyMessage());
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error al actualizar foto');
    } finally {
      if (mounted) setState(() => _guardandoFoto = false);
    }
  }

  Future<void> _eliminarFoto() async {
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de eliminar tu foto de perfil?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardandoFoto = true);

    try {
      await _usuarioService.eliminarFotoPerfil();

      if (!mounted) return;
      setState(() {
        _fotoActualUrl = null;
        _imagenSeleccionada = null;
      });
      JPSnackbar.success(context, 'Foto eliminada');
    } on ApiException catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, e.getUserFriendlyMessage());
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error al eliminar foto');
    } finally {
      if (mounted) setState(() => _guardandoFoto = false);
    }
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
              primary: AppColorsPrimary.main,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1C1C1E),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColorsPrimary.main,
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
              headerBackgroundColor: AppColorsPrimary.main,
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
      final perfilActualizado = await _usuarioService.obtenerPerfil(
        forzarRecarga: true,
      );

      if (!mounted) return;
      _nombreCtrl.text = perfilActualizado.firstName;
      _apellidoCtrl.text = perfilActualizado.lastName;
      _emailCtrl.text = perfilActualizado.usuarioEmail;
      _telefonoCtrl.text = _telefonoNacionalDesdePerfil(
        perfilActualizado.telefono,
      );
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
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
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
      title: Text(
        'Editar Información',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: CupertinoColors.label.resolveFrom(context),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground
                  .resolveFrom(context)
                  .withValues(alpha: 0.95),
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
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: CupertinoColors.label.resolveFrom(context),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    // Determinar qué imagen mostrar
    final ImageProvider? avatarImage;
    if (_imagenSeleccionada != null) {
      avatarImage = FileImage(_imagenSeleccionada!);
    } else if (_fotoActualUrl != null) {
      avatarImage = NetworkImage(_fotoActualUrl!);
    } else {
      avatarImage = null;
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _guardandoFoto ? null : _mostrarOpcionesFoto,
            child: Container(
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
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 3,
                      ),
                      image: avatarImage != null
                          ? DecorationImage(
                              image: avatarImage,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _guardandoFoto
                        ? const Center(child: CupertinoActivityIndicator())
                        : avatarImage == null
                        ? Center(
                            child: Text(
                              widget.perfil.usuarioNombre.isNotEmpty
                                  ? widget.perfil.usuarioNombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: AppColorsPrimary.main,
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
                        color: AppColorsPrimary.main,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsPrimary.main.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Toca la foto para cambiarla',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
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
                    color: AppColorsPrimary.main.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColorsPrimary.main,
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
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.label.resolveFrom(context),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: CupertinoColors.tertiarySystemGroupedBackground
                .resolveFrom(context),
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
              borderSide: const BorderSide(
                color: AppColorsPrimary.main,
                width: 2,
              ),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'TELÉFONO CELULAR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
            hintStyle: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: CupertinoColors.tertiarySystemGroupedBackground
                .resolveFrom(context),
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
              borderSide: const BorderSide(
                color: AppColorsPrimary.main,
                width: 2,
              ),
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
            // FIX: Guardar solo el número actual que escribe el usuario.
            // IntlPhoneField a veces mantiene estado interno.
            // Al asignar phone.number, aseguramos usar lo que el usuario ve.
            _telefonoNumero = phone.number;
          },
          onCountryChanged: (country) {
            final dial = country.dialCode.replaceAll(RegExp(r'\D'), '');
            _dialCode = dial.isEmpty ? '+593' : '+$dial';
          },
          validator: (phone) {
            // Validación local básica
            final digits = phone?.number.replaceAll(RegExp(r'\D'), '') ?? '';
            if (digits.isEmpty) {
              return 'Requerido';
            }
            // Aceptar 09... (10) o 9... (9)
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'FECHA DE NACIMIENTO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
              color: CupertinoColors.tertiarySystemGroupedBackground
                  .resolveFrom(context),
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
                        ? CupertinoColors.label.resolveFrom(context)
                        : CupertinoColors.placeholderText.resolveFrom(context),
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
                          color: AppColorsPrimary.main.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_calcularEdad(_fechaNacimiento!)} años',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColorsPrimary.main,
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
                  color: AppColorsPrimary.main.withValues(alpha: 0.3),
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
            backgroundColor: AppColorsPrimary.main,
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
                  child: CupertinoActivityIndicator(radius: 14),
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

    // Prioridad Ecuador - remover +593 y devolver número sin cero inicial
    if (limpio.startsWith('+593')) {
      var local = limpio.substring(4); // Remover +593
      // Remover cero inicial si existe (el widget lo muestra aparte)
      if (local.startsWith('0')) local = local.substring(1);
      return local;
    }

    // Intento genérico de separar dial code
    if (limpio.startsWith('+')) {
      final dial = _dialCodeDesdePerfil(limpio);
      if (limpio.startsWith(dial)) {
        return limpio.substring(dial.length);
      }
    }

    return limpio;
  }

  String _dialCodeDesdePerfil(String? telefono) {
    if (telefono == null || telefono.trim().isEmpty) return '+593';
    final limpio = telefono.trim();

    if (limpio.startsWith('+593')) return '+593';

    if (limpio.startsWith('+')) {
      // Intentar capturar código de país (1 a 4 dígitos)
      // NO usar \d+ porque capturaría todo el teléfono
      final match = RegExp(r'^\+(\d{1,4})').firstMatch(limpio);
      if (match != null) return '+${match.group(1)}';
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
    return normalizeUserPhoneForProfile(rawNumber: numero, dialCode: _dialCode);
  }
}
