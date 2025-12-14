# notificaciones/urls.py
"""
Rutas de la API de Notificaciones.
Utiliza DefaultRouter para generar automáticamente las rutas de las acciones
personalizadas (marcar_leida, estadisticas, etc).
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NotificacionViewSet

# Namespace para reversión de URLs (ej: 'notificaciones:notificacion-list')
app_name = 'notificaciones'
router = DefaultRouter()
router.register(r'', NotificacionViewSet, basename='notificacion')

urlpatterns = [
    path('', include(router.urls)),
]