// lib/screens/pantalla_router.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import './user/pantalla_inicio.dart'; 
import './supplier/pantalla_inicio_proveedor.dart';
import './delivery/pantalla_inicio_repartidor.dart';
import './admin/pantalla_dashboard.dart';

/// Router inteligente que redirige según el rol del usuario
class PantallaRouter extends StatefulWidget {
  const PantallaRouter({super.key});

  @override
  State<PantallaRouter> createState() => _PantallaRouterState();
}

class _PantallaRouterState extends State<PantallaRouter> {
  final _authService = AuthService();
  String? _error;

  @override
  void initState() {
    super.initState();
    // CORRECCIÓN CRÍTICA:
    // Utilizamos addPostFrameCallback para asegurar que el contexto esté listo
    // y el primer frame renderizado antes de intentar navegar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rutearSegunRol();
    });
  }

  Future<void> _rutearSegunRol() async {
    // Verificación de montaje por seguridad adicional al inicio
    if (!mounted) return;

    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('ROUTER: Determinando ruta según rol...');
      debugPrint('═══════════════════════════════════════════════════════');

      // 1. Verificar autenticación básica
      if (!_authService.isAuthenticated) {
        debugPrint('No autenticado - Redirigiendo a login');
        if (mounted) {
          // Usamos pushReplacementNamed para ir al login y evitar volver atrás
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // 2. Obtener rol desde caché
      String? rol = _authService.getRolCacheado()?.toUpperCase();
      debugPrint('Rol cacheado: ${rol ?? "NULL"}');

      // 3. Si no hay rol, intentar recargar desde la API (Tokens)
      if (rol == null || rol.isEmpty) {
        debugPrint('Rol nulo o vacío. Intentando recargar perfil/tokens...');
        try {
          await _authService.loadTokens();
          rol = _authService.getRolCacheado()?.toUpperCase();
          debugPrint('Rol después de recarga: ${rol ?? "NULL"}');
        } catch (e) {
          debugPrint('Advertencia: No se pudieron recargar tokens: $e');
        }
      }

      // 4. Fallback de seguridad: Si sigue nulo, asumir USUARIO
      if (rol == null || rol.isEmpty) {
        debugPrint('No se encontró rol tras intentos. Asignando rol: USUARIO');
        rol = 'USUARIO';
      }

      // 5. Ejecutar navegación
      if (mounted) {
        await _navegarSegunRol(rol);
      }

      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('Error crítico en router: $e');
      debugPrint('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = 'No se pudo iniciar sesión correctamente.\nVerifica tu conexión.';
        });
      }
    }
  }

  Future<void> _navegarSegunRol(String rol) async {
    // Nota: El delay aquí ya no es estrictamente necesario para evitar el crash
    // gracias al addPostFrameCallback, pero lo mantenemos breve para suavidad visual
    // si la carga es instantánea.
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    Widget destino;
    String nombreRuta;

    switch (rol) {
      case 'USUARIO':
        debugPrint('Rol identificado: USUARIO -> PantallaInicio (CON NAVEGACIÓN)');
        destino = const PantallaInicio(); 
        nombreRuta = 'PantallaInicio';
        break;

      case 'REPARTIDOR':
        debugPrint('Rol identificado: REPARTIDOR -> PantallaInicioRepartidor');
        destino = const PantallaInicioRepartidor();
        nombreRuta = 'PantallaInicioRepartidor';
        break;

      case 'PROVEEDOR':
        debugPrint('Rol identificado: PROVEEDOR -> PantallaInicioProveedor');
        destino = const PantallaInicioProveedor();
        nombreRuta = 'PantallaInicioProveedor';
        break;

      case 'ADMINISTRADOR':
      case 'STAFF':
        debugPrint('Rol identificado: ADMIN -> PantallaDashboard');
        destino = const PantallaDashboard();
        nombreRuta = 'PantallaDashboard';
        break;

      default:
        debugPrint('Rol desconocido ($rol) -> Redirigiendo a PantallaInicio');
        destino = const PantallaInicio();
        nombreRuta = 'PantallaInicio (Default)';
        break;
    }

    if (!mounted) return;

    // Navegación instantánea (sin animación de transición)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destino,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        settings: RouteSettings(name: nombreRuta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estado de Error
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _error = null);
                    // Reintentamos usando el callback de frame por consistencia
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       _rutearSegunRol();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Estado de Carga (Loading)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o Spinner
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Texto informativo
            Text(
              'Iniciando sesión...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}