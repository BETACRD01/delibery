// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; 
// Configuracion base
import './config/rutas.dart';
import './config/api_config.dart';
import './services/servicio_notificacion.dart';
import './services/notification_handler.dart';
// import './services/ubicacion_service.dart'
import './services/auth_service.dart';
import './apis/subapis/http_client.dart';
// Providers
import './providers/proveedor_roles.dart';
import './providers/proveedor_carrito.dart';
import './providers/proveedor_pedido.dart';
import './providers/locale_provider.dart';
import './providers/notificaciones_provider.dart';
import './l10n/app_localizations.dart';
// Controllers Proveedor
import '../controllers/user/perfil_controller.dart';
import './controllers/supplier/supplier_controller.dart';
// Controller de Repartidorvg
import './controllers/delivery/repartidor_controller.dart';
// Services
import './services/pedido_service.dart';
// Screens for dynamic routing
import './screens/delivery/pantalla_ver_comprobante.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Notificacion background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }

  await _solicitarPermisosCriticos();

  try {
    await ApiConfig.initialize();
    debugPrint('Deteccion de red completada: ${ApiConfig.currentServerIp}');
  } catch (e) {
    debugPrint('Error detectando red: $e');
  }
  final apiClient = ApiClient();
  try {
    await apiClient.loadTokens();
    debugPrint('Tokens cargados desde almacenamiento');
  } catch (e) {
    debugPrint('Error cargando tokens: $e');
  }

  final hasToken = apiClient.isAuthenticated;
  debugPrint('Estado autenticacion: ${hasToken ? "Autenticado" : "No autenticado"}');

  if (hasToken && apiClient.accessToken != null) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('Servicio notificaciones iniciado');
    } catch (e) {
      debugPrint('Error servicio notificaciones: $e');
    }

    final authService = AuthService();
    final rolUsuario = authService.getRolCacheado()?.toUpperCase();
    debugPrint('Rol detectado: $rolUsuario');
  }

  // 5. Definir ruta inicial
  final initialRoute = hasToken ? Rutas.router : Rutas.login;
  debugPrint('Iniciando UI en ruta: $initialRoute');
  runApp(MyApp(
    initialRoute: initialRoute == Rutas.router ? Rutas.root : initialRoute,
    authToken: apiClient.accessToken,
  ));
}
Future<void> _solicitarPermisosCriticos() async {
  debugPrint('Solicitando permisos iniciales...');
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location, // Vital para ApiConfig
    Permission.notification,
  ].request();
  if (statuses[Permission.location]!.isGranted) {
    debugPrint('Permiso de ubicación concedido');
  } else {
    debugPrint('Permiso de ubicación DENEGADO. La detección de IP automática fallará.');
  }
}
class MyApp extends StatefulWidget {
  final String initialRoute;
  final String? authToken;

  const MyApp({
    super.key,
    this.initialRoute = Rutas.login,
    this.authToken,
  });
  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Inicializar NotificationHandler después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentContext != null) {
        try {
          final notificationHandler = NotificationHandler();
          notificationHandler.initialize(_navigatorKey.currentContext!);
          debugPrint('NotificationHandler inicializado en MyApp');
        } catch (e) {
          debugPrint('Error inicializando NotificationHandler: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupplierController()),
        ChangeNotifierProvider(create: (_) => RepartidorController()),
        ChangeNotifierProvider(create: (_) => ProveedorRoles()..inicializar()),
        ChangeNotifierProvider(create: (_) => ProveedorCarrito()),
        ChangeNotifierProvider(create: (_) => PerfilController()),
        ChangeNotifierProvider(create: (_) => NotificacionesProvider()),
        
        ChangeNotifierProvider(
        create: (_) => PedidoProvider(
        PedidoService(),
        ),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
       ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          final appLocale = localeProvider.locale ?? const Locale('es');
          return MaterialApp(
            title: 'JP Express',
            debugShowCheckedModeBanner: false,

            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: appLocale,

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4FC3F7)),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                foregroundColor: Colors.white,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            navigatorKey: _navigatorKey,
            initialRoute: widget.initialRoute,
            routes: Rutas.obtenerRutas(),

            onGenerateRoute: (settings) {
              // Manejar rutas con argumentos para notificaciones push
              if (settings.name == '/delivery/ver-comprobante') {
                final args = settings.arguments as Map<String, dynamic>?;
                final pagoId = args?['pagoId'] as int?;
                if (pagoId != null) {
                  return MaterialPageRoute(
                    builder: (_) => PantallaVerComprobante(pagoId: pagoId),
                    settings: settings,
                  );
                }
              }
              return null;
            },

            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => PantallaRutaNoEncontrada(
                  nombreRuta: settings.name ?? 'desconocida',
                ),
              );
            },

            navigatorObservers: [RouteLogger()],
          );
        },
      ),
    );
  }
}

class PantallaRutaNoEncontrada extends StatelessWidget {
  final String nombreRuta;
  const PantallaRutaNoEncontrada({super.key, required this.nombreRuta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error de Navegacion'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'La ruta "$nombreRuta" no existe',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Rutas.login,
                    (route) => false,
                  );
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('PUSH: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('POP: ${previousRoute?.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('REPLACE: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
  }
}
