// lib/screens/supplier/widgets/producto_card.dart

import 'package:flutter/material.dart';
import '../../../config/api_config.dart';

/// Card para mostrar un producto - Diseño limpio
class ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onEditar,
    this.onEliminar,
  });

  static const Color _exito = Color(0xFF10B981);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final nombre = producto['nombre'] ?? 'Producto';
    final precio = producto['precio'];
    final stock = producto['stock'] ?? producto['cantidad'];
    final disponible = producto['disponible'] ?? true;
    final imagen = producto['imagen'] ?? producto['logo'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImagen(imagen),
              const SizedBox(width: 12),
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
                        // ✅ AHORA ES const
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
                              // ✅ AHORA ES const
                              fontSize: 12,
                              color: _textoSecundario,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        _buildBadge(disponible),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
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

  Widget _buildImagen(String? imagen) {
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
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
    );
  }

  Widget _buildBadge(bool disponible) {
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

  String _formatPrecio(dynamic precio) {
    if (precio is num) return precio.toStringAsFixed(2);
    if (precio is String) return precio;
    return '0.00';
  }
}
