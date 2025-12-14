import 'package:flutter/material.dart';

class PedidoUtils {
  static Color getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmado':
        return Colors.orange.shade700;
      case 'en_preparacion':
        return Colors.blue.shade600;
      case 'en_ruta':
        return Colors.cyan.shade600;
      case 'entregado':
        return Colors.green.shade600;
      case 'cancelado':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  static Color getColorFondoEstado(String estado) {
    return getColorEstado(estado).withValues(alpha: 0.1);
  }

  static Widget buildEstadoBadge(String estado, String estadoDisplay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getColorFondoEstado(estado),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getColorEstado(estado).withValues(alpha: 0.3)),
      ),
      child: Text(
        estadoDisplay,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: getColorEstado(estado),
        ),
      ),
    );
  }
}