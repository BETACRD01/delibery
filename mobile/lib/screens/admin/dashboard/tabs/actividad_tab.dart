import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../apis/admin/acciones_admin_api.dart';
import '../constants/dashboard_colors.dart';

import 'package:provider/provider.dart';
import '../../../../providers/core/theme_provider.dart';
import '../../../../theme/primary_colors.dart';

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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.listar(pageSize: 20);
      if (!mounted) return;

      final results = data['results'];
      setState(() {
        _acciones = results is List ? results : [];
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo cargar el historial');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: DashboardColors.rojo)),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _cargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_acciones.isEmpty) {
      return Center(
        child: Text(
          'Sin actividad reciente',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColorsPrimary.main,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _acciones.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? Colors.grey[800] : Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final a = _acciones[index] as Map<String, dynamic>;
          final titulo =
              a['tipo_accion_display'] ?? a['tipo_accion'] ?? 'Acción';
          final desc = a['descripcion'] ?? a['resumen'] ?? '';
          final admin = a['admin_email'] ?? 'Admin';
          final fecha = a['fecha_accion']?.toString() ?? '';
          final exitosa = a['exitosa'] != false;

          return _buildListItem(
            titulo: titulo,
            descripcion: desc,
            admin: admin,
            fecha: fecha,
            exitosa: exitosa,
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildListItem({
    required String titulo,
    required String descripcion,
    required String admin,
    required String fecha,
    required bool exitosa,
    required bool isDark,
  }) {
    final color = exitosa ? DashboardColors.verde : DashboardColors.rojo;
    final icon = exitosa ? Icons.check : Icons.error_outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fecha,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  admin,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
