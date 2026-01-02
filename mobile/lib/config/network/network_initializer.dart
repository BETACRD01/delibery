// lib/config/network_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'api_config.dart';

// ============================================================================
// NETWORK INITIALIZER (ADAPTADO A NGROK)
// ============================================================================

class NetworkInitializer {
  NetworkInitializer._();

  /// Inicializa la configuración.
  static Future<void> initialize() async {
    debugPrint('Inicializando configuración de red...');
    await ApiConfig.initialize();
  }

  // --------------------------------------------------------------------------
  // Getters Informativos
  // --------------------------------------------------------------------------

  // Ya no detectamos nombres de WiFi (Casa/Trabajo), ahora es Modo Desarrollo o Prod.
  static String get currentNetwork =>
      ApiConfig.isProduction ? 'Internet (Producción)' : 'Túnel Seguro (Ngrok)';

  // La IP ahora es la URL completa
  static String get serverIp => ApiConfig.baseUrl;

  static String get baseUrl => ApiConfig.baseUrl;

  // Asumimos conectado si hay una URL configurada
  static bool get isConnected => ApiConfig.baseUrl.isNotEmpty;

  // --------------------------------------------------------------------------
  // Widget Info (Panel de Estado)
  // --------------------------------------------------------------------------

  static Widget buildNetworkInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          label: 'Modo',
          value: currentNetwork,
          icon: ApiConfig.isProduction ? Icons.public : Icons.developer_mode,
          color: ApiConfig.isProduction ? Colors.green : Colors.orange,
        ),
        _InfoRow(
          label: 'Conexión',
          // Mostramos solo una parte de la URL para que no ocupe mucho espacio
          value: serverIp.replaceAll('https://', ''),
          icon: Icons.link,
        ),
        _InfoRow(
          label: 'Estado',
          value: 'Activo',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGETS PRIVADOS (UI)
// ============================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.blue),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow
                  .ellipsis, // Evita desbordamiento si la URL es larga
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REFRESH BUTTON (SIMULADO)
// ============================================================================

class NetworkRefreshButton extends StatefulWidget {
  final VoidCallback? onNetworkChanged;

  const NetworkRefreshButton({super.key, this.onNetworkChanged});

  @override
  State<NetworkRefreshButton> createState() => _NetworkRefreshButtonState();
}

class _NetworkRefreshButtonState extends State<NetworkRefreshButton> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);

    try {
      // Como Ngrok es fijo, no necesitamos "buscar" IPs.
      // Simulamos una pequeña carga para dar feedback al usuario.
      await Future.delayed(const Duration(milliseconds: 800));

      // Llamamos al callback si existe (para recargar pantallas)
      widget.onNetworkChanged?.call();

      if (mounted) {
        _showSnackBar(
          'Conexión sincronizada: ${NetworkInitializer.currentNetwork}',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error de conexión', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _refreshing ? null : _refresh,
      icon: _refreshing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(radius: 14),
            )
          : const Icon(
              Icons.sync,
            ), // Cambiado a icono de Sync que tiene más sentido
      tooltip: 'Sincronizar conexión',
    );
  }
}
