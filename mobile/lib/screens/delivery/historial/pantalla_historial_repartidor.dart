// lib/screens/delivery/historial/pantalla_historial_repartidor.dart

import 'package:flutter/material.dart';
import 'package:mobile/models/entrega_historial.dart';
import 'package:mobile/services/repartidor_service.dart';

/// Pantalla dedicada al historial de entregas vinculada al backend.
class PantallaHistorialRepartidor extends StatefulWidget {
  const PantallaHistorialRepartidor({super.key});

  @override
  State<PantallaHistorialRepartidor> createState() =>
      _PantallaHistorialRepartidorState();
}

class _PantallaHistorialRepartidorState
    extends State<PantallaHistorialRepartidor> {
  static const Color _surface = Color(0xFFF2F4F7);
  static const Color _accent = Color(0xFF0A84FF);
  static const Color _success = Color(0xFF34C759);
  static const Color _errorColor = Color(0xFFEA3E3E);
  static const Color _cardBorder = Color(0xFFE1E4EB);
  static const Color _shadowColor = Color(0x1A000000);

  final RepartidorService _service = RepartidorService();
  final ScrollController _scrollController = ScrollController();

  List<EntregaHistorial> _entregas = [];
  double _totalComisiones = 0;
  int _totalEntregas = 0;
  bool _loading = true;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _service.obtenerHistorialEntregas();
      final parsed = HistorialEntregasResponse.fromJson(response);
      setState(() {
        _entregas = parsed.entregas;
        _totalComisiones = parsed.totalComisiones;
        _totalEntregas = parsed.totalEntregas;
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

  List<EntregaHistorial> get _entregasFiltradas {
    if (_busqueda.trim().isEmpty) return _entregas;
    final termino = _busqueda.toLowerCase();
    return _entregas.where((entrega) {
      final nombre = entrega.clienteNombre.toLowerCase();
      final direccion = entrega.clienteDireccion.toLowerCase();
      return nombre.contains(termino) || direccion.contains(termino);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Historial de entregas',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildResumen(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBuscador(),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildListado()),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResumenItem(
            'Entregas',
            '$_totalEntregas',
            Icons.check_circle,
            _accent,
          ),
          _buildResumenItem(
            'Comisión',
            'Bs ${_totalComisiones.toStringAsFixed(2)}',
            Icons.monetization_on,
            _success,
          ),
          _buildResumenItem(
            'Visibles',
            '${_entregas.length}',
            Icons.history,
            Colors.grey[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(
    String label,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBuscador() {
    return TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Buscar por cliente o dirección',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(color: _cardBorder),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (valor) => setState(() => _busqueda = valor),
    );
  }

  Widget _buildListado() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: _errorColor),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarHistorial,
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
        ),
      );
    }

    final listado = _entregasFiltradas;

    if (listado.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Aún no tienes entregas registradas. Se mostrarán aquí en cuanto completes tu primera entrega.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _cargarHistorial,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: listado.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildEntregaCard(listado[index]);
        },
      ),
    );
  }

  Widget _buildEntregaCard(EntregaHistorial entrega) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Placeholder: podrías mostrar detalles extra
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(entrega),
                const SizedBox(height: 12),
                _buildLineaDetalle(
                  Icons.person,
                  'Cliente',
                  entrega.clienteNombre,
                ),
                const SizedBox(height: 8),
                _buildLineaDetalle(
                  Icons.location_on,
                  'Dirección',
                  entrega.clienteDireccion,
                ),
                const SizedBox(height: 8),
                _buildLineaDetalle(Icons.payment, 'Método', entrega.metodoPago),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      entrega.tieneComprobante
                          ? Icons.camera_alt
                          : Icons.info_outline,
                      color: entrega.tieneComprobante ? _success : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entrega.tieneComprobante
                          ? 'Comprobante recibido'
                          : 'Sin comprobante',
                      style: TextStyle(
                        color: entrega.tieneComprobante
                            ? _success
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Bs ${entrega.montoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(EntregaHistorial entrega) {
    final fecha = entrega.fechaFormateada;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Text(
            '#${entrega.id}',
            style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            fecha,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        _buildEstadoChip(entrega),
      ],
    );
  }

  Widget _buildLineaDetalle(IconData icono, String etiqueta, String valor) {
    return Row(
      children: [
        Icon(icono, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$etiqueta: $valor',
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip(EntregaHistorial entrega) {
    final color = entrega.montoTotal > 0 ? _success : _errorColor;
    final text = entrega.tieneComprobante ? 'Completado' : 'Pendiente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
