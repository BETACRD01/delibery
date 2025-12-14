// lib/screens/supplier/tabs/pedidos_tab.dart

import 'package:flutter/material.dart';

/// Tab de pedidos - Diseño limpio y funcional
class PedidosTab extends StatelessWidget {
  const PedidosTab({super.key});

  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    // Proveedores ya no gestionan pedidos desde la app.
    return _buildEstadoVacio(
      icono: Icons.receipt_long_outlined,
      titulo: 'Pedidos deshabilitados',
      mensaje: 'La gestión de pedidos se realiza desde el panel administrativo.',
      color: _textoSecundario,
    );
  }

  Widget _buildEstadoVacio({
    required IconData icono,
    required String titulo,
    required String mensaje,
    required Color color,
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
          ],
        ),
      ),
    );
  }
}
