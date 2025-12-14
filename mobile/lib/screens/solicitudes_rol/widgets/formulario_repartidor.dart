// lib/screens/user/perfil/solicitudes_rol/widgets/formulario_repartidor.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../services/solicitudes_service.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../models/solicitud_cambio_rol.dart';

/// 📝 FORMULARIO PARA SOLICITUD DE REPARTIDOR (VERSIÓN FINAL CLEAN)
class FormularioRepartidor extends StatefulWidget {
  final VoidCallback onSubmitSuccess;
  final VoidCallback onBack;

  const FormularioRepartidor({
    super.key,
    required this.onSubmitSuccess,
    required this.onBack,
  });

  @override
  State<FormularioRepartidor> createState() => _FormularioRepartidorState();
}

class _FormularioRepartidorState extends State<FormularioRepartidor> {
  // ══════════════════════════════════════════════════════════════════════════════
  // 📋 CONTROLADORES
  // ══════════════════════════════════════════════════════════════════════════════

  final _formKey = GlobalKey<FormState>();
  final _solicitudesService = SolicitudesService();
  final _authService = AuthService();

  final _cedulaController = TextEditingController();
  final _zonaCoberturaController = TextEditingController();
  final _motivoController = TextEditingController();

  String? _tipoVehiculo;
  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _zonaCoberturaController.dispose();
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

              _buildLabel('Cédula de Identidad'),
              _buildCedulaField(), // Campo limpio
              const SizedBox(height: 20),

              _buildLabel('Tipo de Vehículo'),
              _buildTipoVehiculoField(),
              const SizedBox(height: 20),

              _buildLabel('Zona de Cobertura'),
              _buildZonaCoberturaField(),
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
  // 🧩 WIDGETS UI
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
                color: JPColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delivery_dining_rounded, color: JPColors.info, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ser Repartidor',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: JPColors.textPrimary),
                  ),
                  Text(
                    'Completa tus datos para comenzar',
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
    // (Mismo código de estado de usuario que tenías antes)
    final user = _authService.user;
    final esRepartidor = user?.roles.contains('REPARTIDOR') ?? false;

    if (esRepartidor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JPColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JPColors.success),
        ),
        child: const Row(
          children:[
            Icon(Icons.check_circle, color: JPColors.success),
            SizedBox(width: 12),
            Expanded(child: Text("Ya eres Repartidor", style: TextStyle(fontWeight: FontWeight.bold))),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: JPColors.info)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: JPColors.error)),
    );
  }

  // 🔹 CAMPO CÉDULA LIMPIO (SIN ICONOS EXTRA)
  Widget _buildCedulaField() {
    return TextFormField(
      controller: _cedulaController,
      decoration: _cleanInputDecoration('Ej: 1712345678', Icons.badge_outlined),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(13),
      ],
      validator: (value) => (value == null || value.length < 10) ? 'Ingresa una cédula válida' : null,
    );
  }

  Widget _buildTipoVehiculoField() {
    return DropdownButtonFormField<String>(
      initialValue: _tipoVehiculo,
      decoration: _cleanInputDecoration('Selecciona vehículo', Icons.two_wheeler_outlined),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: JPColors.textSecondary),
      dropdownColor: Colors.white,
      items: TipoVehiculo.values.map((tipo) {
        return DropdownMenuItem(
          value: tipo.value,
          child: Text(tipo.label, style: const TextStyle(fontSize: 14, color: JPColors.textPrimary)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _tipoVehiculo = value),
      validator: (value) => value == null ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildZonaCoberturaField() {
    return TextFormField(
      controller: _zonaCoberturaController,
      decoration: _cleanInputDecoration('Ej: Centro, Norte', Icons.map_outlined),
      textCapitalization: TextCapitalization.words,
      validator: (value) => (value == null || value.length < 3) ? 'Campo obligatorio' : null,
    );
  }

  Widget _buildMotivoField() {
    return TextFormField(
      controller: _motivoController,
      decoration: _cleanInputDecoration('Cuéntanos...', Icons.edit_note_outlined),
      maxLines: 4,
      validator: (value) => (value == null || value.length < 10) ? 'Mínimo 10 caracteres' : null,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🔘 BOTÓN DE ENVÍO (AQUÍ OCURRE LA MAGIA)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildBotones() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _enviarSolicitud,
            style: ElevatedButton.styleFrom(
              backgroundColor: JPColors.info,
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

  // ══════════════════════════════════════════════════════════════════════════════
  // ⚙️ LÓGICA DE ENVÍO + VALIDACIÓN
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _enviarSolicitud() async {
    // 1. Ocultar teclado
    FocusScope.of(context).unfocus();
    
    // 2. Validaciones locales (formato)
    if (!_formKey.currentState!.validate()) {
      _mostrarSnack('Revisa los campos', isError: true);
      return;
    }

    // 3. Iniciar carga (Spinner)
    setState(() => _isLoading = true);
    
    try {
      // 4. Enviar al Backend
      // En este momento, mientras carga, el backend revisa si la cédula existe.
      await _solicitudesService.crearSolicitudRepartidor(
        cedulaIdentidad: _cedulaController.text.trim(),
        tipoVehiculo: _tipoVehiculo!,
        zonaCobertura: _zonaCoberturaController.text.trim(),
        motivo: _motivoController.text.trim(),
      );

      // 5. Si no hubo error, todo bien
      if (!mounted) return;
      widget.onSubmitSuccess();
      
    } catch (e) {
      if (!mounted) return;
      
      // 6. SI HUBO ERROR (Ej: Cédula duplicada), lo mostramos aquí
      String errorMsg = e.toString();
      
      // Limpieza cosmética del mensaje
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.substring(11); 
      }
      
      _mostrarSnack(errorMsg, isError: true); // SnackBar Rojo
      
    } finally {
      // 7. Detener carga
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