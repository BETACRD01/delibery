// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import './config/rutas.dart';
import './config/api_config.dart';
import './services/servicio_notificacion.dart';
import './services/notification_handler.dart';
import './services/auth_service.dart';
import './apis/subapis/http_client.dart';
import './providers/proveedor_carrito.dart';
import './providers/proveedor_pedido.dart';
import './providers/locale_provider.dart';
import './providers/notificaciones_provider.dart';
import './l10n/app_localizations.dart';
import '../controllers/user/perfil_controller.dart';
import './controllers/supplier/supplier_controller.dart';
import './controllers/delivery/repartidor_controller.dart';
import './services/pedido_service.dart';
import './screens/delivery/pantalla_ver_comprobante.dart';
import './services/role_manager.dart';

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

  await _initFirebase();
  await [Permission.location, Permission.notification].request();
  await ApiConfig.initialize().catchError((e) => debugPrint('Error red: $e'));

  final apiClient = ApiClient();
  await apiClient.loadTokens().catchError(
    (e) => debugPrint('Error tokens: $e'),
  );

  if (apiClient.isAuthenticated && apiClient.accessToken != null) {
    await NotificationService().initialize().catchError(
      (e) => debugPrint('Error notificaciones: $e'),
    );
    debugPrint('Rol: ${AuthService().getRolCacheado()?.toUpperCase()}');
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
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentContext != null) {
        NotificationHandler().initialize(_navigatorKey.currentContext!);
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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale ?? const Locale('es'),
          theme: _buildTheme(),
          navigatorKey: _navigatorKey,
          initialRoute: widget.initialRoute,
          routes: Rutas.obtenerRutas(),
          onGenerateRoute: _onGenerateRoute,
          onUnknownRoute: (s) => MaterialPageRoute(
            settings: s,
            builder: (_) => _PantallaError(ruta: s.name ?? 'desconocida'),
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    final radius = BorderRadius.circular(12);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4FC3F7)),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
