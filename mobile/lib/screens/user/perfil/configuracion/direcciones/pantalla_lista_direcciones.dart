// lib/screens/user/perfil/configuracion/direcciones/pantalla_lista_direcciones.dart

import 'package:flutter/material.dart';
import '../../../../../theme/jp_theme.dart' hide JPSnackbar;
import '../../../../../services/usuarios_service.dart';
import '../../../../../models/usuario.dart';
import 'pantalla_mis_direcciones.dart';
import '../../../../../widgets/jp_snackbar.dart';

class PantallaListaDirecciones extends StatefulWidget {
  const PantallaListaDirecciones({super.key});

  @override
  State<PantallaListaDirecciones> createState() => _PantallaListaDireccionesState();
}

class _PantallaListaDireccionesState extends State<PantallaListaDirecciones> {
  final _usuarioService = UsuarioService();
  List<DireccionModel> _direcciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _usuarioService.listarDirecciones(forzarRecarga: true);
      if (mounted) setState(() => _direcciones = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar tus direcciones');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _nuevaDireccion() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaAgregarDireccion()),
    );

    // Recargar lista si hubo cambios
    if (resultado == true) {
      await _cargarDirecciones();
    }
  }

  Future<void> _editarDireccion(DireccionModel dir) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaAgregarDireccion(direccion: dir)),
    );

    // Recargar lista si hubo cambios
    if (resultado == true) {
      await _cargarDirecciones();
    }
  }

  Future<void> _eliminarDireccion(DireccionModel dir) async {
    try {
      await _usuarioService.eliminarDireccion(dir.id);
      if (mounted) {
        JPSnackbar.success(context, '✓ Dirección eliminada correctamente');
        _cargarDirecciones();
      }
    } catch (e) {
      if (!mounted) return;
      JPSnackbar.error(context, 'Error al eliminar: $e');
    }
  }

  void _mostrarDialogoEliminar(DireccionModel dir) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: JPColors.error, size: 28),
            SizedBox(width: 12),
            Text('Eliminar dirección'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar esta dirección?\n\n"${dir.etiqueta.isNotEmpty ? dir.etiqueta : dir.direccion}"',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: JPColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarDireccion(dir);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JPColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JPColors.background,
      appBar: AppBar(
        title: const Text('Mis Direcciones'),
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaDireccion,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nueva dirección'),
        backgroundColor: JPColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: JPColors.primary))
          : _error != null
              ? _buildError()
              : _direcciones.isEmpty
                  ? _buildEmpty()
                  : _buildLista(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: JPColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: JPColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDirecciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JPColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: JPColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 64,
                color: JPColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aún no tienes direcciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: JPColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega una dirección de entrega para\nrecibir tus pedidos más rápido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JPColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _nuevaDireccion,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Agregar primera dirección'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JPColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _cargarDirecciones,
      color: JPColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _direcciones.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDireccionCard(_direcciones[index]),
        ),
      ),
    );
  }

  Widget _buildDireccionCard(DireccionModel dir) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editarDireccion(dir),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: dir.esPredeterminada
                        ? JPColors.primary.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    dir.esPredeterminada ? Icons.star : Icons.location_on_outlined,
                    color: dir.esPredeterminada ? JPColors.primary : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dir.etiqueta.isNotEmpty ? dir.etiqueta : 'Mi dirección',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: JPColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dir.esPredeterminada)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: JPColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: JPColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dir.direccion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: JPColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (dir.ciudad != null && dir.ciudad!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              size: 14,
                              color: JPColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dir.ciudad!,
                              style: const TextStyle(
                                color: JPColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (dir.telefonoContacto != null && dir.telefonoContacto!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_iphone,
                              size: 14,
                              color: JPColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dir.telefonoContacto!,
                              style: const TextStyle(
                                color: JPColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Botón de opciones
                IconButton(
                  icon: const Icon(Icons.more_vert, color: JPColors.textSecondary),
                  onPressed: () => _mostrarOpciones(dir),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarOpciones(DireccionModel dir) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: JPColors.primary),
                title: const Text('Editar dirección'),
                onTap: () {
                  Navigator.pop(context);
                  _editarDireccion(dir);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: JPColors.error),
                title: const Text('Eliminar dirección'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoEliminar(dir);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
