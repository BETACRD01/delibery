// lib/screens/supplier/screens/pantalla_estadisticas_proveedor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/supplier/supplier_controller.dart';

/// Pantalla dedicada de estadísticas del proveedor
class PantallaEstadisticasProveedor extends StatelessWidget {
  const PantallaEstadisticasProveedor({super.key});

  static const Color _primario = Color(0xFF1E88E5);
  static const Color _exito = Color(0xFF10B981);
  static const Color _alerta = Color(0xFFF59E0B);
  static const Color _morado = Color(0xFF8B5CF6);
  static const Color _textoSecundario = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _primario,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SupplierController>().refrescar(),
          ),
        ],
      ),
      body: Consumer<SupplierController>(
        builder: (context, controller, child) {
          if (!controller.verificado) {
            return _buildSinVerificar();
          }

          return RefreshIndicator(
            onRefresh: () => controller.refrescar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Resumen rápido
                _buildResumenRapido(controller),
                const SizedBox(height: 24),

                // Ventas
                _buildSeccion('Ventas'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        valor: '\$${controller.ventasHoy.toStringAsFixed(2)}',
                        etiqueta: 'Hoy',
                        icono: Icons.today_outlined,
                        color: _exito,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        valor: '\$${controller.ventasMes.toStringAsFixed(2)}',
                        etiqueta: 'Este mes',
                        icono: Icons.calendar_month_outlined,
                        color: _primario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Rendimiento
                _buildSeccion('Rendimiento'),
                const SizedBox(height: 10),
                _buildStatCardLarge(
                  valor: controller.valoracionPromedio > 0
                  ? controller.valoracionPromedio.toStringAsFixed(1)
                  : '--',
                  etiqueta: 'Valoración promedio',
                  subtitulo: '${controller.totalResenas} reseñas totales',
                  icono: Icons.star_outline,
                  color: _morado,
                ),
                const SizedBox(height: 12),
                _buildStatCardLarge(
                  valor: '${controller.totalProductos}',
                  etiqueta: 'Productos activos',
                  subtitulo: 'En tu catálogo',
                  icono: Icons.inventory_2_outlined,
                  color: _primario,
                ),

                const SizedBox(height: 24),

                // Gráfico placeholder
                _buildGraficoPlaceholder(),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenRapido(SupplierController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
        _primario,
       _primario.withValues(alpha: 0.8),
           ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del día',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${controller.ventasHoy.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'en ventas hoy',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('${controller.pedidosPendientesCount}', 'Pendientes'),
              const SizedBox(width: 24),
              _buildMiniStat('${controller.totalProductos}', 'Productos'),
              const SizedBox(width: 24),
              _buildMiniStat(
                controller.valoracionPromedio > 0 
                    ? '${controller.valoracionPromedio.toStringAsFixed(1)}★' 
                    : '--',
                'Rating',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String valor, String etiqueta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
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

  Widget _buildStatCard({
    required String valor,
    required String etiqueta,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 12, color: _textoSecundario),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardLarge({
    required String valor,
    required String etiqueta,
    required String subtitulo,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(fontSize: 13, color: _textoSecundario)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                Text(subtitulo, style:const TextStyle(fontSize: 12, color: _textoSecundario)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Gráfico de ventas',
              style: TextStyle(color: _textoSecundario, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Próximamente',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinVerificar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 64, color: _alerta.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text(
              'Estadísticas no disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las estadísticas estarán disponibles cuando tu cuenta sea verificada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
