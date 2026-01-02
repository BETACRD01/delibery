// lib/screens/delivery/ganancias/pantalla_ganancias_repartidor.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/entrega_historial.dart';
import 'package:mobile/services/repartidor/repartidor_service.dart';
import 'package:mobile/screens/delivery/historial/pantalla_detalle_entrega.dart';

/// Pantalla de ganancias vinculada al backend y alineada al diseño tipo iOS.
class PantallaGananciasRepartidor extends StatefulWidget {
  const PantallaGananciasRepartidor({super.key});

  @override
  State<PantallaGananciasRepartidor> createState() =>
      _PantallaGananciasRepartidorState();
}

class _PantallaGananciasRepartidorState
    extends State<PantallaGananciasRepartidor> {
  static const Color _accent = Color(0xFF0CB7F2); // Celeste corporativo
  static const Color _success = Color(0xFF34C759);

  // Dynamic Colors
  Color get _surface =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);
  Color get _cardBg =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
  Color get _cardBorder => CupertinoColors.separator.resolveFrom(context);
  Color get _textPrimary => CupertinoColors.label.resolveFrom(context);
  Color get _textSecondary =>
      CupertinoColors.secondaryLabel.resolveFrom(context);

  final RepartidorService _service = RepartidorService();
  final DateFormat _fechaFormat = DateFormat('dd/MM/yyyy HH:mm');
  List<EntregaHistorial> _entregas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarGanancias();
  }

  Future<void> _cargarGanancias() async {
    setState(() {
      if (_entregas.isEmpty) {
        _loading = true; // Solo mostrar loading inicial si no hay data
      }
      _error = null;
    });

    try {
      final response = await _service.obtenerHistorialEntregas();
      final parsed = HistorialEntregasResponse.fromJson(response);
      if (!mounted) return;
      setState(() {
        _entregas = parsed.entregas.reversed.toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  double _calcularGanancia(EntregaHistorial entrega) {
    if (entrega.tipo == 'directo') {
      return entrega.montoTotal;
    }
    return entrega.comisionRepartidor;
  }

  double get _gananciaTotal =>
      _entregas.fold(0.0, (sum, item) => sum + _calcularGanancia(item));

  double get _gananciaSemana {
    final ahora = DateTime.now();
    final sieteDiasAntes = ahora.subtract(const Duration(days: 7));
    return _entregas
        .where(
          (entrega) => _parseFecha(
            entrega.fechaEntregado,
          ).isAfter(sieteDiasAntes.subtract(const Duration(seconds: 1))),
        )
        .fold(0.0, (sum, item) => sum + _calcularGanancia(item));
  }

  double get _gananciaHoy {
    final ahora = DateTime.now();
    return _entregas
        .where((entrega) {
          final fecha = _parseFecha(entrega.fechaEntregado);
          return fecha.year == ahora.year &&
              fecha.month == ahora.month &&
              fecha.day == ahora.day;
        })
        .fold(0.0, (sum, item) => sum + _calcularGanancia(item));
  }

  DateTime _parseFecha(String valor) {
    try {
      return DateTime.parse(valor);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: _surface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Mis ganancias'),
              backgroundColor: _surface,
              border: null,
            ),
            CupertinoSliverRefreshControl(onRefresh: _cargarGanancias),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading && _entregas.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else if (_error != null)
                    _buildErrorState()
                  else ...[
                    _buildResumen(),
                    const SizedBox(height: 24),
                    Text(
                      'HISTORIAL RECIENTE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_entregas.isEmpty)
                      _buildEmptyState()
                    else
                      _buildListadoEntregas(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ganancia Total',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_gananciaTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: _cardBorder),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildIndicador('Hoy', _gananciaHoy, _accent)),
              Container(width: 1, height: 40, color: _cardBorder),
              Expanded(
                child: _buildIndicador('Semana', _gananciaSemana, _success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicador(String label, double monto, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildListadoEntregas() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(_entregas.length, (index) {
          final entrega = _entregas[index];
          final isLast = index == _entregas.length - 1;
          return Column(
            children: [
              _buildEntregaItem(entrega),
              if (!isLast) Divider(height: 1, indent: 60, color: _cardBorder),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEntregaItem(EntregaHistorial entrega) {
    final fecha = _fechaFormat.format(_parseFecha(entrega.fechaEntregado));

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => PantallaDetalleEntrega(entrega: entrega),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                entrega.tieneComprobante
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.cube_box_fill,
                color: _accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${entrega.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fecha,
                    style: TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_calcularGanancia(entrega).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver más',
                      style: TextStyle(
                        fontSize: 12,
                        color: _accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: _accent,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            color: _accent,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar ganancias',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            color: _accent,
            borderRadius: BorderRadius.circular(30),
            onPressed: _cargarGanancias,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.money_dollar_circle,
            size: 48,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay ganancias',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus ganancias aparecerán aquí en cuanto completes tu primer pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
