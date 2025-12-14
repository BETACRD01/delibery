// lib/screens/user/perfil/solicitudes_rol/widgets/formulario_proveedor.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../services/solicitudes_service.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../models/solicitud_cambio_rol.dart';

/// 📝 FORMULARIO PARA SOLICITUD DE PROVEEDOR
/// Diseño: Clean UI / Minimalista
class FormularioProveedor extends StatefulWidget {
  final VoidCallback onSubmitSuccess;
  final VoidCallback onBack;

  const FormularioProveedor({
    super.key,
    required this.onSubmitSuccess,
    required this.onBack,
  });

  @override
  State<FormularioProveedor> createState() => _FormularioProveedorState();
}

class _FormularioProveedorState extends State<FormularioProveedor> {
  // ══════════════════════════════════════════════════════════════════════════════
  // 📋 CONTROLADORES Y ESTADO
  // ══════════════════════════════════════════════════════════════════════════════

  final _formKey = GlobalKey<FormState>();
  final _solicitudesService = SolicitudesService();
  final _authService = AuthService();

  final _rucController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _motivoController = TextEditingController();

  String? _tipoNegocio;
  TimeOfDay? _horarioApertura;
  TimeOfDay? _horarioCierre;
  bool _isLoading = false;

  @override
  void dispose() {
    _rucController.dispose();
    _nombreComercialController.dispose();
    _descripcionController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              _buildCardEstadoUsuario(),
              const SizedBox(height: 32),

              _buildLabel('RUC'),
              _buildRUCField(),
              const SizedBox(height: 20),

              _buildLabel('Nombre Comercial'),
              _buildNombreComercialField(),
              const SizedBox(height: 20),

              _buildLabel('Tipo de Negocio'),
              _buildTipoNegocioField(),
              const SizedBox(height: 20),

              _buildLabel('Descripción'),
              _buildDescripcionField(),
              const SizedBox(height: 20),

              _buildLabel('Horario de Atención'),
              _buildHorariosSection(),
              const SizedBox(height: 20),

              _buildLabel('Motivo de la Solicitud'),
              _buildMotivoField(),
              const SizedBox(height: 40),

              _buildBotones(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🧩 SECCIONES UI
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: JPColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_rounded, color: JPColors.secondary, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ser Proveedor',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: JPColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Registra tu negocio y vende más',
                    style: TextStyle(fontSize: 14, color: JPColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardEstadoUsuario() {
    final user = _authService.user;
    final esProveedor = user?.roles.contains('PROVEEDOR') ?? false;

    if (esProveedor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JPColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JPColors.success),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: JPColors.success),
            SizedBox(width: 12),
            Expanded(child: Text('Ya eres Proveedor', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: JPColors.textPrimary),
      ),
    );
  }

  InputDecoration _cleanInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: JPColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, color: JPColors.textSecondary, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: JPColors.secondary)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: JPColors.error)),
    );
  }

  Widget _buildRUCField() {
    return TextFormField(
      controller: _rucController,
      decoration: _cleanInputDecoration('Ej: 1712345678001', Icons.badge_outlined),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(13),
      ],
      validator: (value) => (value == null || value.length != 13) ? 'El RUC debe tener 13 dígitos' : null,
    );
  }

  Widget _buildNombreComercialField() {
    return TextFormField(
      controller: _nombreComercialController,
      decoration: _cleanInputDecoration('Ej: Restaurante Sabor Latino', Icons.storefront_outlined),
      textCapitalization: TextCapitalization.words,
      validator: (value) => (value == null || value.length < 3) ? 'Nombre demasiado corto' : null,
    );
  }

  Widget _buildTipoNegocioField() {
    return DropdownButtonFormField<String>(
      initialValue: _tipoNegocio,
      decoration: _cleanInputDecoration('Selecciona categoría', Icons.category_outlined),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JPColors.textSecondary),
      dropdownColor: Colors.white,
      items: TipoNegocio.values.map((tipo) {
        return DropdownMenuItem(
          value: tipo.value,
          child: Text(tipo.label, style: const TextStyle(fontSize: 14, color: JPColors.textPrimary)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _tipoNegocio = value),
      validator: (value) => value == null ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      decoration: _cleanInputDecoration('Describe tus productos o servicios...', Icons.description_outlined),
      maxLines: 3,
      maxLength: 500,
      validator: (value) => (value == null || value.length < 10) ? 'Detalla un poco más' : null,
    );
  }

  Widget _buildHorariosSection() {
    return Row(
      children: [
        Expanded(
          child: _buildHorarioButton(
            label: 'Apertura',
            icon: Icons.wb_sunny_outlined,
            time: _horarioApertura,
            onTap: () => _seleccionarHorario(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHorarioButton(
            label: 'Cierre',
            icon: Icons.nights_stay_outlined,
            time: _horarioCierre,
            onTap: () => _seleccionarHorario(false),
          ),
        ),
      ],
    );
  }

  Widget _buildHorarioButton({
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: JPColors.textSecondary),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 12, color: JPColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? time.format(context) : '--:--',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: time != null ? JPColors.textPrimary : JPColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivoField() {
    return TextFormField(
      controller: _motivoController,
      decoration: _cleanInputDecoration('¿Por qué deseas unirte?', Icons.edit_note_outlined),
      maxLines: 3,
      validator: (value) => (value == null || value.length < 10) ? 'Escribe un motivo válido' : null,
    );
  }

  Widget _buildBotones() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _enviarSolicitud,
            style: ElevatedButton.styleFrom(
              backgroundColor: JPColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('ENVIAR SOLICITUD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : widget.onBack,
            style: TextButton.styleFrom(foregroundColor: JPColors.textSecondary),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarHorario(bool esApertura) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: esApertura
          ? (_horarioApertura ?? const TimeOfDay(hour: 8, minute: 0))
          : (_horarioCierre ?? const TimeOfDay(hour: 18, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: JPColors.secondary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (esApertura) {
          _horarioApertura = picked;
        } else {
          _horarioCierre = picked;
        }
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ⚙️ LÓGICA DE ENVÍO + MANEJO DE DUPLICADOS (RUC)
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _enviarSolicitud() async {
    FocusScope.of(context).unfocus();
    final user = _authService.user;

    // Validaciones
    if (user == null || user.email.contains('Anonymous')) {
      _mostrarSnack('Debes iniciar sesión para continuar', isError: true);
      return;
    }
    if (user.roles.contains('PROVEEDOR')) {
      _mostrarSnack('Ya eres Proveedor.', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _mostrarSnack('Revisa los campos obligatorios', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _solicitudesService.crearSolicitudProveedor(
        ruc: _rucController.text.trim(),
        nombreComercial: _nombreComercialController.text.trim(),
        tipoNegocio: _tipoNegocio!,
        descripcionNegocio: _descripcionController.text.trim(),
        motivo: _motivoController.text.trim(),
        horarioApertura: _horarioApertura?.format(context),
        horarioCierre: _horarioCierre?.format(context),
      );

      if (!mounted) return;
      widget.onSubmitSuccess();
      
    } catch (e) {
      if (!mounted) return;
      
      // ⚠️ AQUÍ MANEJAMOS EL ERROR DE RUC DUPLICADO
      // Si el Backend responde: "El RUC 123... ya está registrado", aquí lo capturamos.
      String errorMsg = e.toString();
      
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.substring(11); 
      }
      
      _mostrarSnack(errorMsg, isError: true);

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? JPColors.error : JPColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}