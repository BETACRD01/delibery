// lib/screens/admin/dashboard/widgets/actividad_reciente_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../apis/admin/acciones_admin_api.dart';
import '../constants/dashboard_colors.dart';

class ActividadRecienteCard extends StatefulWidget {
  const ActividadRecienteCard({super.key});

  @override
  State<ActividadRecienteCard> createState() => _ActividadRecienteCardState();
}

class _ActividadRecienteCardState extends State<ActividadRecienteCard> {
  final _api = AccionesAdminAPI();
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.listar(pageSize: 5);
      final results = data['results'];
      setState(() {
        _items = results is List ? results : [];
      });
    } catch (e) {
      setState(() => _error = 'No se pudo cargar la actividad');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Últimas Acciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loading ? null : _cargar,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CupertinoActivityIndicator(radius: 14))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: DashboardColors.rojo))
            else if (_items.isEmpty)
              const Text('Sin actividad reciente')
            else
              ..._items.map((item) {
                final accion = item as Map<String, dynamic>;
                final titulo = accion['tipo_accion_display'] ?? accion['tipo_accion'] ?? 'Acción';
                final descripcion = accion['descripcion'] ?? accion['resumen'] ?? '';
                final fecha = accion['fecha_accion']?.toString() ?? '';
                final admin = accion['admin_email'] ?? 'Admin';
                final exitosa = accion['exitosa'] != false;
                final color = exitosa ? DashboardColors.verde : DashboardColors.rojo;
                return Column(
                  children: [
                    _buildItemActividad(
                      titulo,
                      descripcion.isEmpty ? admin : '$descripcion • $admin',
                      exitosa ? Icons.check_circle : Icons.error_outline,
                      color,
                      fecha,
                    ),
                    const Divider(),
                  ],
                );
              }).take(5),
          ],
        ),
      ),
    );
  }

  Widget _buildItemActividad(
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
    String tiempo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(tiempo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
