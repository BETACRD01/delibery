import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../apis/admin/solicitudes_api.dart';
import '../../../models/solicitud_cambio_rol.dart';
import '../dashboard/widgets/detalle_solicitud_modal.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../theme/app_colors_primary.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaSolicitudesRol extends StatefulWidget {
  const PantallaSolicitudesRol({super.key});

  @override
  State<PantallaSolicitudesRol> createState() => _PantallaSolicitudesRolState();
}

class _PantallaSolicitudesRolState extends State<PantallaSolicitudesRol>
    with SingleTickerProviderStateMixin {
  // ============================================================================
  // SERVICIOS Y CONTROLADORES
  // ============================================================================
  final _solicitudesApi = SolicitudesAdminAPI();
  int _currentIdx = 0; // Using index for sliding control

  // ============================================================================
  // ESTADO
  // ============================================================================
  bool _loading = true;
  String? _error;

  // Solicitudes por estado
  List<SolicitudCambioRol> _pendientes = [];
  List<SolicitudCambioRol> _aceptadas = [];
  List<SolicitudCambioRol> _rechazadas = [];
  List<SolicitudCambioRol> _revertidas = [];

  // ============================================================================
  // COLORES
  // ============================================================================
  // Using AppColorsPrimary.main for corporate identity

  // ============================================================================
  // CICLO DE VIDA
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  // ============================================================================
  // METODOS DE DATOS
  // ============================================================================

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Cargar todas las solicitudes en paralelo
      final responses = await Future.wait([
        _solicitudesApi.listarSolicitudes(estado: 'PENDIENTE', pageSize: 100),
        _solicitudesApi.listarSolicitudes(estado: 'ACEPTADA', pageSize: 100),
        _solicitudesApi.listarSolicitudes(estado: 'RECHAZADA', pageSize: 100),
        _solicitudesApi.listarSolicitudes(estado: 'REVERTIDA', pageSize: 100),
      ]);

      if (mounted) {
        setState(() {
          // Pendientes
          final pendientesData = responses[0]['results'] as List<dynamic>?;
          _pendientes =
              pendientesData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];

          // Aceptadas
          final aceptadasData = responses[1]['results'] as List<dynamic>?;
          _aceptadas =
              aceptadasData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];

          // Rechazadas
          final rechazadasData = responses[2]['results'] as List<dynamic>?;
          _rechazadas =
              rechazadasData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];

          // Revertidas
          final revertidasData = responses[3]['results'] as List<dynamic>?;
          _revertidas =
              revertidasData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar solicitudes';
          _loading = false;
        });
      }
    }
  }

  // ============================================================================
  // ACCIONES (Simplificadas para usar el modal existente)
  // ============================================================================

  Future<void> _abrirDetalleSolicitud(SolicitudCambioRol solicitud) async {
    await DetalleSolicitudModal.mostrar(
      context: context,
      solicitud: solicitud,
      onAceptar: (motivo) async {
        await _procesarAccion(
          () => _solicitudesApi.aceptarSolicitud(
            solicitud.id,
            motivoRespuesta: motivo,
          ),
          'Solicitud aceptada',
        );
      },
      onRechazar: (motivo) async {
        await _procesarAccion(
          () => _solicitudesApi.rechazarSolicitud(
            solicitud.id,
            motivoRespuesta: motivo,
          ),
          'Solicitud rechazada',
        );
      },
      onRevertir: (motivo) async {
        await _procesarAccion(
          () => _solicitudesApi.revertirSolicitud(
            solicitud.id,
            motivoReversion: motivo,
          ),
          'Solicitud revertida',
        );
      },
      onEliminar: () async {
        await _procesarAccion(
          () => _solicitudesApi.eliminarSolicitud(solicitud.id),
          'Solicitud eliminada',
        );
      },
    );
  }

  Future<void> _procesarAccion(
    Future<void> Function() accion,
    String exitoMsg,
  ) async {
    try {
      await accion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exitoMsg),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: AppColorsPrimary.main,
          ),
        );
        // ignore: unawaited_futures
        _cargarSolicitudes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // UI - BUILD PRINCIPAL
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Solicitudes de Rol'),
        backgroundColor: bgColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColorsPrimary.main),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColorsPrimary.main),
            onPressed: _cargarSolicitudes,
          ),
        ],
        iconTheme: IconThemeData(color: AppColorsPrimary.main),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: bgColor,
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _currentIdx,
              children: const {
                0: Text('Pendientes'),
                1: Text('Aceptadas'),
                2: Text('Otras'),
              },
              onValueChanged: (val) {
                if (val != null) {
                  setState(() => _currentIdx = val);
                }
              },
              thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
              backgroundColor: isDark
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFF767680).withValues(alpha: 0.12),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                ? _buildError(isDark)
                : _buildCurrentList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentList(bool isDark) {
    if (_currentIdx == 0) {
      return _buildListaSolicitudes(_pendientes, 'pendientes', isDark);
    }
    if (_currentIdx == 1) {
      return _buildListaSolicitudes(_aceptadas, 'aceptadas', isDark);
    }

    // Combine rejected and reverted for 'Otras' tab for cleaner UI
    final otras = [..._rechazadas, ..._revertidas];
    otras.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return _buildListaSolicitudes(otras, 'otras', isDark);
  }

  Widget _buildListaSolicitudes(
    List<SolicitudCambioRol> solicitudes,
    String tipo,
    bool isDark,
  ) {
    if (solicitudes.isEmpty) {
      return _buildListaVacia(tipo, isDark);
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: solicitudes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final solicitud = solicitudes[index];
          return _buildTarjetaSolicitudiOS(solicitud, isDark);
        },
      ),
    );
  }

  Widget _buildListaVacia(String tipo, bool isDark) {
    String mensaje = 'No hay solicitudes';
    if (tipo == 'pendientes') {
      mensaje = 'No hay solicitudes pendientes';
    } else if (tipo == 'aceptadas') {
      mensaje = 'No hay solicitudes aceptadas';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaSolicitudiOS(SolicitudCambioRol solicitud, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        // No shadow or very subtle for iOS style
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirDetalleSolicitud(solicitud),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        (solicitud.esProveedor
                                ? DashboardColors.verde
                                : DashboardColors.azul)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      solicitud.iconoRol,
                      color: solicitud.esProveedor
                          ? DashboardColors.verde
                          : DashboardColors.azul,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.usuarioNombre ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solicitud.usuarioEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              solicitud.rolSolicitado == 'PROVEEDOR'
                                  ? 'Proveedor'
                                  : 'Repartidor',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            solicitud.fechaCreacionFormateada,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Indicator or Chevron
                if (solicitud.estado == 'PENDIENTE')
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    CupertinoIcons.chevron_forward,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error desconocido',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _cargarSolicitudes,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
