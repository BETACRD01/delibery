
// lib/screens/admin/dashboard/tabs/proveedores_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/admin/dashboard_controller.dart';
import '../constants/dashboard_colors.dart';

class ProveedoresTab extends StatelessWidget {
  const ProveedoresTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Gestión de Proveedores',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verifica y gestiona los proveedores de la plataforma',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                if (controller.proveedoresPendientes > 0) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DashboardColors.naranja.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DashboardColors.naranja,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          color: DashboardColors.naranja,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${controller.proveedoresPendientes} proveedores esperando verificación',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}