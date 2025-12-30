# envios/serializers.py
"""
Serializers para validar entrada y salida de datos de envíos.
Sincronizado con la lógica de Baños/Tena.
"""
from rest_framework import serializers
import logging
from decimal import Decimal

from .models import (
    ZonaTarifariaEnvio,
    CiudadEnvio,
    ConfiguracionEnvios,
)

logger = logging.getLogger('envios')

# ======================================================
#  REQUEST (Lo que envía el celular)
# ======================================================
class CotizacionEnvioRequestSerializer(serializers.Serializer):
    lat_destino = serializers.FloatField(
        required=True, 
        help_text="Latitud del cliente",
        min_value=-90.0,
        max_value=90.0,
        error_messages={
            'min_value': 'La latitud debe estar entre -90 y 90 grados.',
            'max_value': 'La latitud debe estar entre -90 y 90 grados.',
            'invalid': 'La latitud debe ser un número válido.',
            'required': 'La latitud es requerida.'
        }
    )
    
    lng_destino = serializers.FloatField(
        required=True, 
        help_text="Longitud del cliente",
        min_value=-180.0,
        max_value=180.0,
        error_messages={
            'min_value': 'La longitud debe estar entre -180 y 180 grados.',
            'max_value': 'La longitud debe estar entre -180 y 180 grados.',
            'invalid': 'La longitud debe ser un número válido.',
            'required': 'La longitud es requerida.'
        }
    )
    
    tipo_servicio = serializers.CharField(
        required=False, 
        default='delivery',
        max_length=50
    )

    # --- NUEVOS CAMPOS PARA COURIER/ENCARGO ---
    lat_origen = serializers.FloatField(
        required=False, 
        allow_null=True,
        help_text="Latitud de recogida (Obligatorio para tipo_servicio='courier')"
    )
    lng_origen = serializers.FloatField(
        required=False, 
        allow_null=True,
        help_text="Longitud de recogida (Obligatorio para tipo_servicio='courier')"
    )

    def validate(self, data):
        """
        Validación adicional a nivel de objeto.
        Verifica que las coordenadas sean razonables para Ecuador.
        """
        lat = data.get('lat_destino')
        lng = data.get('lng_destino')
        
        # Validación de Courier
        tipo = data.get('tipo_servicio', 'delivery')
        lat_origen = data.get('lat_origen')
        lng_origen = data.get('lng_origen')

        # Regla de Negocio: Si es courier, NECESITAMOS saber dónde recoger
        if tipo == 'courier':
            if lat_origen is None or lng_origen is None:
                raise serializers.ValidationError(
                    "Para el servicio de Courier/Encargo, las coordenadas de origen son obligatorias."
                )
        
        # Coordenadas aproximadas de Ecuador: -5° a 2° lat, -92° a -75° lng
        # Solo advertencia en logs, no rechazamos la petición
        if lat is not None and lng is not None:
            if not (-6 <= lat <= 3) or not (-93 <= lng <= -74):
                logger.warning(
                    f"Coordenadas fuera de Ecuador detectadas: "
                    f"lat={lat}, lng={lng}. Posible error del cliente."
                )
        
        return data


# ======================================================
#  CREAR PEDIDO COURIER (Request desde App Móvil)
# ======================================================
class UbicacionSerializer(serializers.Serializer):
    """Serializer para datos de ubicación (origen/destino)"""
    lat = serializers.FloatField(required=True, min_value=-90, max_value=90)
    lng = serializers.FloatField(required=True, min_value=-180, max_value=180)
    direccion = serializers.CharField(required=True, max_length=500)


class ReceptorSerializer(serializers.Serializer):
    """Serializer para datos del receptor del paquete"""
    nombre = serializers.CharField(required=True, max_length=150)
    telefono = serializers.CharField(required=True, max_length=20)


class PaqueteSerializer(serializers.Serializer):
    """Serializer para datos del paquete"""
    tipo = serializers.CharField(required=True, max_length=50)
    descripcion = serializers.CharField(required=False, allow_blank=True, max_length=500)


class PagoSerializer(serializers.Serializer):
    """Serializer para datos de pago"""
    metodo = serializers.ChoiceField(choices=['EFECTIVO', 'TRANSFERENCIA'], required=True)
    total_estimado = serializers.FloatField(required=True, min_value=0)


class CrearPedidoCourierSerializer(serializers.Serializer):
    """
    Serializer principal para crear un pedido de tipo Courier.
    Recibe todos los datos necesarios desde la app móvil.
    """
    origen = UbicacionSerializer(required=True)
    destino = UbicacionSerializer(required=True)
    receptor = ReceptorSerializer(required=True)
    paquete = PaqueteSerializer(required=True)
    pago = PagoSerializer(required=True)

    def validate(self, data):
        """Validaciones adicionales"""
        origen = data.get('origen', {})
        destino = data.get('destino', {})
        
        # Verificar que origen y destino no sean el mismo punto
        if (origen.get('lat') == destino.get('lat') and 
            origen.get('lng') == destino.get('lng')):
            raise serializers.ValidationError(
                "El origen y destino no pueden ser el mismo punto."
            )
        
        return data

# ======================================================
#  RESPONSE (Lo que responde el servidor)
# ======================================================
class CotizacionEnvioResponseSerializer(serializers.Serializer):
    distancia_km = serializers.FloatField()
    tiempo_mins = serializers.IntegerField()
    #
    costo_base = serializers.FloatField()
    costo_km_extra = serializers.FloatField()
    recargo_nocturno = serializers.FloatField()  
    total_envio = serializers.FloatField()
    #
    origen_referencia = serializers.CharField()
    es_horario_nocturno = serializers.BooleanField(required=False, default=False)
    metodo_calculo = serializers.CharField()
    advertencia = serializers.CharField(required=False, allow_null=True)  # Campo opcional para warnings


# ======================================================
#  ADMIN: CONFIGURACIÓN DINÁMICA DE ENVÍOS
# ======================================================


class ZonaTarifariaEnvioSerializer(serializers.ModelSerializer):
    class Meta:
        model = ZonaTarifariaEnvio
        fields = (
            "id",
            "codigo",
            "nombre_display",
            "tarifa_base",
            "km_incluidos",
            "precio_km_extra",
            "max_distancia_km",
            "orden",
        )

    def validate(self, attrs):
        max_dist = attrs.get("max_distancia_km")
        if max_dist is not None and max_dist <= Decimal("0"):
            raise serializers.ValidationError(
                {"max_distancia_km": "Debe ser mayor a 0 o dejar vacío para zona abierta."}
            )
        return attrs


class CiudadEnvioSerializer(serializers.ModelSerializer):
    class Meta:
        model = CiudadEnvio
        fields = (
            "id",
            "codigo",
            "nombre",
            "lat",
            "lng",
            "radio_max_cobertura_km",
            "activo",
        )

    def validate_radio_max_cobertura_km(self, value):
        if value <= 0:
            raise serializers.ValidationError("El radio de cobertura debe ser mayor a 0.")
        return value

    def validate(self, attrs):
        lat = attrs.get("lat")
        lng = attrs.get("lng")
        if lat is not None and (lat < Decimal("-90") or lat > Decimal("90")):
            raise serializers.ValidationError({"lat": "Latitud inválida."})
        if lng is not None and (lng < Decimal("-180") or lng > Decimal("180")):
            raise serializers.ValidationError({"lng": "Longitud inválida."})
        return attrs


class ConfiguracionEnviosSerializer(serializers.ModelSerializer):
    class Meta:
        model = ConfiguracionEnvios
        fields = (
            "id",
            "recargo_nocturno",
            "hora_inicio_nocturno",
            "hora_fin_nocturno",
            "actualizado_en",
        )
        read_only_fields = ("id", "actualizado_en")

    def validate(self, attrs):
        inicio = attrs.get("hora_inicio_nocturno", getattr(self.instance, "hora_inicio_nocturno", None))
        fin = attrs.get("hora_fin_nocturno", getattr(self.instance, "hora_fin_nocturno", None))
        if inicio is not None and fin is not None and not (0 <= inicio <= 23 and 0 <= fin <= 23):
            raise serializers.ValidationError("Las horas deben estar entre 0 y 23.")
        return attrs
