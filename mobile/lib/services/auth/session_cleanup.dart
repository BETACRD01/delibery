// lib/services/auth/session_cleanup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/delivery/repartidor_controller.dart';
import '../../controllers/supplier/supplier_controller.dart';
import '../../controllers/user/perfil_controller.dart';
import '../../providers/notificaciones_provider.dart';
import '../../providers/proveedor_carrito.dart';
import '../../providers/proveedor_pedido.dart';

class SessionCleanup {
  static Future<void> clearProviders(BuildContext context) async {
    if (!context.mounted) return;
    context.read<ProveedorCarrito>().limpiar();
    context.read<PedidoProvider>().limpiar();
    context.read<PerfilController>().limpiar();
    await context.read<NotificacionesProvider>().limpiar();
    if (!context.mounted) return;
    context.read<RepartidorController>().limpiar();
    context.read<SupplierController>().limpiar();
  }

  static Future<void> clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historial_busqueda');
    await prefs.remove(NotificacionesProvider.storageKey);
  }
}
