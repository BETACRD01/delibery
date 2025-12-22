// lib/screens/ratings/pantalla_calificaciones_entidad.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/resena_model.dart';
import '../../services/calificaciones_service.dart';
import '../../widgets/ratings/rating_summary_card.dart';
import '../../widgets/ratings/star_rating_display.dart';

/// Pantalla para ver calificaciones completas de una entidad específica.
class PantallaCalificacionesEntidad extends StatefulWidget {
  final String entityType;
  final int entityId;
  final String entityNombre;

  const PantallaCalificacionesEntidad({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.entityNombre,
  });

  @override
  State<PantallaCalificacionesEntidad> createState() =>
      _PantallaCalificacionesEntidadState();
}

class _PantallaCalificacionesEntidadState
    extends State<PantallaCalificacionesEntidad> {
  final _service = CalificacionesService();
  bool _cargando = true;
  String? _error;
  List<ResenaModel> _resenas = [];
  RatingSummary? _resumen;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await _service.obtenerCalificaciones(
        entityType: widget.entityType,
        entityId: widget.entityId,
      );
      final resumen = await _service.obtenerResumen(
        entityType: widget.entityType,
        entityId: widget.entityId,
      );

      if (!mounted) return;
      setState(() {
        _resenas = respuesta.resenas;
        _resumen = resumen;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar las calificaciones.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.entityNombre)),
      child: SafeArea(
        child: _cargando
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
            ? _buildEmpty(_error!)
            : RefreshIndicator(
                onRefresh: _cargar,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: 1 + _resenas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeader();
                    final resena = _resenas[index - 1];
                    return _ResenaTile(resena: resena);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_resumen == null) return const SizedBox.shrink();

    return RatingSummaryCard(
      averageRating: _resumen!.promedioCalificacion,
      totalReviews: _resumen!.totalCalificaciones,
      ratingBreakdown: _resumen!.desglosePorEstrellas,
      onViewAllTap: null,
    );
  }

  Widget _buildEmpty(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
