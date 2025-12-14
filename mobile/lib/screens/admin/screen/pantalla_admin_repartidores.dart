import 'package:flutter/material.dart';

import '../../../apis/admin/repartidores_admin_api.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaAdminRepartidores extends StatefulWidget {
  const PantallaAdminRepartidores({super.key});

  @override
  State<PantallaAdminRepartidores> createState() => _PantallaAdminRepartidoresState();
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        'Total repartidores: $_total',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  List<dynamic> _extraerLista(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['results'] is List<dynamic>) return data['results'] as List<dynamic>;
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
      final Map<String, dynamic> data =
          await _api.listar(search: _searchController.text.trim());
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
      setState(() => _error = 'No se pudieron cargar repartidores');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repartidores'),
        backgroundColor: Colors.white,
        foregroundColor: DashboardColors.morado,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar repartidor',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _cargar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  color: DashboardColors.morado,
                  onPressed: _cargar,
                ),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                      onRefresh: _cargar,
                      child: _items.isEmpty
                          ? const Center(child: Text('No hay repartidores'))
                          : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final r = _items[index] as Map<String, dynamic>;
                                  final nombre = r['usuario_nombre'] ?? 'Repartidor';
                                  final email = r['usuario_email'] ?? 'Sin email';
                                  final verificado = r['verificado'] == true;
                                  final activo = r['activo'] != false;
                                  final estado = r['estado'] ?? 'N/A';
                                  return ListTile(
                                    title: Text(nombre),
                                    subtitle: Text('$email • Estado: $estado'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          verificado ? 'Verificado' : 'Pendiente',
                                          style: TextStyle(
                                            color: verificado ? DashboardColors.verde : DashboardColors.naranja,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          activo ? 'Activo' : 'Inactivo',
                                          style: TextStyle(
                                            color: activo ? DashboardColors.azul : DashboardColors.rojo,
                                          ),
                                        ),
                                      ],
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
}
