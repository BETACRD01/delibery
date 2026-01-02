// lib/screens/user/perfil/configuracion/direcciones/pantalla_mis_direcciones.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Material,
        Icons,
        TextFormField,
        InputDecoration,
        OutlineInputBorder,
        ListTile,
        Divider,
        MaterialType;
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:mobile/services/core/api/api_exception.dart';
import '../../../../../models/auth/usuario.dart';
import '../../../../../services/core/ui/toast_service.dart';
import '../../../../../services/usuarios/usuarios_service.dart';
import '../../../../../theme/primary_colors.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../../../widgets/maps/map_location_picker.dart';

/// 📍 Pantalla optimizada para gestionar direcciones
/// ✅ Modo unificado: Crea O Edita según el contexto
/// ✅ Sin duplicados: Al editar, actualiza la dirección existente
class PantallaAgregarDireccion extends StatefulWidget {
  final DireccionModel?
  direccion; // Si viene null = CREAR, si viene dato = EDITAR

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
    _calleSecundariaController = TextEditingController(
      text: dir?.calleSecundaria ?? '',
    );
    _ciudadController = TextEditingController(text: dir?.ciudad ?? '');
    _telefonoController = TextEditingController();
    _indicacionesController = TextEditingController(
      text: dir?.indicaciones ?? '',
    );

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
      final telefono =
          (_telefonoCompleto.isNotEmpty
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

        // ✅ También actualizar el celular del usuario si fue ingresado
        if (telefono.isNotEmpty) {
          await _actualizarCelularUsuario(telefono);
        }

        if (!mounted) return;
        ToastService().showSuccess(
          context,
          'Dirección actualizada correctamente',
        );
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

          // ✅ También actualizar el celular del usuario si fue ingresado
          if (telefono.isNotEmpty) {
            await _actualizarCelularUsuario(telefono);
          }

          if (!mounted) return;
          ToastService().showSuccess(context, 'Dirección creada correctamente');
          Navigator.pop(context, true);
        } on ApiException catch (e) {
          // Detectar si es un error de duplicado
          final errorMensaje = e.getUserFriendlyMessage().toLowerCase();
          final esDuplicado =
              errorMensaje.contains('ya tienes') ||
              errorMensaje.contains('muy cercana') ||
              errorMensaje.contains('duplicad');

          if (esDuplicado && mounted) {
            ToastService().showError(
              context,
              'Ya tienes una dirección en esta ubicación. Por favor edita la dirección existente.',
            );
          } else if (mounted) {
            ToastService().showError(context, e.getUserFriendlyMessage());
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ToastService().showError(context, 'Error al guardar dirección: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Actualiza el campo celular del usuario en el backend
  Future<void> _actualizarCelularUsuario(String telefono) async {
    try {
      // El backend espera el campo 'telefono' para actualizar user.celular
      await _usuarioService.actualizarPerfil({'telefono': telefono});
    } catch (e) {
      // No bloquear si falla la actualización del celular
      debugPrint('Error actualizando celular del usuario: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🎨 UI
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: JPCupertinoColors.background(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: JPCupertinoColors.surface(context),
        middle: Text(_modoEdicion ? 'Editar Dirección' : 'Nueva Dirección'),
        border: Border(
          bottom: BorderSide(
            color: JPCupertinoColors.separator(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Dirección con autocompletado
                _buildCampoDireccionConAutocompletado(),
                const SizedBox(height: 16),

                // Calle secundaria
                _buildCampoTexto(
                  controller: _calleSecundariaController,
                  label: 'Calle secundaria',
                  icon: CupertinoIcons.map,
                  hint: 'Ej: Esq. con Calle 10',
                  opcional: true,
                ),
                const SizedBox(height: 16),

                // Piso/Departamento
                _buildCampoTexto(
                  controller: _pisoController,
                  label: 'Piso / Departamento',
                  icon: CupertinoIcons.building_2_fill,
                  hint: 'Ej: Torre B, depto 302',
                  opcional: true,
                ),
                const SizedBox(height: 16),

                // Ciudad
                _buildCampoTexto(
                  controller: _ciudadController,
                  label: 'Ciudad',
                  icon: CupertinoIcons.location_solid,
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
                  icon: CupertinoIcons.text_alignleft,
                  hint: 'Ej: Llamar al llegar, timbre dañado',
                  maxLines: 3,
                  opcional: true,
                ),
                const SizedBox(height: 16),

                // Teléfono
                _buildCampoTelefono(),
                const SizedBox(height: 32),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _guardando ? null : _guardarDireccion,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _guardando
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _modoEdicion
                                    ? CupertinoIcons.check_mark
                                    : CupertinoIcons.location_fill,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _modoEdicion
                                    ? 'Actualizar dirección'
                                    : 'Guardar dirección',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ), // Form
        ), // Material
      ), // SafeArea
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
        _direccionController.selection = TextSelection.fromPosition(
          TextPosition(offset: _direccionController.text.length),
        );
      });

      if (prediction.description != null &&
          prediction.description!.isNotEmpty) {
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
        Row(
          children: [
            Icon(CupertinoIcons.home, color: AppColorsPrimary.main, size: 20),
            const SizedBox(width: 8),
            Text(
              'Dirección principal',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.label(context),
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.systemRed(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: CupertinoColors.transparent,
          child: Stack(
            children: [
              GooglePlaceAutoCompleteTextField(
                textEditingController: _direccionController,
                googleAPIKey: 'AIzaSyAVomIe-K4kpGMrQTc-bZaNcBvJtkK-KBA',
                debounceTime: 300,
                countries: const ['ec'],
                isLatLngRequired: true,
                inputDecoration: InputDecoration(
                  hintText: 'Ej: Av. Amazonas y 10 de Agosto',
                  hintStyle: TextStyle(
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: JPCupertinoColors.separator(context),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: AppColorsPrimary.main,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: JPCupertinoColors.systemRed(context),
                    ),
                  ),
                  filled: true,
                  fillColor: JPCupertinoColors.surface(context),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: _mostrarSeleccionMapaPlaceholder,
                        child: Icon(
                          CupertinoIcons.map,
                          color: AppColorsPrimary.main,
                          size: 22,
                        ),
                      ),
                      if (_direccionController.text.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          onPressed: () {
                            setState(() {
                              _direccionController.clear();
                              _latitud = null;
                              _longitud = null;
                            });
                          },
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: JPCupertinoColors.systemGrey(context),
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
                textStyle: TextStyle(
                  fontSize: 14,
                  color: JPCupertinoColors.label(context),
                ),
                itemBuilder: (context, index, Prediction prediction) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place,
                      color: AppColorsPrimary.main,
                      size: 18,
                    ),
                    title: Text(
                      prediction.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: prediction.structuredFormatting != null
                        ? Text(
                            prediction.structuredFormatting?.secondaryText ??
                                '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  );
                },
                seperatedBuilder: Divider(
                  height: 1,
                  color: JPCupertinoColors.separator(context),
                ),
                itemClick: (Prediction prediction) {
                  _direccionController.text = prediction.description ?? '';
                  _direccionController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _direccionController.text.length),
                  );
                },
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  _onPlaceSelected(prediction);
                },
                isCrossBtnShown: false,
                containerHorizontalPadding: 0,
              ),
            ],
          ),
        ),
        if (_latitud != null && _longitud != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: JPCupertinoColors.systemGreen(
                  context,
                ).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: JPCupertinoColors.systemGreen(context),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ubicación confirmada',
                    style: TextStyle(
                      color: JPCupertinoColors.systemGreen(context),
                      fontSize: 12.5,
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

  /// Abre el selector de mapa para elegir ubicación
  void _mostrarSeleccionMapaPlaceholder() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitud,
          initialLongitude: _longitud,
          onLocationSelected: (lat, lng, address) {
            setState(() {
              _latitud = lat;
              _longitud = lng;
              // Actualizar el campo de dirección con el nombre claro de la ubicación
              if (_direccionController.text.isEmpty ||
                  _direccionController.text == 'Moviendo mapa...') {
                _direccionController.text = address;
              }
            });

            // Mostrar confirmación sutil
            ToastService().showSuccess(
              context,
              'Ubicación seleccionada correctamente',
            );
          },
        ),
      ),
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
            Icon(icon, color: AppColorsPrimary.main, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.label(context),
              ),
            ),
            if (!opcional)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: JPCupertinoColors.systemRed(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: CupertinoColors.transparent,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              color: JPCupertinoColors.label(context),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: JPCupertinoColors.separator(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColorsPrimary.main, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: JPCupertinoColors.systemRed(context),
                ),
              ),
              filled: true,
              fillColor: JPCupertinoColors.surface(context),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: maxLines,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildCampoTelefono() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.phone, color: AppColorsPrimary.main, size: 20),
            const SizedBox(width: 8),
            Text(
              'Teléfono de contacto',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.label(context),
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: JPCupertinoColors.systemRed(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: CupertinoColors.transparent,
          child: IntlPhoneField(
            controller: _telefonoController,
            initialCountryCode: 'EC',
            disableLengthCheck: false,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              color: JPCupertinoColors.label(context),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Número de teléfono',
              hintStyle: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: JPCupertinoColors.separator(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColorsPrimary.main, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: JPCupertinoColors.systemRed(context),
                ),
              ),
              filled: true,
              fillColor: JPCupertinoColors.surface(context),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (phone) {
              final dial = phone.countryCode;
              String local = phone.number.replaceAll(RegExp(r'\s'), '');
              if (local.startsWith('0') && local.length > 1) {
                local = local.substring(1);
              }
              final normalized = local.isNotEmpty
                  ? '$dial$local'
                  : phone.completeNumber;
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
        ),
      ],
    );
  }
}
