# envios/serializers.py
"""
Serializers para validar entrada y salida de datos de envíos.
Sincronizado con la lógica de Baños/Tena.
"""
from rest_framework import serializers
import logging

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

    def validate(self, data):
        """
        Validación adicional a nivel de objeto.
        Verifica que las coordenadas sean razonables para Ecuador.
        """
        lat = data.get('lat_destino')
        lng = data.get('lng_destino')
        
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