# 📚 Delibery API Documentation

## Base URL
```
Desarrollo: http://localhost:8000/api
Producción: https://api.delibery.com/api
```

## Autenticación

Todos los endpoints (excepto registro y login) requieren autenticación mediante JWT Bearer Token.

```http
Authorization: Bearer {access_token}
```

---

## 🔐 Authentication

### Registro de Usuario
```http
POST /auth/register/
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "Password123!",
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+593987654321",
  "fecha_nacimiento": "1990-01-15"
}

Response: 201 Created
{
  "message": "Usuario registrado exitosamente",
  "user": {
    "id": 1,
    "email": "usuario@ejemplo.com",
    "nombre": "Juan",
    "apellido": "Pérez",
    "rol_activo": "usuario"
  },
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### Login
```http
POST /auth/login/
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "Password123!"
}

Response: 200 OK
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "usuario@ejemplo.com",
    "nombre": "Juan",
    "apellido": "Pérez",
    "rol_activo": "usuario",
    "roles_aprobados": ["usuario"]
  }
}
```

### Refresh Token
```http
POST /auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}

Response: 200 OK
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### Logout
```http
POST /auth/logout/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Sesión cerrada exitosamente"
}
```

### Recuperar Contraseña
```http
POST /auth/password-reset/
Content-Type: application/json

{
  "email": "usuario@ejemplo.com"
}

Response: 200 OK
{
  "message": "Código de verificación enviado al correo"
}
```

### Verificar Código
```http
POST /auth/verify-code/
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "codigo": "123456"
}

Response: 200 OK
{
  "message": "Código verificado correctamente",
  "reset_token": "temp-token-123..."
}
```

### Nueva Contraseña
```http
POST /auth/set-new-password/
Content-Type: application/json

{
  "reset_token": "temp-token-123...",
  "new_password": "NewPassword123!"
}

Response: 200 OK
{
  "message": "Contraseña actualizada exitosamente"
}
```

---

## 👤 Usuarios

### Obtener Perfil
```http
GET /usuarios/perfil/
Authorization: Bearer {token}

Response: 200 OK
{
  "id": 1,
  "email": "usuario@ejemplo.com",
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+593987654321",
  "fecha_nacimiento": "1990-01-15",
  "foto_perfil": "https://...",
  "rol_activo": "usuario",
  "roles_aprobados": ["usuario"],
  "direcciones": [...]
}
```

### Actualizar Perfil
```http
PATCH /usuarios/perfil/
Authorization: Bearer {token}
Content-Type: application/json

{
  "nombre": "Juan Carlos",
  "telefono": "+593987654322"
}

Response: 200 OK
{...}
```

### Cambiar Rol Activo
```http
POST /usuarios/cambiar-rol/
Authorization: Bearer {token}
Content-Type: application/json

{
  "rol": "proveedor"
}

Response: 200 OK
{
  "message": "Rol cambiado exitosamente",
  "rol_activo": "proveedor"
}
```

### Direcciones Favoritas

#### Listar Direcciones
```http
GET /usuarios/direcciones/
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": 1,
    "nombre": "Casa",
    "direccion": "Calle Principal 123",
    "latitud": -1.2345,
    "longitud": -78.1234,
    "referencia": "Cerca del parque",
    "es_principal": true
  }
]
```

#### Crear Dirección
```http
POST /usuarios/direcciones/
Authorization: Bearer {token}
Content-Type: application/json

{
  "nombre": "Trabajo",
  "direccion": "Av. Secundaria 456",
  "latitud": -1.2345,
  "longitud": -78.1234,
  "referencia": "Edificio azul",
  "es_principal": false
}

Response: 201 Created
```

---

## 🛍️ Productos

### Listar Productos
```http
GET /productos/
Authorization: Bearer {token}

Query Parameters:
- categoria: ID de categoría
- proveedor: ID de proveedor
- search: Búsqueda por nombre
- ordering: precio, -precio, created_at, -created_at
- page: Número de página
- page_size: Tamaño de página (default: 20)

Response: 200 OK
{
  "count": 100,
  "next": "http://api.../productos/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "nombre": "Hamburguesa Clásica",
      "descripcion": "Deliciosa hamburguesa con carne de res",
      "precio": "8.50",
      "precio_oferta": "7.00",
      "imagen": "https://...",
      "categoria": {
        "id": 1,
        "nombre": "Comida Rápida"
      },
      "proveedor": {
        "id": 1,
        "nombre": "Burger King",
        "logo": "https://..."
      },
      "disponible": true,
      "stock": 50
    }
  ]
}
```

### Detalle de Producto
```http
GET /productos/{id}/
Authorization: Bearer {token}

Response: 200 OK
{
  "id": 1,
  "nombre": "Hamburguesa Clásica",
  "descripcion": "Deliciosa hamburguesa con carne de res...",
  "precio": "8.50",
  "precio_oferta": "7.00",
  "imagen": "https://...",
  "imagenes_adicionales": [...],
  "categoria": {...},
  "proveedor": {...},
  "disponible": true,
  "stock": 50,
  "calificacion_promedio": 4.5,
  "total_calificaciones": 120
}
```

### Productos Populares
```http
GET /productos/populares/
Authorization: Bearer {token}

Response: 200 OK
[...]
```

### Productos por Categoría
```http
GET /productos/por-categoria/{categoria_id}/
Authorization: Bearer {token}

Response: 200 OK
[...]
```

---

## 🛒 Carrito

### Ver Carrito
```http
GET /carrito/
Authorization: Bearer {token}

Response: 200 OK
{
  "items": [
    {
      "id": 1,
      "producto": {
        "id": 1,
        "nombre": "Hamburguesa Clásica",
        "precio": "8.50",
        "imagen": "https://..."
      },
      "cantidad": 2,
      "precio_unitario": "8.50",
      "subtotal": "17.00"
    }
  ],
  "total": "17.00",
  "total_items": 2
}
```

### Agregar al Carrito
```http
POST /carrito/items/
Authorization: Bearer {token}
Content-Type: application/json

{
  "producto": 1,
  "cantidad": 2
}

Response: 201 Created
```

### Actualizar Cantidad
```http
PATCH /carrito/items/{id}/
Authorization: Bearer {token}
Content-Type: application/json

{
  "cantidad": 3
}

Response: 200 OK
```

### Eliminar del Carrito
```http
DELETE /carrito/items/{id}/
Authorization: Bearer {token}

Response: 204 No Content
```

### Vaciar Carrito
```http
DELETE /carrito/vaciar/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Carrito vaciado exitosamente"
}
```

---

## 📦 Pedidos

### Crear Pedido
```http
POST /pedidos/
Authorization: Bearer {token}
Content-Type: application/json

{
  "direccion_entrega": "Calle Principal 123",
  "latitud": -1.2345,
  "longitud": -78.1234,
  "metodo_pago": "efectivo",
  "notas": "Sin cebolla, por favor",
  "items": [
    {
      "producto": 1,
      "cantidad": 2
    }
  ]
}

Response: 201 Created
{
  "id": 1,
  "codigo": "PED-001",
  "estado": "pendiente",
  "total": "17.00",
  "direccion_entrega": "Calle Principal 123",
  "items": [...],
  "created_at": "2024-12-14T10:30:00Z"
}
```

### Mis Pedidos
```http
GET /pedidos/mis-pedidos/
Authorization: Bearer {token}

Query Parameters:
- estado: pendiente, confirmado, en_camino, entregado, cancelado
- fecha_desde: YYYY-MM-DD
- fecha_hasta: YYYY-MM-DD

Response: 200 OK
[
  {
    "id": 1,
    "codigo": "PED-001",
    "estado": "en_camino",
    "total": "17.00",
    "proveedor": {...},
    "repartidor": {...},
    "created_at": "2024-12-14T10:30:00Z",
    "tiempo_estimado": 30
  }
]
```

### Detalle de Pedido
```http
GET /pedidos/{id}/
Authorization: Bearer {token}

Response: 200 OK
{
  "id": 1,
  "codigo": "PED-001",
  "estado": "en_camino",
  "total": "17.00",
  "subtotal": "15.00",
  "costo_envio": "2.00",
  "direccion_entrega": "Calle Principal 123",
  "latitud": -1.2345,
  "longitud": -78.1234,
  "notas": "Sin cebolla",
  "metodo_pago": "efectivo",
  "items": [...],
  "proveedor": {...},
  "repartidor": {
    "id": 1,
    "nombre": "Carlos",
    "telefono": "+593987654321",
    "ubicacion_actual": {
      "latitud": -1.2340,
      "longitud": -78.1230
    }
  },
  "historial": [
    {
      "estado": "pendiente",
      "fecha": "2024-12-14T10:30:00Z"
    },
    {
      "estado": "confirmado",
      "fecha": "2024-12-14T10:35:00Z"
    }
  ],
  "created_at": "2024-12-14T10:30:00Z",
  "tiempo_estimado": 30
}
```

### Cancelar Pedido
```http
POST /pedidos/{id}/cancelar/
Authorization: Bearer {token}
Content-Type: application/json

{
  "motivo": "Ya no lo necesito"
}

Response: 200 OK
{
  "message": "Pedido cancelado exitosamente"
}
```

### Calificar Pedido
```http
POST /pedidos/{id}/calificar/
Authorization: Bearer {token}
Content-Type: application/json

{
  "calificacion_proveedor": 5,
  "comentario_proveedor": "Excelente comida",
  "calificacion_repartidor": 4,
  "comentario_repartidor": "Buen servicio"
}

Response: 201 Created
```

---

## 🚴 Repartidor

### Pedidos Disponibles
```http
GET /repartidores/pedidos-disponibles/
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": 1,
    "codigo": "PED-001",
    "proveedor": {...},
    "direccion_entrega": "Calle Principal 123",
    "total": "17.00",
    "distancia": 2.5,
    "comision_estimada": "2.00"
  }
]
```

### Aceptar Pedido
```http
POST /repartidores/aceptar-pedido/{pedido_id}/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Pedido aceptado exitosamente",
  "pedido": {...}
}
```

### Mis Entregas
```http
GET /repartidores/mis-entregas/
Authorization: Bearer {token}

Query Parameters:
- estado: en_camino, entregado
- fecha_desde: YYYY-MM-DD
- fecha_hasta: YYYY-MM-DD

Response: 200 OK
[...]
```

### Actualizar Ubicación
```http
POST /repartidores/actualizar-ubicacion/
Authorization: Bearer {token}
Content-Type: application/json

{
  "latitud": -1.2345,
  "longitud": -78.1234
}

Response: 200 OK
{
  "message": "Ubicación actualizada"
}
```

### Marcar como Entregado
```http
POST /repartidores/marcar-entregado/{pedido_id}/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Pedido marcado como entregado"
}
```

### Ganancias
```http
GET /repartidores/ganancias/
Authorization: Bearer {token}

Query Parameters:
- fecha_desde: YYYY-MM-DD
- fecha_hasta: YYYY-MM-DD

Response: 200 OK
{
  "total_ganancias": "150.00",
  "entregas_completadas": 25,
  "promedio_por_entrega": "6.00",
  "detalles": [...]
}
```

### Datos Bancarios

#### Ver Datos Bancarios
```http
GET /repartidores/datos-bancarios/
Authorization: Bearer {token}

Response: 200 OK
{
  "banco": "Banco Pichincha",
  "tipo_cuenta": "ahorros",
  "numero_cuenta": "****5678",
  "cedula_titular": "1234567890",
  "nombre_titular": "Carlos Ramírez"
}
```

#### Actualizar Datos Bancarios
```http
PUT /repartidores/datos-bancarios/
Authorization: Bearer {token}
Content-Type: application/json

{
  "banco": "Banco Pichincha",
  "tipo_cuenta": "ahorros",
  "numero_cuenta": "2200123456",
  "cedula_titular": "1234567890",
  "nombre_titular": "Carlos Ramírez"
}

Response: 200 OK
```

---

## 🏪 Proveedor

### Mis Pedidos (Proveedor)
```http
GET /proveedores/mis-pedidos/
Authorization: Bearer {token}

Query Parameters:
- estado: pendiente, confirmado, preparando, listo, en_camino, entregado
- fecha_desde: YYYY-MM-DD
- fecha_hasta: YYYY-MM-DD

Response: 200 OK
[...]
```

### Confirmar Pedido
```http
POST /proveedores/confirmar-pedido/{pedido_id}/
Authorization: Bearer {token}
Content-Type: application/json

{
  "tiempo_preparacion": 30
}

Response: 200 OK
{
  "message": "Pedido confirmado",
  "tiempo_estimado": 30
}
```

### Rechazar Pedido
```http
POST /proveedores/rechazar-pedido/{pedido_id}/
Authorization: Bearer {token}
Content-Type: application/json

{
  "motivo": "Sin stock"
}

Response: 200 OK
```

### Marcar como Listo
```http
POST /proveedores/marcar-listo/{pedido_id}/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Pedido listo para recoger"
}
```

### Mis Productos
```http
GET /proveedores/mis-productos/
Authorization: Bearer {token}

Response: 200 OK
[...]
```

### Crear Producto
```http
POST /proveedores/productos/
Authorization: Bearer {token}
Content-Type: multipart/form-data

nombre: Hamburguesa Premium
descripcion: La mejor hamburguesa
precio: 12.50
categoria: 1
imagen: [file]
stock: 100
disponible: true

Response: 201 Created
```

### Estadísticas
```http
GET /proveedores/estadisticas/
Authorization: Bearer {token}

Query Parameters:
- periodo: hoy, semana, mes, año

Response: 200 OK
{
  "ventas_totales": "1250.00",
  "pedidos_completados": 45,
  "calificacion_promedio": 4.5,
  "productos_mas_vendidos": [...]
}
```

---

## 👨‍💼 Admin

### Dashboard
```http
GET /admin/dashboard/
Authorization: Bearer {token}

Response: 200 OK
{
  "total_usuarios": 150,
  "total_proveedores": 45,
  "total_repartidores": 30,
  "pedidos_activos": 25,
  "pedidos_hoy": 120,
  "ingresos_hoy": "1250.50",
  "usuarios_nuevos_mes": 30
}
```

### Solicitudes de Cambio de Rol

#### Listar Solicitudes
```http
GET /admin/solicitudes/
Authorization: Bearer {token}

Query Parameters:
- estado: pendiente, aprobada, rechazada
- rol_solicitado: proveedor, repartidor

Response: 200 OK
[
  {
    "id": 1,
    "usuario": {...},
    "rol_solicitado": "proveedor",
    "estado": "pendiente",
    "documentos": [...],
    "created_at": "2024-12-14T10:00:00Z"
  }
]
```

#### Aprobar Solicitud
```http
POST /admin/solicitudes/{id}/aprobar/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Solicitud aprobada"
}
```

#### Rechazar Solicitud
```http
POST /admin/solicitudes/{id}/rechazar/
Authorization: Bearer {token}
Content-Type: application/json

{
  "motivo": "Documentos incompletos"
}

Response: 200 OK
```

### Gestión de Usuarios
```http
GET /admin/usuarios/
Authorization: Bearer {token}

Query Parameters:
- search: Búsqueda por nombre o email
- rol: usuario, proveedor, repartidor, administrador
- activo: true, false

Response: 200 OK
[...]
```

### Resetear Contraseña Usuario
```http
POST /admin/usuarios/{id}/resetear-password/
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Email enviado con nueva contraseña temporal"
}
```

---

## 🎟️ Rifas

### Listar Rifas Activas
```http
GET /rifas/activas/
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": 1,
    "titulo": "iPhone 15 Pro",
    "descripcion": "Participa y gana",
    "premio": "iPhone 15 Pro 256GB",
    "imagen": "https://...",
    "fecha_sorteo": "2024-12-25T20:00:00Z",
    "boletos_totales": 100,
    "boletos_vendidos": 75,
    "precio_boleto": "5.00"
  }
]
```

### Comprar Boleto
```http
POST /rifas/{id}/comprar-boleto/
Authorization: Bearer {token}
Content-Type: application/json

{
  "cantidad": 1
}

Response: 201 Created
{
  "message": "Boleto comprado exitosamente",
  "boletos": ["ABC-001"]
}
```

### Mis Boletos
```http
GET /rifas/mis-boletos/
Authorization: Bearer {token}

Response: 200 OK
[...]
```

---

## 🔔 Notificaciones

### Listar Notificaciones
```http
GET /notificaciones/
Authorization: Bearer {token}

Query Parameters:
- leida: true, false

Response: 200 OK
[
  {
    "id": 1,
    "tipo": "pedido",
    "titulo": "Pedido confirmado",
    "mensaje": "Tu pedido ha sido confirmado",
    "leida": false,
    "data": {...},
    "created_at": "2024-12-14T10:30:00Z"
  }
]
```

### Marcar como Leída
```http
POST /notificaciones/{id}/marcar-leida/
Authorization: Bearer {token}

Response: 200 OK
```

### Marcar Todas como Leídas
```http
POST /notificaciones/marcar-todas-leidas/
Authorization: Bearer {token}

Response: 200 OK
```

---

## 📊 Códigos de Estado HTTP

- `200 OK` - Solicitud exitosa
- `201 Created` - Recurso creado exitosamente
- `204 No Content` - Solicitud exitosa sin contenido de respuesta
- `400 Bad Request` - Datos de entrada inválidos
- `401 Unauthorized` - No autenticado
- `403 Forbidden` - No autorizado para esta acción
- `404 Not Found` - Recurso no encontrado
- `500 Internal Server Error` - Error del servidor

## 🔒 Permisos por Rol

| Endpoint | Usuario | Proveedor | Repartidor | Admin |
|----------|---------|-----------|------------|-------|
| `/productos/` | ✅ | ✅ | ✅ | ✅ |
| `/pedidos/` | ✅ | ❌ | ❌ | ✅ |
| `/proveedores/mis-pedidos/` | ❌ | ✅ | ❌ | ✅ |
| `/repartidores/pedidos-disponibles/` | ❌ | ❌ | ✅ | ✅ |
| `/admin/dashboard/` | ❌ | ❌ | ❌ | ✅ |

---

**Última actualización:** 2024-12-14