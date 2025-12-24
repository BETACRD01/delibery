import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../apis/admin/usuarios_admin_api.dart';
import '../../../../apis/helpers/api_exception.dart';
import '../../../../config/api_config.dart';
import '../../dashboard/constants/dashboard_colors.dart';

class PantallaResetearPasswordUsuario extends StatefulWidget {
  const PantallaResetearPasswordUsuario({super.key});

  @override
  State<PantallaResetearPasswordUsuario> createState() => _PantallaResetearPasswordUsuarioState();
}

class _PantallaResetearPasswordUsuarioState extends State<PantallaResetearPasswordUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usuariosApi = UsuariosAdminAPI();

  Map<String, dynamic>? _usuarioSeleccionado;
  bool _loadingBusqueda = false;
  bool _loadingReset = false;
  String? _errorBusqueda;
  String? _errorReset;
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _searchController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _loadingBusqueda = true;
      _errorBusqueda = null;
      _usuarioSeleccionado = null;
    });

    try {
      final data = await _usuariosApi.buscarUsuarios(search: _searchController.text.trim());
      final resultados = data['results'] as List? ?? [];
      if (resultados.isEmpty) {
        setState(() => _errorBusqueda = 'No se encontró ningún usuario con ese dato');
      } else {
        setState(() => _usuarioSeleccionado = resultados.first as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      setState(() => _errorBusqueda = e.message);
    } catch (_) {
      setState(() => _errorBusqueda = 'Error buscando usuario');
    } finally {
      setState(() => _loadingBusqueda = false);
    }
  }

  Future<void> _resetearPassword() async {
    if (_usuarioSeleccionado == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loadingReset = true;
      _errorReset = null;
    });

    try {
      await _usuariosApi.resetearPassword(
        usuarioId: _usuarioSeleccionado!['id'] as int,
        nuevaPassword: _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada'),
            backgroundColor: DashboardColors.verde,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      setState(() => _errorReset = e.message);
    } catch (_) {
      setState(() => _errorReset = 'No se pudo actualizar la contraseña');
    } finally {
      setState(() => _loadingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resetear password de usuario'),
        backgroundColor: Colors.white,
        foregroundColor: DashboardColors.morado,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Busca por email o nombre. Se aplicará al primer resultado.',
              style: TextStyle(color: DashboardColors.gris),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Email o nombre',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadingBusqueda ? null : _buscar,
                  icon: _loadingBusqueda
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CupertinoActivityIndicator(radius: 14),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.morado,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ],
            ),
            if (_errorBusqueda != null) ...[
              const SizedBox(height: 8),
              Text(_errorBusqueda!, style: const TextStyle(color: DashboardColors.rojo)),
            ],
            const SizedBox(height: 12),
            if (_usuarioSeleccionado != null) _buildUsuarioCard(_usuarioSeleccionado!),
            const SizedBox(height: 12),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_mostrarPassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_mostrarPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                        if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                        return null;
                      },
                    ),
                    if (_errorReset != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorReset!, style: const TextStyle(color: DashboardColors.rojo)),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _loadingReset
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CupertinoActivityIndicator(radius: 14),
                              )
                            : const Icon(Icons.lock_reset),
                        label: Text(_loadingReset ? 'Actualizando...' : 'Resetear contraseña'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.morado,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _loadingReset ? null : _resetearPassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuarioCard(Map<String, dynamic> user) {
    final email = user['email'] ?? user['usuario_email'] ?? 'Sin email';
    final nombre = user['nombre'] ?? user['usuario_nombre'] ?? 'Usuario';
    final rolActivo = user['rol_activo'] ?? user['rol'] ?? ApiConfig.rolUsuario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardColors.grisClaro.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(email),
          const SizedBox(height: 4),
          Text('Rol: $rolActivo'),
          const SizedBox(height: 4),
          Text('ID: ${user['id']}'),
        ],
      ),
    );
  }
}
