import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../apis/admin/acciones_admin_api.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../theme/app_colors_primary.dart';
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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.listar(pageSize: 5);
      final results = data['results'];
      if (mounted) {
        setState(() {
          _items = results is List ? results : [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo cargar la actividad');
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
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÚLTIMAS ACCIONES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _loading ? null : _cargar,
                child: Icon(
                  CupertinoIcons.refresh,
                  size: 20,
                  color: AppColorsPrimary.main,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator(),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: DashboardColors.rojo),
                ),
              ),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Sin actividad reciente',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ..._items
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final showDivider = index < _items.length - 1;

                  final accion = item as Map<String, dynamic>;
                  final titulo =
                      accion['tipo_accion_display'] ??
                      accion['tipo_accion'] ??
                      'Acción';
                  final descripcion =
                      accion['descripcion'] ?? accion['resumen'] ?? '';
                  final fecha = accion['fecha_accion']?.toString() ?? '';
                  final admin = accion['admin_email'] ?? 'Admin';
                  final exitosa = accion['exitosa'] != false;
                  final color = exitosa
                      ? DashboardColors.verde
                      : DashboardColors.rojo;

                  return Column(
                    children: [
                      _buildItemActividad(
                        titulo,
                        descripcion.isEmpty ? admin : '$descripcion • $admin',
                        exitosa ? Icons.check_circle : Icons.error_outline,
                        color,
                        fecha,
                        textColor,
                        isDark,
                      ),
                      if (showDivider)
                        Divider(
                          height: 1,
                          indent: 44,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                    ],
                  );
                })
                .take(5),
        ],
      ),
    );
  }

  Widget _buildItemActividad(
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
    String tiempo,
    Color textColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  tiempo,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
