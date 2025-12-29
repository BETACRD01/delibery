// lib/screens/user/perfil/solicitudes_rol/widgets/formulario_proveedor.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        TimeOfDay,
        Material,
        Icons,
        InputDecoration,
        InputBorder,
        ListTile,
        Divider;
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../../../services/solicitudes/solicitudes_service.dart';
import '../../../../../services/auth/auth_service.dart';
import '../../../../../services/core/toast_service.dart';
import '../../../../../models/solicitud_cambio_rol.dart';
import '../../../../../widgets/maps/map_location_picker.dart';

/// 📝 FORMULARIO PARA SOLICITUD DE PROVEEDOR
/// Diseño: iOS Native Style
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
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  String? _tipoNegocio;
  TimeOfDay? _horarioApertura;
  TimeOfDay? _horarioCierre;
  double? _latitud;
  double? _longitud;
  bool _isLoading = false;

  @override
  void dispose() {
    _rucController.dispose();
    _nombreComercialController.dispose();
    _descripcionController.dispose();
    _motivoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // Header con ícono
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildHeader(),
                ),
              ),

              // Estado del usuario
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCardEstadoUsuario(),
                ),
              ),

              // Formulario en grupos estilo iOS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Grupo 1: Información Básica
                      _buildSectionHeader('INFORMACIÓN BÁSICA'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([
                        _buildIOSTextField(
                          controller: _rucController,
                          placeholder: 'RUC',
                          prefix: CupertinoIcons.number,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(13),
                          ],
                        ),
                        _buildDivider(),
                        _buildIOSTextField(
                          controller: _nombreComercialController,
                          placeholder: 'Nombre Comercial',
                          prefix: CupertinoIcons.building_2_fill,
                          textCapitalization: TextCapitalization.words,
                        ),
                        _buildDivider(),
                        _buildTipoNegocioField(),
                      ]),

                      const SizedBox(height: 24),

                      // Grupo 2: Descripción
                      _buildSectionHeader('SOBRE TU NEGOCIO'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([
                        _buildIOSTextArea(
                          controller: _descripcionController,
                          placeholder: 'Describe tus productos o servicios...',
                          maxLines: 4,
                          maxLength: 500,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Grupo 3: Horarios
                      _buildSectionHeader('HORARIO DE ATENCIÓN'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([_buildHorarioRow()]),

                      const SizedBox(height: 24),

                      // Grupo 4: Ubicación del Negocio
                      _buildSectionHeader('UBICACIÓN DEL NEGOCIO'),
                      const SizedBox(height: 8),
                      _buildCampoDireccionConMapa(),

                      const SizedBox(height: 24),

                      // Grupo 5: Motivo
                      _buildSectionHeader('MOTIVO DE SOLICITUD'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([
                        _buildIOSTextArea(
                          controller: _motivoController,
                          placeholder: '¿Por qué deseas unirte?',
                          maxLines: 4,
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Botones
                      _buildBotones(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🧩 COMPONENTES UI ESTILO iOS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: CupertinoColors.systemCyan.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.building_2_fill,
            color: CupertinoColors.systemCyan,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ser Proveedor',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: CupertinoColors.label
                      .resolveFrom(context)
                      .withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Registra tu negocio y vende más',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardEstadoUsuario() {
    final user = _authService.user;
    final esProveedor = user?.roles.contains('PROVEEDOR') ?? false;

    if (!esProveedor) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: CupertinoColors.systemGreen,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ya eres Proveedor',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: CupertinoColors.systemGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          letterSpacing: -0.08,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 44),
      height: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }

  Widget _buildIOSTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            prefix,
            size: 22,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              decoration: null,
              style: const TextStyle(fontSize: 17, letterSpacing: -0.4),
              placeholderStyle: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSTextArea({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 3,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: null,
        style: const TextStyle(fontSize: 17, letterSpacing: -0.4),
        placeholderStyle: TextStyle(
          color: CupertinoColors.placeholderText.resolveFrom(context),
          fontSize: 17,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 📍 CAMPO DE DIRECCIÓN CON MAPA
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCampoDireccionConMapa() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Campo de dirección con estilo iOS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemCyan,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    CupertinoIcons.location_solid,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Material(
                    color: CupertinoColors.transparent,
                    child: GooglePlaceAutoCompleteTextField(
                      textEditingController: _direccionController,
                      googleAPIKey: 'AIzaSyAVomIe-K4kpGMrQTc-bZaNcBvJtkK-KBA',
                      debounceTime: 300,
                      countries: const ['ec'],
                      isLatLngRequired: true,
                      inputDecoration: InputDecoration(
                        hintText: 'Ingresa la dirección',
                        hintStyle: TextStyle(
                          color: CupertinoColors.placeholderText.resolveFrom(
                            context,
                          ),
                          fontSize: 17,
                          letterSpacing: -0.4,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      textStyle: TextStyle(
                        fontSize: 17,
                        letterSpacing: -0.4,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      itemBuilder: (context, index, Prediction prediction) {
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.place,
                            color: CupertinoColors.systemCyan,
                            size: 20,
                          ),
                          title: Text(
                            prediction.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15),
                          ),
                        );
                      },
                      seperatedBuilder: Divider(
                        height: 1,
                        indent: 50,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      itemClick: (Prediction prediction) {
                        _direccionController.text =
                            prediction.description ?? '';
                        _direccionController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _direccionController.text.length,
                              ),
                            );
                      },
                      getPlaceDetailWithLatLng: (Prediction prediction) async {
                        _direccionController.text =
                            prediction.description ?? '';
                        if (prediction.description != null) {
                          try {
                            final locations = await locationFromAddress(
                              prediction.description!,
                            );
                            if (locations.isNotEmpty) {
                              setState(() {
                                _latitud = locations.first.latitude;
                                _longitud = locations.first.longitude;
                                final parts = prediction.description!.split(
                                  ',',
                                );
                                if (parts.length >= 2) {
                                  _ciudadController.text =
                                      parts[parts.length - 2].trim();
                                }
                              });
                            }
                          } catch (e) {
                            debugPrint('Error obteniendo coordenadas: $e');
                          }
                        }
                      },
                      isCrossBtnShown: false,
                      containerHorizontalPadding: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divisor
          Container(
            margin: const EdgeInsets.only(left: 60),
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),

          // Botón seleccionar en mapa
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onPressed: _mostrarSeleccionMapa,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemCyan,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    CupertinoIcons.map_fill,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _latitud != null
                        ? 'Ubicación seleccionada ✓'
                        : 'Seleccionar en mapa',
                    style: TextStyle(
                      fontSize: 17,
                      letterSpacing: -0.4,
                      color: _latitud != null
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemCyan,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                ),
              ],
            ),
          ),

          // Indicador de ubicación confirmada
          if (_latitud != null && _longitud != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CupertinoColors.activeGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    color: CupertinoColors.activeGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ubicación confirmada',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeGreen,
                          ),
                        ),
                        if (_ciudadController.text.isNotEmpty)
                          Text(
                            _ciudadController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarSeleccionMapa() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitud,
          initialLongitude: _longitud,
          onLocationSelected: (lat, lng, address) {
            setState(() {
              _latitud = lat;
              _longitud = lng;
              if (_direccionController.text.isEmpty) {
                _direccionController.text = address;
              }
              // Extraer ciudad
              final parts = address.split(',');
              if (parts.length >= 2) {
                _ciudadController.text = parts[parts.length - 2].trim();
              }
            });
            ToastService().showSuccess(context, 'Ubicación seleccionada');
          },
        ),
      ),
    );
  }

  Widget _buildTipoNegocioField() {
    return GestureDetector(
      onTap: _mostrarSelectorTipoNegocio,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.square_grid_2x2,
              size: 22,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tipoNegocio != null
                    ? TipoNegocio.values
                          .firstWhere((t) => t.value == _tipoNegocio)
                          .label
                    : 'Tipo de Negocio',
                style: TextStyle(
                  fontSize: 17,
                  letterSpacing: -0.4,
                  color: _tipoNegocio != null
                      ? CupertinoColors.label.resolveFrom(context)
                      : CupertinoColors.placeholderText.resolveFrom(context),
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorarioRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildHorarioButton(
              label: 'Apertura',
              icon: CupertinoIcons.sunrise,
              time: _horarioApertura,
              onTap: () => _seleccionarHorario(true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildHorarioButton(
              label: 'Cierre',
              icon: CupertinoIcons.moon,
              time: _horarioCierre,
              onTap: () => _seleccionarHorario(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioButton({
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time != null ? time.format(context) : '--:--',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: time != null
                    ? CupertinoColors.label.resolveFrom(context)
                    : CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotones() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: !_isLoading
                ? const LinearGradient(
                    colors: [
                      CupertinoColors.systemCyan,
                      CupertinoColors.systemTeal,
                    ],
                  )
                : null,
            color: _isLoading
                ? CupertinoColors.systemGrey5.resolveFrom(context)
                : null,
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _enviarSolicitud,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Enviar Solicitud',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          onPressed: _isLoading ? null : widget.onBack,
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 17,
              color: _isLoading
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemCyan,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎬 ACCIONES
  // ══════════════════════════════════════════════════════════════════════════════

  void _mostrarSelectorTipoNegocio() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SizedBox(
          height: 250,
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const Text(
                      'Tipo de Negocio',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setState(
                      () => _tipoNegocio = TipoNegocio.values[index].value,
                    );
                  },
                  children: TipoNegocio.values.map((tipo) {
                    return Center(
                      child: Text(
                        tipo.label,
                        style: const TextStyle(fontSize: 17),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarHorario(bool esApertura) async {
    final initialTime = esApertura
        ? (_horarioApertura ?? const TimeOfDay(hour: 8, minute: 0))
        : (_horarioCierre ?? const TimeOfDay(hour: 18, minute: 0));

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SizedBox(
          height: 250,
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    Text(
                      esApertura ? 'Hora de Apertura' : 'Hora de Cierre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      final picked = TimeOfDay(
                        hour: newTime.hour,
                        minute: newTime.minute,
                      );
                      if (esApertura) {
                        _horarioApertura = picked;
                      } else {
                        _horarioCierre = picked;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ⚙️ LÓGICA DE ENVÍO + MANEJO DE DUPLICADOS (RUC)
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _enviarSolicitud() async {
    FocusScope.of(context).unfocus();
    final user = _authService.user;

    // Validaciones
    if (user == null || user.email.contains('Anonymous')) {
      _mostrarAlerta('Debes iniciar sesión para continuar', isError: true);
      return;
    }
    if (user.roles.contains('PROVEEDOR')) {
      _mostrarAlerta('Ya eres Proveedor.', isError: true);
      return;
    }
    if (_rucController.text.length != 13) {
      _mostrarAlerta('El RUC debe tener 13 dígitos', isError: true);
      return;
    }
    if (_nombreComercialController.text.length < 3) {
      _mostrarAlerta('Nombre comercial demasiado corto', isError: true);
      return;
    }
    if (_tipoNegocio == null) {
      _mostrarAlerta('Selecciona un tipo de negocio', isError: true);
      return;
    }
    if (_descripcionController.text.length < 10) {
      _mostrarAlerta('La descripción debe ser más detallada', isError: true);
      return;
    }
    if (_motivoController.text.length < 10) {
      _mostrarAlerta('Escribe un motivo válido', isError: true);
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
        // Campos de ubicación
        direccion: _direccionController.text.trim(),
        latitud: _latitud,
        longitud: _longitud,
        ciudad: _ciudadController.text.trim(),
      );

      if (!mounted) return;
      widget.onSubmitSuccess();
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }

      _mostrarAlerta(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarAlerta(String mensaje, {bool isError = false}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Icon(
          isError
              ? CupertinoIcons.exclamationmark_circle
              : CupertinoIcons.check_mark_circled,
          color: isError
              ? CupertinoColors.systemRed
              : CupertinoColors.systemGreen,
          size: 48,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(mensaje, style: const TextStyle(fontSize: 15)),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
