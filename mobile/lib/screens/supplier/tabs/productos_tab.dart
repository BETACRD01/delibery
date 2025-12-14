// lib/screens/supplier/tabs/productos_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/producto_model.dart';
import '../screens/pantalla_productos_proveedor.dart';

/// Tab de productos - Diseño limpio y profesional
class ProductosTab extends StatelessWidget {
  const ProductosTab({super.key});

  static const Color _textoSecundario = Color(0xFF6B7280);
  static const Color _exito = Color(0xFF10B981);
  static const Color _alerta = Color(0xFFF59E0B);

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

        if (controller.productos.isEmpty) {
          return _buildEstadoVacio(
            icono: Icons.inventory_2_outlined,
            titulo: 'Sin productos',
            mensaje: 'Agrega tu primer producto para comenzar a vender.',
            color: _textoSecundario,
            accion: FilledButton.icon(
              onPressed: () => _irAGestionProductos(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar producto'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refrescarProductos(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.productos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final producto = controller.productos[index];
              return _buildProductoCard(context, producto);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductoCard(BuildContext context, ProductoModel producto) {
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
        onTap: () => _irAGestionProductos(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen
              _buildImagenProducto(imagen),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
                          const SizedBox(width: 12),
                        ],
                        _buildBadgeDisponible(disponible),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
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
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  Widget _buildBadgeDisponible(bool disponible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: disponible
            ? _exito.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        disponible ? 'Disponible' : 'Agotado',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: disponible ? _exito : Colors.red,
        ),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
            if (accion != null) ...[
              const SizedBox(height: 24),
              accion,
            ],
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
}
