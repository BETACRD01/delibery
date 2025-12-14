import 'package:flutter/material.dart';

import '../../../apis/admin/proveedores_admin_api.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaAdminProveedores extends StatefulWidget {
  const PantallaAdminProveedores({super.key});

  @override
  State<PantallaAdminProveedores> createState() => _PantallaAdminProveedoresState();
}

class _PantallaAdminProveedoresState extends State<PantallaAdminProveedores> {
  final _api = ProveedoresAdminAPI();
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
        'Total proveedores: $_total',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _api.listar(search: _searchController.text.trim());
      final results = (data['results'] as List?) ?? [];
      setState(() {
        _items = results;
        _total = (data['count'] as num?)?.toInt() ?? results.length;
      });
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar proveedores');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
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
                      labelText: 'Buscar proveedor',
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
                        child: ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = _items[index] as Map<String, dynamic>;
                            final nombre = p['nombre'] ?? p['usuario_nombre'] ?? 'Proveedor';
                            final email = p['usuario_email'] ?? 'Sin email';
                            final verificado = p['verificado'] == true;
                            final activo = p['activo'] != false;
                            return ListTile(
                              title: Text(nombre),
                              subtitle: Text(email),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(verificado ? 'Verificado' : 'Pendiente',
                                      style: TextStyle(
                                        color: verificado ? DashboardColors.verde : DashboardColors.naranja,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Text(activo ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        color: activo ? DashboardColors.azul : DashboardColors.rojo,
                                      )),
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
