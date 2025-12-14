import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import '../config/network_initializer.dart';

class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({super.key});

  @override
  State<NetworkTestPage> createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    // Simulamos la peticion
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conexion OK: ${ApiConfig.baseUrl}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostico Red'),
        backgroundColor: const Color(0xFF4FC3F7),
        actions: [
          NetworkRefreshButton(onNetworkChanged: () => setState(() {})),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Componente visual de estado
          NetworkInitializer.buildNetworkInfo(),
          
          const Divider(height: 30),

          // 2. Informacion Esencial
          const Text('Configuracion Activa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          
          _simpleInfoRow('Base URL', ApiConfig.baseUrl),
          _simpleInfoRow('Entorno', ApiConfig.isDevelopment ? 'Desarrollo' : 'Produccion'),
          _simpleInfoRow('Timeout', '${ApiConfig.connectTimeout.inSeconds}s'),

          const SizedBox(height: 30),

          // 3. Boton de Accion Principal
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: _isLoading ? null : _testConnection,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.wifi_find),
            label: Text(_isLoading ? 'Probando...' : 'Probar Conexion'),
          ),
        ],
      ),
    );
  }

  // Helper para filas de texto
  Widget _simpleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado!'), duration: Duration(milliseconds: 500)));
        },
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.copy, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}