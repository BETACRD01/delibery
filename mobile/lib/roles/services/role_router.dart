// lib/role_switch/services/role_router.dart

import 'package:flutter/material.dart';
import '../../config/routing/rutas.dart';
import '../models/roles.dart';

class RoleRouter {
  static String routeForRole(AppRole role) {
    switch (role) {
      case AppRole.provider:
        return Rutas.proveedorHome;
      case AppRole.courier:
        return Rutas.repartidorHome;
      case AppRole.user:
        return Rutas.inicio;
    }
  }

  static Future<void> navigateByRole(BuildContext context, AppRole role) async {
    final ruta = routeForRole(role);
    await Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(ruta, (route) => false);
  }
}
