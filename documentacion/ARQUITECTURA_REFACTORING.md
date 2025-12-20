# 🏗️ Plan de Refactorización: Arquitectura en Capas

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Análisis de Situación Actual](#análisis-de-situación-actual)
3. [Problemas Identificados](#problemas-identificados)
4. [Arquitectura Propuesta](#arquitectura-propuesta)
5. [Reglas de Arquitectura](#reglas-de-arquitectura)
6. [Plan de Migración](#plan-de-migración)
7. [Ejemplos de Refactorización](#ejemplos-de-refactorización)

---

## 🎯 Resumen Ejecutivo

### Problema
La arquitectura actual tiene responsabilidades mezcladas entre `lib/apis/` y `lib/services/`:
- **15 de 17 servicios** (88%) hacen llamadas HTTP directas sin pasar por capa de APIs
- **Solo 2 servicios** (12%) usan correctamente la capa de APIs
- Validaciones de negocio ubicadas en `lib/apis/helpers/`
- Token management mezclado con HTTP client
- Código duplicado en construcción de URLs y manejo de errores

### Solución
Implementar arquitectura en capas limpia con separación clara de responsabilidades:

```
┌─────────────────────────────────────────────────┐
│              UI LAYER (Screens)                  │
│         Widgets, Providers, Controllers          │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│          BUSINESS LOGIC LAYER                    │
│              lib/services/                       │
│  • Validaciones                                  │
│  • Caching                                       │
│  • Transformación de modelos                     │
│  • Orquestación de múltiples APIs                │
│  • Reglas de negocio                             │
└──────────────────┬──────────────────────────────┘
                   │ ❌ NO acceso directo a HttpClient
                   ▼
┌─────────────────────────────────────────────────┐
│            API LAYER                             │
│              lib/apis/                           │
│  • Solo HTTP requests/responses                  │
│  • Mapeo de endpoints                            │
│  • Serialización JSON                            │
│  • Manejo de códigos HTTP                        │
└──────────────────┬──────────────────────────────┘
                   │ ❌ NO business logic
                   ▼
┌─────────────────────────────────────────────────┐
│          HTTP CLIENT LAYER                       │
│         lib/apis/core/http_client.dart          │
│  • Interceptors                                  │
│  • Headers management                            │
│  • Error handling HTTP                           │
│  • Logging                                       │
└─────────────────────────────────────────────────┘
```

### Métricas del Proyecto

| Métrica | Actual | Objetivo |
|---------|--------|----------|
| Servicios usando API layer | 2 (12%) | 17 (100%) |
| Servicios con ApiClient directo | 15 (88%) | 0 (0%) |
| Lógica de negocio en apis/ | Sí (api_validators.dart) | No |
| Duplicación URL building | Alta | Baja |
| Token management | En HttpClient | En AuthService |

---

## 📊 Análisis de Situación Actual

### Estructura Actual

```
lib/
├── apis/
│   ├── admin/ (7 archivos)
│   │   ├── acciones_admin_api.dart
│   │   ├── dashboard_admin_api.dart
│   │   ├── envios_admin_api.dart
│   │   ├── proveedores_admin_api.dart
│   │   ├── repartidores_admin_api.dart
│   │   ├── rifas_admin_api.dart
│   │   ├── solicitudes_api.dart
│   │   └── usuarios_admin_api.dart
│   ├── user/ (3 archivos)
│   │   ├── rifas_api.dart
│   │   ├── rifas_usuarios_api.dart
│   │   └── usuarios_api.dart
│   ├── helpers/
│   │   ├── api_exception.dart
│   │   └── api_validators.dart ⚠️ BUSINESS LOGIC EN APIs
│   └── subapis/
│       └── http_client.dart ⚠️ TOKEN MANAGEMENT MEZCLADO
│
└── services/ (21 archivos)
    ├── auth_service.dart ❌ Usa ApiClient directo
    ├── carrito_service.dart ❌ Usa ApiClient directo
    ├── envio_service.dart ❌ Usa ApiClient directo
    ├── location_service.dart
    ├── notification_handler.dart ✅ UI service (OK)
    ├── pago_service.dart ❌ Usa ApiClient directo
    ├── pedido_grupo_service.dart ❌ Usa ApiClient directo
    ├── pedido_service.dart ❌ Usa ApiClient directo
    ├── productos_service.dart ❌ Usa ApiClient directo
    ├── proveedor_service.dart ❌ Usa ApiClient directo
    ├── rastreo_inteligente_service.dart
    ├── repartidor_datos_bancarios_service.dart ❌ Usa ApiClient directo
    ├── repartidor_service.dart ❌ Usa ApiClient directo
    ├── role_manager.dart ❌ Usa ApiClient directo
    ├── roles_service.dart ❌ Usa ApiClient directo
    ├── servicio_notificacion.dart ✅ Usa API layer
    ├── solicitudes_service.dart ❌ Usa ApiClient directo
    ├── super_service.dart ❌ Usa ApiClient directo
    ├── toast_service.dart ✅ UI service (OK)
    ├── ubicacion_service.dart
    └── usuarios_service.dart ✅ Usa API layer
```

### Patrones Identificados

#### ✅ PATRÓN CORRECTO: Service → API Layer → HttpClient

**Ejemplo: `usuarios_service.dart`**

```dart
// lib/services/usuarios_service.dart
class UsuarioService {
  final _api = UsuariosApi();  // ✅ Usa capa de API

  PerfilModel? _perfilCache;  // ✅ Business logic: caching

  Future<PerfilModel> obtenerPerfil({bool forzarRecarga = false}) async {
    // ✅ Business logic: cache strategy
    if (!forzarRecarga && _perfilCache != null) {
      return _perfilCache!;
    }

    // ✅ Llama a API layer
    final response = await _api.obtenerPerfil();

    // ✅ Business logic: model transformation
    final perfilData = response['perfil'] as Map<String, dynamic>;
    _perfilCache = PerfilModel.fromJson(perfilData);

    return _perfilCache!;
  }
}
```

```dart
// lib/apis/user/usuarios_api.dart
class UsuariosApi {
  final _client = ApiClient();  // ✅ API usa HttpClient

  Future<Map<String, dynamic>> obtenerPerfil() async {
    // ✅ Solo HTTP request, sin business logic
    return await _client.get(ApiConfig.usuariosPerfil);
  }
}
```

**Responsabilidades bien separadas:**
- **Service**: Caching, model transformation, error enrichment
- **API**: Solo HTTP call y endpoint mapping

---

#### ❌ PATRÓN INCORRECTO: Service → ApiClient Directo

**Ejemplo 1: `auth_service.dart`**

```dart
// lib/services/auth_service.dart
class AuthService {
  final _client = ApiClient();  // ❌ Bypassing API layer

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    // ❌ Business logic mezclada con HTTP
    _normalizeData(data);
    _validateRequired(data);
    _validatePasswords(data);

    // ❌ Direct HTTP call
    final response = await _client.postPublic(ApiConfig.registro, data);

    // ❌ More business logic
    await _handleAuthResponse(response);
    return response;
  }

  // ❌ Validation logic in service but no API abstraction
  void _validateRequired(Map<String, dynamic> data) { ... }
  void _validatePasswords(Map<String, dynamic> data) { ... }
}
```

**Problemas:**
1. Service hace HTTP calls directos
2. No existe `auth_api.dart` para abstraer endpoints
3. Validaciones mezcladas con HTTP
4. Token management en `_handleAuthResponse` debería estar centralizado

---

**Ejemplo 2: `roles_service.dart`**

```dart
// lib/services/roles_service.dart
class RolesService {
  final _client = ApiClient();  // ❌ Direct ApiClient usage

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    // ❌ Business logic: transformation
    final response = await _client.post(
      ApiConfig.usuariosCambiarRolActivo,
      {'nuevo_rol': nuevoRol.toUpperCase()},
    );

    // ❌ Business logic: token management
    if (response.containsKey('tokens')) {
      await _client.saveTokens(...);
    }

    return response;
  }

  // ✅ Business logic correcto (pero falta API layer)
  bool esRolValido(String rol) => _rolesValidos.contains(rol);
  String obtenerNombreRol(String rol) => switch (rol) { ... };
}
```

**Problemas:**
1. Direct HTTP calls sin API abstraction
2. Token management mezclado (debería ser responsabilidad de AuthService)
3. No reutilización - si otra parte necesita cambiar rol, duplica código

---

**Ejemplo 3: `productos_service.dart`**

```dart
// lib/services/productos_service.dart
class ProductosService {
  final _client = ApiClient();  // ❌ Direct usage

  Future<List<ProductoModel>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
  }) async {
    // ❌ Business logic: URL building duplicado
    String url = ApiConfig.productosLista;
    final List<String> params = [];

    if (categoriaId != null) params.add('categoria_id=$categoriaId');
    if (proveedorId != null) params.add('proveedor_id=$proveedorId');
    if (soloOfertas) params.add('solo_ofertas=true');
    if (busqueda != null) params.add('search=${Uri.encodeComponent(busqueda)}');

    if (params.isNotEmpty) url += '?${params.join('&')}';

    // ❌ Direct HTTP call
    final response = await _client.get(url);

    // ✅ Business logic correcto: transformation
    final List<dynamic> data = _extraerLista(response);
    return data.map((json) => ProductoModel.fromJson(json)).toList();
  }
}
```

**Problemas:**
1. URL query building es lógica HTTP, no de negocio
2. Patrón duplicado en muchos servicios
3. Si cambia formato de URL, hay que modificar service (debería ser en API)

---

**Ejemplo 4: `carrito_service.dart`**

```dart
// lib/services/carrito_service.dart
class CarritoService {
  final _client = ApiClient();  // ❌ Direct usage

  Future<Map<String, dynamic>> agregarAlCarrito({
    required String productoId,
    int cantidad = 1,
  }) async {
    // ❌ Direct HTTP call con endpoint hardcoded
    final response = await _client.post(
      '${ApiConfig.apiUrl}/productos/carrito/agregar/',
      {
        'producto_id': int.parse(productoId),  // ✅ Business logic: parsing
        'cantidad': cantidad,
      },
    );

    return response;
  }
}
```

**Problemas:**
1. Endpoint construction manual (`${ApiConfig.apiUrl}/...`)
2. No abstracción de API - dificulta testing
3. Parsing de string a int debería ser en UI o API layer

---

#### ⚠️ CÓDIGO UBICADO INCORRECTAMENTE

**`lib/apis/helpers/api_validators.dart`**

```dart
// ❌ Business logic en carpeta apis/
class ApiValidators {
  static bool esEmailValido(String email) => ...;
  static Map<String, dynamic> validarPassword(String password) => ...;
  static bool esCelularValido(String celular) => ...;
  static bool esRucValido(String ruc) => ...;

  // ❌ Estas son validaciones de NEGOCIO, no de HTTP
}
```

**Problema:**
- Validaciones son lógica de negocio → deben estar en `lib/services/core/` o `lib/utils/`
- `apis/` debe contener solo código relacionado con HTTP

---

**`lib/apis/subapis/http_client.dart`**

```dart
// ❌ Token management mezclado con HTTP client
class ApiClient {
  String? _accessToken;
  String? _refreshToken;
  String? _userRole;

  Future<void> saveTokens(String access, String refresh, {
    String? role,
    int? userId,
  }) async {
    // ❌ Business logic: token lifecycle
    _accessToken = access;
    await _storage.write(key: 'access_token', value: access);
  }

  Future<void> cacheUserRole(String role) async {
    // ❌ Business logic: role management
    _userRole = role;
  }
}
```

**Problema:**
- Token lifecycle es responsabilidad de `AuthService`, no de HTTP client
- HTTP client debería solo USAR tokens, no gestionarlos

---

## 🔴 Problemas Identificados

### 1. Inconsistencia Arquitectónica

| Patrón | Cantidad | Porcentaje | Estado |
|--------|----------|------------|--------|
| Service → API Layer | 2 | 12% | ✅ Correcto |
| Service → ApiClient Directo | 15 | 88% | ❌ Incorrecto |

**Impacto:**
- Desarrolladores nuevos no saben qué patrón seguir
- Code reviews inconsistentes
- Código difícil de mantener

### 2. Responsabilidades Mezcladas

**En Services:**
- ✅ Business logic (correcto)
- ❌ HTTP calls directos (debería ser en APIs)
- ❌ URL building (debería ser en APIs)
- ❌ Token management (debería centralizarse)

**En APIs:**
- ✅ HTTP calls (correcto)
- ❌ Business validations (`api_validators.dart`)

**En HttpClient:**
- ✅ HTTP requests (correcto)
- ❌ Token lifecycle management (debería ser en AuthService)

### 3. Código Duplicado

**URL Query Building** (repetido en ~10 servicios):
```dart
String url = ApiConfig.baseUrl;
final params = [];
if (filter != null) params.add('filter=$filter');
if (params.isNotEmpty) url += '?${params.join('&')}';
```

**Error Handling** (repetido en todos los servicios):
```dart
try {
  final response = await _client.get(url);
  return response;
} catch (e) {
  throw ApiException(statusCode: 0, message: 'Error...', errors: {...});
}
```

**Token Saving** (duplicado en auth_service, roles_service):
```dart
await _client.saveTokens(tokens['access'], tokens['refresh'], role: role);
```

### 4. Tight Coupling

**15 servicios dependen directamente de:**
- `ApiClient` (implementación concreta)
- `ApiConfig` (configuración global)

**Problemas:**
- Dificulta testing (no se puede mockear fácilmente)
- Cambios en `ApiClient` afectan a 15 archivos
- No se puede cambiar HTTP library sin refactorizar todo

### 5. Dificultad para Testing

```dart
// ❌ Difícil de testear
class ProductosService {
  final _client = ApiClient();  // Singleton, no inyectable

  Future<List<ProductoModel>> obtener() async {
    final response = await _client.get(url);  // No se puede mockear
    return ...;
  }
}

// ✅ Fácil de testear
class ProductosService {
  final ProductosApi _api;  // Inyectable

  ProductosService([ProductosApi? api]) : _api = api ?? ProductosApi();

  Future<List<ProductoModel>> obtener() async {
    final response = await _api.obtenerProductos();  // Fácil mockear
    return ...;
  }
}
```

### 6. Escalabilidad Limitada

**Escenario:** Agregar un nuevo endpoint para productos
```dart
// ❌ Actual: Modificar ProductosService (business logic)
class ProductosService {
  Future<ProductoModel> obtenerProductoConRecomendaciones(int id) async {
    final url = '${ApiConfig.productosLista}$id/recomendaciones/';
    final response = await _client.get(url);
    // ... transformación
  }
}

// ✅ Propuesto: Modificar ProductosApi (HTTP layer)
class ProductosApi {
  Future<Map<String, dynamic>> obtenerProductoConRecomendaciones(int id) async {
    return await _client.get(ApiConfig.productoRecomendaciones(id));
  }
}

// Service no cambia
class ProductosService {
  Future<ProductoModel> obtenerProductoConRecomendaciones(int id) async {
    final response = await _api.obtenerProductoConRecomendaciones(id);
    // ... transformación
  }
}
```

---

## 🎯 Arquitectura Propuesta

### Estructura de Carpetas

```
lib/
├── apis/                              # HTTP LAYER
│   ├── core/                          # Core HTTP infrastructure
│   │   ├── http_client.dart          # HTTP client, interceptors
│   │   ├── api_exception.dart        # HTTP exceptions
│   │   └── api_config.dart           # Endpoint configuration
│   │
│   ├── auth/                          # Authentication endpoints
│   │   └── auth_api.dart             # registro, login, logout, refresh
│   │
│   ├── user/                          # User module endpoints
│   │   ├── usuarios_api.dart         # perfil, direcciones, métodos pago
│   │   └── rifas_api.dart            # rifas endpoints
│   │
│   ├── productos/                     # Products module endpoints
│   │   └── productos_api.dart        # productos, categorías, promociones
│   │
│   ├── pedidos/                       # Orders module endpoints
│   │   ├── pedidos_api.dart          # pedidos CRUD
│   │   └── carrito_api.dart          # carrito endpoints
│   │
│   ├── roles/                         # Roles module endpoints
│   │   └── roles_api.dart            # cambiar rol, obtener roles
│   │
│   └── admin/                         # Admin endpoints
│       ├── solicitudes_api.dart
│       ├── dashboard_api.dart
│       ├── proveedores_api.dart
│       ├── repartidores_api.dart
│       └── usuarios_api.dart
│
├── services/                          # BUSINESS LOGIC LAYER
│   ├── core/                          # Core services
│   │   ├── validators.dart           # Business validations
│   │   ├── transformers.dart         # Data transformations
│   │   └── cache_manager.dart        # Caching strategy
│   │
│   ├── auth/                          # Authentication business logic
│   │   ├── auth_service.dart         # login, register, token lifecycle
│   │   └── token_manager.dart        # token storage, refresh
│   │
│   ├── user/                          # User business logic
│   │   ├── usuarios_service.dart     # perfil, caching
│   │   └── roles_service.dart        # role switching, validation
│   │
│   ├── productos/                     # Products business logic
│   │   └── productos_service.dart    # filtering, sorting, caching
│   │
│   ├── pedidos/                       # Orders business logic
│   │   ├── pedidos_service.dart      # order orchestration
│   │   └── carrito_service.dart      # cart business rules
│   │
│   ├── delivery/                      # Delivery business logic
│   │   ├── repartidor_service.dart
│   │   └── rastreo_service.dart
│   │
│   └── ui/                            # UI services (OK to have)
│       ├── toast_service.dart
│       ├── notification_handler.dart
│       └── location_service.dart
│
├── models/                            # Data models
├── providers/                         # State management
└── screens/                           # UI layer
```

### Responsabilidades por Capa

#### 📡 API Layer (`lib/apis/`)

**Responsabilidad:** Solo HTTP communication

**Puede hacer:**
- ✅ HTTP requests (GET, POST, PATCH, DELETE)
- ✅ Endpoint mapping
- ✅ Request/Response JSON serialization
- ✅ HTTP error code handling
- ✅ Query parameters building
- ✅ Multipart form data

**NO puede hacer:**
- ❌ Business validations
- ❌ Data caching
- ❌ Model transformation
- ❌ Orchestration de múltiples endpoints
- ❌ Token lifecycle management

**Ejemplo:**

```dart
// lib/apis/productos/productos_api.dart
class ProductosApi {
  final _client = ApiClient();

  /// Obtiene productos con filtros opcionales
  Future<Map<String, dynamic>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
  }) async {
    // ✅ Query building es responsabilidad de API layer
    final params = <String, String>{};

    if (categoriaId != null) params['categoria_id'] = categoriaId;
    if (proveedorId != null) params['proveedor_id'] = proveedorId;
    if (soloOfertas) params['solo_ofertas'] = 'true';
    if (busqueda != null && busqueda.isNotEmpty) {
      params['search'] = busqueda;
    }

    final url = Uri.parse(ApiConfig.productosLista).replace(
      queryParameters: params.isNotEmpty ? params : null,
    );

    // ✅ Solo HTTP call, retorna JSON crudo
    return await _client.get(url.toString());
  }

  /// Obtiene detalle de un producto
  Future<Map<String, dynamic>> obtenerProducto(int id) async {
    return await _client.get(ApiConfig.productoDetalle(id));
  }

  // ❌ NO hacer esto en API layer
  // Future<ProductoModel> obtenerProducto(int id) async {
  //   final response = await _client.get(...);
  //   return ProductoModel.fromJson(response);  // ❌ Model transformation
  // }
}
```

---

#### 💼 Service Layer (`lib/services/`)

**Responsabilidad:** Business logic y orchestration

**Puede hacer:**
- ✅ Llamar a API layer (NOT ApiClient directly)
- ✅ Business validations
- ✅ Data caching
- ✅ Model transformation (JSON → Models)
- ✅ Orchestrate multiple API calls
- ✅ Implement business rules
- ✅ Error enrichment

**NO puede hacer:**
- ❌ HTTP requests directos
- ❌ Endpoint construction
- ❌ HTTP error handling bajo nivel

**Ejemplo:**

```dart
// lib/services/productos/productos_service.dart
class ProductosService {
  // ✅ Dependency injection de API layer
  final ProductosApi _api;

  ProductosService([ProductosApi? api]) : _api = api ?? ProductosApi();

  // ✅ Business logic: caching
  List<ProductoModel>? _productosCache;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  /// Obtiene productos con cache strategy
  Future<List<ProductoModel>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
    bool forzarRecarga = false,
  }) async {
    // ✅ Business logic: cache invalidation
    if (!forzarRecarga && _esValidoElCache()) {
      return _productosCache!;
    }

    // ✅ Llama a API layer
    final response = await _api.obtenerProductos(
      categoriaId: categoriaId,
      proveedorId: proveedorId,
      busqueda: busqueda,
      soloOfertas: soloOfertas,
    );

    // ✅ Business logic: data extraction y transformation
    final List<dynamic> data = response['results'] ?? response;
    final productos = data
        .map((json) => ProductoModel.fromJson(json))
        .toList();

    // ✅ Business logic: filtering (ejemplo)
    final productosFiltrados = productos
        .where((p) => p.disponible)
        .toList();

    // ✅ Business logic: caching
    _productosCache = productosFiltrados;
    _lastFetch = DateTime.now();

    return productosFiltrados;
  }

  bool _esValidoElCache() {
    if (_productosCache == null || _lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  /// Limpia el cache
  void invalidarCache() {
    _productosCache = null;
    _lastFetch = null;
  }
}
```

---

#### 🔐 Auth & Token Management

**Responsabilidad:** Centralizar gestión de autenticación

```dart
// lib/apis/auth/auth_api.dart
class AuthApi {
  final _client = ApiClient();

  /// ✅ Solo HTTP calls
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _client.postPublic(ApiConfig.login, {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return await _client.postPublic(ApiConfig.registro, data);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _client.postPublic(ApiConfig.refreshToken, {
      'refresh': refreshToken,
    });
  }
}
```

```dart
// lib/services/auth/token_manager.dart
class TokenManager {
  static const _storage = FlutterSecureStorage(...);

  String? _accessToken;
  String? _refreshToken;
  String? _userRole;
  int? _userId;

  /// ✅ Business logic: token storage
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    int? userId,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userRole = role;
    _userId = userId;

    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    if (role != null) await _storage.write(key: 'user_role', value: role);
  }

  /// ✅ Business logic: token retrieval
  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    return await _storage.read(key: 'access_token');
  }

  /// ✅ Business logic: clear tokens
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _userRole = null;
    _userId = null;

    await _storage.deleteAll();
  }
}
```

```dart
// lib/services/auth/auth_service.dart
class AuthService {
  final AuthApi _api;
  final TokenManager _tokenManager;

  AuthService({
    AuthApi? api,
    TokenManager? tokenManager,
  })  : _api = api ?? AuthApi(),
        _tokenManager = tokenManager ?? TokenManager();

  /// ✅ Business logic: validation + orchestration
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // ✅ Business logic: validation
    if (!Validators.esEmailValido(email)) {
      throw ValidationException('Email inválido');
    }

    if (password.length < 8) {
      throw ValidationException('Password debe tener al menos 8 caracteres');
    }

    // ✅ Llama a API
    final response = await _api.login(email, password);

    // ✅ Business logic: extract and save tokens
    final tokens = response['tokens'];
    await _tokenManager.saveTokens(
      accessToken: tokens['access'],
      refreshToken: tokens['refresh'],
      role: response['rol'],
      userId: response['user_id'],
    );

    // ✅ Business logic: model transformation
    final userData = response['user'];
    return UserModel.fromJson(userData);
  }

  /// ✅ Business logic: registration validation
  Future<UserModel> register(Map<String, dynamic> data) async {
    // ✅ Normalize
    data['email'] = data['email']?.toString().trim().toLowerCase();

    // ✅ Validate
    _validateRegistrationData(data);

    // ✅ Call API
    final response = await _api.register(data);

    // ✅ Save tokens
    final tokens = response['tokens'];
    await _tokenManager.saveTokens(
      accessToken: tokens['access'],
      refreshToken: tokens['refresh'],
      role: response['rol'],
      userId: response['user_id'],
    );

    return UserModel.fromJson(response['user']);
  }

  void _validateRegistrationData(Map<String, dynamic> data) {
    // ✅ Business validations
    final requiredFields = ['email', 'password', 'nombre', 'apellido'];
    for (final field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        throw ValidationException('$field es requerido');
      }
    }

    if (!Validators.esEmailValido(data['email'])) {
      throw ValidationException('Email inválido');
    }

    final passwordValidation = Validators.validarPassword(data['password']);
    if (!passwordValidation['valida']) {
      throw ValidationException(passwordValidation['errores'].join(', '));
    }
  }
}
```

---

## 📜 Reglas de Arquitectura

### Regla 1: Services NUNCA llaman ApiClient directamente

```dart
// ❌ MAL
class ProductosService {
  final _client = ApiClient();

  Future<List<ProductoModel>> obtener() async {
    final response = await _client.get(ApiConfig.productos);
    return ...;
  }
}

// ✅ BIEN
class ProductosService {
  final ProductosApi _api;

  ProductosService([ProductosApi? api]) : _api = api ?? ProductosApi();

  Future<List<ProductoModel>> obtener() async {
    final response = await _api.obtenerProductos();
    return ...;
  }
}
```

### Regla 2: APIs NUNCA hacen transformación de modelos

```dart
// ❌ MAL
class ProductosApi {
  Future<ProductoModel> obtenerProducto(int id) async {
    final response = await _client.get(ApiConfig.productoDetalle(id));
    return ProductoModel.fromJson(response);  // ❌ Model transformation
  }
}

// ✅ BIEN
class ProductosApi {
  Future<Map<String, dynamic>> obtenerProducto(int id) async {
    return await _client.get(ApiConfig.productoDetalle(id));
  }
}
```

### Regla 3: APIs retornan JSON crudo (Map/List)

```dart
// ✅ Retorno de APIs
Future<Map<String, dynamic>> obtenerPerfil();
Future<List<dynamic>> obtenerProductos();
Future<Map<String, dynamic>> crearPedido(Map<String, dynamic> data);
```

### Regla 4: Services retornan Models

```dart
// ✅ Retorno de Services
Future<PerfilModel> obtenerPerfil();
Future<List<ProductoModel>> obtenerProductos();
Future<PedidoModel> crearPedido(CrearPedidoRequest request);
```

### Regla 5: Validaciones en `lib/services/core/validators.dart`

```dart
// ✅ BIEN - lib/services/core/validators.dart
class Validators {
  static bool esEmailValido(String email) => ...;
  static Map<String, dynamic> validarPassword(String password) => ...;
}

// ❌ MAL - lib/apis/helpers/api_validators.dart
class ApiValidators {  // ❌ No debería estar en apis/
  static bool esEmailValido(String email) => ...;
}
```

### Regla 6: Caching SOLO en Services

```dart
// ✅ BIEN
class UsuarioService {
  PerfilModel? _perfilCache;

  Future<PerfilModel> obtenerPerfil({bool forzarRecarga = false}) async {
    if (!forzarRecarga && _perfilCache != null) return _perfilCache!;
    final response = await _api.obtenerPerfil();
    _perfilCache = PerfilModel.fromJson(response['perfil']);
    return _perfilCache!;
  }
}

// ❌ MAL - Cache en API layer
class UsuariosApi {
  PerfilModel? _cache;  // ❌ APIs no cachean
  ...
}
```

### Regla 7: Token Management en AuthService/TokenManager

```dart
// ❌ MAL - Token management en HttpClient
class ApiClient {
  Future<void> saveTokens(...) async { ... }  // ❌ Business logic
}

// ✅ BIEN - Token management en TokenManager
class TokenManager {
  Future<void> saveTokens(...) async { ... }
}
```

### Regla 8: Dependency Injection para Testability

```dart
// ✅ BIEN - Inyectable para testing
class ProductosService {
  final ProductosApi _api;

  ProductosService([ProductosApi? api]) : _api = api ?? ProductosApi();
}

// Test:
final mockApi = MockProductosApi();
final service = ProductosService(mockApi);

// ❌ MAL - No inyectable
class ProductosService {
  final _api = ProductosApi();  // ❌ Hardcoded, no se puede mockear
}
```

---

## 🚀 Plan de Migración

### Fase 1: Preparación (1-2 días)

**Objetivo:** Crear infraestructura nueva sin romper código existente

#### 1.1 Crear estructura de carpetas

```bash
mkdir -p lib/apis/{core,auth,user,productos,pedidos,roles}
mkdir -p lib/services/{core,auth,user,productos,pedidos,delivery,ui}
```

#### 1.2 Mover archivos core

```bash
# HTTP Client (ya existe)
# lib/apis/subapis/http_client.dart → lib/apis/core/http_client.dart

# API Exception (ya existe)
# lib/apis/helpers/api_exception.dart → lib/apis/core/api_exception.dart

# Validators (mover de apis/ a services/)
# lib/apis/helpers/api_validators.dart → lib/services/core/validators.dart
```

#### 1.3 Crear TokenManager

```dart
// lib/services/auth/token_manager.dart
class TokenManager {
  // Extraer token management de ApiClient
}
```

#### 1.4 Crear APIs faltantes

**Lista de APIs a crear:**

1. `lib/apis/auth/auth_api.dart` - Para AuthService
2. `lib/apis/productos/productos_api.dart` - Para ProductosService
3. `lib/apis/pedidos/carrito_api.dart` - Para CarritoService
4. `lib/apis/pedidos/pedidos_api.dart` - Para PedidoService
5. `lib/apis/roles/roles_api.dart` - Para RolesService

**Esfuerzo:** 3-4 horas

---

### Fase 2: Migración por Módulo (5-10 días)

**Estrategia:** Migrar módulo por módulo, probando después de cada uno

#### Módulo 1: Auth (CRÍTICO)

**Archivos a refactorizar:**
1. `lib/services/auth_service.dart`
2. `lib/apis/auth/auth_api.dart` (crear)
3. `lib/services/auth/token_manager.dart` (crear)

**Pasos:**
1. Crear `AuthApi` con endpoints: login, register, logout, refreshToken
2. Crear `TokenManager` para gestión de tokens
3. Refactorizar `AuthService` para usar `AuthApi` + `TokenManager`
4. Testing completo de flujo de autenticación
5. Commit: `refactor(auth): separate auth API and service layers`

**Esfuerzo:** 4-6 horas

---

#### Módulo 2: Usuarios

**Archivos:**
- `lib/apis/user/usuarios_api.dart` (ya existe ✅)
- `lib/services/user/usuarios_service.dart` (ya correcto ✅)

**Pasos:**
1. Verificar que UsuarioService use UsuariosApi correctamente ✅
2. Verificar tests
3. Commit: `refactor(usuarios): verify service-api separation`

**Esfuerzo:** 1 hora (solo verificación)

---

#### Módulo 3: Roles

**Archivos a refactorizar:**
1. `lib/services/roles_service.dart`
2. `lib/apis/roles/roles_api.dart` (crear)

**Pasos:**
1. Crear `RolesApi` con endpoints:
   - `obtenerRolesDisponibles()`
   - `cambiarRolActivo(String nuevoRol)`
2. Refactorizar `RolesService`:
   - Llamar a `RolesApi` en lugar de `ApiClient`
   - Mover token saving a `TokenManager`
3. Testing de cambio de rol
4. Commit: `refactor(roles): separate roles API and service layers`

**Esfuerzo:** 3-4 horas

---

#### Módulo 4: Productos

**Archivos a refactorizar:**
1. `lib/services/productos_service.dart`
2. `lib/apis/productos/productos_api.dart` (crear)

**Pasos:**
1. Crear `ProductosApi` con endpoints:
   - `obtenerProductos({filtros})`
   - `obtenerProducto(int id)`
   - `obtenerCategorias()`
   - `obtenerPromociones()`
2. Mover URL building de Service a API
3. Refactorizar `ProductosService`:
   - Llamar a `ProductosApi`
   - Mantener caching y transformación
4. Testing de productos, categorías, promociones
5. Commit: `refactor(productos): separate productos API and service layers`

**Esfuerzo:** 5-6 horas

---

#### Módulo 5: Pedidos & Carrito

**Archivos a refactorizar:**
1. `lib/services/carrito_service.dart`
2. `lib/services/pedido_service.dart`
3. `lib/apis/pedidos/carrito_api.dart` (crear)
4. `lib/apis/pedidos/pedidos_api.dart` (crear)

**Pasos:**
1. Crear `CarritoApi` con endpoints:
   - `obtenerCarrito()`
   - `agregarAlCarrito(productoId, cantidad)`
   - `actualizarCantidad(itemId, cantidad)`
   - `eliminarItem(itemId)`
2. Crear `PedidosApi` con endpoints:
   - `listarPedidos({filtros})`
   - `obtenerDetalle(pedidoId)`
   - `crearPedido(data)`
   - `cambiarEstado(pedidoId, estado)`
3. Refactorizar `CarritoService` y `PedidoService`
4. Testing de flujo completo: agregar al carrito → crear pedido
5. Commit: `refactor(pedidos): separate pedidos/carrito API and service layers`

**Esfuerzo:** 6-8 horas

---

#### Módulo 6: Delivery (Repartidor, Proveedor)

**Archivos a refactorizar:**
1. `lib/services/repartidor_service.dart`
2. `lib/services/proveedor_service.dart`
3. Crear APIs correspondientes

**Esfuerzo:** 4-6 horas

---

#### Módulo 7: Admin

**Archivos:**
- APIs admin ya existen ✅
- Crear services si no existen

**Esfuerzo:** 2-3 horas

---

### Fase 3: Cleanup (1-2 días)

#### 3.1 Eliminar código obsoleto

- Remover `api_validators.dart` de `apis/helpers/`
- Limpiar `http_client.dart` (remover token management)

#### 3.2 Mover archivos a nueva estructura

```bash
# Mover validators
mv lib/apis/helpers/api_validators.dart lib/services/core/validators.dart

# Limpiar carpeta helpers si quedó vacía
```

#### 3.3 Actualizar imports en toda la app

```dart
// Actualizar imports
// Viejo:
import '../apis/helpers/api_validators.dart';

// Nuevo:
import '../services/core/validators.dart';
```

**Esfuerzo:** 2-3 horas

---

### Fase 4: Testing & Verificación (2-3 días)

#### 4.1 Testing por módulo

- [ ] Auth: Login, register, logout, refresh token
- [ ] Usuarios: Perfil, direcciones, métodos pago
- [ ] Roles: Cambio de rol, obtener roles
- [ ] Productos: Listar, filtrar, búsqueda
- [ ] Carrito: Agregar, actualizar, eliminar
- [ ] Pedidos: Crear, listar, cambiar estado

#### 4.2 Testing de integración

- [ ] Flujo completo: Login → Agregar al carrito → Crear pedido
- [ ] Cambio de rol → Verificar endpoints correctos
- [ ] Refresh token automático

#### 4.3 Performance testing

- [ ] Verificar que caching funcione
- [ ] No degradación de performance

**Esfuerzo:** 8-12 horas

---

### Fase 5: Documentación (1 día)

#### 5.1 Actualizar README

```markdown
## Arquitectura

### Capas

1. **API Layer** (`lib/apis/`): HTTP communication
2. **Service Layer** (`lib/services/`): Business logic
3. **UI Layer** (`lib/screens/`): Widgets y estado

### Reglas

- Services SOLO llaman a APIs
- APIs retornan JSON crudo
- Services retornan Models
- Validaciones en `services/core/validators.dart`
```

#### 5.2 Crear guías para desarrolladores

- Cómo agregar un nuevo endpoint
- Cómo agregar validaciones
- Cómo escribir tests

**Esfuerzo:** 3-4 horas

---

## 🔄 Ejemplos de Refactorización

### Ejemplo 1: AuthService

#### ANTES (❌ Patrón incorrecto)

```dart
// lib/services/auth_service.dart
class AuthService {
  final _client = ApiClient();  // ❌ Direct usage

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    // ❌ Business logic + HTTP mezclados
    _normalizeData(data);
    _validateRequired(data);
    _validatePasswords(data);

    final response = await _client.postPublic(ApiConfig.registro, data);

    await _handleAuthResponse(response);
    return response;
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> response) async {
    // ❌ Token management en Service
    final tokens = response['tokens'];
    await _client.saveTokens(
      tokens['access'],
      tokens['refresh'],
      role: response['rol'],
      userId: response['user_id'],
    );
  }
}
```

#### DESPUÉS (✅ Patrón correcto)

```dart
// lib/apis/auth/auth_api.dart
class AuthApi {
  final _client = ApiClient();

  /// Solo HTTP calls
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return await _client.postPublic(ApiConfig.registro, data);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _client.postPublic(ApiConfig.login, {
      'email': email,
      'password': password,
    });
  }
}
```

```dart
// lib/services/auth/token_manager.dart
class TokenManager {
  static const _storage = FlutterSecureStorage(...);

  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
    int? userId,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    if (role != null) await _storage.write(key: 'user_role', value: role);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }
}
```

```dart
// lib/services/auth/auth_service.dart
class AuthService {
  final AuthApi _api;
  final TokenManager _tokenManager;

  AuthService({AuthApi? api, TokenManager? tokenManager})
      : _api = api ?? AuthApi(),
        _tokenManager = tokenManager ?? TokenManager();

  /// Business logic: validation + orchestration
  Future<UserModel> register(Map<String, dynamic> data) async {
    // ✅ Business logic: normalize
    data['email'] = data['email']?.toString().trim().toLowerCase();

    // ✅ Business logic: validate
    _validateRegistrationData(data);

    // ✅ Call API layer
    final response = await _api.register(data);

    // ✅ Business logic: save tokens through TokenManager
    final tokens = response['tokens'];
    await _tokenManager.saveTokens(
      accessToken: tokens['access'],
      refreshToken: tokens['refresh'],
      role: response['rol'],
      userId: response['user_id'],
    );

    // ✅ Business logic: model transformation
    return UserModel.fromJson(response['user']);
  }

  void _validateRegistrationData(Map<String, dynamic> data) {
    // ✅ Business validations
    final requiredFields = ['email', 'password', 'nombre', 'apellido'];
    for (final field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        throw ValidationException('$field es requerido');
      }
    }

    if (!Validators.esEmailValido(data['email'])) {
      throw ValidationException('Email inválido');
    }

    final passwordValidation = Validators.validarPassword(data['password']);
    if (!passwordValidation['valida']) {
      throw ValidationException(passwordValidation['errores'].join(', '));
    }
  }
}
```

**Beneficios:**
- ✅ AuthApi testeable independientemente
- ✅ TokenManager reutilizable por otros servicios
- ✅ AuthService enfocado en business logic
- ✅ Fácil mockear para tests

---

### Ejemplo 2: ProductosService

#### ANTES (❌ Patrón incorrecto)

```dart
// lib/services/productos_service.dart
class ProductosService {
  final _client = ApiClient();  // ❌ Direct usage

  Future<List<ProductoModel>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
  }) async {
    // ❌ URL building en Service (HTTP concern)
    String url = ApiConfig.productosLista;
    final List<String> params = [];

    if (categoriaId != null) params.add('categoria_id=$categoriaId');
    if (proveedorId != null) params.add('proveedor_id=$proveedorId');
    if (soloOfertas) params.add('solo_ofertas=true');

    if (busqueda != null && busqueda.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(busqueda)}');
    }

    if (params.isNotEmpty) url += '?${params.join('&')}';

    // ❌ Direct HTTP call
    final response = await _client.get(url);

    // ✅ Business logic: transformation (correcto)
    final List<dynamic> data = _extraerLista(response);
    return data.map((json) => ProductoModel.fromJson(json)).toList();
  }
}
```

#### DESPUÉS (✅ Patrón correcto)

```dart
// lib/apis/productos/productos_api.dart
class ProductosApi {
  final _client = ApiClient();

  /// ✅ HTTP layer: query building + HTTP call
  Future<Map<String, dynamic>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
  }) async {
    // ✅ Query building es responsabilidad de API
    final params = <String, String>{};

    if (categoriaId != null) params['categoria_id'] = categoriaId;
    if (proveedorId != null) params['proveedor_id'] = proveedorId;
    if (soloOfertas) params['solo_ofertas'] = 'true';
    if (busqueda != null && busqueda.isNotEmpty) {
      params['search'] = busqueda;
    }

    final url = Uri.parse(ApiConfig.productosLista).replace(
      queryParameters: params.isNotEmpty ? params : null,
    );

    // ✅ Retorna JSON crudo
    return await _client.get(url.toString());
  }

  Future<Map<String, dynamic>> obtenerCategoria(String id) async {
    return await _client.get(ApiConfig.categoriaDetalle(id));
  }
}
```

```dart
// lib/services/productos/productos_service.dart
class ProductosService {
  final ProductosApi _api;

  ProductosService([ProductosApi? api]) : _api = api ?? ProductosApi();

  // ✅ Business logic: caching
  List<ProductoModel>? _productosCache;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  Future<List<ProductoModel>> obtenerProductos({
    String? categoriaId,
    String? proveedorId,
    String? busqueda,
    bool soloOfertas = false,
    bool forzarRecarga = false,
  }) async {
    // ✅ Business logic: cache strategy
    if (!forzarRecarga && _esValidoElCache()) {
      return _productosCache!;
    }

    // ✅ Call API layer
    final response = await _api.obtenerProductos(
      categoriaId: categoriaId,
      proveedorId: proveedorId,
      busqueda: busqueda,
      soloOfertas: soloOfertas,
    );

    // ✅ Business logic: data extraction
    final List<dynamic> data = response['results'] ?? response;

    // ✅ Business logic: transformation
    final productos = data
        .map((json) => ProductoModel.fromJson(json))
        .toList();

    // ✅ Business logic: filtering
    final productosFiltrados = productos
        .where((p) => p.disponible)
        .toList();

    // ✅ Business logic: caching
    _productosCache = productosFiltrados;
    _lastFetch = DateTime.now();

    return productosFiltrados;
  }

  bool _esValidoElCache() {
    if (_productosCache == null || _lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  void invalidarCache() {
    _productosCache = null;
    _lastFetch = null;
  }
}
```

**Beneficios:**
- ✅ ProductosApi maneja solo HTTP concerns
- ✅ ProductosService enfocado en business logic y caching
- ✅ Fácil cambiar formato de URL sin tocar Service
- ✅ Testeable: mock ProductosApi fácilmente

---

### Ejemplo 3: RolesService

#### ANTES (❌ Patrón incorrecto)

```dart
// lib/services/roles_service.dart
class RolesService {
  final _client = ApiClient();  // ❌ Direct usage

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    // ❌ Business logic + HTTP + Token management mezclados
    final response = await _client.post(
      ApiConfig.usuariosCambiarRolActivo,
      {'nuevo_rol': nuevoRol.toUpperCase()},
    );

    // ❌ Token management en RolesService
    if (response.containsKey('tokens')) {
      final tokens = response['tokens'];
      await _client.saveTokens(
        tokens['access'],
        tokens['refresh'],
        role: tokens['rol'],
      );
    }

    return response;
  }
}
```

#### DESPUÉS (✅ Patrón correcto)

```dart
// lib/apis/roles/roles_api.dart
class RolesApi {
  final _client = ApiClient();

  /// ✅ Solo HTTP call
  Future<Map<String, dynamic>> obtenerRolesDisponibles() async {
    return await _client.get(ApiConfig.usuariosMisRoles);
  }

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    return await _client.post(ApiConfig.usuariosCambiarRolActivo, {
      'nuevo_rol': nuevoRol,
    });
  }
}
```

```dart
// lib/services/user/roles_service.dart
class RolesService {
  final RolesApi _api;
  final TokenManager _tokenManager;

  RolesService({
    RolesApi? api,
    TokenManager? tokenManager,
  })  : _api = api ?? RolesApi(),
        _tokenManager = tokenManager ?? TokenManager();

  Future<Map<String, dynamic>> cambiarRolActivo(String nuevoRol) async {
    // ✅ Business logic: validation
    if (!esRolValido(nuevoRol)) {
      throw ValidationException('Rol inválido: $nuevoRol');
    }

    // ✅ Business logic: transformation
    final rolNormalizado = nuevoRol.toUpperCase();

    // ✅ Call API layer
    final response = await _api.cambiarRolActivo(rolNormalizado);

    // ✅ Business logic: token update through TokenManager
    if (response.containsKey('tokens')) {
      final tokens = response['tokens'];
      await _tokenManager.saveTokens(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
        role: tokens['rol'],
      );
    }

    return response;
  }

  // ✅ Business logic: validations
  static const _rolesValidos = ['USUARIO', 'PROVEEDOR', 'REPARTIDOR', 'ADMINISTRADOR'];

  bool esRolValido(String rol) => _rolesValidos.contains(rol.toUpperCase());

  String obtenerNombreRol(String rol) => switch (rol.toUpperCase()) {
        'USUARIO' || 'CLIENTE' => 'Cliente',
        'PROVEEDOR' => 'Proveedor',
        'REPARTIDOR' => 'Repartidor',
        'ADMINISTRADOR' => 'Administrador',
        _ => rol,
      };
}
```

**Beneficios:**
- ✅ RolesApi maneja solo HTTP
- ✅ TokenManager centraliza gestión de tokens
- ✅ RolesService enfocado en business rules
- ✅ Reutilizable y testeable

---

## 📊 Checklist de Migración

### Fase 1: Preparación ☐
- [ ] Crear estructura de carpetas
- [ ] Mover `api_validators.dart` a `services/core/validators.dart`
- [ ] Crear `TokenManager` en `services/auth/`
- [ ] Actualizar imports de `validators`

### Fase 2: Migración por Módulo ☐

#### Módulo Auth ☐
- [ ] Crear `lib/apis/auth/auth_api.dart`
- [ ] Implementar endpoints: login, register, logout, refresh
- [ ] Refactorizar `AuthService` para usar `AuthApi`
- [ ] Mover token management a `TokenManager`
- [ ] Testing de autenticación completo
- [ ] Commit

#### Módulo Usuarios ☐
- [ ] Verificar `UsuariosApi` existente
- [ ] Verificar `UsuarioService` usa `UsuariosApi`
- [ ] Testing
- [ ] Commit

#### Módulo Roles ☐
- [ ] Crear `lib/apis/roles/roles_api.dart`
- [ ] Implementar endpoints roles
- [ ] Refactorizar `RolesService`
- [ ] Testing cambio de rol
- [ ] Commit

#### Módulo Productos ☐
- [ ] Crear `lib/apis/productos/productos_api.dart`
- [ ] Mover URL building de Service a API
- [ ] Refactorizar `ProductosService`
- [ ] Testing productos, categorías
- [ ] Commit

#### Módulo Pedidos & Carrito ☐
- [ ] Crear `lib/apis/pedidos/carrito_api.dart`
- [ ] Crear `lib/apis/pedidos/pedidos_api.dart`
- [ ] Refactorizar `CarritoService`
- [ ] Refactorizar `PedidoService`
- [ ] Testing flujo completo
- [ ] Commit

#### Módulo Delivery ☐
- [ ] Crear APIs para repartidor/proveedor
- [ ] Refactorizar services correspondientes
- [ ] Testing
- [ ] Commit

### Fase 3: Cleanup ☐
- [ ] Eliminar código obsoleto
- [ ] Limpiar `http_client.dart`
- [ ] Actualizar todos los imports
- [ ] Commit

### Fase 4: Testing ☐
- [ ] Testing de cada módulo
- [ ] Testing de integración
- [ ] Performance testing
- [ ] Verificar no hay regresiones

### Fase 5: Documentación ☐
- [ ] Actualizar README con arquitectura
- [ ] Crear guía para desarrolladores
- [ ] Documentar reglas de arquitectura
- [ ] Commit final

---

## 🎯 Métricas de Éxito

| Métrica | Antes | Objetivo |
|---------|-------|----------|
| **Arquitectura** |
| Services usando API layer | 2 (12%) | 17 (100%) |
| Services con ApiClient directo | 15 (88%) | 0 (0%) |
| Lógica de negocio en apis/ | Sí | No |
| **Código** |
| Duplicación URL building | ~10 lugares | 0 |
| Token management centralizado | No | Sí |
| Testability score | Bajo | Alto |
| **Calidad** |
| Coverage de tests | ? | 70%+ |
| Compilación sin warnings | ? | ✅ |
| Tiempo de build | Baseline | ≤ Baseline |

---

## 📝 Conclusión

Esta refactorización logrará:

1. **Arquitectura limpia**: Separación clara entre HTTP communication y business logic
2. **Mantenibilidad**: Código organizado, fácil de entender y modificar
3. **Escalabilidad**: Agregar nuevas features sin romper código existente
4. **Testabilidad**: Fácil escribir tests unitarios con mocks
5. **Consistencia**: Un solo patrón arquitectónico en toda la app
6. **Reducción de duplicación**: Código HTTP y validaciones centralizados

**Tiempo estimado total:** 3-4 semanas (15-20 días de desarrollo activo)

**Riesgo:** Medio (mitigado por migración incremental y testing exhaustivo)

**ROI:** Alto (mejora significativa en mantenibilidad y escalabilidad a largo plazo)

---

**Documento generado:** 2025-12-20
**Autor:** Claude Sonnet 4.5
**Proyecto:** Delibery Mobile - Refactorización Arquitectónica
