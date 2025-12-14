// lib/screens/user/perfil/editar/pantalla_editar_informacion.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/jp_theme.dart';
import '../../../../services/usuarios_service.dart';
import '../../../../apis/helpers/api_exception.dart';
import '../../../../models/usuario.dart';

/// Pantalla para editar información personal completa
/// (Nombre, Apellido, Email, Teléfono, Fecha Nacimiento)
class PantallaEditarInformacion extends StatefulWidget {
  final PerfilModel perfil;

  const PantallaEditarInformacion({super.key, required this.perfil});

  @override
  State<PantallaEditarInformacion> createState() =>
      _PantallaEditarInformacionState();
}

class _PantallaEditarInformacionState extends State<PantallaEditarInformacion> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioService = UsuarioService();

  // Controladores para campos editables
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;
  
  DateTime? _fechaNacimiento;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    
    // ----------------------------------------------------------------------
    //  CORRECCIÓN APLICADA: Lógica de respaldo para nombres vacíos
    // ----------------------------------------------------------------------
    String nombreInicial = widget.perfil.firstName;
    String apellidoInicial = widget.perfil.lastName;

    // Si los campos individuales vienen vacíos, intentamos extraerlos del nombre completo
    if (nombreInicial.isEmpty && apellidoInicial.isEmpty && widget.perfil.usuarioNombre.isNotEmpty) {
      final partes = widget.perfil.usuarioNombre.trim().split(' ');
      
      if (partes.isNotEmpty) {
        nombreInicial = partes[0]; // La primera palabra es el nombre
        
        if (partes.length > 1) {
          // El resto de palabras forman el apellido
          apellidoInicial = partes.sublist(1).join(' ');
        }
      }
    }

    _nombreCtrl = TextEditingController(text: nombreInicial);
    _apellidoCtrl = TextEditingController(text: apellidoInicial);
    // ----------------------------------------------------------------------

    _emailCtrl = TextEditingController(text: widget.perfil.usuarioEmail);
    _telefonoCtrl = TextEditingController(text: widget.perfil.telefono);
    _fechaNacimiento = widget.perfil.fechaNacimiento;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELECCIONAR FECHA
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _seleccionarFecha() async {
    final fechaActual = DateTime.now();
    final fechaMinima = DateTime(fechaActual.year - 100);
    final fechaMaxima = DateTime(fechaActual.year - 13);

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? fechaMaxima,
      firstDate: fechaMinima,
      lastDate: fechaMaxima,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: JPColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: JPColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GUARDAR CAMBIOS
  // ══════════════════════════════════════════════════════════════════════════

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

      final telefono = _telefonoCtrl.text.trim();
      if (telefono != widget.perfil.telefono) {
        if (telefono.isNotEmpty && !RegExp(r'^09\d{8}$').hasMatch(telefono)) {
          throw ApiException(statusCode: 400, message: 'Celular inválido (debe ser 09xxxxxxxx)');
        }
        datos['telefono'] = telefono.isEmpty ? null : telefono;
      }

      if (_fechaNacimiento != widget.perfil.fechaNacimiento) {
        if (_fechaNacimiento != null) {
          final fechaStr = '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-'
              '${_fechaNacimiento!.month.toString().padLeft(2, '0')}-'
              '${_fechaNacimiento!.day.toString().padLeft(2, '0')}';
          datos['fecha_nacimiento'] = fechaStr;
        } else {
          datos['fecha_nacimiento'] = null;
        }
      }

      // 3. Verificar si hubo cambios reales
      if (datos.isEmpty) {
        if (!mounted) return;
        JPSnackbar.info(context, 'No has realizado cambios');
        return;
      }

      // 4. Enviar al Backend
      await _usuarioService.actualizarPerfil(datos);

      if (!mounted) return;
      JPSnackbar.success(context, 'Información actualizada correctamente');
      Navigator.pop(context, true); // Retornar true para recargar perfil

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

  // ══════════════════════════════════════════════════════════════════════════
  //  UI
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                
                _buildSectionTitle('Datos Personales'),
                const SizedBox(height: 16),
                
                // Fila Nombre y Apellido
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nombreCtrl,
                        label: 'Nombre',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _apellidoCtrl,
                        label: 'Apellido',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Email
                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Correo Electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                  helperText: 'Cambiar tu correo podría cerrar tu sesión en otros dispositivos.',
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Contacto y Detalles'),
                const SizedBox(height: 16),

                // Teléfono
                _buildTextField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono Celular',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  hintText: '09xxxxxxxx',
                ),
                const SizedBox(height: 20),

                // Fecha Nacimiento
                _buildFechaField(),

                const SizedBox(height: 40),
                _buildBotonGuardar(),
              ],
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
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: Colors.white,
      foregroundColor: JPColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: JPColors.background,
                  border: Border.all(color: Colors.grey[200]!),
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
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: JPColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: JPColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Mantén tus datos actualizados',
            style: TextStyle(color: JPColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: JPColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15),
      validator: validator,
      decoration: _inputDecoration(label, icon).copyWith(
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
      ),
    );
  }

  Widget _buildFechaField() {
    return InkWell(
      onTap: _seleccionarFecha,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration('Fecha de nacimiento', Icons.cake_outlined),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fechaNacimiento != null
                  ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                  : 'Seleccionar fecha',
              style: TextStyle(
                fontSize: 15,
                color: _fechaNacimiento != null ? JPColors.textPrimary : JPColors.textHint,
              ),
            ),
            if (_fechaNacimiento != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: JPColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_calcularEdad(_fechaNacimiento!)} años',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: JPColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: JPColors.textSecondary, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.all(16),
      labelStyle: const TextStyle(color: JPColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: JPColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: JPColors.error),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _guardando ? null : _guardarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: JPColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: _guardando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'GUARDAR CAMBIOS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  String _calcularEdad(DateTime fecha) {
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month || (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad.toString();
  }
}