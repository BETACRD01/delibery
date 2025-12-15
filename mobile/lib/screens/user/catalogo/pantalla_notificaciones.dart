// lib/screens/user/catalogo/pantalla_notificaciones.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/jp_theme.dart';
import '../../../models/notificacion_model.dart';
import '../../../providers/notificaciones_provider.dart';

/// Inbox unificado (push + internas) accesible desde la campana
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificacionesProvider>().recargar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionesProvider>(
      builder: (context, inbox, _) {
        final noLeidasCount = inbox.noLeidas.length;
        final totalCount = inbox.todas.length;

        return Scaffold(
          backgroundColor: JPColors.background,
          appBar: AppBar(
            backgroundColor: JPColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Notificaciones'),
            elevation: 0,
            actions: [
              if (noLeidasCount > 0)
                TextButton(
                  onPressed: inbox.marcarTodasComoLeidas,
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
                Tab(text: 'No leídas ($noLeidasCount)'),
                Tab(text: 'Todas ($totalCount)'),
              ],
            ),
          ),
          body: _buildBody(inbox),
        );
      },
    );
  }

  Widget _buildBody(NotificacionesProvider inbox) {
    if (inbox.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (inbox.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: JPColors.textHint),
            const SizedBox(height: 12),
            Text(
              inbox.error!,
              style: const TextStyle(color: JPColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                inbox.recargar();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListaNotificaciones(inbox.noLeidas, inbox, esNoLeidas: true),
        _buildListaNotificaciones(inbox.todas, inbox, esNoLeidas: false),
      ],
    );
  }

  Widget _buildListaNotificaciones(
    List<NotificacionModel> notificaciones,
    NotificacionesProvider inbox, {
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
            const SizedBox(height: 12),
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
      onRefresh: inbox.recargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notificaciones.length,
        itemBuilder: (context, index) {
          final notificacion = notificaciones[index];
          return _NotificacionCard(
            notificacion: notificacion,
            onTap: () => _abrirNotificacion(notificacion, inbox),
            onMarcarLeida: () => _marcarComoLeida(notificacion, inbox),
            onEliminar: () => inbox.eliminar(notificacion.id),
          );
        },
      ),
    );
  }

  void _abrirNotificacion(
    NotificacionModel notificacion,
    NotificacionesProvider inbox,
  ) {
    if (!notificacion.leida) {
      _marcarComoLeida(notificacion, inbox);
    }

    switch (notificacion.tipo) {
      case 'pedido':
      case 'promocion':
      case 'pago':
        // En este paso solo marcamos como leída; la navegación específica se puede
        // agregar usando metadata cuando esté listo.
        break;
      default:
        _mostrarDetalleNotificacion(notificacion);
    }
  }

  void _mostrarDetalleNotificacion(NotificacionModel notificacion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
      ),
    );
  }

  void _marcarComoLeida(
    NotificacionModel notificacion,
    NotificacionesProvider inbox,
  ) {
    inbox.marcarComoLeida(notificacion.id);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═════════════════════════════════════════════════════════════════════════════

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
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
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
                  : notificacion.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notificacion.leida
                  ? Colors.grey[200]!
                  : notificacion.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notificacion.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificacion.icono,
                  color: notificacion.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                    Row(
                      children: [
                        Text(
                          notificacion.tiempoTranscurrido,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (!notificacion.leida) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onMarcarLeida,
                            child: const Text(
                              'Marcar leída',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
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
