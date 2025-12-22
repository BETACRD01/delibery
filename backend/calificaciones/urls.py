# calificaciones/urls.py

from django.urls import path, include, re_path
from rest_framework.routers import DefaultRouter
from .views import CalificacionViewSet, TipoCalificacionView

router = DefaultRouter()
router.register(r'', CalificacionViewSet, basename='calificacion')

urlpatterns = [
    # Tipos de calificación (antes del router para evitar conflictos)
    path('tipos/', TipoCalificacionView.as_view({'get': 'list'}), name='tipos-calificacion'),

    # Calificaciones por entidad (producto/cliente/repartidor/proveedor)
    re_path(
        r'^(?P<entity_type>producto|cliente|repartidor|proveedor)/(?P<entity_id>\d+)/resumen/$',
        CalificacionViewSet.as_view({'get': 'resumen_entidad'}),
        name='calificaciones-resumen-entidad',
    ),
    re_path(
        r'^(?P<entity_type>producto|cliente|repartidor|proveedor)/(?P<entity_id>\d+)/$',
        CalificacionViewSet.as_view({'get': 'por_entidad'}),
        name='calificaciones-entidad',
    ),
    
    # Router principal
    path('', include(router.urls)),
]

"""
ENDPOINTS DISPONIBLES:
======================

CRUD Básico:
- GET    /api/calificaciones/                    → Lista calificaciones recibidas
- POST   /api/calificaciones/                    → Crear calificación
- GET    /api/calificaciones/{id}/               → Detalle de calificación
- PATCH  /api/calificaciones/{id}/               → Actualizar calificación
- DELETE /api/calificaciones/{id}/               → Eliminar calificación

Acciones Personalizadas:
- GET    /api/calificaciones/dadas/              → Calificaciones que he dado
- GET    /api/calificaciones/recibidas/          → Calificaciones que he recibido
- GET    /api/calificaciones/pendientes/{pedido_id}/  → Calificaciones pendientes
- GET    /api/calificaciones/estadisticas/       → Mis estadísticas
- GET    /api/calificaciones/mi_resumen/         → Mi resumen de calificaciones
- POST   /api/calificaciones/rapida/             → Calificación rápida
- GET    /api/calificaciones/pedido/{pedido_id}/ → Calificaciones de un pedido
- GET    /api/calificaciones/usuario/{user_id}/  → Calificaciones de un usuario

Utilidades:
- GET    /api/calificaciones/tipos/              → Lista tipos de calificación
"""
