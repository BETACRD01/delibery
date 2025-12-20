# settings/urls.py

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse

# Imports para Documentación (Swagger)
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# ==========================================
# CONFIGURACIÓN SWAGGER
# ==========================================
schema_view = get_schema_view(
   openapi.Info(
      title="Deliber API",
      default_version='v1',
      description="Documentación oficial de la API de Deliber",
      terms_of_service="https://www.google.com/policies/terms/",
      contact=openapi.Contact(email="soporte@deliber.com"),
      license=openapi.License(name="BSD License"),
   ),
   public=True,
   permission_classes=(permissions.AllowAny,),
   authentication_classes=[],  # <--- ESTO SOLUCIONA EL ERROR ROJO (FETCH ERROR)
)

# ==========================================
# VISTAS DE SISTEMA
# ==========================================
def api_root(request):
    """Endpoint raíz para verificación de estado del servicio."""
    return JsonResponse({
        "service": "Deliber API",
        "status": "online",
        "version": "1.0.0",
        "environment": "debug" if settings.DEBUG else "production"
    })

def health_check(request):
    """Endpoint ligero para balanceadores de carga."""
    return JsonResponse({"status": "ok"})

# ==========================================
# DEFINICIÓN DE RUTAS
# ==========================================
urlpatterns = [
    # Sistema
    path("", api_root, name="api-root"),
    path("health/", health_check, name="health-check"),
    path("admin/", admin.site.urls),

    # Documentación API (Soluciona el 404 en /api/)
    path('api/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('api/redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    path('api/swagger<format>/', schema_view.without_ui(cache_timeout=0), name='schema-json'),

    # Autenticación y Cuentas (AllAuth + Custom)
    path("accounts/", include("allauth.urls")),
    path("api/auth/", include(("authentication.urls", "authentication"), namespace="authentication")),
    path("api/admin/", include("administradores.urls")),

    # Módulos Core de Negocio
    path("api/usuarios/", include(("usuarios.urls", "usuarios"), namespace="usuarios")),
    path("api/proveedores/", include(("proveedores.urls", "proveedores"), namespace="proveedores")),
    path("api/repartidores/", include(("repartidores.urls", "repartidores"), namespace="repartidores")),
    path("api/productos/", include(("productos.urls", "productos"), namespace="productos")),
    path("api/pedidos/", include(("pedidos.urls", "pedidos"), namespace="pedidos")),
    path("api/pagos/", include(("pagos.urls", "pagos"), namespace="pagos")),
    path("api/calificaciones/", include(("calificaciones.urls", "calificaciones"), namespace="calificaciones")),
    path("api/super-categorias/", include(("super_categorias.urls", "super_categorias"), namespace="super_categorias")),  # <-- Super Categorías
    
    # Módulos de Soporte y Engagement
    path("api/rifas/", include(("rifas.urls", "rifas"), namespace="rifas")),
    path("api/notificaciones/", include(("notificaciones.urls", "notificaciones"), namespace="notificaciones")),
    path("api/chat/", include(("chat.urls", "chat"), namespace="chat")),
    path("api/reportes/", include(("reportes.urls", "reportes"), namespace="reportes")),
    path("api/envios/", include("envios.url")),  # Público: cotizar
    path("api/admin/envios/", include("envios.admin_urls")),  # Solo admin: config/zonas/ciudades
    path("api/health/", health_check, name="api-health-check"),

    # Módulos de Integración
    path("api/health/", health_check, name="api-health-check"),

]

# ==========================================
# CONFIGURACIÓN DEBUG/MEDIA
# ==========================================
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Intentar cargar admin personalizado de repartidores si existe
try:
    from repartidores.admin import get_admin_urls
    urlpatterns += get_admin_urls()
except (ImportError, AttributeError):
    pass
