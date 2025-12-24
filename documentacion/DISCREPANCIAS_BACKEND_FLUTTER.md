# Discrepancias Backend-Flutter - Proyecto Delibery

## ✅ Limpieza Realizada

### Eliminaciones Completadas:
1. **11 carpetas vacías eliminadas:**
   - `/mobile/lib/services/auth/`
   - `/mobile/lib/services/delivery/`
   - `/mobile/lib/services/pedidos/`
   - `/mobile/lib/services/productos/`
   - `/mobile/lib/services/ui/`
   - `/mobile/lib/services/user/`
   - `/mobile/lib/apis/auth/`
   - `/mobile/lib/apis/core/`
   - `/mobile/lib/apis/pedidos/`
   - `/mobile/lib/apis/productos/`
   - `/mobile/lib/apis/roles/`

2. **Servicios duplicados eliminados:**
   - `rastreo_inteligente_service.dart` (duplicado de ubicacion_service.dart)

---

## 🔍 Discrepancias Críticas Identificadas

### 1. USUARIO - Direcciones (DUPLICACIÓN)

**Backend:**
```
usuarios/urls.py
├── GET    /api/usuarios/direcciones/
├── POST   /api/usuarios/direcciones/
├── PUT    /api/usuarios/direcciones/<uuid:direccion_id>/
├── DELETE /api/usuarios/direcciones/<uuid:direccion_id>/
└── PUT    /api/usuarios/direcciones/predeterminada/
```

**Flutter - PROBLEMA:**
```
Dos servicios hacen lo mismo:

1. UsuarioService (services/usuarios_service.dart)
   └── listarDirecciones()
   └── agregarDireccion()
   └── eliminarDireccion()

2. AddressService (services/features/user/address_service.dart)
   └── fetchAddresses()
   └── createAddress()
   └── deleteAddress()
   └── setDefaultAddress()
```

**Solución:** Usar SOLO `AddressService` y eliminar métodos de direcciones de `UsuarioService`

---

### 2. USUARIO - Métodos de Pago (DUPLICACIÓN)

**Backend:**
```
usuarios/urls.py
├── GET    /api/usuarios/metodos-pago/
├── POST   /api/usuarios/metodos-pago/
└── DELETE /api/usuarios/metodos-pago/<uuid:metodo_id>/
```

**Flutter - PROBLEMA:**
```
Dos servicios hacen lo mismo:

1. UsuarioService (services/usuarios_service.dart)
   └── listarMetodosPago()
   └── agregarMetodoPago()

2. PaymentMethodService (services/features/user/payment_method_service.dart)
   └── fetchPaymentMethods()
   └── createPaymentMethod()
   └── deletePaymentMethod()
```

**Solución:** Usar SOLO `PaymentMethodService` y eliminar métodos de pago de `UsuarioService`

---

### 3. REPARTIDOR - Ubicación (TRIPLICACIÓN)

**Backend:**
```
repartidores/urls.py
├── POST /api/repartidores/ubicacion/
└── GET  /api/repartidores/ubicacion/historial/
```

**Flutter - PROBLEMA:**
```
Tres servicios para 2 endpoints:

1. LocationService (services/location_service.dart)
   └── obtenerUbicacionActual() - Solo lectura local

2. UbicacionService (services/ubicacion_service.dart)
   └── actualizarUbicacion() → POST /api/repartidores/ubicacion/
   └── iniciarRastreo()
   └── detenerRastreo()

3. RepartidorService (services/repartidor_service.dart)
   └── actualizarUbicacion() → Duplica lo de UbicacionService
```

**Solución:**
- Mantener `LocationService` para geolocalización local
- Usar SOLO `UbicacionService` para envío al backend
- Eliminar `actualizarUbicacion()` de `RepartidorService`

---

### 4. PRODUCTOS - Categorías (CONFUSIÓN)

**Backend:**
```
productos/urls.py
└── GET /api/productos/categorias/

super_categorias/urls.py (app separada)
└── GET /api/super-categorias/
```

**Flutter - PROBLEMA:**
```
1. ProductosService.obtenerCategorias()
   → ¿Llama a /categorias/ o /super-categorias/?

2. SuperService.obtenerSuperCategorias()
   → Llama a /super-categorias/
   → Pero SuperService también tiene obtenerProductos() mezclado
```

**Solución:**
- `ProductosService` → solo productos y categorías normales
- `SuperService` → solo super categorías
- Separar claramente las responsabilidades

---

### 5. PROVEEDOR - Productos (CONFUSIÓN DE ROLES)

**Backend:**
```
proveedores/urls.py
├── GET    /api/proveedores/gestion-admin/
└── GET    /api/proveedores/mis-productos/

productos/urls.py
├── GET    /api/productos/provider/products/
├── POST   /api/productos/provider/products/
├── GET    /api/productos/provider/products/<id>/
└── PATCH  /api/productos/provider/products/<id>/
```

**Flutter - PROBLEMA:**
```
1. ProveedorService (services/proveedor_service.dart)
   └── listarProveedores() - CRUD de proveedores como entidad
   └── NO tiene gestión de productos del proveedor

2. ProductosService (services/productos_service.dart)
   └── obtenerProductosDelProveedorActual() → /provider/products/
   └── crearProductoProveedor() → /provider/products/
   └── Mezcla productos globales con productos del proveedor
```

**Solución:** Crear `SupplierProductsService` separado para gestión de productos del proveedor

---

### 6. PEDIDOS - Carrito (SERVICIO NO USADO)

**Backend:**
```
productos/urls.py (carrito dentro de productos)
├── GET    /api/productos/carrito/
├── POST   /api/productos/carrito/agregar/
├── PUT    /api/productos/carrito/item/<int:item_id>/cantidad/
├── DELETE /api/productos/carrito/item/<int:item_id>/
├── DELETE /api/productos/carrito/limpiar/
└── POST   /api/productos/carrito/checkout/
```

**Flutter - PROBLEMA:**
```
1. CarritoService existe (services/carrito_service.dart)
   └── Implementa todos los métodos del backend

2. PERO se usa a través de ProveedorCarrito (providers/proveedor_carrito.dart)
   └── ProveedorCarrito llama a CarritoService internamente
   └── Las pantallas usan ProveedorCarrito, no CarritoService directamente
```

**Solución:** Está bien diseñado. `CarritoService` = API, `ProveedorCarrito` = State Management

---

### 7. NOTIFICACIONES (BIFURCACIÓN)

**Backend:**
```
usuarios/urls.py
├── POST /api/usuarios/fcm-token/
└── GET  /api/usuarios/notificaciones/

notificaciones/urls.py (app separada)
└── [Endpoints de notificaciones]
```

**Flutter - OK:**
```
NotificationService (services/servicio_notificacion.dart)
└── Maneja correctamente FCM tokens y notificaciones
```

**Nota:** La bifurcación en backend es normal (FCM tokens en usuarios, gestión en notificaciones)

---

## 📊 Servicios Verificados - TODOS ACTIVOS

Los siguientes servicios están siendo usados CORRECTAMENTE:

| Servicio | Uso | Archivos | Estado |
|----------|-----|----------|--------|
| `CarritoService` | Provider | 1 archivo | ✅ ACTIVO |
| `PagoService` | Pantallas pedidos | 3 archivos | ✅ ACTIVO |
| `EnvioService` | Pantalla carrito | 1 archivo | ✅ ACTIVO |
| `SessionCleanup` | Limpieza de sesión | 4 archivos | ✅ ACTIVO |
| `SuperService` | Super categorías | 3 archivos | ✅ ACTIVO |
| `ToastService` | Notificaciones UI | 15+ archivos | ✅ MUY ACTIVO |

**Conclusión:** NO se pueden eliminar más servicios. Todos están en uso.

---

## 🎯 Plan de Reorganización Recomendado

### Fase 1: Consolidar Servicios de Usuario (Prioridad ALTA)

**Objetivo:** Eliminar duplicación entre `UsuarioService` y `/features/user/`

**Acción:**
1. Migrar todo a `/services/features/user/`:
   ```
   /services/features/user/
   ├── profile_service.dart (perfil)
   ├── address_service.dart (direcciones) ← ya existe
   ├── payment_method_service.dart (métodos pago) ← ya existe
   └── raffle_service.dart (rifas) ← crear nuevo
   ```

2. Eliminar métodos duplicados de `UsuarioService`:
   - Quitar `listarDirecciones()`
   - Quitar `agregarDireccion()`
   - Quitar `eliminarDireccion()`
   - Quitar `listarMetodosPago()`
   - Quitar `agregarMetodoPago()`

3. Mantener en `UsuarioService` solo:
   - `obtenerPerfil()` (delegarlo a ProfileService)
   - `actualizarPerfil()` (delegarlo a ProfileService)
   - `obtenerEstadisticas()`

### Fase 2: Separar Productos del Proveedor (Prioridad MEDIA)

**Objetivo:** Clarificar responsabilidades entre productos globales y del proveedor

**Acción:**
1. Crear `/services/supplier/`:
   ```
   /services/supplier/
   ├── supplier_profile_service.dart
   └── supplier_products_service.dart ← NUEVO
   ```

2. Mover de `ProductosService` a `SupplierProductsService`:
   - `obtenerProductosDelProveedorActual()`
   - `crearProductoProveedor()`
   - `actualizarProductoProveedor()`
   - `obtenerDetalleProductoProveedor()`
   - `obtenerRatingsProductoProveedor()`

3. Dejar en `ProductosService` solo productos globales:
   - `obtenerProductos()`
   - `obtenerProducto()`
   - `obtenerCategorias()`
   - `obtenerPromociones()`

### Fase 3: Limpiar Ubicación de Repartidor (Prioridad BAJA)

**Objetivo:** Eliminar método duplicado

**Acción:**
1. Eliminar `actualizarUbicacion()` de `RepartidorService`
2. Usar SOLO `UbicacionService.actualizarUbicacion()`
3. Documentar que:
   - `LocationService` = geolocalización local (sin backend)
   - `UbicacionService` = rastreo con envío al backend

### Fase 4: Reorganizar Estructura de Carpetas (Prioridad BAJA)

**Objetivo:** Estructura clara por rol

**Estructura propuesta:**
```
/mobile/lib/services/
├── auth/
│   ├── auth_service.dart
│   └── role_manager.dart
├── user/
│   ├── profile_service.dart
│   ├── address_service.dart
│   ├── payment_method_service.dart
│   └── raffle_service.dart
├── supplier/
│   ├── supplier_profile_service.dart
│   └── supplier_products_service.dart
├── delivery/
│   ├── delivery_service.dart
│   ├── delivery_location_service.dart
│   └── delivery_earnings_service.dart
├── products/
│   ├── productos_service.dart
│   └── super_service.dart
├── orders/
│   ├── pedido_service.dart
│   └── pedido_grupo_service.dart
├── shared/
│   ├── carrito_service.dart
│   ├── pago_service.dart
│   ├── envio_service.dart
│   ├── calificaciones_service.dart
│   └── toast_service.dart
└── core/
    ├── location_service.dart
    ├── cache_service.dart
    └── session_cleanup.dart
```

---

## 📝 Endpoints Backend Sin Servicio Flutter

Los siguientes endpoints existen en el backend pero NO tienen servicio dedicado en Flutter:

```
1. /chat/ → No hay ChatService
2. /reportes/ → No hay ReportService
3. /analytics/ → No hay AnalyticsService
4. /compensaciones/ → No hay CompensationService
5. /integraciones/ → No hay IntegrationService
```

**Decisión:** Implementar servicios solo cuando las pantallas los necesiten

---

## ✅ Resumen de Estado Actual

| Aspecto | Estado | Acción |
|---------|--------|--------|
| **Carpetas vacías** | ✅ Eliminadas (11) | Completo |
| **Servicios duplicados** | ✅ rastreo_inteligente eliminado | Completo |
| **Servicios sin uso** | ✅ Todos verificados activos | Ninguno que eliminar |
| **Duplicación usuario** | ⚠️ Identificada | Requiere refactorización |
| **Duplicación proveedor** | ⚠️ Identificada | Requiere refactorización |
| **Estructura inconsistente** | ⚠️ Mezclada | Requiere reorganización |

**Conclusión:** La aplicación está funcional, pero necesita refactorización para mejorar mantenibilidad.

---

## 🚀 Próximos Pasos Sugeridos

1. **Inmediato:** Documentar mapeo Backend ↔ Flutter en tabla
2. **Corto plazo:** Consolidar servicios de usuario (Fase 1)
3. **Medio plazo:** Separar productos de proveedor (Fase 2)
4. **Largo plazo:** Reorganizar estructura completa (Fase 4)

**No es necesario hacer todo de una vez.** La app funciona correctamente. La reorganización es para mejorar mantenibilidad futura.
