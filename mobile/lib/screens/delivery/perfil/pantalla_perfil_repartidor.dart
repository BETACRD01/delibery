// lib/screens/delivery/perfil/pantalla_perfil_repartidor.dart

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../apis/helpers/api_exception.dart';
import '../../../models/payments/datos_bancarios.dart';
import '../../../models/entities/repartidor.dart';
import '../../../services/repartidor/repartidor_datos_bancarios_service.dart';
import '../../../services/repartidor/repartidor_service.dart';
import '../ganancias/pantalla_datos_bancarios.dart';

/// Pantalla de Edición de Perfil del Repartidor (Estilo iOS)
class PantallaEditarPerfilRepartidor extends StatefulWidget {
  const PantallaEditarPerfilRepartidor({super.key});

  @override
  State<PantallaEditarPerfilRepartidor> createState() =>
      _PantallaEditarPerfilRepartidorState();
}

class _PantallaEditarPerfilRepartidorState
    extends State<PantallaEditarPerfilRepartidor> {
  // ============================================
  // SERVICE
  // ============================================
  final RepartidorService _service = RepartidorService();
  final RepartidorDatosBancariosService _datosService =
      RepartidorDatosBancariosService();

  // ============================================
  // ESTADO
  // ============================================
  PerfilRepartidorModel? _perfil;
  DatosBancarios? _datosBancarios;
  EstadisticasRepartidorModel? _estadisticas;
  bool _loading = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  String? _vehiculoSeleccionado;

  // ============================================
  // CONTROLLERS
  // ============================================
  late TextEditingController _telefonoController;
  String? _telefonoCompleto;

  // Datos del User
  late TextEditingController _emailController;
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;

  // Foto
  File? _fotoSeleccionada;

  // ============================================
  // COLORES
  // ============================================
  static const Color _primary = Color(0xFF0CB7F2); // Celeste corporativo

  // Dynamic Colors
  Color get _surface =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardBg =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _errorColor => CupertinoColors.destructiveRed.resolveFrom(context);
  Color get _successColor => CupertinoColors.activeGreen.resolveFrom(context);

  // ============================================
  // CICLO DE VIDA
  // ============================================

  @override
  void initState() {
    super.initState();

    // Inicializar controllers
    _telefonoController = TextEditingController();
    _emailController = TextEditingController();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();

    _cargarPerfil();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _emailController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  // ============================================
  // CARGAR PERFIL
  // ============================================

  Future<void> _cargarPerfil() async {
    setState(() {
      _loading = true;
    });

    try {
      _perfil = await _service.obtenerMiRepartidor(forzarRecarga: true);

      // Llenar controllers
      _telefonoController.text = _formatearTelefonoParaMostrar(
        _perfil?.telefono,
      );
      _telefonoCompleto = _perfil?.telefono;
      _emailController.text = _perfil?.email ?? '';
      _nombreController.text = _perfil?.firstName ?? '';
      _apellidoController.text = _perfil?.lastName ?? '';
      _vehiculoSeleccionado = _normalizarVehiculo(_perfil?.vehiculo);

      try {
        _estadisticas = await _service.obtenerEstadisticas(forzarRecarga: true);
      } catch (e) {
        developer.log('Error stats: $e');
      }

      await _cargarDatosBancarios();

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        _mostrarToast(
          'Error al cargar perfil',
          color: _errorColor,
          icono: CupertinoIcons.exclamationmark_circle_fill,
        );
      }
    }
  }

  Future<void> _cargarDatosBancarios() async {
    try {
      final datos = await _datosService.obtenerDatosBancarios();
      if (mounted) {
        setState(() {
          _datosBancarios = datos;
        });
      }
    } catch (e) {
      // Ignorar
    }
  }

  // ============================================
  // SELECCIONAR FOTO
  // ============================================

  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();

    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Foto de perfil'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Tomar foto'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Elegir de galería'),
          ),
          if (_perfil?.fotoPerfil != null || _fotoSeleccionada != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                setState(() => _fotoSeleccionada = null);
                // Para eliminar realmente necesitaríamos lógica adicional en guardar
              },
              child: const Text('Eliminar foto'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final File imageFile = File(image.path);
      // Validar tamaño > 5MB opcionalmente

      setState(() => _fotoSeleccionada = imageFile);
    } catch (e) {
      _mostrarToast('Error al seleccionar imagen', color: _errorColor);
    }
  }

  // ============================================
  // VALIDACIÓN Y GUARDADO
  // ============================================

  bool _validarFormulario() {
    // Validar email básico
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      _mostrarToast('Email inválido', color: _errorColor);
      return false;
    }

    if (_nombreController.text.trim().isEmpty) {
      _mostrarToast('Nombre requerido', color: _errorColor);
      return false;
    }

    if ((_vehiculoSeleccionado ?? '').isEmpty) {
      _mostrarToast('Selecciona un vehículo', color: _errorColor);
      return false;
    }

    return true;
  }

  Future<void> _guardarCambios() async {
    if (!_validarFormulario()) return;

    setState(() {
      _guardando = true;
      if (_fotoSeleccionada != null) _subiendoFoto = true;
    });

    try {
      // 1. Detectar cambios
      final telefonoNuevo = _normalizarTelefono(
        (_telefonoCompleto?.isNotEmpty == true
            ? _telefonoCompleto!
            : _telefonoController.text),
      );
      final vehiculoNuevo = _vehiculoSeleccionado ?? '';

      final hayCambiosPerfil =
          telefonoNuevo != (_perfil?.telefono ?? '') ||
          vehiculoNuevo != (_perfil?.vehiculo ?? '') ||
          _fotoSeleccionada != null;

      final emailNuevo = _emailController.text.trim();
      final nombreNuevo = _nombreController.text.trim();
      final apellidoNuevo = _apellidoController.text.trim();

      final hayCambiosContacto =
          emailNuevo != (_perfil?.email ?? '') ||
          nombreNuevo != (_perfil?.firstName ?? '') ||
          apellidoNuevo != (_perfil?.lastName ?? '');

      if (!hayCambiosPerfil && !hayCambiosContacto) {
        _mostrarToast('No hay cambios', icono: CupertinoIcons.info);
        setState(() {
          _guardando = false;
          _subiendoFoto = false;
        });
        return;
      }

      // 2. Actualizar API
      if (hayCambiosPerfil) {
        _perfil = await _service.actualizarMiPerfil(
          telefono: telefonoNuevo.isNotEmpty ? telefonoNuevo : null,
          vehiculo: vehiculoNuevo.isNotEmpty ? vehiculoNuevo : null,
          fotoPerfil: _fotoSeleccionada,
        );
      }

      if (hayCambiosContacto) {
        _perfil = await _service.actualizarMiContacto(
          email: emailNuevo.isNotEmpty ? emailNuevo : null,
          firstName: nombreNuevo.isNotEmpty ? nombreNuevo : null,
          lastName: apellidoNuevo.isNotEmpty ? apellidoNuevo : null,
        );
      }

      // 3. Finalizar
      _fotoSeleccionada = null;
      setState(() {
        _guardando = false;
        _subiendoFoto = false;
      });

      if (mounted) {
        _mostrarToast(
          'Perfil actualizado',
          icono: CupertinoIcons.checkmark_circle_fill,
        );
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      setState(() {
        _guardando = false;
        _subiendoFoto = false;
      });
      _mostrarToast(e.getUserFriendlyMessage(), color: _errorColor);
    } catch (e) {
      setState(() {
        _guardando = false;
        _subiendoFoto = false;
      });
      _mostrarToast('Error al guardar cambios', color: _errorColor);
    }
  }

  // ============================================
  // UI BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Material(
      // Necesario para IntlPhoneField y otros widgets que usen Theme.of(context)
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Editar Perfil'),
          backgroundColor: _cardBg,
          border: const Border(
            bottom: BorderSide(color: Color(0x4D000000), width: 0.0),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _guardando ? null : _guardarCambios,
            child: _guardando
                ? const CupertinoActivityIndicator(radius: 8)
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        child: _loading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CupertinoActivityIndicator());
  }

  Widget _buildContent() {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          _buildFotoPerfil(),
          const SizedBox(height: 20),
          if (_estadisticas != null) _buildResumenCalificaciones(),

          _buildSeccionDatosRepartidor(),
          const SizedBox(height: 20),
          _buildSeccionDatosContacto(),
          const SizedBox(height: 20),
          _buildSeccionDatosBancarios(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildFotoPerfil() {
    ImageProvider? imageProvider;
    if (_fotoSeleccionada != null) {
      imageProvider = FileImage(_fotoSeleccionada!);
    } else if (_perfil?.fotoPerfil != null) {
      imageProvider = NetworkImage(_perfil!.fotoPerfil!);
    }

    return Center(
      child: GestureDetector(
        onTap: _subiendoFoto ? null : _seleccionarFoto,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cardBg,
                border: Border.all(
                  color: CupertinoColors.systemGrey5,
                  width: 4,
                ),
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imageProvider == null
                  ? const Icon(
                      CupertinoIcons.person_fill,
                      size: 60,
                      color: CupertinoColors.systemGrey3,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCalificaciones() {
    final stats = _estadisticas!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  stats.calificacionPromedio.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    if (index < stats.calificacionPromedio.round()) {
                      return const Icon(
                        CupertinoIcons.star_fill,
                        color: CupertinoColors.systemYellow,
                        size: 16,
                      );
                    }
                    return const Icon(
                      CupertinoIcons.star,
                      color: CupertinoColors.systemGrey4,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalCalificaciones} reseñas',
                  style: const TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            if (stats.porcentaje5Estrellas > 0)
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.porcentaje5Estrellas.round()}%',
                      style: TextStyle(
                        color: _successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Clientes muy satisfechos',
                      style: TextStyle(
                        fontSize: 13,
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
    );
  }

  Widget _buildSeccionDatosRepartidor() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('DATOS DEL REPARTIDOR'),
      children: [
        // Phone Field Custom Wrapper
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: IntlPhoneField(
            controller: _telefonoController,
            initialCountryCode: _obtenerCodigoPaisInicial(
              _telefonoCompleto ?? _telefonoController.text,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Teléfono',
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            style: const TextStyle(fontSize: 16),
            dropdownIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
            onChanged: (phone) => _telefonoCompleto = phone.completeNumber,
            flagsButtonMargin: const EdgeInsets.only(right: 8),
          ),
        ),
        // Vehicle Picker
        GestureDetector(
          onTap: () => _mostrarPickerVehiculo(),
          child: CupertinoFormRow(
            prefix: const Text('Vehículo'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _vehiculoSeleccionado != null
                      ? _formatearVehiculo(_vehiculoSeleccionado!)
                      : 'Seleccionar',
                  style: TextStyle(
                    color: _vehiculoSeleccionado != null
                        ? CupertinoColors.label
                        : CupertinoColors.placeholderText,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionDatosContacto() {
    const labelStyle = TextStyle(color: _primary, fontWeight: FontWeight.w500);

    return CupertinoFormSection.insetGrouped(
      header: const Text('CONTACTO'),
      children: [
        CupertinoTextFormFieldRow(
          controller: _emailController,
          placeholder: 'Email',
          prefix: const Text('Email', style: labelStyle),
          keyboardType: TextInputType.emailAddress,
        ),
        CupertinoTextFormFieldRow(
          controller: _nombreController,
          placeholder: 'Nombre',
          prefix: const Text('Nombre', style: labelStyle),
          textCapitalization: TextCapitalization.words,
        ),
        CupertinoTextFormFieldRow(
          controller: _apellidoController,
          placeholder: 'Apellido',
          prefix: const Text('Apellido', style: labelStyle),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildSeccionDatosBancarios() {
    String bankDetailsText = 'Configurar';
    final bankInfo = _datosBancarios;

    // Safely extract bank details if available
    if (bankInfo != null && bankInfo.estanCompletos) {
      final bankName = bankInfo.bancoNombre ?? '';
      final accountNumber = bankInfo.bancoNumeroCuenta ?? '';

      String maskedAccount = '';
      if (accountNumber.isNotEmpty) {
        if (accountNumber.length > 4) {
          maskedAccount =
              ' ••••${accountNumber.substring(accountNumber.length - 4)}';
        } else {
          maskedAccount = ' $accountNumber';
        }
      }
      bankDetailsText = '$bankName$maskedAccount';
    }

    return CupertinoFormSection.insetGrouped(
      header: const Text('DATOS BANCARIOS'),
      children: [
        GestureDetector(
          onTap: _abrirPantallaBancaria,
          child: CupertinoFormRow(
            prefix: const Text('Cuenta Bancaria'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    bankDetailsText,
                    style: TextStyle(
                      color: (bankInfo?.estanCompletos ?? false)
                          ? CupertinoColors.label
                          : CupertinoColors.activeBlue,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  void _mostrarPickerVehiculo() {
    final vehiculos = [
      'motocicleta',
      'bicicleta',
      'automovil',
      'camioneta',
      'otro',
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Listo'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32.0,
                onSelectedItemChanged: (int index) {
                  setState(() => _vehiculoSeleccionado = vehiculos[index]);
                },
                scrollController: FixedExtentScrollController(
                  initialItem: _vehiculoSeleccionado != null
                      ? vehiculos.indexOf(_vehiculoSeleccionado!)
                      : 0,
                ),
                children: vehiculos
                    .map((v) => Center(child: Text(_formatearVehiculo(v))))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirPantallaBancaria() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaDatosBancarios()),
    );
    await _cargarDatosBancarios();
  }

  String _formatearTelefonoParaMostrar(String? telefono) {
    if (telefono == null || telefono.isEmpty) return '';
    // Remover código de país +593 y cualquier cero inicial
    if (telefono.startsWith('+593')) {
      var local = telefono.substring(4);
      if (local.startsWith('0')) local = local.substring(1);
      return local;
    }
    return telefono;
  }

  String _obtenerCodigoPaisInicial(String numero) {
    if (numero.startsWith('+593')) return 'EC';
    if (numero.startsWith('+1')) return 'US';
    if (numero.startsWith('+52')) return 'MX';
    if (numero.startsWith('+57')) return 'CO';
    return 'EC';
  }

  String _normalizarTelefono(String telefono) {
    final valor = telefono.trim();
    if (valor.isEmpty) return '';
    if (valor.startsWith('+5930')) {
      return '+593${valor.substring(5)}';
    }
    return valor;
  }

  String? _normalizarVehiculo(String? vehiculo) {
    if (vehiculo == null) return null;
    final v = vehiculo.toLowerCase().trim();
    if (v == 'moto') return 'motocicleta';
    if (v == 'bici') return 'bicicleta';
    if (v == 'auto' || v == 'carro') return 'automovil';
    final validos = [
      'motocicleta',
      'bicicleta',
      'automovil',
      'camioneta',
      'otro',
    ];
    return validos.contains(v) ? v : 'otro';
  }

  String _formatearVehiculo(String v) {
    switch (v) {
      case 'motocicleta':
        return 'Motocicleta';
      case 'bicicleta':
        return 'Bicicleta';
      case 'automovil':
        return 'Automóvil';
      case 'camioneta':
        return 'Camioneta';
      case 'otro':
        return 'Otro';
      default:
        return v;
    }
  }

  // Toast System
  void _mostrarToast(String mensaje, {IconData? icono, Color? color}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60, // Mostrar arriba
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color ?? _successColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (icono != null) ...[
                    Icon(icono, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }
}
