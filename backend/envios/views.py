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
            # Pasamos TODOS los parámetros, incluyendo los nuevos opcionales para courier
            resultado = CalculadoraEnvioService.cotizar_envio(
                lat_destino=data['lat_destino'],
                lng_destino=data['lng_destino'],
                lat_origen=data.get('lat_origen'), # Nuevo: Puede ser None
                lng_origen=data.get('lng_origen'), # Nuevo: Puede ser None
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


class CrearPedidoCourierView(APIView):
    """
    Endpoint: POST /api/envios/crear-courier/
    Crea un pedido de tipo Courier con todos sus datos.
    
    Payload:
    {
        "origen": {"lat": -1.39, "lng": -78.42, "direccion": "..."},
        "destino": {"lat": -1.40, "lng": -78.43, "direccion": "..."},
        "receptor": {"nombre": "Juan", "telefono": "0999999999"},
        "paquete": {"tipo": "Documentos", "descripcion": "..."},
        "pago": {"metodo": "EFECTIVO", "total_estimado": 3.50}
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from django.db import transaction
        from decimal import Decimal
        from pedidos.models import Pedido, TipoPedido, MetodoPago
        from .models import Envio
        from .serializers import CrearPedidoCourierSerializer
        
        try:
            # 1. Validar datos de entrada
            serializer = CrearPedidoCourierSerializer(data=request.data)
            if not serializer.is_valid():
                logger.warning(f"Datos de courier inválidos: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            data = serializer.validated_data
            origen = data['origen']
            destino = data['destino']
            receptor = data['receptor']
            paquete = data['paquete']
            pago = data['pago']
            
            # 2. Obtener perfil del usuario
            try:
                perfil = request.user.perfil
            except Exception:
                return Response(
                    {"error": "Usuario no tiene perfil asociado."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # 3. Cotizar para obtener los costos reales
            cotizacion = CalculadoraEnvioService.cotizar_envio(
                lat_destino=destino['lat'],
                lng_destino=destino['lng'],
                lat_origen=origen['lat'],
                lng_origen=origen['lng'],
                tipo_servicio='courier'
            )
            
            # 4. Mapear método de pago
            metodo_pago_map = {
                'EFECTIVO': MetodoPago.EFECTIVO,
                'TRANSFERENCIA': MetodoPago.TRANSFERENCIA,
            }
            metodo_pago = metodo_pago_map.get(pago['metodo'], MetodoPago.EFECTIVO)
            
            # 5. Crear Pedido y Envio en transacción
            with transaction.atomic():
                # Crear el Pedido
                pedido = Pedido.objects.create(
                    cliente=perfil,
                    tipo=TipoPedido.DIRECTO,  # Courier es tipo directo
                    metodo_pago=metodo_pago,
                    descripcion=f"Courier: {paquete['tipo']} - {paquete.get('descripcion', '')}. "
                               f"Receptor: {receptor['nombre']} ({receptor['telefono']})",
                    total=Decimal(str(cotizacion['total_envio'])),
                    direccion_origen=origen['direccion'],
                    latitud_origen=origen['lat'],
                    longitud_origen=origen['lng'],
                    direccion_entrega=destino['direccion'],
                    latitud_destino=destino['lat'],
                    longitud_destino=destino['lng'],
                    instrucciones_entrega=paquete.get('instrucciones', ''),
                )
                
                # Crear el Envio (logística)
                envio = Envio.objects.create(
                    pedido=pedido,
                    tipo_servicio='courier',
                    lat_origen_real=Decimal(str(origen['lat'])),
                    lng_origen_real=Decimal(str(origen['lng'])),
                    distancia_km=Decimal(str(cotizacion['distancia_km'])),
                    tiempo_estimado_mins=cotizacion['tiempo_mins'],
                    costo_base=Decimal(str(cotizacion['costo_base'])),
                    costo_km_adicional=Decimal(str(cotizacion['costo_km_extra'])),
                    recargo_nocturno=Decimal(str(cotizacion['recargo_nocturno'])),
                    total_envio=Decimal(str(cotizacion['total_envio'])),
                    ciudad_origen=cotizacion.get('ciudad_origen', 'Personalizado'),
                    zona_destino=cotizacion.get('zona_destino', 'courier'),
                    lat_origen_calc=origen['lat'],
                    lng_origen_calc=origen['lng'],
                    lat_destino_calc=destino['lat'],
                    lng_destino_calc=destino['lng'],
                )
                
                logger.info(f"Pedido Courier creado: {pedido.numero_pedido} - Total: ${cotizacion['total_envio']}")
            
            # 6. Responder con éxito
            return Response({
                "success": True,
                "message": "Pedido de courier creado exitosamente",
                "pedido": {
                    "id": pedido.id,
                    "numero_pedido": pedido.numero_pedido,
                    "estado": pedido.estado,
                    "metodo_pago": pedido.metodo_pago,
                    "total": float(pedido.total),
                },
                "envio": {
                    "distancia_km": float(envio.distancia_km),
                    "tiempo_estimado_mins": envio.tiempo_estimado_mins,
                    "total_envio": float(envio.total_envio),
                }
            }, status=status.HTTP_201_CREATED)
            
        except ValueError as e:
            return Response(
                {"error": str(e)}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Error creando pedido courier: {e}", exc_info=True)
            return Response(
                {"error": "No se pudo crear el pedido en este momento."},
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
