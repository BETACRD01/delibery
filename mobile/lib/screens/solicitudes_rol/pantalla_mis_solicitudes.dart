// lib/screens/user/perfil/solicitudes_rol/pantalla_mis_solicitudes.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../models/solicitud_cambio_rol.dart';
import '../../../../services/solicitudes_service.dart';
import 'pantalla_solicitar_rol.dart';

/// 📋 PANTALLA DE MIS SOLICITUDES
/// Diseño: iOS Native Style
class PantallaMisSolicitudes extends StatefulWidget {
  const PantallaMisSolicitudes({super.key});

  @override
  State<PantallaMisSolicitudes> createState() => _PantallaMisSolicitudesState();
}

class _PantallaMisSolicitudesState extends State<PantallaMisSolicitudes> {
  final _solicitudesService = SolicitudesService();

  List<SolicitudCambioRol> _solicitudes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _solicitudesService.obtenerMisSolicitudes();

      // Lógica de lectura flexible (results o directo)
      List<dynamic>? listaJson;
      if (response.containsKey('results')) {
        listaJson = response['results'] as List<dynamic>;
      } else if (response is List) {
        listaJson = response as List<dynamic>;
      } else if (response.containsKey('solicitudes')) {
        listaJson = response['solicitudes'] as List<dynamic>;
      }

      if (mounted) {
        setState(() {
          _solicitudes =
              listaJson
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las solicitudes';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground
            .resolveFrom(context)
            .withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
        middle: const Text(
          'Mis Solicitudes',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _crearSolicitud,
          child: const Icon(
            CupertinoIcons.add_circled_solid,
            size: 28,
            color: CupertinoColors.activeBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: Material(type: MaterialType.transparency, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 17,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _cargarSolicitudes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 80,
              color: CupertinoColors.systemGrey3.resolveFrom(context),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aún no tienes solicitudes',
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.secondaryLabel,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Toca + para crear una nueva',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _cargarSolicitudes),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SolicitudCard(solicitud: _solicitudes[index]),
              ),
              childCount: _solicitudes.length,
            ),
          ),
        ),
      ],
    );
  }

  void _crearSolicitud() async {
    final resultado = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(builder: (_) => const PantallaSolicitarRol()),
    );
    if (resultado == true) await _cargarSolicitudes();
  }
}

/// 🎴 TARJETA DE SOLICITUD - ESTILO iOS
class _SolicitudCard extends StatelessWidget {
  final SolicitudCambioRol solicitud;

  const _SolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icono + Rol + Badge
            Row(
              children: [
                // Icono circular
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getColorForRole().withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    solicitud.iconoRol,
                    size: 24,
                    color: _getColorForRole(),
                  ),
                ),
                const SizedBox(width: 12),

                // Info del rol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.rolTexto,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: -0.4,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        solicitud.fechaCreacionFormateada,
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

                // Badge de estado
                _EstadoBadge(solicitud: solicitud),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Container(
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),

            const SizedBox(height: 12),

            // Datos principales
            _DatoFila(
              icon: CupertinoIcons.info_circle,
              label: solicitud.esProveedor ? 'Negocio' : 'Vehículo',
              value: solicitud.esProveedor
                  ? (solicitud.nombreComercial ?? 'N/A')
                  : (solicitud.tipoVehiculoTexto ?? 'N/A'),
            ),

            // Respuesta del Admin
            if (solicitud.motivoRespuesta != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: solicitud.colorEstado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: solicitud.colorEstado.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_text,
                          size: 16,
                          color: solicitud.colorEstado,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Respuesta del Administrador',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: solicitud.colorEstado,
                            letterSpacing: -0.08,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      solicitud.motivoRespuesta!,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.label.resolveFrom(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForRole() {
    return solicitud.esProveedor
        ? CupertinoColors.systemBlue
        : CupertinoColors.systemGreen;
  }
}

/// Badge de estado estilo iOS
class _EstadoBadge extends StatelessWidget {
  final SolicitudCambioRol solicitud;

  const _EstadoBadge({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solicitud.colorEstado.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        solicitud.estadoTexto,
        style: TextStyle(
          color: solicitud.colorEstado,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: -0.08,
        ),
      ),
    );
  }
}

/// Fila de dato con icono
class _DatoFila extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DatoFila({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            letterSpacing: -0.2,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: CupertinoColors.label,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
