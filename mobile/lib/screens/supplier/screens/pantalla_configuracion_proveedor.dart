// lib/screens/supplier/screens/pantalla_configuracion_proveedor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/supplier/supplier_controller.dart';

/// Pantalla de configuración del proveedor
class PantallaConfiguracionProveedor extends StatefulWidget {
  const PantallaConfiguracionProveedor({super.key});

  @override
  State<PantallaConfiguracionProveedor> createState() => _PantallaConfiguracionProveedorState();
}

class _PantallaConfiguracionProveedorState extends State<PantallaConfiguracionProveedor> {
  // Configuraciones
  bool _notificacionesPedidos = true;
  bool _notificacionesPromos = false;
  bool _sonidoNotificaciones = true;
  bool _modoOscuro = false;

  static const Color _primario = Color(0xFF1E88E5);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _primario,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información de cuenta
          _buildSeccion('Cuenta'),
          const SizedBox(height: 10),
          Consumer<SupplierController>(
            builder: (context, controller, child) {
              return _buildInfoCard(
                items: [
                  _InfoItem(
                    icono: Icons.store_outlined,
                    titulo: 'Negocio',
                    valor: controller.nombreNegocio.isNotEmpty ? controller.nombreNegocio : '---',
                  ),
                  _InfoItem(
                    icono: Icons.email_outlined,
                    titulo: 'Email',
                    valor: controller.email.isNotEmpty ? controller.email : '---',
                  ),
                  _InfoItem(
                    icono: Icons.verified_outlined,
                    titulo: 'Estado',
                    valor: controller.verificado ? 'Verificado' : 'Pendiente',
                    valorColor: controller.verificado ? Colors.green : Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Notificaciones
          _buildSeccion('Notificaciones'),
          const SizedBox(height: 10),
          _buildConfigCard(
            children: [
              _buildSwitch(
                titulo: 'Notificaciones de pedidos',
                subtitulo: 'Recibir alertas de nuevos pedidos',
                valor: _notificacionesPedidos,
                onChanged: (v) => setState(() => _notificacionesPedidos = v),
              ),
              const Divider(height: 1),
              _buildSwitch(
                titulo: 'Promociones y novedades',
                subtitulo: 'Recibir información de ofertas',
                valor: _notificacionesPromos,
                onChanged: (v) => setState(() => _notificacionesPromos = v),
              ),
              const Divider(height: 1),
              _buildSwitch(
                titulo: 'Sonido de notificaciones',
                subtitulo: 'Reproducir sonido al recibir pedidos',
                valor: _sonidoNotificaciones,
                onChanged: (v) => setState(() => _sonidoNotificaciones = v),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apariencia
          _buildSeccion('Apariencia'),
          const SizedBox(height: 10),
          _buildConfigCard(
            children: [
              _buildSwitch(
                titulo: 'Modo oscuro',
                subtitulo: 'Usar tema oscuro en la aplicación',
                valor: _modoOscuro,
                onChanged: (v) => setState(() => _modoOscuro = v),
              ),
            ],
          ),
          const SizedBox(height: 24),

        const SizedBox(height: 32),
         const Center(
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(color: _textoSecundario, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo) {
    return Text(
      titulo.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _textoSecundario,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard({required List<_InfoItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(item.icono, size: 20, color: _textoSecundario),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titulo,
                            style:const TextStyle(fontSize: 12, color: _textoSecundario),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.valor,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item.valorColor ?? Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConfigCard({required List<Widget> children, Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitch({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitulo, style:const TextStyle(fontSize: 12, color: _textoSecundario)),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onChanged,
            activeThumbColor: _primario,
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color? valorColor;

  _InfoItem({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.valorColor,
  });
}

/// Sheet para cambiar contraseña
class _CambiarContrasenaSheet extends StatefulWidget {
  @override
  State<_CambiarContrasenaSheet> createState() => _CambiarContrasenaSheetState();
}

class _CambiarContrasenaSheetState extends State<_CambiarContrasenaSheet> {
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _mostrarActual = false;
  bool _mostrarNueva = false;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cambiar Contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _actualController,
              obscureText: !_mostrarActual,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarActual ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _mostrarActual = !_mostrarActual),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nuevaController,
              obscureText: !_mostrarNueva,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(_mostrarNueva ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _mostrarNueva = !_mostrarNueva),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmarController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _cambiarContrasena,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cambiar Contraseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cambiarContrasena() {
    if (_nuevaController.text != _confirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    // TODO: Cambiar contraseña en backend
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}
