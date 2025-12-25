// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../controllers/user/perfil_controller.dart';
import './apis/subapis/http_client.dart';
import './config/api_config.dart';
import './config/performance_config.dart';
import './config/rutas.dart';
import './controllers/delivery/repartidor_controller.dart';
import './controllers/supplier/supplier_controller.dart';
import './l10n/app_localizations.dart';
import './providers/locale_provider.dart';
import './providers/notificaciones_provider.dart';
import './providers/proveedor_carrito.dart';
import './providers/proveedor_pedido.dart';
import './screens/delivery/pantalla_ver_comprobante.dart';
import './services/auth/auth_service.dart';
import './services/notifications/notification_handler.dart';
import './services/pedidos/pedido_service.dart';
import './services/roles/role_manager.dart';
import './services/notifications/servicio_notificacion.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notificacion background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    // Ensure debug paint overlays are disabled.
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    debugRepaintRainbowEnabled = false;
    return true;
  }());

  // Inicializar optimizaciones de rendimiento
  PerformanceConfig.initialize();

  await _initFirebase();

  final apiClient = ApiClient();
  final initFutures = <Future<void>>[
    [Permission.location, Permission.notification].request().then((_) {}),
    ApiConfig.initialize().catchError((e) => debugPrint('Error red: $e')),
    apiClient.loadTokens().catchError((e) => debugPrint('Error tokens: $e')),
  ];
  await Future.wait(initFutures);

  if (apiClient.isAuthenticated && apiClient.accessToken != null) {
    // Verificar si la sesión es realmente válida antes de inicializar servicios
    final isSessionValid = await AuthService().verificarToken().catchError(
      (_) => false,
    );

    if (isSessionValid) {
      await NotificationService().initialize().catchError(
        (e) => debugPrint('Error notificaciones: $e'),
      );
      debugPrint(
        'Sesion valida - Rol: ${AuthService().getRolCacheado()?.toUpperCase()}',
      );
    } else {
      // Sesión inválida: limpiar tokens viejos silenciosamente
      debugPrint('Sesion expirada, redirigiendo a login...');
      await apiClient.clearTokens();
    }
  }

  runApp(
    MyApp(
      initialRoute: apiClient.isAuthenticated ? Rutas.root : Rutas.login,
      authToken: apiClient.accessToken,
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Error Firebase: $e');
  }
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  final String? authToken;

  const MyApp({super.key, this.initialRoute = Rutas.login, this.authToken});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Rutas.navigatorKey.currentContext != null) {
        NotificationHandler().initialize(Rutas.navigatorKey.currentContext!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupplierController()),
        ChangeNotifierProvider(create: (_) => RepartidorController()),
        ChangeNotifierProvider(create: (_) => RoleManager()..initialize()),
        ChangeNotifierProvider(create: (_) => ProveedorCarrito()),
        ChangeNotifierProvider(create: (_) => PerfilController()),
        ChangeNotifierProvider(create: (_) => NotificacionesProvider()),
        ChangeNotifierProvider(create: (_) => PedidoProvider(PedidoService())),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          title: 'JP Express',
          debugShowCheckedModeBanner: false,

          // Color de fondo para evitar pantallas negras durante transiciones
          color: Colors.white,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale ?? const Locale('es'),
          theme: AppTheme.lightTheme,
          navigatorKey: Rutas.navigatorKey,
          initialRoute: widget.initialRoute,
          routes: Rutas.obtenerRutas(),
          onGenerateRoute: _onGenerateRoute,
          onUnknownRoute: (s) => MaterialPageRoute(
            settings: s,
            builder: (_) => _PantallaError(ruta: s.name ?? 'desconocida'),
          ),

          // Builder para optimización de rendimiento
          builder: (context, child) {
            return MediaQuery(
              // Limitar escalado de texto para major rendimiento
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/delivery/ver-comprobante') {
      final pagoId =
          (settings.arguments as Map<String, dynamic>?)?['pagoId'] as int?;
      if (pagoId != null) {
        return MaterialPageRoute(
          builder: (_) => PantallaVerComprobante(pagoId: pagoId),
          settings: settings,
        );
      }
    }
    return null;
  }
}

class _PantallaError extends StatelessWidget {
  final String ruta;
  const _PantallaError({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error de Navegación'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'La ruta "$ruta" no existe',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Rutas.login,
                (_) => false,
              ),
              child: const Text('Volver al initio'),
            ),
          ],
        ),
      ),
    );
  }
}
