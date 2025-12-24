# Guía Rápida de Servicios - Delibery

## 🚀 Quick Reference

### ¿Qué servicio usar para cada tarea?

#### 🔐 AUTENTICACIÓN

```dart
// Login y Registro
import 'services/auth_service.dart';
await AuthService().login(email: email, password: password);
await AuthService().loginWithGoogle(accessToken: token);
await AuthService().register(data);
await AuthService().logout();

// Recuperación de Contraseña
await AuthService().solicitarRecuperacion(email: email);
await AuthService().verificarCodigo(email: email, codigo: codigo);
await AuthService().resetPassword(email: email, codigo: codigo, nuevaPassword: password);
await AuthService().cambiarPassword(passwordActual: oldPass, nuevaPassword: newPass);

// Roles
await AuthService().cambiarRolActivo('PROVEEDOR');
final roles = await AuthService().obtenerRolesDisponibles();

// Estado
final isAuth = AuthService().isAuthenticated;
final user = AuthService().user; // UserInfo?
```

#### 👤 USUARIO

```dart
// Perfil
import 'services/features/user/profile_service.dart';
final profile = await ProfileService().getProfile();

// Direcciones
import 'services/features/user/address_service.dart';
final addresses = await AddressService().fetchAddresses();

// Métodos de Pago
import 'services/features/user/payment_method_service.dart';
final methods = await PaymentMethodService().fetchPaymentMethods();

// Rifas/Sorteos ← NUEVO
import 'services/features/user/raffle_service.dart';
final rifas = await RaffleService().obtenerRifasParticipaciones();

// Estadísticas y Notificaciones (aún en UsuarioService)
import 'services/usuarios_service.dart';
final stats = await UsuarioService().obtenerEstadisticas();
```

#### 🏪 PROVEEDOR

```dart
// Perfil del Proveedor
import 'services/proveedor_service.dart';
final proveedores = await ProveedorService().listarProveedores();

// Productos del Proveedor ← NUEVO
import 'services/supplier/supplier_products_service.dart';
final productos = await SupplierProductsService().obtenerProductosDelProveedorActual();
await SupplierProductsService().crearProductoProveedor(data, imagen: file);
```

#### 📦 PRODUCTOS (Catálogo Global)

```dart
// Productos globales (catálogo)
import 'services/productos_service.dart';
final productos = await ProductosService().obtenerProductos();
final categorias = await ProductosService().obtenerCategorias();

// Super categorías
import 'services/super_service.dart';
final superCategorias = await SuperService().obtenerSuperCategorias();
```

#### 🚚 REPARTIDOR

```dart
// Perfil y estadísticas
import 'services/repartidor_service.dart';
final perfil = await RepartidorService().obtenerPerfil();

// Ubicación en tiempo real
import 'services/ubicacion_service.dart';
await UbicacionService().iniciarRastreo();
await UbicacionService().detenerRastreo();

// Geolocalización local (sin backend)
import 'services/location_service.dart';
final ubicacion = await LocationService().obtenerUbicacionActual();
final distancia = LocationService().calcularDistancia(lat1, lng1, lat2, lng2);
```

#### 🛒 PEDIDOS Y CARRITO

```dart
// Carrito
import 'services/carrito_service.dart';
await CarritoService().agregar(productoId, cantidad);

// O mejor, usar el Provider:
import 'providers/proveedor_carrito.dart';
final carrito = Provider.of<ProveedorCarrito>(context);

// Pedidos
import 'services/pedido_service.dart';
final pedidos = await PedidoService().obtenerPedidos();

// Pagos
import 'services/pago_service.dart';
await PagoService().procesarPago(pedidoId, metodo);

// Envíos
import 'services/envio_service.dart';
final cotizacion = await EnvioService().cotizarEnvio(origen, destino);
```

#### 🌐 OTROS

```dart
// Calificaciones y reseñas
import 'services/calificaciones_service.dart';
await CalificacionesService().calificar(pedidoId, estrellas, comentario);

// Notificaciones UI (Toast)
import 'services/toast_service.dart';
ToastService().showSuccess(context, 'Mensaje');
ToastService().showError(context, 'Error');
ToastService().showWarning(context, 'Advertencia');

// Limpieza de sesión
import 'services/session_cleanup.dart';
await SessionCleanup.clearProviders(context);
```

---

## 📊 Mapeo Backend → Flutter

| Endpoint | Servicio | Archivo |
|----------|----------|---------|
| `/auth/login/` | AuthApi → AuthService | `apis/auth/auth_api.dart` |
| `/auth/registro/` | AuthApi → AuthService | `apis/auth/auth_api.dart` |
| `/auth/logout/` | AuthApi → AuthService | `apis/auth/auth_api.dart` |
| `/auth/recuperar-password/` | PasswordApi → AuthService | `apis/auth/password_api.dart` |
| `/auth/cambiar-password/` | PasswordApi → AuthService | `apis/auth/password_api.dart` |
| `/usuarios/cambiar-rol/` | RolesApi → AuthService | `apis/auth/roles_api.dart` |
| `/usuarios/perfil/` | ProfileService | `features/user/profile_service.dart` |
| `/usuarios/direcciones/` | AddressService | `features/user/address_service.dart` |
| `/usuarios/metodos-pago/` | PaymentMethodService | `features/user/payment_method_service.dart` |
| `/usuarios/rifas/` | RaffleService | `features/user/raffle_service.dart` |
| `/productos/provider/products/` | SupplierProductsService | `supplier/supplier_products_service.dart` |
| `/productos/productos/` | ProductosService | `productos_service.dart` |
| `/repartidores/ubicacion/` | UbicacionService | `ubicacion_service.dart` |
| `/pedidos/` | PedidoService | `pedido_service.dart` |
| `/productos/carrito/` | CarritoService | `carrito_service.dart` |

---

## ⚠️ Servicios Deprecated (Migrar Gradualmente)

```dart
// ❌ EVITAR (métodos deprecated):
UsuarioService().listarDirecciones()
UsuarioService().listarMetodosPago()
UsuarioService().obtenerRifas()
ProductosService().obtenerProductosDelProveedorActual()
ProductosService().crearProductoProveedor()

// ✅ USAR EN SU LUGAR:
AddressService().fetchAddresses()
PaymentMethodService().fetchPaymentMethods()
RaffleService().obtenerRifasParticipaciones()
SupplierProductsService().obtenerProductosDelProveedorActual()
SupplierProductsService().crearProductoProveedor()
```

---

## 📁 Estructura de Carpetas

```
apis/
├── auth/                   ← APIs de autenticación ✨ NUEVO
│   ├── auth_api.dart       (login, registro, logout)
│   ├── password_api.dart   (recuperación y cambio)
│   └── roles_api.dart      (gestión de roles)
│
├── user/                   ← APIs de usuario
│   ├── rifas_api.dart
│   ├── rifas_usuarios_api.dart
│   └── usuarios_api.dart
│
└── subapis/
    └── http_client.dart

models/
├── user_info.dart          ← Modelo de usuario ✨ NUEVO
├── producto_model.dart
├── categoria_model.dart
└── ...

services/
├── features/user/          ← Servicios de usuario especializados
│   ├── profile_service.dart
│   ├── address_service.dart
│   ├── payment_method_service.dart
│   └── raffle_service.dart
│
├── supplier/               ← Servicios de proveedor
│   └── supplier_products_service.dart
│
├── core/                   ← Infraestructura
│   ├── cache_service.dart
│   └── validation/
│
└── [otros servicios raíz]
    ├── auth_service.dart   (refactorizado - usa APIs) ✨
    ├── productos_service.dart
    ├── repartidor_service.dart
    ├── pedido_service.dart
    ├── carrito_service.dart
    └── ...
```

---

## 🔧 Tips de Uso

### 1. Singleton Pattern
Todos los servicios usan Singleton:
```dart
final service = MyService(); // Siempre retorna la misma instancia
```

### 2. Caché
Muchos servicios tienen caché interno:
```dart
// Primera llamada: consulta API
await ProfileService().getProfile();

// Segunda llamada: retorna desde caché
await ProfileService().getProfile();

// Forzar recarga:
await ProfileService().getProfile(forceReload: true);
```

### 3. Manejo de Errores
```dart
try {
  final data = await MyService().getData();
} on ApiException catch (e) {
  // Error de API (400, 500, etc)
  print(e.message);
  print(e.statusCode);
} catch (e) {
  // Otros errores (red, parsing, etc)
  print('Error: $e');
}
```

### 4. Provider vs Service
```dart
// Services: Lógica de negocio + API
final data = await MyService().getData();

// Providers: State management + UI reactivity
final provider = Provider.of<MyProvider>(context);
provider.cargarDatos();
```

---

## 📖 Documentación Completa

Para más detalles ver:
- `REORGANIZACION_SERVICIOS_COMPLETA.md` - Resumen completo
- `DISCREPANCIAS_BACKEND_FLUTTER.md` - Análisis técnico
- `MIGRACION_USUARIO_SERVICE.md` - Guía de migración
