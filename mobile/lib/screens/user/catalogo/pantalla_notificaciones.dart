// lib/screens/user/notificaciones/pantalla_notificaciones.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart';
import '../../../models/notificacion_model.dart';

/// Pantalla de notificaciones del usuario
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<NotificacionModel> _notificaciones = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarNotificaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // TODO: Llamar al servicio real
      // _notificaciones = await _notificacionesService.obtenerNotificaciones();
      
      // MOCK - Datos de prueba
      await Future.delayed(const Duration(milliseconds: 800));
      _notificaciones = _generarNotificacionesMock();
      
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar notificaciones: $e';
        _loading = false;
      });
    }
  }

  List<NotificacionModel> _generarNotificacionesMock() {
    return [
      NotificacionModel(
        id: '1',
        titulo: '¡Pedido en camino! 🚚',
        mensaje: 'Tu pedido #1234 está siendo entregado. Llegará en 15 minutos.',
        tipo: 'pedido',
        fecha: DateTime.now().subtract(const Duration(minutes: 5)),
        leida: false,
        metadata: {'pedido_id': '1234'},
      ),
      NotificacionModel(
        id: '2',
        titulo: '🎉 Nueva promoción: 40% OFF',
        mensaje: 'Happy Hour en bebidas. Aprovecha ahora.',
        tipo: 'promocion',
        fecha: DateTime.now().subtract(const Duration(hours: 2)),
        leida: false,
      ),
      NotificacionModel(
        id: '3',
        titulo: 'Pago confirmado ✅',
        mensaje: 'Tu pago de \$18.99 fue procesado exitosamente.',
        tipo: 'pago',
        fecha: DateTime.now().subtract(const Duration(hours: 5)),
        leida: true,
        metadata: {'monto': 18.99},
      ),
      NotificacionModel(
        id: '4',
        titulo: 'Pedido entregado',
        mensaje: 'Tu pedido #1230 fue entregado. ¡Buen provecho!',
        tipo: 'pedido',
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        leida: true,
      ),
      NotificacionModel(
        id: '5',
        titulo: 'Sistema actualizado',
        mensaje: 'Nueva versión disponible con mejoras de rendimiento.',
        tipo: 'sistema',
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        leida: true,
      ),
    ];
  }

  List<NotificacionModel> get _noLeidas {
    return _notificaciones.where((n) => !n.leida).toList();
  }

  List<NotificacionModel> get _todas {
    return _notificaciones;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Notificaciones'),
        elevation: 0,
        actions: [
          if (_noLeidas.isNotEmpty)
            TextButton(
              onPressed: _marcarTodasComoLeidas,
              child: const Text(
                'Marcar todas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'No leídas (${_noLeidas.length})',
            ),
            const Tab(
              text: 'Todas',
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: JPColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarNotificaciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListaNotificaciones(_noLeidas, esNoLeidas: true),
        _buildListaNotificaciones(_todas, esNoLeidas: false),
      ],
    );
  }

  Widget _buildListaNotificaciones(
    List<NotificacionModel> notificaciones, {
    required bool esNoLeidas,
  }) {
    if (notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              esNoLeidas
                  ? 'No tienes notificaciones nuevas'
                  : 'No hay notificaciones',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notificaciones.length,
        itemBuilder: (context, index) {
          return _NotificacionCard(
            notificacion: notificaciones[index],
            onTap: () => _abrirNotificacion(notificaciones[index]),
            onMarcarLeida: () => _marcarComoLeida(notificaciones[index]),
            onEliminar: () => _eliminarNotificacion(notificaciones[index]),
          );
        },
      ),
    );
  }

  void _abrirNotificacion(NotificacionModel notificacion) {
    // Marcar como leída
    if (!notificacion.leida) {
      _marcarComoLeida(notificacion);
    }

    // Navegar según el tipo
    switch (notificacion.tipo) {
      case 'pedido':
        // TODO: Navegar a detalle de pedido
        debugPrint('Abrir pedido: ${notificacion.metadata?['pedido_id']}');
        break;
      case 'promocion':
        // TODO: Navegar a promociones
        debugPrint('Abrir promociones');
        break;
      case 'pago':
        // TODO: Navegar a historial de pagos
        debugPrint('Abrir historial de pagos');
        break;
      default:
        // Mostrar detalle de la notificación
        _mostrarDetalleNotificacion(notificacion);
    }
  }

  void _mostrarDetalleNotificacion(NotificacionModel notificacion) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(notificacion.icono, color: notificacion.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notificacion.titulo,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notificacion.mensaje),
              const SizedBox(height: 12),
              Text(
                notificacion.tiempoTranscurrido,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _marcarComoLeida(NotificacionModel notificacion) {
    setState(() {
      final index = _notificaciones.indexWhere((n) => n.id == notificacion.id);
      if (index != -1) {
        _notificaciones[index] = notificacion.copyWith(leida: true);
      }
    });

    // TODO: Actualizar en el backend
    // await _notificacionesService.marcarComoLeida(notificacion.id);
  }

  void _marcarTodasComoLeidas() {
    setState(() {
      _notificaciones = _notificaciones.map((n) {
        return n.copyWith(leida: true);
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas las notificaciones marcadas como leídas'),
        duration: Duration(seconds: 2),
      ),
    );

    // TODO: Actualizar en el backend
    // await _notificacionesService.marcarTodasComoLeidas();
  }

  void _eliminarNotificacion(NotificacionModel notificacion) {
    setState(() {
      _notificaciones.removeWhere((n) => n.id == notificacion.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notificación eliminada'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            setState(() {
              _notificaciones.add(notificacion);
              _notificaciones.sort((a, b) => b.fecha.compareTo(a.fecha));
            });
          },
        ),
      ),
    );

    // TODO: Eliminar en el backend
    // await _notificacionesService.eliminarNotificacion(notificacion.id);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _NotificacionCard extends StatelessWidget {
  final NotificacionModel notificacion;
  final VoidCallback onTap;
  final VoidCallback onMarcarLeida;
  final VoidCallback onEliminar;

  const _NotificacionCard({
    required this.notificacion,
    required this.onTap,
    required this.onMarcarLeida,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notificacion.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: JPColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) => onEliminar(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notificacion.leida
                ? Colors.white
                : notificacion.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notificacion.leida
                  ? Colors.grey[200]!
                  : notificacion.color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notificacion.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificacion.icono,
                  color: notificacion.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: TextStyle(
                              fontWeight: notificacion.leida
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 15,
                              color: JPColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notificacion.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notificacion.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notificacion.tiempoTranscurrido,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}