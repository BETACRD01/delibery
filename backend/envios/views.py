# envios/views.py
"""
Vistas API para el módulo de Envíos.
Controlador que conecta la petición HTTP con la lógica de cálculo (Baños/Tena).
"""

import logging
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from administradores.permissions import (
    AdministradorActivo,
    EsAdministrador,
    PuedeConfigurarSistema,
)
from administradores.views import BaseAdminViewSetMixin
from .models import CiudadEnvio, ConfiguracionEnvios, ZonaTarifariaEnvio
from .serializers import (
    CotizacionEnvioRequestSerializer,
    CotizacionEnvioResponseSerializer,
    ZonaTarifariaEnvioSerializer,
    CiudadEnvioSerializer,
    ConfiguracionEnviosSerializer,
)
from .services import CalculadoraEnvioService

logger = logging.getLogger('envios')

class CotizarEnvioView(APIView):
    """
    Endpoint: POST /api/envios/cotizar/
    Calcula el costo de envío.
    
    LÓGICA:
    1. Recibe coordenadas de destino.
    2. El servicio detecta automáticamente el Hub más cercano (Baños o Tena).
    3. Devuelve tarifa base + extras.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # 1. Validar entrada de datos
            # El serializer verifica que lat_destino y lng_destino existan y sean números
            serializer_req = CotizacionEnvioRequestSerializer(data=request.data)
            
            if not serializer_req.is_valid():
                logger.warning(f"Datos de cotización inválidos: {serializer_req.errors}")
                return Response(serializer_req.errors, status=status.HTTP_400_BAD_REQUEST)
            
            data = serializer_req.validated_data

            # 2. Llamar al servicio lógico (CORREGIDO)
            # Ya NO pasamos 'lat_origen' ni 'proveedores'. 
            # El servicio usa sus constantes fijas para Baños/Tena.
            resultado = CalculadoraEnvioService.cotizar_envio(
                lat_destino=data['lat_destino'],
                lng_destino=data['lng_destino'],
                tipo_servicio=data.get('tipo_servicio', 'delivery')
            )

            # 3. Responder con datos estructurados
            # Usamos el serializer de respuesta si existe, o enviamos el dict directo
            try:
                serializer_res = CotizacionEnvioResponseSerializer(resultado)
                return Response(serializer_res.data, status=status.HTTP_200_OK)
            except NameError:
                # Fallback si no has creado el ResponseSerializer aún
                return Response(resultado, status=status.HTTP_200_OK)

        except ValueError as e:
            # Errores de negocio (ej: coordenadas imposibles)
            return Response(
                {"error": str(e)}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        except Exception as e:
            # Errores técnicos inesperados
            logger.error(f"Error crítico en cotización: {e}", exc_info=True)
            return Response(
                {"error": "No se pudo calcular el envío en este momento."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================
# ADMIN: CONFIGURACIÓN DE ENVÍOS
# ============================================


class ConfiguracionEnviosViewSet(BaseAdminViewSetMixin, viewsets.ViewSet):
    """
    Endpoints admin para leer/actualizar recargo y horario nocturno.
    """
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeConfigurarSistema,
    ]

    def list(self, request):
        config = ConfiguracionEnvios.obtener()
        serializer = ConfiguracionEnviosSerializer(config)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def update(self, request, pk=None):
        config = ConfiguracionEnvios.obtener()
        serializer = ConfiguracionEnviosSerializer(config, data=request.data, partial=False)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)

    def partial_update(self, request, pk=None):
        config = ConfiguracionEnvios.obtener()
        serializer = ConfiguracionEnviosSerializer(config, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class ZonaTarifariaEnvioViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """
    CRUD de zonas tarifarias (tarifa base, km incluidos y extras).
    """
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeConfigurarSistema,
    ]
    serializer_class = ZonaTarifariaEnvioSerializer
    queryset = ZonaTarifariaEnvio.objects.all().order_by("orden")


class CiudadEnvioViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """
    CRUD de hubs/ciudades de origen (puntos cero).
    """
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeConfigurarSistema,
    ]
    serializer_class = CiudadEnvioSerializer
    queryset = CiudadEnvio.objects.all().order_by("nombre")
