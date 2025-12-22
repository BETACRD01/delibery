// lib/screens/supplier/screens/perfil_proveedor_editable.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../config/api_config.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../widgets/ratings/rating_summary_card.dart';

/// Panel de perfil del proveedor - Diseño profesional y limpio
class PerfilProveedorEditable extends StatefulWidget {
  const PerfilProveedorEditable({super.key});

  @override
  State<PerfilProveedorEditable> createState() => _PerfilProveedorEditableState();
}

class _PerfilProveedorEditableState extends State<PerfilProveedorEditable> {
  bool _editando = false;
  bool _guardando = false;
  String? _error;

  // Controllers - Negocio
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _horarioAperturaController;
  late TextEditingController _horarioCierreController;
  late TextEditingController _rucController;

  // Controllers - Contacto
  late TextEditingController _emailController;
  late TextEditingController _nombreCompletoController;
  late TextEditingController _telefonoController;
  String? _telefonoCompleto;
  String? _logoUrlCaido;

  String? _tipoProveedorSeleccionado;
  File? _logoSeleccionado;

  // Colores profesionales
  static const Color _primario = Color(0xFF1E88E5);
  static const Color _exito = Color(0xFF10B981);
  static const Color _peligro = Color(0xFFEF4444);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _horarioAperturaController.dispose();
    _horarioCierreController.dispose();
    _rucController.dispose();
    _emailController.dispose();
    _nombreCompletoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _inicializarFormulario() {
    final controller = context.read<SupplierController>();

    _nombreController = TextEditingController(text: controller.nombreNegocio);
    _descripcionController = TextEditingController(text: controller.proveedor?.descripcion ?? '');
    _direccionController = TextEditingController(text: controller.direccion);
    _ciudadController = TextEditingController(text: controller.ciudad);
    _horarioAperturaController = TextEditingController(
      text: _formatearHora(controller.horarioApertura),
    );
    _horarioCierreController = TextEditingController(
      text: _formatearHora(controller.horarioCierre),
    );
    _rucController = TextEditingController(text: controller.ruc);
    _tipoProveedorSeleccionado = controller.proveedor?.tipoProveedor;
    _emailController = TextEditingController(text: controller.email);
    _nombreCompletoController = TextEditingController(text: controller.nombreCompleto);
    _telefonoController =
        TextEditingController(text: _formatearTelefonoParaMostrar(controller.telefono));
    _telefonoCompleto = controller.telefono;
  }

  String _formatearHora(String? hora) {
    if (hora == null || hora.isEmpty) return '';
    return hora.length >= 5 ? hora.substring(0, 5) : hora;
  }

  Future<void> _seleccionarLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() => _logoSeleccionado = File(picked.path));
      }
    } catch (e) {
      _mostrarSnackBar('Error al seleccionar imagen', esError: true);
    }
  }

  Future<void> _seleccionarHora(TextEditingController controller) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) {
      controller.text = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';
    }
  }

  bool _validar() {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarSnackBar('El nombre del negocio es requerido', esError: true);
      return false;
    }
    if (_rucController.text.trim().length < 10) {
      _mostrarSnackBar('El RUC debe tener al menos 10 caracteres', esError: true);
      return false;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _mostrarSnackBar('Email inválido', esError: true);
      return false;
    }
    return true;
  }

  Future<void> _guardarCambios() async {
    if (!_validar()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final controller = context.read<SupplierController>();
      final telefonoFinal = _normalizarTelefono(
        _telefonoCompleto?.isNotEmpty == true
            ? _telefonoCompleto!
            : _telefonoController.text,
      );

      // Datos del negocio
      final datosPerfil = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'ruc': _rucController.text.trim(),
        'tipo_proveedor': _tipoProveedorSeleccionado,
        'descripcion': _descripcionController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'telefono': telefonoFinal.isNotEmpty ? telefonoFinal : null,
        if (_horarioAperturaController.text.isNotEmpty)
          'horario_apertura': _horarioAperturaController.text.trim(),
        if (_horarioCierreController.text.isNotEmpty)
          'horario_cierre': _horarioCierreController.text.trim(),
      };

      final successPerfil = await controller.actualizarPerfil(datosPerfil);
      if (!successPerfil) {
        setState(() {
          _error = controller.error;
          _guardando = false;
        });
        return;
      }

      // Datos de contacto
      final partes = _nombreCompletoController.text.trim().split(' ');
      final firstName = partes.isNotEmpty ? partes[0] : '';
      final lastName = partes.length > 1 ? partes.sublist(1).join(' ') : '';

      final successContacto = await controller.actualizarDatosContacto(
        email: _emailController.text.trim(),
        firstName: firstName,
        lastName: lastName,
      );

      if (!successContacto) {
        setState(() {
          _error = controller.error;
          _guardando = false;
        });
        return;
      }

      // Logo
      if (_logoSeleccionado != null) {
        await controller.subirLogo(_logoSeleccionado!);
      }

      setState(() {
        _editando = false;
        _logoSeleccionado = null;
        _guardando = false;
        _telefonoCompleto = telefonoFinal;
      });

      _mostrarSnackBar('Cambios guardados');
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
  }

  void _cancelarEdicion() {
    setState(() {
      _editando = false;
      _logoSeleccionado = null;
      _error = null;
      _telefonoCompleto = _telefonoController.text.trim();
    });
    _inicializarFormulario();
  }

  void _mostrarSnackBar(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? _peligro : _exito,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _primario,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_editando)
            TextButton.icon(
              onPressed: () => setState(() => _editando = true),
              icon: const Icon(Icons.edit, size: 18, color: Colors.white),
              label: const Text('Editar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Consumer<SupplierController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeaderLogo(controller),
                const SizedBox(height: 20),

                // Sección de calificaciones
                _buildSeccionCalificaciones(controller),

                _buildSeccion('Contacto', [
                  _buildCampo('Email', _emailController, Icons.email_outlined),
                  _buildCampo('Nombre completo', _nombreCompletoController, Icons.person_outline),
                  _buildCampoTelefono(),
                ]),
                const SizedBox(height: 16),
                _buildSeccion('Negocio', [
                  _buildCampo('Nombre del negocio', _nombreController, Icons.store_outlined),
                  _buildCampo('RUC', _rucController, Icons.badge_outlined),
                  _buildDropdownTipo(),
                  _buildCampo('Descripción', _descripcionController, Icons.description_outlined, maxLines: 2),
                ]),
                const SizedBox(height: 16),
                _buildSeccion('Ubicación', [
                  _buildCampo('Dirección', _direccionController, Icons.location_on_outlined),
                  _buildCampo('Ciudad', _ciudadController, Icons.location_city_outlined),
                ]),
                const SizedBox(height: 16),
                _buildSeccion('Horarios', [
                  _buildCampoHora('Apertura', _horarioAperturaController),
                  _buildCampoHora('Cierre', _horarioCierreController),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _peligro.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: _peligro, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style:const TextStyle(color: _peligro, fontSize: 13))),
                      ],
                    ),
                  ),
                ],
                if (_editando) ...[
                  const SizedBox(height: 24),
                  _buildBotones(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderLogo(SupplierController controller) {
    Widget? imagen;

    if (_logoSeleccionado != null) {
      imagen = ClipOval(
        child: Image.file(
          _logoSeleccionado!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (controller.logo != null && controller.logo!.isNotEmpty) {
      final url = controller.logo!.startsWith('http')
          ? controller.logo!
          : '${ApiConfig.baseUrl}${controller.logo}';
      if (_logoUrlCaido == url) {
        imagen = _buildLogoPlaceholder();
      } else {
        imagen = ClipOval(
          child: Image.network(
            url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (!mounted) return _buildLogoPlaceholder();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _logoUrlCaido = url);
              });
              return _buildLogoPlaceholder();
            },
          ),
        );
      }
    } else {
      imagen = _buildLogoPlaceholder();
    }

    return GestureDetector(
      onTap: _editando ? _seleccionarLogo : null,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: _primario, width: 3),
            ),
            child: imagen,
          ),
          if (_editando)
            Positioned(
              bottom: 0,
              right: 0,
            child: Container(
                padding: const EdgeInsets.all(6),
                decoration:const BoxDecoration(
                  color: _primario,
                  shape: BoxShape.circle,
                ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionCalificaciones(SupplierController controller) {
    final valoracion = controller.valoracionPromedio;
    final totalResenas = controller.totalResenas;

    // Si no hay reseñas, no mostrar nada
    if (totalResenas == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CompactRatingSummaryCard(
        averageRating: valoracion,
        totalReviews: totalResenas,
        subtitle: 'Calificación promedio del negocio',
        // onTap: () {
        //   // TODO: Navegar a pantalla de todas las reseñas del proveedor
        // },
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textoSecundario,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: child,
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCampo(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    if (!_editando) {
      return Row(
        children: [
          Icon(icon, size: 20, color: _textoSecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _textoSecundario)),
                const SizedBox(height: 2),
                Text(
                  controller.text.isEmpty ? '---' : controller.text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildCampoTelefono() {
    if (!_editando) {
      return _buildCampo('Teléfono', _telefonoController, Icons.phone_outlined);
    }

      return IntlPhoneField(
        controller: _telefonoController,
        initialCountryCode: _obtenerCodigoPaisInicial(_telefonoController.text),
        decoration: InputDecoration(
          labelText: 'Teléfono',
          prefixIcon: const Icon(Icons.phone_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
          counterText: '',
        ),
        autovalidateMode: AutovalidateMode.disabled,
        onChanged: (phone) => _telefonoCompleto = phone.completeNumber,
      );
  }

  Widget _buildCampoHora(String label, TextEditingController controller) {
    if (!_editando) {
      return Row(
        children: [
         const Icon(Icons.access_time, size: 20, color: _textoSecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _textoSecundario)),
                const SizedBox(height: 2),
                Text(
                  controller.text.isEmpty ? '---' : _formatearHora(controller.text),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _seleccionarHora(controller),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.access_time, size: 20),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTipo() {
    if (!_editando) {
      return Row(
        children: [
         const Icon(Icons.category_outlined, size: 20, color: _textoSecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tipo', style: TextStyle(fontSize: 11, color: _textoSecundario)),
                const SizedBox(height: 2),
                Text(
                  _getNombreTipo(_tipoProveedorSeleccionado),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _tipoProveedorSeleccionado,
      decoration: InputDecoration(
        labelText: 'Tipo de proveedor',
        prefixIcon: const Icon(Icons.category_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      items: ApiConfig.tiposProveedor.map((tipo) {
        return DropdownMenuItem(value: tipo, child: Text(_getNombreTipo(tipo)));
      }).toList(),
      onChanged: (v) => setState(() => _tipoProveedorSeleccionado = v),
    );
  }

  String _getNombreTipo(String? tipo) {
    switch (tipo) {
      case 'restaurante': return 'Restaurante';
      case 'farmacia': return 'Farmacia';
      case 'supermercado': return 'Supermercado';
      case 'tienda': return 'Tienda';
      case 'otro': return 'Otro';
      default: return 'Seleccionar';
    }
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _guardando ? null : _cancelarEdicion,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _guardando ? null : _guardarCambios,
            style: FilledButton.styleFrom(
              backgroundColor: _exito,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }

  String _obtenerCodigoPaisInicial(String numero) {
    final valor = numero.trim();
    if (valor.startsWith('+593')) return 'EC';
    if (valor.startsWith('+1')) return 'US';
    if (valor.startsWith('+52')) return 'MX';
    if (valor.startsWith('+57')) return 'CO';
    return 'EC';
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Icon(Icons.store, size: 40, color: Colors.grey.shade400),
    );
  }

  String _normalizarTelefono(String telefono) {
    final valor = telefono.trim();
    if (valor.isEmpty) return '';
    if (valor.startsWith('+5930')) {
      return '+593${valor.substring(5)}';
    }
    return valor;
  }

  String _formatearTelefonoParaMostrar(String? telefono) {
    if (telefono == null || telefono.isEmpty) return '';
    if (telefono.startsWith('+593')) {
      final resto = telefono.substring(4);
      return '0$resto';
    }
    return telefono;
  }
}
