from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    ConfiguracionEnviosViewSet,
    ZonaTarifariaEnvioViewSet,
    CiudadEnvioViewSet,
)

app_name = "envios_admin"

router = DefaultRouter()
router.register(r"configuracion", ConfiguracionEnviosViewSet, basename="configuracion-envios")
router.register(r"zonas", ZonaTarifariaEnvioViewSet, basename="zona-envio")
router.register(r"ciudades", CiudadEnvioViewSet, basename="ciudad-envio")

urlpatterns = [
    path("", include(router.urls)),
]
