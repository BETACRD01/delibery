# Guía de Migración: UsuarioService → Servicios Especializados

## 🎯 Objetivo

Refactorizar `UsuarioService` para que delegue responsabilidades a servicios especializados, eliminando duplicación y mejorando la organización del código.

---

## 📋 Estado Actual

### UsuarioService Actual (MONOLÍTICO):

```
UsuarioService
├── Perfil (obtenerPerfil, actualizarPerfil)
├── Direcciones (listarDirecciones, crearDireccion, eliminarDireccion)
├── Métodos de Pago (listarMetodosPago, crearMetodoPago)
├── Rifas (obtenerRifas, participarEnRifa)
├── Estadísticas (obtenerEstadisticas)
└── Notificaciones (obtenerPreferencias, actualizarPreferencias)
```

### Servicios Especializados YA Existentes:

```
/services/features/user/
├── ProfileService ✓ (gestión de perfil)
├── AddressService ✓ (gestión de direcciones)
├── PaymentMethodService ✓ (gestión de métodos de pago)
└── RaffleService ✓ (NUEVO - gestión de rifas)
```

---

## ⚠️ Problema de Duplicación

### Direcciones (DUPLICADO):

```dart
// UsuarioService
Future<List<DireccionModel>> listarDirecciones()
Future<DireccionModel> crearDireccion(DireccionModel direccion)
Future<void> eliminarDireccion(String id)

// AddressService (services/features/user/address_service.dart)
Future<List<AddressModel>> fetchAddresses()
Future<AddressModel> createAddress(CreateAddressRequest request)
Future<void> deleteAddress(String addressId)
```

**Problema:** Dos servicios hacen lo mismo con diferentes nombres.

### Métodos de Pago (DUPLICADO):

```dart
// UsuarioService
Future<List<MetodoPagoModel>> listarMetodosPago()
Future<MetodoPagoModel> crearMetodoPago(MetodoPagoModel metodo)

// PaymentMethodService (services/features/user/payment_method_service.dart)
Future<List<PaymentMethodModel>> fetchPaymentMethods()
Future<PaymentMethodModel> createPaymentMethod(CreatePaymentMethodRequest request)
Future<void> deletePaymentMethod(String methodId)
```

**Problema:** Dos servicios hacen lo mismo con diferentes nombres.

---

## ✅ Estrategia de Migración (SIN ROMPER CÓDIGO EXISTENTE)

### Opción 1: Deprecation + Delegation (RECOMENDADA)

**Ventajas:**
- No rompe código existente
- Migración gradual
- Warnings claros en el IDE

**Proceso:**
1. Mantener métodos actuales en `UsuarioService`
2. Marcarlos como `@deprecated`
3. Hacerlos delegar a los servicios especializados
4. Actualizar pantallas gradualmente

**Ejemplo:**

```dart
// En UsuarioService

@Deprecated('Use AddressService().fetchAddresses() instead')
Future<List<DireccionModel>> listarDirecciones({bool forzarRecarga = false}) async {
  // Delegación al servicio especializado
  final addressService = AddressService();
  final addresses = await addressService.fetchAddresses(forceReload: forzarRecarga);

  // Mapear de AddressModel a DireccionModel (si son diferentes)
  return addresses.map((addr) => DireccionModel.fromAddressModel(addr)).toList();
}

@Deprecated('Use AddressService().createAddress() instead')
Future<DireccionModel> crearDireccion(DireccionModel direccion) async {
  final addressService = AddressService();
  final request = CreateAddressRequest.fromDireccionModel(direccion);
  final created = await addressService.createAddress(request);
  return DireccionModel.fromAddressModel(created);
}
```

### Opción 2: Unificación de Modelos (MÁS TRABAJO)

Si `DireccionModel` y `AddressModel` son iguales, unificar:

```dart
// Eliminar DireccionModel
// Usar solo AddressModel en toda la app
```

---

## 🔄 Plan de Migración Paso a Paso

### Fase 1: Crear RaffleService ✅ COMPLETADO

```bash
✓ Creado: services/features/user/raffle_service.dart
```

### Fase 2: Agregar Delegation a UsuarioService

**Modificar `UsuarioService` para delegar:**

```dart
// lib/services/usuarios_service.dart

import 'features/user/address_service.dart';
import 'features/user/payment_method_service.dart';
import 'features/user/profile_service.dart';
import 'features/user/raffle_service.dart';

class UsuarioService {
  // Servicios especializados
  final _profileService = ProfileService();
  final _addressService = AddressService();
  final _paymentService = PaymentMethodService();
  final _raffleService = RaffleService();

  // -------------------------------------------------------------------------
  // PERFIL - Delegación a ProfileService
  // -------------------------------------------------------------------------

  @Deprecated('Use ProfileService().getProfile() instead')
  Future<PerfilModel> obtenerPerfil({bool forzarRecarga = false}) async {
    return await _profileService.getProfile(forceReload: forzarRecarga);
  }

  @Deprecated('Use ProfileService().updateProfile() instead')
  Future<PerfilModel> actualizarPerfil({...}) async {
    final request = UpdateProfileRequest(...);
    return await _profileService.updateProfile(request);
  }

  // -------------------------------------------------------------------------
  // DIRECCIONES - Delegación a AddressService
  // -------------------------------------------------------------------------

  @Deprecated('Use AddressService().fetchAddresses() instead')
  Future<List<DireccionModel>> listarDirecciones({bool forzarRecarga = false}) async {
    final addresses = await _addressService.fetchAddresses(forceReload: forzarRecarga);
    // Si DireccionModel != AddressModel, mapear aquí
    return addresses.map((addr) => DireccionModel.fromMap(addr.toMap())).toList();
  }

  @Deprecated('Use AddressService().createAddress() instead')
  Future<DireccionModel> crearDireccion(DireccionModel direccion) async {
    final request = CreateAddressRequest(...); // Mapear de DireccionModel
    final created = await _addressService.createAddress(request);
    return DireccionModel.fromMap(created.toMap());
  }

  @Deprecated('Use AddressService().deleteAddress() instead')
  Future<void> eliminarDireccion(String id) async {
    await _addressService.deleteAddress(id);
    _direccionesCache = null; // Invalidar caché local
  }

  // -------------------------------------------------------------------------
  // MÉTODOS DE PAGO - Delegación a PaymentMethodService
  // -------------------------------------------------------------------------

  @Deprecated('Use PaymentMethodService().fetchPaymentMethods() instead')
  Future<List<MetodoPagoModel>> listarMetodosPago({bool forzarRecarga = false}) async {
    final methods = await _paymentService.fetchPaymentMethods(forceReload: forzarRecarga);
    return methods.map((m) => MetodoPagoModel.fromMap(m.toMap())).toList();
  }

  @Deprecated('Use PaymentMethodService().createPaymentMethod() instead')
  Future<MetodoPagoModel> crearMetodoPago(MetodoPagoModel metodo) async {
    final request = CreatePaymentMethodRequest(...);
    final created = await _paymentService.createPaymentMethod(request);
    return MetodoPagoModel.fromMap(created.toMap());
  }

  @Deprecated('Use PaymentMethodService().deletePaymentMethod() instead')
  Future<void> eliminarMetodoPago(String id) async {
    await _paymentService.deletePaymentMethod(id);
    _metodosPagoCache = null;
  }

  // -------------------------------------------------------------------------
  // RIFAS - Delegación a RaffleService
  // -------------------------------------------------------------------------

  @Deprecated('Use RaffleService().obtenerRifasParticipaciones() instead')
  Future<Map<String, dynamic>> obtenerRifasParticipaciones({bool forzarRecarga = false}) async {
    return await _raffleService.obtenerRifasParticipaciones(forzarRecarga: forzarRecarga);
  }

  @Deprecated('Use RaffleService().participarEnRifa() instead')
  Future<Map<String, dynamic>> participarEnRifa(String rifaId) async {
    return await _raffleService.participarEnRifa(rifaId);
  }

  @Deprecated('Use RaffleService().obtenerRifaActiva() instead')
  Future<Map<String, dynamic>?> obtenerRifaActiva({bool forzarRecarga = false}) async {
    return await _raffleService.obtenerRifaActiva(forzarRecarga: forzarRecarga);
  }

  // ... resto de métodos de rifas
}
```

### Fase 3: Actualizar Pantallas Gradualmente

**Buscar y reemplazar en pantallas:**

```bash
# Buscar todas las referencias a UsuarioService
grep -r "UsuarioService()" mobile/lib/screens/

# Actualizar una por una:
# Antes:
final usuario = UsuarioService();
final direcciones = await usuario.listarDirecciones();

# Después:
final addressService = AddressService();
final direcciones = await addressService.fetchAddresses();
```

### Fase 4: Eliminar Métodos Deprecated (FUTURO)

Una vez que todas las pantallas usen los servicios especializados:

```dart
// Eliminar métodos @deprecated de UsuarioService
// Mantener solo:
// - obtenerEstadisticas()
// - obtenerPreferenciasNotificaciones()
// - actualizarPreferenciasNotificaciones()
```

---

## 📊 Comparación de Modelos

### ¿DireccionModel vs AddressModel son iguales?

**Verificar:**
```bash
# Comparar estructuras
diff mobile/lib/models/direccion.dart mobile/lib/apis/dtos/user/responses/address_model.dart
```

**Si son iguales:** Eliminar uno y usar solo el otro
**Si son diferentes:** Mantener mapeo en los métodos deprecated

---

## 🎯 Resultado Final Esperado

### UsuarioService Refactorizado (SLIM):

```dart
class UsuarioService {
  // Solo mantener métodos que NO tienen servicio especializado:

  Future<EstadisticasModel> obtenerEstadisticas()
  Future<Map<String, bool>> obtenerPreferenciasNotificaciones()
  Future<void> actualizarPreferenciasNotificaciones()
  Future<void> actualizarFcmToken()

  // Todo lo demás → delegado o eliminado
}
```

### Pantallas Actualizadas:

```dart
// ANTES (TODO EN UsuarioService):
final usuarioService = UsuarioService();
final perfil = await usuarioService.obtenerPerfil();
final direcciones = await usuarioService.listarDirecciones();
final metodos = await usuarioService.listarMetodosPago();
final rifas = await usuarioService.obtenerRifas();

// DESPUÉS (SERVICIOS ESPECIALIZADOS):
final profileService = ProfileService();
final addressService = AddressService();
final paymentService = PaymentMethodService();
final raffleService = RaffleService();

final perfil = await profileService.getProfile();
final direcciones = await addressService.fetchAddresses();
final metodos = await paymentService.fetchPaymentMethods();
final rifas = await raffleService.obtenerRifasParticipaciones();
```

---

## ⚠️ Precauciones

1. **NO eliminar métodos directamente** → Usar `@deprecated` primero
2. **Verificar modelos** → DireccionModel vs AddressModel pueden diferir
3. **Mantener caché** → Los servicios especializados tienen su propia caché
4. **Actualizar gradualmente** → No cambiar todas las pantallas de una vez
5. **Testing** → Probar cada pantalla después de migrar

---

## 📝 Checklist de Migración

- [x] Crear RaffleService
- [ ] Agregar imports de servicios especializados en UsuarioService
- [ ] Marcar métodos como @deprecated
- [ ] Implementar delegación a servicios especializados
- [ ] Verificar diferencias entre modelos (DireccionModel vs AddressModel)
- [ ] Actualizar pantallas de direcciones
- [ ] Actualizar pantallas de métodos de pago
- [ ] Actualizar pantallas de rifas
- [ ] Actualizar pantallas de perfil
- [ ] Eliminar métodos deprecated (cuando todas las pantallas estén actualizadas)
- [ ] Verificar que no queden referencias a métodos deprecated

---

## 🚀 Comandos Útiles

```bash
# Buscar uso de UsuarioService
grep -r "UsuarioService()" mobile/lib/screens/ | wc -l

# Buscar métodos específicos
grep -r "listarDirecciones" mobile/lib/

# Verificar warnings de deprecated
flutter analyze | grep deprecated

# Compilar y verificar
flutter build apk --debug
```

---

## 📖 Referencias

- Documento principal: `DISCREPANCIAS_BACKEND_FLUTTER.md`
- AddressService: `services/features/user/address_service.dart`
- PaymentMethodService: `services/features/user/payment_method_service.dart`
- ProfileService: `services/features/user/profile_service.dart`
- RaffleService: `services/features/user/raffle_service.dart` ✓ NUEVO
