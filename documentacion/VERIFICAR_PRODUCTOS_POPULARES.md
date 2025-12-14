# 🔍 Verificación: Productos Más Populares en Flutter

## ✅ Backend Funcionando Correctamente

El endpoint está funcionando:
```bash
curl http://localhost:8000/api/productos/productos/mas-populares/
```

Devuelve **19 productos** ordenados por ventas y rating:
1. ANIME YT (50 ventas, 4.5⭐)
2. Pizza Napolitana (45 ventas, 4.7⭐)
3. Pizza Pepperoni (40 ventas, 4.3⭐)
4. Pizza Hawaiana (35 ventas, 4.6⭐)
5. Pizza Cuatro Quesos (30 ventas, 4.4⭐)

## 🔧 Cambios Aplicados en Flutter

### 1. Agregados logs de debugging

**Archivo:** `mobile/lib/screens/user/inicio/controllers/home_controller.dart`
- Línea 151-167: Logs detallados en `_cargarProductosMasPopulares()`

**Archivo:** `mobile/lib/services/productos_service.dart`
- Línea 179-187: Logs de la petición HTTP

### 2. Código corregido

**Archivo:** `mobile/lib/screens/user/inicio/pantalla_home.dart`
- Línea 192: Usa `controller.productosMasPopulares` ✅

## 🐛 Cómo Depurar el Problema

### Paso 1: Ejecutar la app con logs
```bash
cd mobile
flutter run -d linux
```

### Paso 2: Buscar en la consola estos mensajes:

#### ✅ Si funciona verás:
```
🔵 Obteniendo productos más populares desde: http://...
✅ Respuesta recibida del servidor
📦 Productos más populares encontrados: 19
🔵 Iniciando carga de productos más populares...
✅ Productos más populares cargados: 19
📦 Primeros productos populares:
   1. ANIME YT
   2. Pizza Napolitana
   3. Pizza Pepperoni
```

#### ❌ Si hay error verás:
```
❌ Error obteniendo productos más populares: [descripción del error]
```

### Paso 3: Verificar la URL del API

Revisa que la app esté usando la IP correcta del backend. Busca en los logs:
```
🔵 Obteniendo productos más populares desde: http://192.168.1.22:8000/api/productos/productos/mas-populares/
```

Si la IP no es correcta, ajusta en `mobile/lib/config/api_config.dart`.

## 🔍 Posibles Causas del Problema

### 1. Error de conexión
- El dispositivo/emulador no puede conectar con el backend
- Solución: Verifica que ambos estén en la misma red

### 2. Lista vacía sin error
- El servicio devuelve lista vacía pero no lanza excepción
- Verás en logs: `⚠️ La lista de productos más populares está vacía`

### 3. Error al parsear JSON
- El modelo `ProductoModel` no puede parsear la respuesta
- Verás: `❌ Error cargando productos más populares: [error de parsing]`

### 4. Widget no visible
- Los productos cargan pero el widget no se muestra
- Verifica que no haya errores de renderizado en la consola

## 🧪 Test Manual Rápido

Ejecuta este comando en una terminal:
```bash
cd mobile
dart run test_productos_populares.dart
```

Esto probará la conexión directamente sin la app completa.

## 📋 Checklist de Verificación

- [ ] Backend corriendo en `http://localhost:8000` o tu IP local
- [ ] Endpoint devuelve 19 productos: `curl http://localhost:8000/api/productos/productos/mas-populares/`
- [ ] Flutter conecta a la IP correcta del backend
- [ ] Logs de debugging aparecen en la consola de Flutter
- [ ] No hay errores de compilación en Flutter
- [ ] La app carga sin crashes
- [ ] La sección "Más Populares" es visible al hacer scroll

## 🎯 Próximos Pasos

1. **Ejecuta la app:** `flutter run`
2. **Observa los logs** en la consola
3. **Busca los emojis:** 🔵 ✅ ❌ 📦 ⚠️
4. **Comparte los logs** si sigues sin ver productos

## 💡 Información Adicional

- El widget `SeccionDestacados` muestra "Más Populares" como título
- Si la lista está vacía, muestra: "No hay productos destacados"
- Si está cargando, muestra 3 placeholders grises
- Los productos se ordenan por `veces_vendido DESC, rating_promedio DESC`

---

**Fecha:** 2025-12-04
**Archivos Modificados:**
- ✅ `mobile/lib/screens/user/inicio/controllers/home_controller.dart` (logs agregados)
- ✅ `mobile/lib/services/productos_service.dart` (logs agregados)
- ✅ Backend: productos activados con ventas y ratings
