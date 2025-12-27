// lib/screens/supplier/screens/pantalla_configuracion_proveedor.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/supplier/supplier_controller.dart';
import '../../../theme/app_colors_primary.dart';

/// Pantalla de configuración del proveedor - Estilo iOS nativo
class PantallaConfiguracionProveedor extends StatefulWidget {
  const PantallaConfiguracionProveedor({super.key});

  @override
  State<PantallaConfiguracionProveedor> createState() =>
      _PantallaConfiguracionProveedorState();
}

class _PantallaConfiguracionProveedorState
    extends State<PantallaConfiguracionProveedor> {
  // Configuraciones
  bool _notificacionesPedidos = true;
  bool _notificacionesPromos = false;
  bool _sonidoNotificaciones = true;
  bool _modoOscuro = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Configuración'),
        backgroundColor: CupertinoColors.systemBackground
            .resolveFrom(context)
            .withValues(alpha: 0.9),
        border: null,
      ),
      child: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            color: CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
            // Información de cuenta
            _buildSectionHeader('CUENTA'),
            Consumer<SupplierController>(
              builder: (context, controller, child) {
                return _buildSettingsCard([
                  _buildInfoTile(
                    icon: CupertinoIcons.building_2_fill,
                    iconBgColor: const Color(0xFF007AFF),
                    label: 'Negocio',
                    value: controller.nombreNegocio.isNotEmpty
                        ? controller.nombreNegocio
                        : '---',
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: CupertinoIcons.mail_solid,
                    iconBgColor: const Color(0xFF5AC8FA),
                    label: 'Email',
                    value: controller.email.isNotEmpty
                        ? controller.email
                        : '---',
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: controller.verificado
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.clock_fill,
                    iconBgColor: controller.verificado
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.activeOrange,
                    label: 'Estado',
                    value: controller.verificado ? 'Verificado' : 'Pendiente',
                    valueColor: controller.verificado
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.activeOrange,
                  ),
                ]);
              },
            ),
            const SizedBox(height: 24),

            // Notificaciones
            _buildSectionHeader('NOTIFICACIONES'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: CupertinoIcons.bell_fill,
                iconBgColor: const Color(0xFFFF3B30),
                title: 'Notificaciones de pedidos',
                subtitle: 'Recibir alertas de nuevos pedidos',
                value: _notificacionesPedidos,
                onChanged: (v) => setState(() => _notificacionesPedidos = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: CupertinoIcons.tag_fill,
                iconBgColor: const Color(0xFFFF9500),
                title: 'Promociones y novedades',
                subtitle: 'Recibir información de ofertas',
                value: _notificacionesPromos,
                onChanged: (v) => setState(() => _notificacionesPromos = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: CupertinoIcons.speaker_2_fill,
                iconBgColor: const Color(0xFF5856D6),
                title: 'Sonido de notificaciones',
                subtitle: 'Reproducir sonido al recibir pedidos',
                value: _sonidoNotificaciones,
                onChanged: (v) => setState(() => _sonidoNotificaciones = v),
              ),
            ]),
            const SizedBox(height: 24),

            // Apariencia
            _buildSectionHeader('APARIENCIA'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: CupertinoIcons.moon_fill,
                iconBgColor: const Color(0xFF8E8E93),
                title: 'Modo oscuro',
                subtitle: 'Usar tema oscuro en la aplicación',
                value: _modoOscuro,
                onChanged: (v) => setState(() => _modoOscuro = v),
              ),
            ]),
            const SizedBox(height: 32),

            // Versión
            Center(
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemGrey.resolveFrom(context),
          letterSpacing: -0.08,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
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
            child: Icon(icon, color: Colors.white, size: 18),
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
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        valueColor ??
                        CupertinoColors.label.resolveFrom(context),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColorsPrimary.main,
          ),
        ],
      ),
    );
  }
}
