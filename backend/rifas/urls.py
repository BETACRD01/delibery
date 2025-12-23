# -*- coding: utf-8 -*-
# rifas/urls.py
"""
URLs para API REST de Rifas

 ENDPOINTS DISPONIBLES:

RIFAS:
- GET    /api/rifas/                        - Listar todas las rifas
- GET    /api/rifas/{id}/                   - Detalle de rifa específica
- POST   /api/rifas/                        - Crear rifa (solo admin)
- PUT    /api/rifas/{id}/                   - Actualizar rifa (solo admin)
- PATCH  /api/rifas/{id}/                   - Actualizar parcial (solo admin)
- DELETE /api/rifas/{id}/                   - Eliminar rifa (solo admin)

RIFAS - ACCIONES CUSTOM:
- GET    /api/rifas/activa/                 - Obtener rifa activa actual
- GET    /api/rifas/historial-ganadores/    - Historial de ganadores
- GET    /api/rifas/estadisticas/           - Estadísticas generales
- GET    /api/rifas/{id}/elegibilidad/      - Verificar mi elegibilidad
- POST   /api/rifas/{id}/participar/        - Registrar participación
- GET    /api/rifas/{id}/participantes/     - Lista participantes (admin)
- POST   /api/rifas/{id}/sortear/           - Realizar sorteo (admin)
- POST   /api/rifas/{id}/cancelar/          - Cancelar rifa (admin)

PARTICIPACIONES:
- GET    /api/participaciones/              - Listar participaciones
- GET    /api/participaciones/{id}/         - Detalle de participación
- GET    /api/participaciones/mis-participaciones/  - Mis participaciones
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RifaViewSet, ParticipacionViewSet

# ============================================
#  ROUTER PRINCIPAL
# ============================================

router = DefaultRouter()

# Registrar ViewSets
router.register(
    r'rifas',
    RifaViewSet,
    basename='rifa'
)

router.register(
    r'participaciones',
    ParticipacionViewSet,
    basename='participacion'
)

# ============================================
#  ENDPOINTS DIRECTOS PARA APP
# ============================================

rifa_mes_actual = RifaViewSet.as_view({"get": "mes_actual"})
rifa_detalle = RifaViewSet.as_view({"get": "detalle"})
rifa_participar = RifaViewSet.as_view({"post": "participar"})

# ============================================
#  URL PATTERNS
# ============================================

app_name = 'rifas'

urlpatterns = [
    path('mes-actual/', rifa_mes_actual, name='rifa-mes-actual'),
    path('<uuid:pk>/detalle/', rifa_detalle, name='rifa-detalle'),
    path('<uuid:pk>/participar/', rifa_participar, name='rifa-participar'),
    # Incluir todas las rutas del router
    path('', include(router.urls)),
]
