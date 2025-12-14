# envios/views.py
"""
Vistas API para el módulo de Envíos.
Controlador que conecta la petición HTTP con la lógica de cálculo (Baños/Tena).
"""

import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny

from .services import CalculadoraEnvioService
from .serializers import CotizacionEnvioRequestSerializer, CotizacionEnvioResponseSerializer

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