// lib/screens/user/perfil/configuracion/direcciones/pantalla_mis_direcciones.dart

import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../../theme/jp_theme.dart' hide JPSnackbar;
import '../../../../../services/usuarios_service.dart';
import '../../../../../apis/helpers/api_exception.dart';
import '../../../../../models/usuario.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../../widgets/jp_snackbar.dart';

/// 📍 Pantalla optimizada para gestionar direcciones
/// ✅ Modo unificado: Crea O Edita según el contexto
/// ✅ Sin duplicados: Al editar, actualiza la dirección existente
class PantallaAgregarDireccion extends StatefulWidget {
  final DireccionModel? direccion; // Si viene null = CREAR, si viene dato = EDITAR

  const PantallaAgregarDireccion({super.key, this.direccion});

  @override
  State<PantallaAgregarDireccion> createState() =>
      _PantallaAgregarDireccionState();
}

class _PantallaAgregarDireccionState extends State<PantallaAgregarDireccion> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioService = UsuarioService();

  late final TextEditingController _direccionController;
  late final TextEditingController _pisoController;
  late final TextEditingController _calleSecundariaController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _indicacionesController;

  String _telefonoCompleto = '';
  static const String _codigoPaisDefault = '593';

  double? _latitud;
  double? _longitud;
  bool _guardando = false;

  // ✅ Determinar si estamos en modo EDICIÓN
  bool get _modoEdicion => widget.direccion != null;

  @override
  void initState() {
    super.initState();
    final dir = widget.direccion;

    // Inicializar controladores con datos existentes
    _direccionController = TextEditingController(text: dir?.direccion ?? '');
    _pisoController = TextEditingController(text: dir?.pisoApartamento ?? '');
    _calleSecundariaController = TextEditingController(text: dir?.calleSecundaria ?? '');
    _ciudadController = TextEditingController(text: dir?.ciudad ?? '');
    _telefonoController = TextEditingController();
    _indicacionesController = TextEditingController(text: dir?.indicaciones ?? '');

    _setTelefonoInicial(dir?.telefonoContacto);
    _latitud = dir?.latitud;
    _longitud = dir?.longitud;
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _pisoController.dispose();
    _calleSecundariaController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _indicacionesController.dispose();
    super.dispose();
  }

  void _setTelefonoInicial(String? telefonoBackend) {
    if (telefonoBackend == null || telefonoBackend.isEmpty) {
      _telefonoController.text = '';
      _telefonoCompleto = '';
      return;
    }

    String limpio = telefonoBackend.trim();
    if (limpio.startsWith('+')) limpio = limpio.substring(1);
    if (limpio.startsWith(_codigoPaisDefault)) {
      limpio = limpio.substring(_codigoPaisDefault.length);
    }

    _telefonoController.text = limpio;
    _telefonoCompleto = telefonoBackend.startsWith('+')
        ? telefonoBackend
        : '+$_codigoPaisDefault$limpio';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 💾 GUARDAR DIRECCIÓN - MODO UNIFICADO (CREAR O ACTUALIZAR)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _guardarDireccion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final direccionTexto = _direccionController.text.trim();
      final pisoDepto = _pisoController.text.trim();
      final calleSecundaria = _calleSecundariaController.text.trim();
      final ciudad = _ciudadController.text.trim();
      final telefono = (_telefonoCompleto.isNotEmpty
              ? _telefonoCompleto
              : _telefonoController.text)
          .trim();
      final indicaciones = _indicacionesController.text.trim();
      final lat = _latitud ?? 0.0;
      final lon = _longitud ?? 0.0;

      // Construir objeto de dirección
      final direccionData = {
        'tipo': 'casa',
        'direccion': direccionTexto,
        'piso_apartamento': pisoDepto.isEmpty ? null : pisoDepto,
        'calle_secundaria': calleSecundaria.isEmpty ? null : calleSecundaria,
        'latitud': lat,
        'longitud': lon,
        'ciudad': ciudad.isEmpty ? null : ciudad,
        'telefono_contacto': telefono,
        'indicaciones': indicaciones.isEmpty ? null : indicaciones,
        'es_predeterminada': true,
        'activa': true,
      };

      if (_modoEdicion) {
        // ✅ MODO EDICIÓN: Actualizar dirección existente
        await _usuarioService.actualizarDireccion(
          widget.direccion!.id,
          direccionData,
        );

        _usuarioService.limpiarCacheDirecciones();

        if (!mounted) return;
        JPSnackbar.success(context, '✓ Dirección actualizada correctamente');
        Navigator.pop(context, true);
      } else {
        // ✅ MODO CREACIÓN: Intentar crear nueva dirección
        try {
          final nuevaDireccion = DireccionModel(
            id: '',
            tipo: 'casa',
            tipoDisplay: 'Casa',
            etiqueta: '', // El backend lo genera
            direccion: direccionTexto,
            referencia: null,
            pisoApartamento: pisoDepto.isEmpty ? null : pisoDepto,
            calleSecundaria: calleSecundaria.isEmpty ? null : calleSecundaria,
            latitud: lat,
            longitud: lon,
            ciudad: ciudad.isEmpty ? null : ciudad,
            telefonoContacto: telefono,
            indicaciones: indicaciones.isEmpty ? null : indicaciones,
            esPredeterminada: true,
            activa: true,
            vecesUsada: 0,
            ultimoUso: null,
            direccionCompleta: direccionTexto,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _usuarioService.crearDireccion(nuevaDireccion);
          _usuarioService.limpiarCacheDirecciones();

          if (!mounted) return;
          JPSnackbar.success(context, '✓ Dirección creada correctamente');
          Navigator.pop(context, true);
        } on ApiException catch (e) {
          // Detectar si es un error de duplicado
          final errorMensaje = e.getUserFriendlyMessage().toLowerCase();
          final esDuplicado = errorMensaje.contains('ya tienes') ||
                             errorMensaje.contains('muy cercana') ||
                             errorMensaje.contains('duplicad');

          if (esDuplicado && mounted) {
            JPSnackbar.error(
              context,
              'Ya tienes una dirección en esta ubicación. Por favor edita la dirección existente.',
            );
          } else if (mounted) {
            JPSnackbar.error(context, e.getUserFriendlyMessage());
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error al guardar dirección: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🎨 UI
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        title: Text(_modoEdicion ? 'Editar Dirección' : 'Nueva Dirección'),
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header con icono
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: JPColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JPColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _modoEdicion ? 'Actualiza tu dirección' : 'Agrega una nueva dirección',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: JPColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Usa Google Maps para mayor precisión',
                          style: TextStyle(
                            fontSize: 13,
                            color: JPColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dirección con autocompletado
            _buildCampoDireccionConAutocompletado(),
            const SizedBox(height: 16),

            // Calle secundaria
            _buildCampoTexto(
              controller: _calleSecundariaController,
              label: 'Calle secundaria',
              icon: Icons.alt_route_rounded,
              hint: 'Ej: Esq. con Calle 10',
              opcional: true,
            ),
            const SizedBox(height: 16),

            // Piso/Departamento
            _buildCampoTexto(
              controller: _pisoController,
              label: 'Piso / Departamento',
              icon: Icons.apartment_rounded,
              hint: 'Ej: Torre B, depto 302',
              opcional: true,
            ),
            const SizedBox(height: 16),

            // Ciudad
            _buildCampoTexto(
              controller: _ciudadController,
              label: 'Ciudad',
              icon: Icons.location_city,
              hint: 'Ciudad / Provincia',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La ciudad es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Indicaciones
            _buildCampoTexto(
              controller: _indicacionesController,
              label: 'Indicaciones de entrega',
              icon: Icons.notes_rounded,
              hint: 'Ej: Llamar al llegar, timbre dañado',
              maxLines: 3,
              opcional: true,
            ),
            const SizedBox(height: 16),

            // Teléfono
            _buildCampoTelefono(),
            const SizedBox(height: 32),

            // Botón guardar
            ElevatedButton(
              onPressed: _guardando ? null : _guardarDireccion,
              style: ElevatedButton.styleFrom(
                backgroundColor: JPColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_modoEdicion ? Icons.check : Icons.add_location_alt),
                        const SizedBox(width: 8),
                        Text(
                          _modoEdicion ? 'Actualizar dirección' : 'Guardar dirección',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🧩 COMPONENTES VISUALES
  // ══════════════════════════════════════════════════════════════════════════

  /// Maneja la selección de una dirección del autocompletado
  Future<void> _onPlaceSelected(Prediction prediction) async {
    try {
      setState(() {
        _direccionController.text = prediction.description ?? '';
      });

      if (prediction.description != null && prediction.description!.isNotEmpty) {
        try {
          final locations = await locationFromAddress(prediction.description!);
          if (locations.isNotEmpty) {
            setState(() {
              _latitud = locations.first.latitude;
              _longitud = locations.first.longitude;
            });
          }
        } catch (e) {
          debugPrint('Error obteniendo coordenadas: $e');
        }
      }
    } catch (e) {
      debugPrint('Error al seleccionar lugar: $e');
    }
  }

  Widget _buildCampoDireccionConAutocompletado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home, color: JPColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Dirección principal',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              ' *',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: JPColors.error),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GooglePlaceAutoCompleteTextField(
          textEditingController: _direccionController,
          googleAPIKey: "AIzaSyAVomIe-K4kpGMrQTc-bZaNcBvJtkK-KBA",
          inputDecoration: InputDecoration(
            hintText: 'Busca tu dirección en Google Maps...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: JPColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: JPColors.error),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: _direccionController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _direccionController.clear();
                        _latitud = null;
                        _longitud = null;
                      });
                    },
                  )
                : const Icon(Icons.search, color: Colors.grey),
          ),
          debounceTime: 600,
          countries: const ["ec"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (Prediction prediction) {
            _onPlaceSelected(prediction);
          },
          itemClick: (Prediction prediction) {
            _direccionController.text = prediction.description ?? '';
            _direccionController.selection = TextSelection.fromPosition(
              TextPosition(offset: _direccionController.text.length),
            );
          },
          itemBuilder: (context, index, Prediction prediction) {
            return Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: JPColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      prediction.description ?? "",
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
          seperatedBuilder: const Divider(height: 1),
          isCrossBtnShown: true,
          containerHorizontalPadding: 12,
        ),
        if (_latitud != null && _longitud != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: JPColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: JPColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: JPColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Ubicación confirmada en el mapa',
                    style: TextStyle(
                      color: JPColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool opcional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: JPColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (!opcional)
              const Text(
                ' *',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: JPColors.error),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: JPColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: JPColors.error),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCampoTelefono() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.phone_iphone_rounded, color: JPColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Teléfono de contacto',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              ' *',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: JPColors.error),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IntlPhoneField(
          controller: _telefonoController,
          initialCountryCode: 'EC',
          disableLengthCheck: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: 'Número de teléfono',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: JPColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: JPColors.error),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (phone) {
            final dial = phone.countryCode;
            String local = phone.number.replaceAll(RegExp(r'\s'), '');
            if (local.startsWith('0') && local.length > 1) {
              local = local.substring(1);
            }
            final normalized = local.isNotEmpty ? '$dial$local' : phone.completeNumber;
            setState(() => _telefonoCompleto = normalized);
          },
          validator: (phone) {
            String local = phone?.number.replaceAll(RegExp(r'\s'), '') ?? '';
            if (local.isEmpty) {
              return 'Ingresa un número de contacto';
            }
            if (local.startsWith('0') && local.length > 1) {
              local = local.substring(1);
            }
            if (local.length < 6) return 'Número demasiado corto';
            return null;
          },
        ),
      ],
    );
  }
}
