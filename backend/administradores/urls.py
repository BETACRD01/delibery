# -*- coding: utf-8 -*-
# administradores/urls.py
"""
Configuración de URLs para el módulo de administradores
Rutas API RESTful automáticas con DefaultRouter
Endpoint especial para configuración global (Singleton)
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = "administradores"

# ============================================
# CONFIGURACIÓN DEL ROUTER
# ============================================

router = DefaultRouter()

# 1. Gestión de Usuarios y Roles
# Genera /admin/usuarios/ y /admin/usuarios/<pk>/
# LA ACCIÓN 'normales' DENTRO DE ESTE VIEWSET GENERA /admin/usuarios/normales/
router.register(
    r"usuarios", 
    views.GestionUsuariosViewSet, 
    basename="admin-usuarios"
)

# Asegúrate de haber agregado la clase AdministradoresViewSet en views.py
router.register(
    r"administradores", 
    views.AdministradoresViewSet, 
    basename="admin-administradores"
)

router.register(
    r"solicitudes-cambio-rol",
    views.GestionSolicitudesCambioRolViewSet,
    basename="admin-solicitudes-cambio-rol",
)

# 2. Gestión de Actores Externos
router.register(
    r"proveedores", 
    views.GestionProveedoresViewSet, 
    basename="admin-proveedores"
)
router.register(
    r"repartidores", 
    views.GestionRepartidoresViewSet, 
    basename="admin-repartidores"
)

# 3. Auditoría y Métricas
router.register(
    r"acciones", 
    views.AccionesAdministrativasViewSet, 
    basename="admin-acciones"
)
router.register(
    r"dashboard", 
    views.DashboardAdminViewSet, 
    basename="admin-dashboard"
)



# ============================================
# DEFINICIÓN DE PATRONES URL
# ============================================

urlpatterns = [
    # Incluir todas las rutas generadas por el router
    path("", include(router.urls)),

    # Endpoint Singleton: Configuración del Sistema
    path(
        "configuracion/",
        views.ConfiguracionSistemaViewSet.as_view({
            "get": "list",      # Nota: devolverá una lista con 1 objeto
            "put": "update",    # Funciona gracias al override de get_object en la view
            "patch": "partial_update"
        }),
        name="admin-configuracion",
    ),
]