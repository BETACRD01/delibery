// lib/screens/delivery/ganancias/pantalla_ganancias_repartidor.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/entrega_historial.dart';
import 'package:mobile/services/repartidor_service.dart';

/// Pantalla de ganancias vinculada al backend y alineada al diseño tipo iOS.
class PantallaGananciasRepartidor extends StatefulWidget {
  const PantallaGananciasRepartidor({super.key});

  @override
  State<PantallaGananciasRepartidor> createState() =>
      _PantallaGananciasRepartidorState();
}

class _PantallaGananciasRepartidorState
    extends State<PantallaGananciasRepartidor> {
  static const Color _surface = Color(0xFFF2F4F7);
  static const Color _accent = Color(0xFF0A84FF);
  static const Color _success = Color(0xFF34C759);
  static const Color _cardBorder = Color(0xFFE1E4EB);
  static const Color _shadowColor = Color(0x1A000000);

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
      _loading = true;
      _error = null;
    });

    try {
      final response = await _service.obtenerHistorialEntregas();
      final parsed = HistorialEntregasResponse.fromJson(response);
      setState(() {
        _entregas = parsed.entregas.reversed.toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  double get _gananciaTotal =>
      _entregas.fold(0.0, (sum, item) => sum + item.montoTotal);

  double get _gananciaSemana {
    final ahora = DateTime.now();
    final sieteDiasAntes = ahora.subtract(const Duration(days: 7));
    return _entregas
        .where(
          (entrega) => _parseFecha(
            entrega.fechaEntregado,
          ).isAfter(sieteDiasAntes.subtract(const Duration(seconds: 1))),
        )
        .fold(0.0, (sum, item) => sum + item.montoTotal);
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
        .fold(0.0, (sum, item) => sum + item.montoTotal);
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
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Mis ganancias',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildResumen(),
            const SizedBox(height: 16),
            Expanded(child: _buildListado()),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de ganancias',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${_gananciaTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total acumulado',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicador('Hoy', _gananciaHoy, _accent),
              _buildIndicador('Últimos 7 días', _gananciaSemana, _success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicador(String label, double monto, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildListado() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Error cargando las ganancias',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarGanancias,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_entregas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Las ganancias aparecerán aquí en cuanto completes tu primera entrega.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _cargarGanancias,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        itemBuilder: (_, index) => _buildEntregaCard(_entregas[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _entregas.length,
      ),
    );
  }

  Widget _buildEntregaCard(EntregaHistorial entrega) {
    final fecha = _fechaFormat.format(_parseFecha(entrega.fechaEntregado));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _accent.withValues(alpha: 0.1),
          child: Icon(
            entrega.tieneComprobante ? Icons.check_circle : Icons.info_outline,
            color: entrega.tieneComprobante ? _success : Colors.grey[600],
          ),
        ),
        title: Text(
          'Bs ${entrega.montoTotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${entrega.clienteNombre} · $fecha\nMétodo: ${entrega.metodoPago}',
          style: const TextStyle(fontSize: 13),
        ),
        isThreeLine: true,
        trailing: entrega.tieneComprobante
            ? const Icon(Icons.receipt_long, color: _success)
            : const SizedBox.shrink(),
      ),
    );
  }
}
