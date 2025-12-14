// lib/screens/user/super/pantalla_categoria_detalle.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/categoria_super_model.dart';
import '../../../controllers/user/categoria_super_controller.dart';
import 'pantalla_productos_proveedor.dart';

/// Pantalla de detalle de una categoría Super
/// Muestra proveedores y productos de la categoría seleccionada
class PantallaCategoriaDetalle extends StatefulWidget {
  final CategoriaSuperModel categoria;

  const PantallaCategoriaDetalle({
    super.key,
    required this.categoria,
  });

  @override
  State<PantallaCategoriaDetalle> createState() => _PantallaCategoriaDetalleState();
}

class _PantallaCategoriaDetalleState extends State<PantallaCategoriaDetalle> {
  late final CategoriaSuperController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CategoriaSuperController(widget.categoria.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.categoria.nombre),
          elevation: 0,
          backgroundColor: widget.categoria.color,
          foregroundColor: Colors.white,
        ),
        body: Consumer<CategoriaSuperController>(
          builder: (context, controller, _) {
            if (controller.error != null) {
              return _buildError(controller.error!);
            }

            if (controller.proveedores.isEmpty && controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.proveedores.isEmpty) {
              return _buildSinProveedores();
            }

            return _buildListaProveedores(controller);
          },
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 24),
          Text(
            'Error al cargar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _controller.refrescar(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSinProveedores() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.categoria.icono,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No hay proveedores disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente agregaremos más opciones',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProveedores(CategoriaSuperController controller) {
    return RefreshIndicator(
      onRefresh: controller.refrescar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.proveedores.length,
        itemBuilder: (context, index) {
          final proveedor = controller.proveedores[index];
          return _buildTarjetaProveedor(proveedor);
        },
      ),
    );
  }

  Widget _buildTarjetaProveedor(dynamic proveedor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onProveedorPressed(proveedor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre y verificación
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proveedor['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (proveedor['verificado'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verificado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (proveedor['descripcion'] != null &&
                  proveedor['descripcion'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  proveedor['descripcion'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Dirección
              if (proveedor['direccion'] != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        proveedor['direccion'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Calificación y estado
              Row(
                children: [
                  if (proveedor['calificacion'] != null &&
                      proveedor['calificacion'] > 0) ...[
                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      proveedor['calificacion'].toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (proveedor['total_resenas'] != null &&
                        proveedor['total_resenas'] > 0) ...[
                      Text(
                        ' (${proveedor['total_resenas']})',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(width: 16),
                  ],

                  // Estado abierto/cerrado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: proveedor['esta_abierto'] == true
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      proveedor['esta_abierto'] == true ? 'Abierto' : 'Cerrado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: proveedor['esta_abierto'] == true
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onProveedorPressed(dynamic proveedor) {
    // Navegar a la pantalla de productos del proveedor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaProductosProveedor(
          proveedor: proveedor,
          categoriaColor: widget.categoria.color,
        ),
      ),
    );
  }
}
