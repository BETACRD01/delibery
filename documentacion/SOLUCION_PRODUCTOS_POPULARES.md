# Solución: Productos Más Populares

## Problema Identificado

Los productos "Más Populares" no se mostraban en la app Flutter porque:
1. ✅ Los productos en la base de datos tenían `veces_vendido = 0` y `rating_promedio = 0.00`
2. ✅ El endpoint ordenaba por ventas y rating, pero todos tenían el mismo valor (0)
3. ✅ En `pantalla_home.dart` se usaba `productosDestacados` en lugar de `productosMasPopulares`

## Solución Aplicada

### 1. Base de Datos (✅ COMPLETADO)

Ejecutado el script SQL `activar_productos.sql` que:
- Activó 13 productos como **destacados**
- Añadió datos de ventas y ratings a los primeros 10 productos:
  - ANIME YT: 50 ventas, rating 4.5 ⭐
  - Pizza Napolitana: 45 ventas, rating 4.7 ⭐
  - Pizza Pepperoni: 40 ventas, rating 4.3 ⭐
  - Pizza Hawaiana: 35 ventas, rating 4.6 ⭐
  - Pizza Cuatro Quesos: 30 ventas, rating 4.4 ⭐
  - Hamburguesa Clásica: 25 ventas, rating 4.2 ⭐
  - Hamburguesa BBQ Bacon: 20 ventas, rating 4.8 ⭐
  - Hamburguesa Vegetariana: 15 ventas, rating 4.1 ⭐
  - Coca Cola 500ml: 10 ventas, rating 4.5 ⭐
  - Jugo Natural de Naranja: 8 ventas, rating 4.3 ⭐

### 2. Backend (✅ VERIFICADO)

El endpoint funciona correctamente:
```
GET http://localhost:8000/api/productos/productos/mas-populares/
```

Retorna los productos ordenados por:
1. `veces_vendido` (descendente)
2. `rating_promedio` (descendente)

### 3. Flutter (✅ CORREGIDO)

**Archivo modificado:** `mobile/lib/screens/user/inicio/pantalla_home.dart`

**Cambio realizado (línea 192):**
```dart
// ❌ ANTES (INCORRECTO):
productos: controller.productosDestacados,

// ✅ AHORA (CORRECTO):
productos: controller.productosMasPopulares,
```

**Archivo limpiado:** `mobile/lib/screens/user/inicio/controllers/home_controller.dart`
- Eliminados todos los métodos mock (`_categoriasMock()`, `_promocionesMock()`, `_productosDestacadosMock()`)
- Código ahora solo usa datos del backend Django

### 4. Widget de Visualización (✅ YA EXISTÍA)

El widget `SeccionDestacados` ya estaba correctamente implementado en:
- `mobile/lib/screens/user/inicio/widgets/seccion_destacados.dart`
- Muestra el título "Más Populares"
- Lista productos con imagen, nombre, precio, rating y botón de carrito

## Endpoints Disponibles

### Productos Destacados
```
GET /api/productos/productos/destacados/
```
Retorna productos donde `destacado = true`

### Más Populares (MÁS VENDIDOS)
```
GET /api/productos/productos/mas-populares/
```
Retorna productos ordenados por:
- `veces_vendido DESC`
- `rating_promedio DESC`

### Novedades
```
GET /api/productos/productos/novedades/
```
Retorna productos ordenados por `created_at DESC` (los más recientes primero)

### Ofertas
```
GET /api/productos/productos/ofertas/
```
Retorna productos donde `precio_anterior > precio` (tienen descuento)

## Cómo Verificar

### 1. Verificar Base de Datos
```bash
cd backend
PGPASSWORD=deliber_password_2024 psql -h localhost -U deliber_user -d deliber_db -c "
  SELECT id, nombre, veces_vendido, rating_promedio, total_resenas
  FROM productos
  WHERE disponible = true
  ORDER BY veces_vendido DESC, rating_promedio DESC
  LIMIT 10;
"
```

### 2. Verificar Backend API
```bash
curl http://localhost:8000/api/productos/productos/mas-populares/ | python3 -m json.tool
```

### 3. Verificar en Flutter
1. Iniciar la app: `cd mobile && flutter run`
2. En la pantalla Home, desplazarse hacia abajo
3. Buscar la sección "Más Populares"
4. Verificar que se muestren los productos con más ventas

## Archivos Modificados

### Flutter
- ✅ `mobile/lib/screens/user/inicio/pantalla_home.dart` (línea 192)
- ✅ `mobile/lib/screens/user/inicio/controllers/home_controller.dart` (eliminados mocks)

### Backend (Scripts creados)
- ✅ `backend/activar_productos.sql` (script SQL para activar productos)
- ✅ `backend/activar_productos_destacados.py` (script Python alternativo)

## Estado Final

- ✅ **Base de Datos:** 19 productos totales, 13 destacados, 10 con datos de ventas
- ✅ **Backend API:** Endpoints funcionando correctamente
- ✅ **Flutter:** Código corregido para usar `productosMasPopulares`
- ✅ **Visualización:** Widget `SeccionDestacados` ya implementado

## Próximos Pasos (Opcional)

Si quieres añadir más realismo a los datos:

1. **Actualizar más productos con ventas:**
   ```sql
   UPDATE productos
   SET veces_vendido = FLOOR(RANDOM() * 30 + 5),
       rating_promedio = ROUND(CAST(RANDOM() * 1.5 + 3.5 AS NUMERIC), 2),
       total_resenas = FLOOR(RANDOM() * 20 + 5)
   WHERE disponible = true;
   ```

2. **Crear productos novedades:** Los productos más recientes ya se detectan automáticamente por `created_at`

3. **Agregar más ofertas:** Actualizar `precio_anterior` en productos que quieras mostrar en oferta

---

**Fecha:** 2025-12-04
**Estado:** ✅ SOLUCIONADO
