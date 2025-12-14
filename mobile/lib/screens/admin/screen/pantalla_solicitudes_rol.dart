// lib/screens/admin/pantalla_solicitudes_rol.dart

import 'package:flutter/material.dart';
import '../../../apis/admin/solicitudes_api.dart';
import '../../../models/solicitud_cambio_rol.dart';

/// Pantalla completa para gestion de Solicitudes de Cambio de Rol
/// Similar al componente de React pero adaptado a Flutter
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
  late TabController _tabController;

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

  // Contadores
  int _totalPendientes = 0;
  int _totalAceptadas = 0;
  int _totalRechazadas = 0;
  int _totalRevertidas = 0;

  // Solicitud seleccionada para mostrar detalle
  SolicitudCambioRol? _solicitudSeleccionada;

  // ============================================================================
  // COLORES
  // ============================================================================
  static const Color _morado = Color(0xFF9C27B0);
  static const Color _verde = Color(0xFF4CAF50);
  static const Color _azul = Color(0xFF2196F3);
  static const Color _naranja = Color(0xFFFF9800);
  static const Color _rojo = Color(0xFFF44336);
  static const Color _gris = Color(0xFF757575);
  static const Color _grisClaro = Color(0xFFE0E0E0);

  // ============================================================================
  // CICLO DE VIDA
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _solicitudSeleccionada = null;
      });
    }
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
          _pendientes = pendientesData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];
          _totalPendientes = responses[0]['count'] ?? _pendientes.length;

          // Aceptadas
          final aceptadasData = responses[1]['results'] as List<dynamic>?;
          _aceptadas = aceptadasData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];
          _totalAceptadas = responses[1]['count'] ?? _aceptadas.length;

          // Rechazadas
          final rechazadasData = responses[2]['results'] as List<dynamic>?;
          _rechazadas = rechazadasData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];
          _totalRechazadas = responses[2]['count'] ?? _rechazadas.length;

          // Revertidas
          final revertidasData = responses[3]['results'] as List<dynamic>?;
          _revertidas = revertidasData
                  ?.map((json) => SolicitudCambioRol.fromJson(json))
                  .toList() ??
              [];
          _totalRevertidas = responses[3]['count'] ?? _revertidas.length;

          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar solicitudes: $e';
          _loading = false;
        });
      }
    }
  }

  // ============================================================================
  // ACCIONES
  // ============================================================================

  Future<void> _aceptarSolicitud(SolicitudCambioRol solicitud) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Solicitud'),
        content: Text(
          'Estas seguro de aceptar la solicitud de ${solicitud.usuarioEmail} para ser ${solicitud.rolTexto}?\n\nEsto creara automaticamente su perfil de ${solicitud.rolTexto}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _verde),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmar == true) {
      try {
        await _solicitudesApi.aceptarSolicitud(
          solicitud.id,
          motivoRespuesta: 'Solicitud aprobada por administrador',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud aceptada exitosamente'),
              backgroundColor: _verde,
            ),
          );
          setState(() {
            _solicitudSeleccionada = null;
          });
          _cargarSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: _rojo,
            ),
          );
        }
      }
    }
  }

  Future<void> _rechazarSolicitud(SolicitudCambioRol solicitud) async {
    final motivoController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por que rechazas la solicitud de ${solicitud.usuarioEmail}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo *',
                border: OutlineInputBorder(),
                hintText: 'Describe el motivo...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmar == true) {
      final motivo = motivoController.text.trim();
      if (motivo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes especificar un motivo'),
            backgroundColor: _rojo,
          ),
        );
        return;
      }

      try {
        await _solicitudesApi.rechazarSolicitud(
          solicitud.id,
          motivoRespuesta: motivo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud rechazada'),
              backgroundColor: _naranja,
            ),
          );
          setState(() {
            _solicitudSeleccionada = null;
          });
          _cargarSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: _rojo,
            ),
          );
        }
      }
    }
  }

  Future<void> _revertirSolicitud(SolicitudCambioRol solicitud) async {
    final motivoController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revertir Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por que deseas revertir la solicitud aceptada de ${solicitud.usuarioEmail}?',
            ),
            const SizedBox(height: 8),
            const Text(
              'Esto desactivara su perfil de proveedor/repartidor.',
              style: TextStyle(fontSize: 12, color: _gris),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de la reversion *',
                border: OutlineInputBorder(),
                hintText: 'Describe el motivo...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmar == true) {
      final motivo = motivoController.text.trim();
      if (motivo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes especificar un motivo'),
            backgroundColor: _rojo,
          ),
        );
        return;
      }

      try {
        await _solicitudesApi.revertirSolicitud(
          solicitud.id,
          motivoReversion: motivo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud revertida'),
              backgroundColor: _naranja,
            ),
          );
          setState(() {
            _solicitudSeleccionada = null;
          });
          _cargarSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: _rojo,
            ),
          );
        }
      }
    }
  }

  Future<void> _eliminarSolicitud(SolicitudCambioRol solicitud) async {
    final confirmacionController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta accion NO se puede deshacer.',
              style: TextStyle(fontWeight: FontWeight.bold, color: _rojo),
            ),
            const SizedBox(height: 8),
            Text(
              'Vas a eliminar permanentemente la solicitud de ${solicitud.usuarioEmail}.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmacionController,
              decoration: const InputDecoration(
                labelText: 'Escribe "ELIMINAR" para confirmar',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmar == true) {
      if (confirmacionController.text.trim() != 'ELIMINAR') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes escribir "ELIMINAR" para confirmar'),
            backgroundColor: _rojo,
          ),
        );
        return;
      }

      try {
        await _solicitudesApi.eliminarSolicitud(solicitud.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud eliminada'),
              backgroundColor: _gris,
            ),
          );
          setState(() {
            _solicitudSeleccionada = null;
          });
          _cargarSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: _rojo,
            ),
          );
        }
      }
    }
  }

  // ============================================================================
  // UI - BUILD PRINCIPAL
  // ============================================================================

  Future<void> _abrirDetalleSolicitud(SolicitudCambioRol solicitud) async {
    setState(() {
      _solicitudSeleccionada = solicitud;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (modalContext) => Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            foregroundColor: _gris,
            elevation: 1,
            title: const Text(
              'Detalle de solicitud',
              style: TextStyle(color: _gris),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(modalContext).pop(),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              _buildDetalleHeader(solicitud),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildDetalleContenido(solicitud),
                ),
              ),
              _buildDetalleAcciones(modalContext, solicitud),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _solicitudSeleccionada = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _loading ? _buildCargando() : _error != null ? _buildError() : _buildContenido(),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Solicitudes de Cambio de Rol'),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_morado, Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _cargarSolicitudes,
          tooltip: 'Actualizar',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        isScrollable: false,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: [
          Tab(
            child: _buildTabConBadge('Pendientes', _totalPendientes, _naranja),
          ),
          Tab(
            child: _buildTabConBadge('Aceptadas', _totalAceptadas, _verde),
          ),
          Tab(
            child: _buildTabConBadge('Rechazadas', _totalRechazadas, _rojo),
          ),
          Tab(
            child: _buildTabConBadge('Revertidas', _totalRevertidas, _gris),
          ),
        ],
      ),
    );
  }

  Widget _buildTabConBadge(String label, int count, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // CONTENIDO PRINCIPAL
  // ============================================================================

  Widget _buildContenido() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildListaSolicitudes(_pendientes, 'pendientes'),
        _buildListaSolicitudes(_aceptadas, 'aceptadas'),
        _buildListaSolicitudes(_rechazadas, 'rechazadas'),
        _buildListaSolicitudes(_revertidas, 'revertidas'),
      ],
    );
  }

  Widget _buildListaSolicitudes(List<SolicitudCambioRol> solicitudes, String tipo) {
    if (solicitudes.isEmpty) {
      return _buildListaVacia(tipo);
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: solicitudes.length,
        itemBuilder: (context, index) {
          final solicitud = solicitudes[index];
          final esSeleccionada = _solicitudSeleccionada?.id == solicitud.id;

          return _buildTarjetaSolicitud(solicitud, esSeleccionada);
        },
      ),
    );
  }

  Widget _buildListaVacia(String tipo) {
    String mensaje;
    IconData icono;

    switch (tipo) {
      case 'pendientes':
        mensaje = 'No hay solicitudes pendientes';
        icono = Icons.inbox;
        break;
      case 'aceptadas':
        mensaje = 'No hay solicitudes aceptadas';
        icono = Icons.check_circle_outline;
        break;
      case 'rechazadas':
        mensaje = 'No hay solicitudes rechazadas';
        icono = Icons.cancel_outlined;
        break;
      case 'revertidas':
        mensaje = 'No hay solicitudes revertidas';
        icono = Icons.undo;
        break;
      default:
        mensaje = 'No hay solicitudes';
        icono = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: _grisClaro),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(
              fontSize: 16,
              color: _gris,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE SOLICITUD
  // ============================================================================

  Widget _buildTarjetaSolicitud(SolicitudCambioRol solicitud, bool esSeleccionada) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: esSeleccionada ? 4 : 1,
      color: esSeleccionada ? _morado.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esSeleccionada
            ? const BorderSide(color: _morado, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _abrirDetalleSolicitud(solicitud),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: solicitud.esProveedor ? _verde : _azul,
                    child: Icon(
                      solicitud.iconoRol,
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
                          solicitud.usuarioNombre ?? solicitud.usuarioEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          solicitud.usuarioEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _gris,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: solicitud.colorEstado.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: solicitud.colorEstado,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      solicitud.estadoTexto,
                      style: TextStyle(
                        color: solicitud.colorEstado,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Info
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(solicitud.iconoRol, size: 16, color: _gris),
                  Text(
                    solicitud.rolTexto,
                    style: const TextStyle(fontSize: 13, color: _gris),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time, size: 16, color: _gris),
                  Text(
                    solicitud.fechaCreacionFormateada,
                    style: const TextStyle(fontSize: 13, color: _gris),
                  ),
                ],
              ),

              // Datos especificos
              if (solicitud.esProveedor && solicitud.nombreComercial != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: _gris),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        solicitud.nombreComercial!,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (solicitud.esRepartidor && solicitud.cedulaIdentidad != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.badge, size: 16, color: _gris),
                    const SizedBox(width: 4),
                    Text(
                      'CI: ${solicitud.cedulaIdentidad}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // PANEL DE DETALLE
  // ============================================================================

  Widget _buildDetalleHeader(SolicitudCambioRol solicitud) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _grisClaro.withValues(alpha: 0.3),
        border: const Border(
          bottom: BorderSide(color: _grisClaro, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: solicitud.esProveedor ? _verde : _azul,
            child: Icon(
              solicitud.iconoRol,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud de ${solicitud.rolTexto}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  solicitud.usuarioEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _gris,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleContenido(SolicitudCambioRol solicitud) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetalleItem('Usuario', solicitud.usuarioNombre ?? 'Sin nombre'),
        _buildDetalleItem('Email', solicitud.usuarioEmail),
        _buildDetalleItem('Rol Solicitado', solicitud.rolTexto),
        _buildDetalleItem('Fecha', solicitud.fechaCreacionFormateada),
        _buildDetalleItem('Estado', solicitud.estadoTexto),

        const SizedBox(height: 16),
        const Text(
          'Motivo:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _gris,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _grisClaro.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            solicitud.motivo,
            style: const TextStyle(fontSize: 14),
          ),
        ),

        // Datos especificos del rol
        if (solicitud.esProveedor) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Datos del Negocio:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (solicitud.nombreComercial != null)
            _buildDetalleItem('Nombre Comercial', solicitud.nombreComercial!),
          if (solicitud.ruc != null) _buildDetalleItem('RUC', solicitud.ruc!),
          if (solicitud.tipoNegocio != null)
            _buildDetalleItem('Tipo de Negocio', solicitud.tipoNegocioTexto!),
          if (solicitud.horarioApertura != null && solicitud.horarioCierre != null)
            _buildDetalleItem(
              'Horario',
              '${solicitud.horarioApertura} - ${solicitud.horarioCierre}',
            ),
        ],

        if (solicitud.esRepartidor) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Datos del Repartidor:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (solicitud.cedulaIdentidad != null)
            _buildDetalleItem('Cedula', solicitud.cedulaIdentidad!),
          if (solicitud.tipoVehiculo != null)
            _buildDetalleItem('Vehiculo', solicitud.tipoVehiculoTexto!),
          if (solicitud.zonaCobertura != null)
            _buildDetalleItem('Zona de Cobertura', solicitud.zonaCobertura!),
        ],

        // Informacion de respuesta (si fue procesada)
        if (solicitud.motivoRespuesta != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Respuesta del Administrador:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (solicitud.adminEmail != null)
            _buildDetalleItem('Procesado por', solicitud.adminEmail!),
          if (solicitud.fechaRespuestaFormateada != null)
            _buildDetalleItem('Fecha', solicitud.fechaRespuestaFormateada!),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: solicitud.colorEstado.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: solicitud.colorEstado,
                width: 1,
              ),
            ),
            child: Text(
              solicitud.motivoRespuesta!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetalleAcciones(BuildContext modalContext, SolicitudCambioRol solicitud) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: _grisClaro, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildBotonesAccion(
        solicitud,
        onActionCompleted: () {
          if (Navigator.of(modalContext).canPop()) {
            Navigator.of(modalContext).pop();
          }
        },
      ),
    );
  }

  Widget _buildDetalleItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _gris,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(
    SolicitudCambioRol solicitud, {
    VoidCallback? onActionCompleted,
  }) {
    if (solicitud.estaPendiente) {
      // Solicitud pendiente: Aceptar / Rechazar
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await _rechazarSolicitud(solicitud);
                onActionCompleted?.call();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _rojo,
                side: const BorderSide(color: _rojo),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _aceptarSolicitud(solicitud);
                onActionCompleted?.call();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else if (solicitud.fueAceptada) {
      // Solicitud aceptada: Revertir / Eliminar
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await _eliminarSolicitud(solicitud);
                onActionCompleted?.call();
              },
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gris,
                side: const BorderSide(color: _gris),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _revertirSolicitud(solicitud);
                onActionCompleted?.call();
              },
              icon: const Icon(Icons.undo),
              label: const Text('Revertir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _naranja,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else {
      // Solicitud rechazada o revertida: Solo eliminar
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await _eliminarSolicitud(solicitud);
            onActionCompleted?.call();
          },
          icon: const Icon(Icons.delete),
          label: const Text('Eliminar Registro'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _rojo,
            side: const BorderSide(color: _rojo),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
  }

  // ============================================================================
  // ESTADOS DE CARGA Y ERROR
  // ============================================================================

  Widget _buildCargando() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: _rojo),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error desconocido',
            style: const TextStyle(fontSize: 16, color: _rojo),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarSolicitudes,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
