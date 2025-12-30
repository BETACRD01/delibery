// lib/screens/supplier/perfil/perfil_proveedor_panel.dart

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../config/rutas.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../services/auth/session_cleanup.dart';
import '../../../theme/app_colors_primary.dart';
import '../../../widgets/ratings/rating_summary_card.dart';
import '../../../widgets/role/role_selector_modal.dart';
import '../screens/pantalla_ayuda_proveedor.dart';
import '../screens/pantalla_configuracion_proveedor.dart';

/// Panel de perfil del proveedor - Diseño iOS nativo
class PerfilProveedorEditable extends StatefulWidget {
  const PerfilProveedorEditable({super.key});

  @override
  State<PerfilProveedorEditable> createState() =>
      _PerfilProveedorEditableState();
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
    _descripcionController = TextEditingController(
      text: controller.proveedor?.descripcion ?? '',
    );
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
    _nombreCompletoController = TextEditingController(
      text: controller.nombreCompleto,
    );
    _telefonoController = TextEditingController(
      text: _formatearTelefonoParaMostrar(controller.telefono),
    );
    _telefonoCompleto = controller.telefono;
  }

  String _formatearHora(String? hora) {
    if (hora == null || hora.isEmpty) return '';
    return hora.length >= 5 ? hora.substring(0, 5) : hora;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      body: Consumer<SupplierController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return const Center(child: CupertinoActivityIndicator(radius: 14));
          }

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(controller)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Calificaciones
                    _buildRatingsSection(controller),

                    // Sección NEGOCIO
                    _buildSectionHeader('NEGOCIO'),
                    _buildNegocioCard(controller),

                    const SizedBox(height: 24),

                    // Sección CONTACTO
                    _buildSectionHeader('CONTACTO'),
                    _buildContactoCard(controller),

                    const SizedBox(height: 24),

                    // Sección UBICACIÓN
                    _buildSectionHeader('UBICACIÓN'),
                    _buildUbicacionCard(controller),

                    const SizedBox(height: 24),

                    // Sección HORARIOS
                    _buildSectionHeader('HORARIOS'),
                    _buildHorariosCard(controller),

                    // Error message
                    if (_error != null) _buildErrorBanner(),

                    // Botones de edición
                    if (_editando) ...[
                      const SizedBox(height: 24),
                      _buildBotonesEdicion(),
                    ],

                    const SizedBox(height: 24),

                    // Sección CAMBIAR ROL
                    _buildSectionHeader('CAMBIAR ROL'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: CupertinoIcons.arrow_right_arrow_left,
                        iconBgColor: const Color(0xFFAF52DE),
                        title: 'Cambiar Rol',
                        subtitle: 'Cliente / Repartidor',
                        onTap: () => showRoleSelectorModal(context),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Sección AJUSTES
                    _buildSectionHeader('AJUSTES'),
                    _buildSettingsCard([
                      _buildSettingsTile(
                        icon: CupertinoIcons.gear,
                        iconBgColor: const Color(0xFF8E8E93),
                        title: 'Configuración',
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) =>
                                const PantallaConfiguracionProveedor(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: CupertinoIcons.question_circle_fill,
                        iconBgColor: const Color(0xFF5856D6),
                        title: 'Ayuda y soporte',
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const PantallaAyudaProveedor(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: CupertinoIcons.square_arrow_left,
                        iconBgColor: CupertinoColors.systemRed,
                        title: 'Cerrar Sesión',
                        onTap: _cerrarSesion,
                      ),
                    ]),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(SupplierController controller) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with title and edit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 50),
                  Text(
                    'Mi Perfil',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_editando)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Editar',
                        style: TextStyle(
                          color: AppColorsPrimary.main,
                          fontSize: 17,
                        ),
                      ),
                      onPressed: () => setState(() => _editando = true),
                    )
                  else
                    const SizedBox(width: 50),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Profile card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo
                  GestureDetector(
                    onTap: _editando ? _seleccionarLogo : null,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColorsPrimary.main,
                                AppColorsPrimary.main.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              shape: BoxShape.circle,
                            ),
                            child: _buildLogoImage(controller),
                          ),
                        ),
                        if (_editando)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColorsPrimary.main,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.camera_fill,
                                size: 10,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Business name and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.nombreNegocio.isNotEmpty
                              ? controller.nombreNegocio
                              : 'Mi Negocio',
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.email.isNotEmpty
                              ? controller.email
                              : 'Sin email',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (controller.verificado) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verificado',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoImage(SupplierController controller) {
    if (_logoSeleccionado != null) {
      return ClipOval(
        child: Image.file(
          _logoSeleccionado!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }

    final logoUrl = controller.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      final url = logoUrl.startsWith('http')
          ? logoUrl
          : '${ApiConfig.baseUrl}$logoUrl';
      if (_logoUrlCaido != url) {
        return ClipOval(
          child: Image.network(
            url,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _logoUrlCaido = url);
              });
              return _buildLogoPlaceholder();
            },
          ),
        );
      }
    }

    return _buildLogoPlaceholder();
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.building_2_fill,
        size: 28,
        color: CupertinoColors.systemGrey.resolveFrom(context),
      ),
    );
  }

  Widget _buildRatingsSection(SupplierController controller) {
    final valoracion = controller.valoracionPromedio;
    final totalResenas = controller.totalResenas;

    if (totalResenas == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CompactRatingSummaryCard(
        averageRating: valoracion,
        totalReviews: totalResenas,
        subtitle: 'Calificación promedio del negocio',
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.systemGrey.resolveFrom(context),
            letterSpacing: -0.08,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
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
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: CupertinoColors.systemGrey3.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECCIONES DE DATOS
  // ---------------------------------------------------------------------------

  Widget _buildNegocioCard(SupplierController controller) {
    return _buildSettingsCard([
      _buildInfoTile(
        icon: CupertinoIcons.building_2_fill,
        iconBgColor: const Color(0xFF007AFF),
        label: 'Nombre',
        value: _nombreController.text,
        controller: _nombreController,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.number,
        iconBgColor: const Color(0xFF5AC8FA),
        label: 'RUC',
        value: _rucController.text,
        controller: _rucController,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.tag_fill,
        iconBgColor: const Color(0xFFFF9500),
        label: 'Tipo',
        value: _getNombreTipo(_tipoProveedorSeleccionado),
        isDropdown: true,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.doc_text_fill,
        iconBgColor: const Color(0xFF34C759),
        label: 'Descripción',
        value: _descripcionController.text,
        controller: _descripcionController,
        maxLines: 2,
      ),
    ]);
  }

  Widget _buildContactoCard(SupplierController controller) {
    return _buildSettingsCard([
      _buildInfoTile(
        icon: CupertinoIcons.mail_solid,
        iconBgColor: const Color(0xFF5AC8FA),
        label: 'Email',
        value: _emailController.text,
        controller: _emailController,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.person_fill,
        iconBgColor: const Color(0xFFAF52DE),
        label: 'Nombre',
        value: _nombreCompletoController.text,
        controller: _nombreCompletoController,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.phone_fill,
        iconBgColor: const Color(0xFF34C759),
        label: 'Teléfono',
        value: _telefonoController.text,
        isPhone: true,
      ),
    ]);
  }

  Widget _buildUbicacionCard(SupplierController controller) {
    return _buildSettingsCard([
      _buildInfoTile(
        icon: CupertinoIcons.location_solid,
        iconBgColor: const Color(0xFFFF3B30),
        label: 'Dirección',
        value: _direccionController.text,
        controller: _direccionController,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.map_fill,
        iconBgColor: const Color(0xFF007AFF),
        label: 'Ciudad',
        value: _ciudadController.text,
        controller: _ciudadController,
      ),
    ]);
  }

  Widget _buildHorariosCard(SupplierController controller) {
    return _buildSettingsCard([
      _buildInfoTile(
        icon: CupertinoIcons.sunrise_fill,
        iconBgColor: const Color(0xFFFF9500),
        label: 'Apertura',
        value: _formatearHora(_horarioAperturaController.text),
        isTime: true,
        controller: _horarioAperturaController,
      ),
      _buildDivider(),
      _buildInfoTile(
        icon: CupertinoIcons.sunset_fill,
        iconBgColor: const Color(0xFF5856D6),
        label: 'Cierre',
        value: _formatearHora(_horarioCierreController.text),
        isTime: true,
        controller: _horarioCierreController,
      ),
    ]);
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isDropdown = false,
    bool isPhone = false,
    bool isTime = false,
    int maxLines = 1,
  }) {
    if (!_editando) {
      // View mode
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isNotEmpty ? value : '---',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Edit mode
    if (isDropdown) {
      return _buildDropdownTile(icon, iconBgColor, label);
    }

    if (isPhone) {
      return _buildPhoneTile(icon, iconBgColor, label);
    }

    if (isTime && controller != null) {
      return _buildTimeTile(icon, iconBgColor, label, controller);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: CupertinoColors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: label,
              maxLines: maxLines,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(IconData icon, Color iconBgColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: () => _mostrarPickerTipo(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getNombreTipo(_tipoProveedorSeleccionado),
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile(IconData icon, Color iconBgColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: IntlPhoneField(
              controller: _telefonoController,
              initialCountryCode: _obtenerCodigoPaisInicial(
                _telefonoController.text,
              ),
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
                counterText: '',
              ),
              autovalidateMode: AutovalidateMode.disabled,
              onChanged: (phone) => _telefonoCompleto = phone.completeNumber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(
    IconData icon,
    Color iconBgColor,
    String label,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: () => _seleccionarHora(controller),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.text.isNotEmpty
                        ? _formatearHora(controller.text)
                        : label,
                    style: TextStyle(
                      color: controller.text.isNotEmpty
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(
                              context,
                            ),
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.clock,
                    size: 16,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesEdicion() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
            onPressed: _guardando ? null : _cancelarEdicion,
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: AppColorsPrimary.main,
            borderRadius: BorderRadius.circular(10),
            onPressed: _guardando ? null : _guardarCambios,
            child: _guardando
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACCIONES
  // ---------------------------------------------------------------------------

  Future<void> _seleccionarLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _logoSeleccionado = File(picked.path));
      }
    } catch (_) {
      _mostrarSnackBar('Error al seleccionar imagen', esError: true);
    }
  }

  Future<void> _seleccionarHora(TextEditingController controller) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) {
      controller.text =
          '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';
      setState(() {});
    }
  }

  void _mostrarPickerTipo() {
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
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Listo'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(
                    () => _tipoProveedorSeleccionado =
                        ApiConfig.tiposProveedor[index],
                  );
                },
                children: ApiConfig.tiposProveedor
                    .map((tipo) => Center(child: Text(_getNombreTipo(tipo))))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelarEdicion() {
    setState(() {
      _editando = false;
      _logoSeleccionado = null;
      _error = null;
    });
    _inicializarFormulario();
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

      final datosPerfil = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'ruc': _rucController.text.trim(),
        'tipo_proveedor': _tipoProveedorSeleccionado,
        'descripcion': _descripcionController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
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

      final partes = _nombreCompletoController.text.trim().split(' ');
      final firstName = partes.isNotEmpty ? partes[0] : '';
      final lastName = partes.length > 1 ? partes.sublist(1).join(' ') : '';

      final successContacto = await controller.actualizarDatosContacto(
        email: _emailController.text.trim(),
        firstName: firstName,
        lastName: lastName,
        telefono: telefonoFinal,
      );

      if (!successContacto) {
        setState(() {
          _error = controller.error;
          _guardando = false;
        });
        return;
      }

      if (_logoSeleccionado != null) {
        await controller.subirLogo(_logoSeleccionado!);
      }

      setState(() {
        _editando = false;
        _logoSeleccionado = null;
        _guardando = false;
      });

      _mostrarSnackBar('Cambios guardados');
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
  }

  bool _validar() {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarSnackBar('El nombre del negocio es requerido', esError: true);
      return false;
    }
    if (_rucController.text.trim().length < 10) {
      _mostrarSnackBar(
        'El RUC debe tener al menos 10 caracteres',
        esError: true,
      );
      return false;
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      _mostrarSnackBar('Email inválido', esError: true);
      return false;
    }
    return true;
  }

  void _mostrarSnackBar(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError
            ? CupertinoColors.systemRed
            : CupertinoColors.activeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final controller = context.read<SupplierController>();
      await SessionCleanup.clearProviders(context);
      final success = await controller.cerrarSesion();

      if (success && mounted) {
        await Rutas.irAYLimpiar(context, Rutas.login);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES
  // ---------------------------------------------------------------------------

  String _getNombreTipo(String? tipo) {
    switch (tipo) {
      case 'restaurante':
        return 'Restaurante';
      case 'farmacia':
        return 'Farmacia';
      case 'supermercado':
        return 'Supermercado';
      case 'tienda':
        return 'Tienda';
      case 'otro':
        return 'Otro';
      default:
        return 'Seleccionar';
    }
  }

  String _obtenerCodigoPaisInicial(String numero) {
    final valor = numero.trim();
    if (valor.startsWith('+593')) return 'EC';
    if (valor.startsWith('+1')) return 'US';
    if (valor.startsWith('+52')) return 'MX';
    if (valor.startsWith('+57')) return 'CO';
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
}
