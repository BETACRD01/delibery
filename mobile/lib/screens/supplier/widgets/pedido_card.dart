// lib/screens/supplier/widgets/pedido_card.dart

import 'package:flutter/material.dart';

/// Card para mostrar un pedido - Diseño limpio
class PedidoCard extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback? onTap;
  final VoidCallback? onAceptar;
  final VoidCallback? onRechazar;

  const PedidoCard({
    super.key,
    required this.pedido,
    this.onTap,
    this.onAceptar,
    this.onRechazar,
  });

  static const Color _exito = Color(0xFF10B981);
  static const Color _alerta = Color(0xFFF59E0B);
  static const Color _primario = Color(0xFF1E88E5);
  static const Color _peligro = Color(0xFFEF4444);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final id = pedido['id'] ?? '000';
    final estado = pedido['estado'] ?? 'pendiente';
    final total = pedido['total'] ?? 0.0;
    final fecha = pedido['fecha'] ?? pedido['created_at'];
    final items = pedido['items'] ?? pedido['productos'] ?? [];
    final cantidadItems = items is List ? items.length : 0;
    final cliente = pedido['cliente'] ?? pedido['usuario'];
    final direccion = pedido['direccion'] ?? pedido['direccion_entrega'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pedido #$id',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildBadgeEstado(estado),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Total y items
                  Row(
                    children: [
                      Text(
                        '\$${_formatPrecio(total)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _exito,          // ← puede ser const
                        ),
                      ),
                      if (cantidadItems > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          '• $cantidadItems ${cantidadItems == 1 ? "item" : "items"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textoSecundario, // ← puede ser const
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Info adicional
                  const SizedBox(height: 10),
                  if (fecha != null)
                    _buildInfoRow(Icons.access_time, _formatFecha(fecha)),
                  if (cliente != null) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.person_outline,
                      _getNombreCliente(cliente),
                    ),
                  ],
                  if (direccion != null) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      _getDireccion(direccion),
                    ),
                  ],
                ],
              ),
            ),

            // Acciones
            if ((onAceptar != null || onRechazar != null) &&
                estado.toLowerCase() == 'pendiente') ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    if (onRechazar != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRechazar,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _peligro,
                            side: BorderSide(
                              color: _peligro.withValues(alpha: 0.5),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Rechazar',
                            style: TextStyle(
                              fontSize: 13,
                              // aquí también es const TextStyle
                            ),
                          ),
                        ),
                      ),
                    if (onRechazar != null && onAceptar != null)
                      const SizedBox(width: 10),
                    if (onAceptar != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: onAceptar,
                          style: FilledButton.styleFrom(
                            backgroundColor: _exito,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(
                              fontSize: 13,
                              // también const TextStyle
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeEstado(String estado) {
    Color color;
    String texto;

    switch (estado.toLowerCase()) {
      case 'pendiente':
        color = _alerta;
        texto = 'Pendiente';
        break;
      case 'aceptado':
      case 'en_preparacion':
        color = _primario;
        texto = 'En proceso';
        break;
      case 'completado':
        color = _exito;
        texto = 'Completado';
        break;
      case 'rechazado':
      case 'cancelado':
        color = _peligro;
        texto = 'Cancelado';
        break;
      default:
        color = _textoSecundario;
        texto = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color, // aquí NO puede ser const porque depende de estado
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _textoSecundario),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              color: _textoSecundario, // ← puede ser const
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatPrecio(dynamic precio) {
    if (precio is num) return precio.toStringAsFixed(2);
    if (precio is String) return precio;
    return '0.00';
  }

  String _formatFecha(dynamic fecha) {
    if (fecha is String) {
      try {
        final date = DateTime.parse(fecha);
        final now = DateTime.now();
        final diff = now.difference(date);

        if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
        if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
        return 'Hace ${diff.inDays}d';
      } catch (e) {
        return fecha;
      }
    }
    return 'Reciente';
  }

  String _getNombreCliente(dynamic cliente) {
    if (cliente is Map) {
      return cliente['nombre'] ??
          cliente['nombre_completo'] ??
          cliente['username'] ??
          'Cliente';
    }
    if (cliente is String) return cliente;
    return 'Cliente';
  }

  String _getDireccion(dynamic direccion) {
    if (direccion is Map) {
      final calle = direccion['calle'] ?? direccion['direccion'] ?? '';
      final ciudad = direccion['ciudad'] ?? '';
      if (calle.isNotEmpty && ciudad.isNotEmpty) return '$calle, $ciudad';
      return calle.isNotEmpty ? calle : ciudad;
    }
    if (direccion is String) return direccion;
    return 'Sin dirección';
  }
}
