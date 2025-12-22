// lib/screens/ratings/pantalla_mis_calificaciones.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/resena_model.dart';
import '../../services/calificaciones_service.dart';
import '../../widgets/ratings/star_rating_display.dart';

/// Lista de calificaciones del usuario (recibidas/realizadas).
/// Nota: requiere wiring con el backend para proveer entityType/entityId
/// correctos; mientras tanto muestra un estado vacío si faltan datos.
class PantallaMisCalificaciones extends StatefulWidget {
  final String? entityType;
  final int? entityId;

  const PantallaMisCalificaciones({super.key, this.entityType, this.entityId});

  @override
  State<PantallaMisCalificaciones> createState() =>
      _PantallaMisCalificacionesState();
}

class _PantallaMisCalificacionesState extends State<PantallaMisCalificaciones> {
  final _service = CalificacionesService();
  final _tabs = const {'recibidas': 'Recibidas', 'realizadas': 'Realizadas'};

  String _tabSeleccionada = 'recibidas';
  bool _cargando = false;
  String? _error;
  List<ResenaModel> _resenas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.entityType == null || widget.entityId == null) {
      setState(() {
        _resenas = [];
        _error =
            'Falta configurar entityType/entityId para cargar calificaciones.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await _service.obtenerCalificaciones(
        entityType: widget.entityType!,
        entityId: widget.entityId!,
      );
      if (!mounted) return;
      setState(() => _resenas = respuesta.resenas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar las calificaciones');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Mis calificaciones'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSegmentedControl<String>(
                children: _tabs.map(
                  (key, value) => MapEntry(
                    key,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Text(value),
                    ),
                  ),
                ),
                onValueChanged: (value) =>
                    setState(() => _tabSeleccionada = value),
                groupValue: _tabSeleccionada,
              ),
            ),
            Expanded(
              child: _cargando
                  ? const Center(child: CupertinoActivityIndicator())
                  : _error != null
                  ? _buildEmptyState(_error!)
                  : _resenas.isEmpty
                  ? _buildEmptyState('Aún no tienes calificaciones.')
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _resenas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final resena = _resenas[index];
                          return _ResenaTile(resena: resena);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }
}

class _ResenaTile extends StatelessWidget {
  final ResenaModel resena;

  const _ResenaTile({required this.resena});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: CupertinoColors.systemGrey4.resolveFrom(
                  context,
                ),
                child: Text(
                  resena.iniciales,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resena.autorNombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      resena.tiempoTranscurrido,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              StarRatingDisplay(
                rating: resena.puntuacion,
                size: 14,
                showCount: false,
              ),
            ],
          ),
          if (resena.comentario != null && resena.comentario!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                resena.comentario!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
