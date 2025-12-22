// lib/screens/admin/dashboard/tabs/actividad_tab.dart
import 'package:flutter/material.dart';
import '../../../../apis/admin/acciones_admin_api.dart';
import '../constants/dashboard_colors.dart';

class ActividadTab extends StatefulWidget {
  const ActividadTab({super.key});

  @override
  State<ActividadTab> createState() => _ActividadTabState();
}

class _ActividadTabState extends State<ActividadTab> {
  final _api = AccionesAdminAPI();
  bool _loading = true;
  String? _error;
  List<dynamic> _acciones = [];

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
      final data = await _api.listar(pageSize: 20);
      final results = data['results'];
      if (results is List) {
        setState(() => _acciones = results);
      } else {
        setState(() => _acciones = []);
      }
    } catch (e) {
      setState(() => _error = 'No se pudo cargar el historial');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: DashboardColors.rojo)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_acciones.isEmpty) {
      return const Center(child: Text('Sin actividad reciente'));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _acciones.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final a = _acciones[index] as Map<String, dynamic>;
          final titulo =
              a['tipo_accion_display'] ?? a['tipo_accion'] ?? 'Acción';
          final desc = a['descripcion'] ?? a['resumen'] ?? '';
          final admin = a['admin_email'] ?? 'Admin';
          final fecha = a['fecha_accion']?.toString() ?? '';
          final exitosa = a['exitosa'] != false;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: exitosa
                  ? DashboardColors.verde.withValues(alpha: 0.2)
                  : DashboardColors.rojo.withValues(alpha: 0.2),
              child: Icon(
                exitosa ? Icons.check : Icons.error_outline,
                color: exitosa ? DashboardColors.verde : DashboardColors.rojo,
              ),
            ),
            title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  '$admin • $fecha',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
