// lib/screens/user/perfil/solicitudes_rol/widgets/formulario_repartidor.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../../../services/solicitudes/solicitudes_service.dart';
import '../../../../../services/auth/auth_service.dart';
import '../../../../../models/solicitud_cambio_rol.dart';

/// 📝 FORMULARIO PARA SOLICITUD DE REPARTIDOR
/// Diseño: iOS Native Style
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

                      // Grupo 1: Información Personal
                      _buildSectionHeader('INFORMACIÓN PERSONAL'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([
                        _buildIOSTextField(
                          controller: _cedulaController,
                          placeholder: 'Cédula de Identidad',
                          prefix: CupertinoIcons.person_crop_square,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(13),
                          ],
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Grupo 2: Vehículo y Zona
                      _buildSectionHeader('DETALLES DE TRABAJO'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([
                        _buildTipoVehiculoField(),
                        _buildDivider(),
                        _buildIOSTextField(
                          controller: _zonaCoberturaController,
                          placeholder: 'Zona de Cobertura',
                          prefix: CupertinoIcons.map_pin_ellipse,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Grupo 3: Motivo
                      _buildSectionHeader('MOTIVO DE SOLICITUD'),
                      const SizedBox(height: 8),
                      _buildGroupedCard([
                        _buildIOSTextArea(
                          controller: _motivoController,
                          placeholder:
                              'Cuéntanos por qué quieres ser repartidor...',
                          maxLines: 5,
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
            color: CupertinoColors.systemGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.car_fill,
            color: CupertinoColors.systemGreen,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ser Repartidor',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Completa tus datos para comenzar',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel,
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
    final esRepartidor = user?.roles.contains('REPARTIDOR') ?? false;

    if (!esRepartidor) return const SizedBox.shrink();

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
              'Ya eres Repartidor',
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
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        decoration: null,
        style: const TextStyle(fontSize: 17, letterSpacing: -0.4),
        placeholderStyle: TextStyle(
          color: CupertinoColors.placeholderText.resolveFrom(context),
          fontSize: 17,
        ),
      ),
    );
  }

  Widget _buildTipoVehiculoField() {
    return GestureDetector(
      onTap: _mostrarSelectorVehiculo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.car_detailed,
              size: 22,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tipoVehiculo != null
                    ? TipoVehiculo.values
                          .firstWhere((t) => t.value == _tipoVehiculo)
                          .label
                    : 'Tipo de Vehículo',
                style: TextStyle(
                  fontSize: 17,
                  letterSpacing: -0.4,
                  color: _tipoVehiculo != null
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
                    colors: [CupertinoColors.systemGreen, Color(0xFF34C759)],
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
                  : CupertinoColors.systemBlue,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🎬 ACCIONES
  // ══════════════════════════════════════════════════════════════════════════════

  void _mostrarSelectorVehiculo() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
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
                    'Tipo de Vehículo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
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
                    () => _tipoVehiculo = TipoVehiculo.values[index].value,
                  );
                },
                children: TipoVehiculo.values.map((tipo) {
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ⚙️ LÓGICA DE ENVÍO + VALIDACIÓN
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _enviarSolicitud() async {
    // 1. Ocultar teclado
    FocusScope.of(context).unfocus();

    // 2. Validaciones locales
    if (_cedulaController.text.length < 10) {
      _mostrarAlerta('Ingresa una cédula válida', isError: true);
      return;
    }
    if (_tipoVehiculo == null) {
      _mostrarAlerta('Selecciona un tipo de vehículo', isError: true);
      return;
    }
    if (_zonaCoberturaController.text.length < 3) {
      _mostrarAlerta('Ingresa la zona de cobertura', isError: true);
      return;
    }
    if (_motivoController.text.length < 10) {
      _mostrarAlerta(
        'El motivo debe tener al menos 10 caracteres',
        isError: true,
      );
      return;
    }

    // 3. Iniciar carga
    setState(() => _isLoading = true);

    try {
      // 4. Enviar al Backend
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

      // 6. Manejo de errores (Ej: Cédula duplicada)
      String errorMsg = e.toString();

      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }

      _mostrarAlerta(errorMsg, isError: true);
    } finally {
      // 7. Detener carga
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
