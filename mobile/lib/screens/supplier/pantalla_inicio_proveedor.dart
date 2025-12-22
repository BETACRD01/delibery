// lib/screens/supplier/pantalla_inicio_proveedor.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/rutas.dart';
import '../../controllers/supplier/supplier_controller.dart';
import '../../services/session_cleanup.dart';
import 'widgets/supplier_drawer.dart';

import 'tabs/productos_tab.dart';
import 'tabs/promociones_tab.dart';
import 'tabs/estadisticas_tab.dart';

/// Pantalla principal para PROVEEDORES
/// Diseño profesional, limpio y funcional
class PantallaInicioProveedor extends StatefulWidget {
  const PantallaInicioProveedor({super.key});

  @override
  State<PantallaInicioProveedor> createState() => _PantallaInicioProveedorState();
}

class _PantallaInicioProveedorState extends State<PantallaInicioProveedor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Paleta principal: celeste + naranja, apoyada en blanco/negro
  static const Color _primario = Color(0xFF0EA5E9); // celeste
  static const Color _alerta = Color(0xFFF59E0B);
  static const Color _peligro = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierController>().cargarDatos();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _peligro),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final controller = context.read<SupplierController>();
      await SessionCleanup.clearProviders(context);
      final success = await controller.cerrarSesion();

      if (success && mounted) {
        Rutas.irAYLimpiar(context, Rutas.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      drawer: SupplierDrawer(onCerrarSesion: _cerrarSesion),
      body: Consumer<SupplierController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return _buildCargando();
          }

          if (controller.rolIncorrecto) {
            return _buildAccesoDenegado(controller.error ?? 'Acceso denegado');
          }

          if (controller.error != null) {
            return _buildError(controller.error!);
          }

          return _buildContenido(controller);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mi Negocio',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: _primario,
      foregroundColor: Colors.white,
      actions: [
        // Badge de verificación
        Consumer<SupplierController>(
          builder: (context, controller, child) {
            if (controller.verificado || controller.loading) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _alerta.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, color: _alerta, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Pendiente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _alerta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 22),
          onPressed: () => context.read<SupplierController>().refrescar(),
          tooltip: 'Actualizar',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(color: _primario),
          child: _buildTabBar(),
        ),
      ),
    );
  }

  Widget _buildContenido(SupplierController controller) {
    return TabBarView(
      controller: _tabController,
      children: const [
        ProductosTab(),
        PromocionesTab(),
        EstadisticasTab(),
      ],
    );
  }

  Widget _buildCargando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _primario, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(
            'Cargando...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        labelColor: _primario,
        unselectedLabelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Productos', icon: Icon(Icons.inventory_2_outlined, size: 20)),
          Tab(text: 'Promociones', icon: Icon(Icons.campaign_outlined, size: 20)),
          Tab(text: 'Stats', icon: Icon(Icons.bar_chart_outlined, size: 20)),
        ],
      ),
    );
  }


  Widget _buildAccesoDenegado(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
            Icons.block_outlined,size: 64,color: _alerta.withValues(alpha: 0.6),),
            const SizedBox(height: 20),
            const Text(
              'Acceso Denegado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Rutas.irAYLimpiar(context, Rutas.login),
              style: FilledButton.styleFrom(backgroundColor: _primario),
              child: const Text('Ir al Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,size: 64,color: _peligro.withValues(alpha: 0.6),),
            const SizedBox(height: 20),
            const Text(
              'Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<SupplierController>().refrescar(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: _primario),
            ),
          ],
        ),
      ),
    );
  }
}
