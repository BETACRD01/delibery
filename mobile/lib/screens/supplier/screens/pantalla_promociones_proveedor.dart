// lib/screens/supplier/screens/pantalla_promociones_proveedor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/supplier/supplier_controller.dart';
import '../../../models/promocion_model.dart';

class PantallaPromocionesProveedor extends StatelessWidget {
  const PantallaPromocionesProveedor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Promociones'),
      ),
      body: Consumer<SupplierController>(
        builder: (context, controller, _) {
          final promos = controller.promociones;
          if (promos.isEmpty) {
            return const Center(child: Text('Sin promociones'));
          }
          return ListView.builder(
            itemCount: promos.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(promos[i].titulo),
            ),
          );
        },
      ),
    );
  }
}

// Helper público para reusar el formulario (stub)
Widget buildFormularioPromocion({PromocionModel? promo}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    child: const Text('Gestión de promociones no disponible en este build'),
  );
}
