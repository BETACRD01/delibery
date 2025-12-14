# 🔧 Corrección: Promociones Visibles en el Carrito

## Problema Detectado

Las promociones se agregaban al carrito pero **no se mostraban** cuando el usuario navegaba a la pantalla del carrito.

### Causa Raíz

El método `agregarPromocion()` agregaba las promociones a la lista `_items`, pero cuando se llamaba a `cargarCarrito()` (que trae datos del backend), se sobrescribía `_items` y se perdían las promociones locales porque el backend no tiene soporte para promociones completas.

## Solución Implementada

### 1. Separación de Datos: Backend vs Local

**Problema:** Mezclar productos del backend con promociones locales en la misma lista.

**Solución:** Crear dos listas separadas:
- `_items`: Productos sincronizados con el backend
- `_promocionesLocales`: Promociones solo en memoria (no persisten en el backend)

```dart
List<ItemCarrito> _items = [];
List<ItemCarrito> _promocionesLocales = []; // Promociones solo en memoria
```

### 2. Getter Unificado

El getter `items` combina ambas listas para mostrarlas en la UI:

```dart
List<ItemCarrito> get items {
  // Combinar productos del backend con promociones locales
  return [..._items, ..._promocionesLocales];
}
```

### 3. Métodos Actualizados

Todos los métodos ahora verifican si el ítem es una promoción local antes de hacer llamadas al backend:

#### **incrementarCantidad()**
```dart
Future<bool> incrementarCantidad(String itemId) async {
  // Verificar si es una promoción local
  final indexPromo = _promocionesLocales.indexWhere((i) => i.id == itemId);
  if (indexPromo != -1) {
    _promocionesLocales[indexPromo].cantidad++;
    notifyListeners();
    return true;
  }

  // Si no, es un producto del backend
  final item = _items.firstWhere((i) => i.id == itemId);
  return await actualizarCantidad(itemId, item.cantidad + 1);
}
```

#### **decrementarCantidad()**
```dart
Future<bool> decrementarCantidad(String itemId) async {
  // Verificar si es una promoción local
  final indexPromo = _promocionesLocales.indexWhere((i) => i.id == itemId);
  if (indexPromo != -1) {
    if (_promocionesLocales[indexPromo].cantidad <= 1) {
      return await removerProducto(itemId);
    }
    _promocionesLocales[indexPromo].cantidad--;
    notifyListeners();
    return true;
  }

  // Si no, es un producto del backend
  // ...
}
```

#### **removerProducto()**
```dart
Future<bool> removerProducto(String itemId) async {
  // Verificar si es una promoción local
  final indexPromo = _promocionesLocales.indexWhere((i) => i.id == itemId);
  if (indexPromo != -1) {
    _promocionesLocales.removeAt(indexPromo);
    notifyListeners();
    debugPrint('Promoción removida localmente');
    return true;
  }

  // Si no, es un producto del backend
  // ...
}
```

#### **limpiarCarrito()**
```dart
Future<bool> limpiarCarrito() async {
  // ...
  _items = [];
  _promocionesLocales = []; // También limpiar promociones locales
  // ...
}
```

#### **checkout()**
```dart
Future<Map<String, dynamic>?> checkout(...) async {
  if (_items.isEmpty && _promocionesLocales.isEmpty) {
    _setLoadingState(error: 'El carrito está vacío');
    return null;
  }

  // ...
  _items = [];
  _promocionesLocales = [];
  // ...
}
```

### 4. Getters Actualizados

#### **cantidadTotal**
```dart
int get cantidadTotal {
  final itemsCount = _items.fold(0, (sum, item) => sum + item.cantidad);
  final promosCount = _promocionesLocales.fold(0, (sum, item) => sum + item.cantidad);
  return itemsCount + promosCount;
}
```

#### **total**
```dart
double get total {
  final itemsTotal = _items.fold(0.0, (sum, item) => sum + item.subtotal);
  final promosTotal = _promocionesLocales.fold(0.0, (sum, item) => sum + item.subtotal);
  return itemsTotal + promosTotal;
}
```

#### **estaVacio**
```dart
bool get estaVacio => _items.isEmpty && _promocionesLocales.isEmpty;
```

### 5. agregarPromocion()

Ahora agrega directamente a `_promocionesLocales`:

```dart
Future<bool> agregarPromocion(
  PromocionModel promocion,
  List<ProductoModel> productosIncluidos, {
  int cantidad = 1,
}) async {
  final precioTotal = productosIncluidos.fold<double>(
    0,
    (sum, p) => sum + p.precio,
  );

  final nuevoItem = ItemCarrito(
    id: 'promo_${promocion.id}_${DateTime.now().millisecondsSinceEpoch}',
    promocion: promocion,
    productosIncluidos: productosIncluidos,
    cantidad: cantidad,
    precioUnitario: precioTotal,
  );

  // Agregar a promociones locales (no al backend)
  _promocionesLocales.add(nuevoItem);
  notifyListeners();

  debugPrint('Promoción agregada localmente: ${promocion.titulo} con ${productosIncluidos.length} productos');
  return true;
}
```

## Beneficios de esta Solución

✅ **Persistencia Local**: Las promociones permanecen en memoria mientras la app está abierta
✅ **Sin Conflictos con Backend**: Los productos del backend no sobrescriben las promociones
✅ **Operaciones Independientes**: Incrementar/decrementar/eliminar funciona sin llamadas al backend
✅ **Total y Cantidades Correctos**: Se calculan sumando ambas listas
✅ **UI Unificada**: La pantalla de carrito no distingue entre fuentes de datos

## Limitaciones Actuales

⚠️ **No Persiste entre Sesiones**: Si cierras la app, las promociones se pierden
⚠️ **No Sincroniza con Backend**: El backend no recibe las promociones en el checkout

## Próximos Pasos (Opcional)

Si se requiere persistencia completa:

1. **Opción 1: Persistencia Local**
   - Guardar `_promocionesLocales` en SharedPreferences o SQLite
   - Cargar al iniciar la app

2. **Opción 2: Soporte Backend**
   - Agregar endpoint `/api/carrito/agregar-promocion/`
   - Modificar modelo de carrito en Django para soportar promociones
   - Sincronizar con el backend como los productos normales

## Archivos Modificados

- [proveedor_carrito.dart](mobile/lib/providers/proveedor_carrito.dart)

## Testing

Para probar:

1. **Agregar promoción**: Ir a detalle de promoción → "Agregar al Carrito"
2. **Ver en carrito**: Navegar al carrito → Debe aparecer la promoción con borde especial
3. **Expandir**: Hacer tap en la promoción → Ver productos incluidos
4. **Incrementar cantidad**: Botón + → Debe aumentar
5. **Decrementar cantidad**: Botón - → Debe disminuir
6. **Eliminar**: Botón X → Debe eliminar la promoción completa
7. **Total correcto**: Verificar que el total incluye la promoción

---

✅ **Problema Solucionado**: Las promociones ahora se muestran correctamente en el carrito y persisten durante la sesión de la app.
