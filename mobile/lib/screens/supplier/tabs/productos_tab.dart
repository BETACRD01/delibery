// lib/screens/supplier/tabs/productos_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/producto_model.dart';
import '../screens/pantalla_productos_proveedor.dart';

/// Tab de productos - Diseño limpio y profesional
class ProductosTab extends StatefulWidget {
  const ProductosTab({super.key});

  @override
  State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {
  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _exito = Color(0xFF10B981);
  static const Color _alerta = Color(0xFFF59E0B);

  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'todos';
  bool _stockBajo = false;
  final Set<String> _seleccionados = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductoModel> _filtrarProductos(List<ProductoModel> items) {
    var filtrados = items.where((producto) {
      final query = _searchController.text.toLowerCase();
      final nombre = producto.nombre.toLowerCase();
      if (query.isNotEmpty && !nombre.contains(query)) return false;
      if (_statusFilter == 'activos' && !producto.disponible) return false;
      if (_statusFilter == 'agotados' && producto.disponible) return false;
      if (_stockBajo && (producto.stock == null || producto.stock! > 5)) {
        return false;
      }
      return true;
    }).toList();
    return filtrados;
  }

  void _toggleSeleccion(String id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados.remove(id);
      } else {
        _seleccionados.add(id);
      }
    });
  }

  void _limpiarSeleccion() {
    setState(() => _seleccionados.clear());
  }

  bool get _modoSeleccion => _seleccionados.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        if (!controller.verificado) {
          return _buildEstadoVacio(
            icono: Icons.verified_user_outlined,
            titulo: 'Verificación pendiente',
            mensaje: 'Tu cuenta debe ser verificada para agregar productos.',
            color: _alerta,
          );
        }

        if (controller.loading) {
          return _buildSkeletons();
        }

        final productosFiltrados = _filtrarProductos(controller.productos);

        if (productosFiltrados.isEmpty) {
          return _buildEmpty(context, controller);
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => controller.refrescarProductos(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  ...productosFiltrados.map(
                    (producto) =>
                        _buildProductoCard(context, controller, producto),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            if (_modoSeleccion)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildAccionesMasivas(controller),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar productos',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => _irAGestionProductos(context),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _exito,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: _exito.withValues(alpha: 0.3), blurRadius: 8),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Wrap(
      runSpacing: 8,
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: _statusFilter == 'todos',
          onSelected: (_) => setState(() => _statusFilter = 'todos'),
        ),
        ChoiceChip(
          label: const Text('Activos'),
          selected: _statusFilter == 'activos',
          onSelected: (_) => setState(() => _statusFilter = 'activos'),
        ),
        ChoiceChip(
          label: const Text('Agotados'),
          selected: _statusFilter == 'agotados',
          onSelected: (_) => setState(() => _statusFilter = 'agotados'),
        ),
        FilterChip(
          label: const Text('Stock bajo'),
          selected: _stockBajo,
          onSelected: (value) => setState(() => _stockBajo = value),
        ),
      ],
    );
  }

  Widget _buildProductoCard(
    BuildContext context,
    SupplierController controller,
    ProductoModel producto,
  ) {
    final seleccionada = _seleccionados.contains(producto.id);
    return GestureDetector(
      onLongPress: () => _toggleSeleccion(producto.id),
      onTap: () {
        if (_modoSeleccion) {
          _toggleSeleccion(producto.id);
          return;
        }
        _irAGestionProductos(context);
      },
      child: Dismissible(
        key: ValueKey(producto.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Producto "${producto.nombre}" eliminado temporalmente',
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionada ? _exito : Colors.grey.withValues(alpha: 0.2),
              width: seleccionada ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: _buildImagenProducto(producto.imagenUrl),
            title: Text(
              producto.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${_formatPrecio(producto.precio)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _exito,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (producto.stock != null)
                      Text(
                        'Stock: ${producto.stock}',
                        style: const TextStyle(
                          color: _textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: producto.disponible
                            ? _exito.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        producto.disponible ? 'Publicado' : 'Pausado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: producto.disponible ? _exito : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: producto.disponible,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      producto.disponible
                          ? 'Producto pausado'
                          : 'Producto publicado',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagenProducto(String? imagen) {
    String? urlCompleta;
    if (imagen != null && imagen.isNotEmpty) {
      urlCompleta = imagen.startsWith('http')
          ? imagen
          : '${ApiConfig.baseUrl}$imagen';
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: urlCompleta != null
            ? Image.network(
                urlCompleta,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, SupplierController controller) {
    return _buildEstadoVacio(
      icono: Icons.inventory_2_outlined,
      titulo: 'Sin productos',
      mensaje: 'Agrega tu primer producto para comenzar a vender.',
      color: _textoSecundario,
      accion: FilledButton.icon(
        onPressed: () => _irAGestionProductos(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Crear producto'),
      ),
    );
  }

  Widget _buildEstadoVacio({
    required IconData icono,
    required String titulo,
    required String mensaje,
    required Color color,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textoSecundario,
                height: 1.4,
              ),
            ),
            if (accion != null) ...[const SizedBox(height: 24), accion],
          ],
        ),
      ),
    );
  }

  String _formatPrecio(dynamic precio) {
    if (precio is num) return precio.toStringAsFixed(2);
    if (precio is String) return precio;
    return '0.00';
  }

  void _irAGestionProductos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PantallaProductosProveedor()),
    );
  }

  Widget _buildAccionesMasivas(SupplierController controller) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_seleccionados.length} seleccionados',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _limpiarSeleccion,
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Acción masiva ejecutada')),
                    );
                  },
                  child: const Text('Pausar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
