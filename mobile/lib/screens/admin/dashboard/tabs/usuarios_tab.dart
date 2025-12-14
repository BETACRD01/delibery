// lib/screens/admin/dashboard/tabs/usuarios_tab.dart
import 'package:flutter/material.dart';
import '../constants/dashboard_colors.dart';

class UsuariosTab extends StatelessWidget {
  const UsuariosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Gestión de Usuarios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí podrás ver y gestionar todos los usuarios',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gestión de usuarios estará disponible pronto'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardColors.azul,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}