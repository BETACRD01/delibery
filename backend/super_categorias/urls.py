# super_categorias/urls.py
"""
URLs para la API de Super Categorías
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import CategoriaSuperViewSet, ProveedorSuperViewSet, ProductoSuperViewSet

# Crear router
router = DefaultRouter()

# Registrar ViewSets
router.register(r'categorias', CategoriaSuperViewSet, basename='categoriasuper')
router.register(r'proveedores', ProveedorSuperViewSet, basename='proveedorsuper')
router.register(r'productos', ProductoSuperViewSet, basename='productosuper')

# URLs
urlpatterns = [
    path('', include(router.urls)),
]

"""
Endpoints disponibles:

CATEGORÍAS SUPER:
- GET    /super/categorias/                    - Listar todas las categorías activas
- GET    /super/categorias/activas/            - Listar solo categorías activas (endpoint directo)
- GET    /super/categorias/{id}/               - Obtener una categoría específica
- GET    /super/categorias/{id}/proveedores/   - Obtener proveedores de una categoría
- POST   /super/categorias/                    - Crear categoría (Admin)
- PUT    /super/categorias/{id}/               - Actualizar categoría (Admin)
- DELETE /super/categorias/{id}/               - Eliminar categoría (Admin)

PROVEEDORES SUPER:
- GET    /super/proveedores/                      - Listar todos los proveedores activos
- GET    /super/proveedores/por_categoria/?categoria={id} - Filtrar por categoría
- GET    /super/proveedores/abiertos/             - Proveedores abiertos actualmente
- GET    /super/proveedores/{id}/                 - Obtener un proveedor específico
- GET    /super/proveedores/{id}/productos/       - Obtener productos de un proveedor
- POST   /super/proveedores/                      - Crear proveedor (Admin)
- PUT    /super/proveedores/{id}/                 - Actualizar proveedor (Admin)
- DELETE /super/proveedores/{id}/                 - Eliminar proveedor (Admin)

PRODUCTOS SUPER:
- GET    /super/productos/                    - Listar todos los productos disponibles
- GET    /super/productos/ofertas/            - Productos en oferta
- GET    /super/productos/destacados/         - Productos destacados
- GET    /super/productos/{id}/               - Obtener un producto específico
- POST   /super/productos/                    - Crear producto (Admin)
- PUT    /super/productos/{id}/               - Actualizar producto (Admin)
- DELETE /super/productos/{id}/               - Eliminar producto (Admin)

Filtros disponibles:
- categorias: ?activo=true, ?destacado=true
- proveedores: ?categoria={id}, ?activo=true, ?verificado=true
- productos: ?proveedor={id}, ?disponible=true, ?destacado=true

Búsqueda:
- ?search={término}

Ordenamiento:
- categorias: ?ordering=orden, ?ordering=nombre
- proveedores: ?ordering=-calificacion, ?ordering=nombre
- productos: ?ordering=precio, ?ordering=-created_at
"""
