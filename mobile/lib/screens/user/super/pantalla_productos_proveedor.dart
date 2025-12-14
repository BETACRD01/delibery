// lib/screens/user/super/pantalla_productos_proveedor.dart

import 'package:flutter/material.dart';
import '../../../services/super_service.dart';

/// Pantalla de productos de un proveedor Super
class PantallaProductosProveedor extends StatefulWidget {
  final Map<String, dynamic> proveedor;
  final Color categoriaColor;

  const PantallaProductosProveedor({
    super.key,
    required this.proveedor,
    required this.categoriaColor,
  });

  @override
  State<PantallaProductosProveedor> createState() => _PantallaProductosProveedorState();
}

class _PantallaProductosProveedorState extends State<PantallaProductosProveedor> {
  final SuperService _service = SuperService();
  List<dynamic> _productos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final productos = await _service.obtenerProductosProveedor(widget.proveedor['id']);

      setState(() {
        _productos = productos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proveedor['nombre'] ?? 'Productos'),
        elevation: 0,
        backgroundColor: widget.categoriaColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_productos.isEmpty) {
      return _buildSinProductos();
    }

    return _buildListaProductos();
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 24),
          Text(
            'Error al cargar productos',
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
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarProductos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSinProductos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No hay productos disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este proveedor no tiene productos en este momento',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    return RefreshIndicator(
      onRefresh: _cargarProductos,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _productos.length,
        itemBuilder: (context, index) {
          final producto = _productos[index];
          return _buildTarjetaProducto(producto);
        },
      ),
    );
  }

  Widget _buildTarjetaProducto(dynamic producto) {
    final double precio = (producto['precio'] is int)
        ? (producto['precio'] as int).toDouble()
        : (producto['precio'] ?? 0.0);

    final double? precioAnterior = producto['precio_anterior'] != null
        ? ((producto['precio_anterior'] is int)
            ? (producto['precio_anterior'] as int).toDouble()
            : producto['precio_anterior'])
        : null;

    final bool enOferta = precioAnterior != null && precioAnterior > precio;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onProductoPressed(producto),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.inventory_2,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),

                  // Badge de descuento
                  if (enOferta)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${producto['porcentaje_descuento'] ?? 0}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Badge de destacado
                  if (producto['destacado'] == true && !enOferta)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DESTACADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] ?? 'Producto',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Precio
                  if (enOferta) ...[
                    Text(
                      '\$${precioAnterior.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ] else
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.categoriaColor,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Stock
                  if (producto['stock'] != null && producto['stock'] > 0)
                    Text(
                      'Stock: ${producto['stock']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Text(
                      'Sin stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onProductoPressed(dynamic producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producto['nombre'] ?? 'Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto['descripcion'] != null &&
                producto['descripcion'].toString().isNotEmpty)
              Text(producto['descripcion']),
            const SizedBox(height: 16),
            Text(
              'Precio: \$${producto['precio']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Próximamente podrás agregar este producto al carrito',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
