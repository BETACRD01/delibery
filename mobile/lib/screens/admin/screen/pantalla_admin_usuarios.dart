import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../apis/admin/usuarios_admin_api.dart';
import '../dashboard/constants/dashboard_colors.dart';

class PantallaAdminUsuarios extends StatefulWidget {
  const PantallaAdminUsuarios({super.key});

  @override
  State<PantallaAdminUsuarios> createState() => _PantallaAdminUsuariosState();
}

class _PantallaAdminUsuariosState extends State<PantallaAdminUsuarios> {
  final _api = UsuariosAdminAPI();
  final _searchController = TextEditingController();

  bool _cargando = true;
  String? _error;
  List<dynamic> _usuarios = [];
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
        'Total usuarios: $_total',
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
      final data = await _api.buscarUsuarios(
        search: _searchController.text.trim(),
      );
      final results = data['results'] as List? ?? [];
      final rawCount = data['count'];
      final parsedCount = rawCount is num
          ? rawCount.toInt()
          : rawCount is String
          ? int.tryParse(rawCount)
          : null;
      final total = parsedCount ?? results.length;
      setState(() {
        _usuarios = results;
        _total = total;
      });
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar usuarios');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
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
                      labelText: 'Buscar por email o nombre',
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
                ? const Center(child: CupertinoActivityIndicator(radius: 14))
                : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.separated(
                      itemCount: _usuarios.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = _usuarios[index] as Map<String, dynamic>;
                        final email =
                            u['email'] ?? u['usuario_email'] ?? 'Sin email';
                        final nombre =
                            u['nombre'] ?? u['usuario_nombre'] ?? 'Usuario';
                        final rol = u['rol_activo'] ?? u['rol'] ?? 'SIN ROL';
                        return ListTile(
                          title: Text(nombre),
                          subtitle: Text('$email • Rol: $rol'),
                          trailing: Text('ID: ${u['id']}'),
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
