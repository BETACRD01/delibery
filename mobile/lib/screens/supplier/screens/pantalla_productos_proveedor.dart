// lib/screens/supplier/screens/pantalla_productos_proveedor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/producto_model.dart';

/// Pantalla dedicada para gestionar productos del proveedor
class PantallaProductosProveedor extends StatefulWidget {
  const PantallaProductosProveedor({super.key});

  @override
  State<PantallaProductosProveedor> createState() => _PantallaProductosProveedorState();
}

class _PantallaProductosProveedorState extends State<PantallaProductosProveedor> {
  static const Color _primario = Color(0xFF1E88E5);
  static const Color _exito = Color(0xFF10B981);
  static const Color _alerta = Color(0xFFF59E0B);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mis Productos', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _primario,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Buscar productos
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filtrar productos
            },
          ),
        ],
      ),
      body: Consumer<SupplierController>(
        builder: (context, controller, child) {
          if (!controller.verificado) {
            return _buildSinVerificar();
          }

          if (controller.productos.isEmpty) {
            return _buildVacio();
          }

          return RefreshIndicator(
            onRefresh: () => controller.refrescar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.productos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildProductoCard(controller.productos[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<SupplierController>(
        builder: (context, controller, child) {
          if (!controller.verificado) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _mostrarFormularioProducto(context),
            backgroundColor: _exito,
            icon: const Icon(Icons.add),
            label: const Text('Agregar'),
          );
        },
      ),
    );
  }

  Widget _buildProductoCard(ProductoModel producto) {
    final nombre = producto.nombre;
    final precio = producto.precio;
    final stock = producto.stock;
    final disponible = producto.disponible;
    final imagen = producto.imagenUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleProducto(producto),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImagenProducto(imagen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                    '\$${_formatPrecio(precio)}',
                     style: const TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.w700,
                     color: _exito,
                      ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (stock != null) ...[
                          Text(
                         'Stock: $stock',
                         style: const TextStyle(
                         fontSize: 12,
                         color: _textoSecundario,
                         ),
                         ),
                          const SizedBox(width: 10),
                        ],
                        _buildBadgeDisponible(disponible),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                onSelected: (value) {
                  switch (value) {
                    case 'editar':
                      _editarProducto(producto);
                      break;
                    case 'eliminar':
                      _confirmarEliminar(producto);
                      break;
                    case 'toggle':
                      _toggleDisponibilidad(producto);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(disponible ? 'Marcar agotado' : 'Marcar disponible'),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagenProducto(String? imagen) {
    String? urlCompleta;
    if (imagen != null && imagen.isNotEmpty) {
      urlCompleta = imagen.startsWith('http') ? imagen : '${ApiConfig.baseUrl}$imagen';
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: urlCompleta != null
            ? Image.network(urlCompleta, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28));
  }

  Widget _buildBadgeDisponible(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: disponible ? _exito.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        disponible ? 'Disponible' : 'Agotado',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: disponible ? _exito : Colors.red),
      ),
    );
  }

  Widget _buildSinVerificar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: _alerta.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text('Verificación pendiente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
             'Tu cuenta debe ser verificada para agregar productos.',
              textAlign: TextAlign.center,
              style: TextStyle(
              fontSize: 14,
              color: _textoSecundario,
                ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: _textoSecundario.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text('Sin productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Agrega tu primer producto para comenzar a vender.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textoSecundario),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _mostrarFormularioProducto(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar producto'),
              style: FilledButton.styleFrom(backgroundColor: _primario),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioProducto(BuildContext context, {ProductoModel? producto}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormularioProducto(producto: producto),
    );
  }

  void _mostrarDetalleProducto(ProductoModel producto) {
    _mostrarFormularioProducto(context, producto: producto);
  }

  void _editarProducto(ProductoModel producto) {
    _mostrarFormularioProducto(context, producto: producto);
  }

  void _confirmarEliminar(ProductoModel producto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _toggleDisponibilidad(ProductoModel producto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disponibilidad de "${producto.nombre}" actualizada')),
    );
  }

  String _formatPrecio(dynamic precio) {
    if (precio is num) return precio.toStringAsFixed(2);
    if (precio is String) return precio;
    return '0.00';
  }
}

/// Formulario para agregar/editar producto
class _FormularioProducto extends StatefulWidget {
  final ProductoModel? producto;

  const _FormularioProducto({this.producto});

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  bool _disponible = true;

  static const Color _exito = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      _nombreController.text = widget.producto!.nombre;
      _descripcionController.text = widget.producto!.descripcion;
      _precioController.text = widget.producto!.precio.toString();
      _stockController.text = widget.producto!.stock?.toString() ?? '';
      _disponible = widget.producto!.disponible;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.producto != null ? 'Editar Producto' : 'Nuevo Producto',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Imagen
            Center(
              child: GestureDetector(
                onTap: () {
                  // Seleccionar imagen
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descripcionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Disponible'),
              value: _disponible,
              onChanged: (v) => setState(() => _disponible = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: _exito,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(widget.producto != null ? 'Guardar Cambios' : 'Agregar Producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.producto != null ? 'Producto actualizado' : 'Producto agregado'),
        backgroundColor: _exito,
      ),
    );
  }
}
