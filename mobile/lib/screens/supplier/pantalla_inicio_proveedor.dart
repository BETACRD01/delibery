import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../controllers/supplier/supplier_controller.dart';
import 'perfil/perfil_proveedor_panel.dart';
import 'screens/pantalla_productos_proveedor.dart';
import 'tabs/estadisticas_tab.dart';
import 'tabs/promociones_tab.dart';

/// Pantalla principal para PROVEEDORES (iOS Native Style)
class PantallaInicioProveedor extends StatefulWidget {
  const PantallaInicioProveedor({super.key});

  @override
  State<PantallaInicioProveedor> createState() =>
      _PantallaInicioProveedorState();
}

class _PantallaInicioProveedorState extends State<PantallaInicioProveedor> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierController>().cargarDatos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        // activeColor: AppColorsPrimary.main, // Usar color del tema si estuviera disponible en el contexto cupertino
        activeColor: const Color(0xFF0CB7F2),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cube_box),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tag),
            label: 'Promos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.graph_square),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled),
            label: 'Perfil',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return const PantallaProductosProveedor();
              case 1:
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Promociones'),
                  ),
                  child: PromocionesTab(),
                );
              case 2:
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Estadísticas'),
                  ),
                  child: EstadisticasTab(),
                );
              case 3:
                return const PerfilProveedorEditable();
              default:
                return const PantallaProductosProveedor();
            }
          },
        );
      },
    );
  }
}
