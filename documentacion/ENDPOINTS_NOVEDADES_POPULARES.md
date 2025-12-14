# Nuevos Endpoints Implementados

## 📝 Resumen
Se han agregado dos nuevos endpoints al backend para soportar las secciones de **Novedades** y **Más Populares** en la aplicación móvil.

---

## 🆕 Endpoint: Novedades

### URL
```
GET /api/productos/productos/novedades/
```

### Descripción
Retorna los 20 productos más recientes ordenados por fecha de creación (descendente).

### Filtros aplicados
- Solo productos con `disponible=True`
- Ordenados por `-created_at` (más recientes primero)
- Límite: 20 productos

### Ejemplo de respuesta
```json
[
  {
    "id": 45,
    "nombre": "Hamburguesa Deluxe",
    "descripcion": "Nueva hamburguesa premium con ingredientes frescos",
    "precio": "12.99",
    "precio_anterior": null,
    "en_oferta": false,
    "porcentaje_descuento": 0,
    "imagen_url": "http://example.com/imagen.jpg",
    "categoria_id": 1,
    "disponible": true,
    "destacado": false,
    "rating_promedio": "0.00",
    "total_resenas": 0,
    "created_at": "2025-12-04T10:30:00Z"
  }
]
```

---

## 🔥 Endpoint: Más Populares

### URL
```
GET /api/productos/productos/mas-populares/
```

### Descripción
Retorna los 20 productos más populares ordenados por cantidad de ventas y rating.

### Filtros aplicados
- Solo productos con `disponible=True`
- Ordenados por:
  1. `-veces_vendido` (más vendidos primero)
  2. `-rating_promedio` (mejor calificados primero)
- Límite: 20 productos

### Ejemplo de respuesta
```json
[
  {
    "id": 12,
    "nombre": "Pizza Familiar Pepperoni",
    "descripcion": "La favorita de todos con extra queso",
    "precio": "18.99",
    "precio_anterior": "22.99",
    "en_oferta": true,
    "porcentaje_descuento": 17,
    "imagen_url": "http://example.com/pizza.jpg",
    "categoria_id": 4,
    "disponible": true,
    "destacado": true,
    "rating_promedio": "4.80",
    "total_resenas": 156,
    "veces_vendido": 450
  }
]
```

---

## 🔗 URLs completas de ProductoViewSet

Con los nuevos cambios, el ProductoViewSet ahora soporta estas acciones:

| Acción | URL | Método | Descripción |
|--------|-----|--------|-------------|
| Lista | `/api/productos/productos/` | GET | Lista todos los productos |
| Detalle | `/api/productos/productos/{id}/` | GET | Detalle de un producto |
| Destacados | `/api/productos/productos/destacados/` | GET | Productos destacados |
| Ofertas | `/api/productos/productos/ofertas/` | GET | Productos en oferta |
| **Novedades** | `/api/productos/productos/novedades/` | GET | **Productos nuevos** ⭐ |
| **Más Populares** | `/api/productos/productos/mas-populares/` | GET | **Productos más vendidos** ⭐ |

---

## ✅ Integración con Flutter

### ProductosService (mobile/lib/services/productos_service.dart)

Los métodos ya están implementados:

```dart
Future<List<ProductoModel>> obtenerProductosNovedades() async {
  try {
    final url = '${ApiConfig.productosLista}novedades/';
    final response = await _client.get(url);
    final lista = _extraerLista(response);
    return lista.map((json) => ProductoModel.fromJson(json)).toList();
  } catch (e) {
    _log('Error obteniendo productos novedades', error: e);
    rethrow;
  }
}

Future<List<ProductoModel>> obtenerProductosMasPopulares() async {
  try {
    final url = '${ApiConfig.productosLista}mas-populares/';
    final response = await _client.get(url);
    final lista = _extraerLista(response);
    return lista.map((json) => ProductoModel.fromJson(json)).toList();
  } catch (e) {
    _log('Error obteniendo productos más populares', error: e);
    rethrow;
  }
}
```

---

## 🧪 Cómo probar los endpoints

### Opción 1: Usando curl

```bash
# Probar endpoint de Novedades
curl http://localhost:8000/api/productos/productos/novedades/

# Probar endpoint de Más Populares
curl http://localhost:8000/api/productos/productos/mas-populares/
```

### Opción 2: Desde el navegador

1. Inicia el servidor: `cd backend && python manage.py runserver`
2. Visita:
   - Novedades: http://localhost:8000/api/productos/productos/novedades/
   - Más Populares: http://localhost:8000/api/productos/productos/mas-populares/

### Opción 3: Usando Postman/Insomnia

- **GET** http://localhost:8000/api/productos/productos/novedades/
- **GET** http://localhost:8000/api/productos/productos/mas-populares/

---

## 📊 Campos importantes del modelo Producto

Los endpoints retornan los siguientes campos clave:

- `veces_vendido`: Contador de cuántas veces se ha vendido el producto
- `rating_promedio`: Calificación promedio (0.00 - 5.00)
- `total_resenas`: Cantidad total de reseñas
- `created_at`: Fecha de creación del producto
- `updated_at`: Última actualización del producto

---

## 🎯 Lógica de ordenamiento

### Novedades
```python
productos = self.get_queryset().order_by('-created_at')[:20]
```
Criterio: Fecha de creación descendente (más nuevos primero)

### Más Populares
```python
productos = self.get_queryset().order_by('-veces_vendido', '-rating_promedio')[:20]
```
Criterios (en orden de prioridad):
1. Cantidad de ventas (descendente)
2. Rating promedio (descendente)

---

## ✅ Estado de implementación

- [x] Backend: Endpoints implementados
- [x] Backend: Verificación de sintaxis (django check)
- [x] Flutter: ProductosService actualizado
- [x] Flutter: HomeController actualizado
- [x] Flutter: UI integrada en pantalla_home.dart
- [x] Flutter: Análisis de código sin errores
- [ ] Testing: Probar con datos reales

---

## 🚀 Próximos pasos

1. **Iniciar servidor backend**:
   ```bash
   cd backend
   python manage.py runserver
   ```

2. **Ejecutar app Flutter**:
   ```bash
   cd mobile
   flutter run
   ```

3. **Verificar datos**: Las secciones de Novedades y Más Populares aparecerán automáticamente si hay productos que cumplan los criterios.

4. **Datos de prueba**: Si no hay productos, considera insertar algunos usando el admin de Django o el script `insertar_productos.py`.

---

## 📝 Notas técnicas

- Los endpoints usan `AllowAny` permission, igual que los otros endpoints de productos
- Se respeta el filtro `disponible=True` automáticamente desde `get_queryset()`
- El límite de 20 productos puede ajustarse según necesidades
- Los endpoints retornan `ProductoListSerializer` que incluye todos los campos necesarios
