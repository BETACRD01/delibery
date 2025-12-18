// lib/config/network_initializer.dart
import 'package:flutter/material.dart';
import 'api_config.dart';

// ============================================================================
// NETWORK INITIALIZER
// ============================================================================

class NetworkInitializer {
  NetworkInitializer._();

  static Future<void> initialize() async {
    debugPrint('Inicializando detección de red...');
    await ApiConfig.initialize();
  }

  // --------------------------------------------------------------------------
  // Getters
  // --------------------------------------------------------------------------

  static String? get currentNetwork => ApiConfig.currentNetwork;
  static String? get serverIp => ApiConfig.currentServerIp;
  static String get baseUrl => ApiConfig.baseUrl;
  static bool get isConnected => ApiConfig.currentServerIp != null;

  // --------------------------------------------------------------------------
  // Widget Info
  // --------------------------------------------------------------------------

  static Widget buildNetworkInfo() {
    final network = currentNetwork ?? 'No detectada';
    final ip = serverIp ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          label: 'Red Actual',
          value: network,
          icon: _getNetworkIcon(network),
        ),
        _InfoRow(label: 'IP Servidor', value: ip, icon: Icons.dns),
        _InfoRow(
          label: 'Estado',
          value: isConnected ? 'Conectado' : 'Desconectado',
          icon: isConnected ? Icons.check_circle : Icons.error,
          color: isConnected ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  static IconData _getNetworkIcon(String network) {
    if (network.contains('CASA')) return Icons.home;
    if (network.contains('INSTITUCIONAL')) return Icons.business;
    if (network.contains('DESCONOCIDA')) return Icons.help_outline;
    return Icons.public;
  }
}

// ============================================================================
// WIDGETS PRIVADOS
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
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REFRESH BUTTON
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
      await ApiConfig.refreshNetwork();
      widget.onNetworkChanged?.call();
      if (mounted) {
        _showSnackBar(
          'Red actualizada: ${ApiConfig.currentNetwork ?? "Desconocida"}',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar: $e', Colors.red);
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
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      tooltip: 'Refrescar red',
    );
  }
}
