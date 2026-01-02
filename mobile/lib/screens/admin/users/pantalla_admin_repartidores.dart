import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../apis/admin/repartidores_admin_api.dart';
import '../../../../providers/core/theme_provider.dart';
import '../../../../theme/app_colors_primary.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaAdminRepartidores extends StatefulWidget {
  const PantallaAdminRepartidores({super.key});

  @override
  State<PantallaAdminRepartidores> createState() =>
      _PantallaAdminRepartidoresState();
}

class _PantallaAdminRepartidoresState extends State<PantallaAdminRepartidores> {
  final _api = RepartidoresAdminAPI();
  final _searchController = TextEditingController();

  bool _cargando = true;
  String? _error;
  List<dynamic> _items = [];
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _extraerLista(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['results'] is List<dynamic>) {
        return data['results'] as List<dynamic>;
      }
      final firstList = data.values.firstWhere(
        (v) => v is List<dynamic>,
        orElse: () => <dynamic>[],
      );
      if (firstList is List<dynamic>) return firstList;
    }
    if (data is List<dynamic>) return data;
    return <dynamic>[];
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> data = await _api.listar(
        search: _searchController.text.trim(),
      );
      final lista = _extraerLista(data);
      setState(() {
        _items = lista;
        final count = data['count'];
        if (count is num) {
          _total = count.toInt();
        } else if (count is String) {
          _total = int.tryParse(count) ?? lista.length;
        } else {
          _total = lista.length;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar repartidores');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryColor = AppColorsPrimary.main;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Repartidores'),
        backgroundColor: bgColor,
        scrolledUnderElevation: 0,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: bgColor,
            child: CupertinoSearchTextField(
              controller: _searchController,
              onSubmitted: (_) => _cargar(),
              placeholder: 'Buscar repartidor',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              itemColor: isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),

          // Header Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'TOTAL REPARTIDORES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _cargando
                ? const Center(child: CupertinoActivityIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton(
                          onPressed: _cargar,
                          child: Text(
                            'Reintentar',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: primaryColor,
                    child: _items.isEmpty
                        ? const Center(child: Text('No hay repartidores'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final r = _items[index] as Map<String, dynamic>;
                              final nombre =
                                  r['usuario_nombre'] ?? 'Repartidor';
                              final email = r['usuario_email'] ?? 'Sin email';
                              final verificado = r['verificado'] == true;
                              final activo = r['activo'] != false;
                              final estado = r['estado'] ?? 'N/A';

                              return Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.delivery_dining,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '$email',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          _buildStatusBadge(
                                            estado.toString().toUpperCase(),
                                            Colors
                                                .blue, // Or verify actual logic for colors
                                            isDark,
                                          ),
                                          _buildStatusBadge(
                                            verificado
                                                ? 'Verificado'
                                                : 'Pendiente',
                                            verificado
                                                ? DashboardColors.verde
                                                : DashboardColors.naranja,
                                            isDark,
                                          ),
                                          _buildStatusBadge(
                                            activo ? 'Activo' : 'Inactivo',
                                            activo
                                                ? DashboardColors.azul
                                                : DashboardColors.rojo,
                                            isDark,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
