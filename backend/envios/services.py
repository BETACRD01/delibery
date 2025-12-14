# envios/services.py
"""
Servicio de Logística Multi-Ciudad (Baños y Tena) con Tarifas Nocturnas.
Integración: Google Maps + Fallback Matemático + Detección de Horario.
"""
import googlemaps
import logging
import pytz
from decimal import Decimal
from django.conf import settings
from django.utils import timezone
from math import radians, cos, sin, asin, sqrt

logger = logging.getLogger('envios')

class CalculadoraEnvioService:
    """
    Calculadora de envíos inteligente.
    1. Detecta la ciudad (Baños o Tena).
    2. Calcula distancia real (Google Maps).
    3. Aplica recargos (Distancia y Horario Nocturno).
    4. Valida cobertura máxima.
    """
    
    # --- CONFIGURACIÓN DE HUBS (Puntos Cero) ---
    CIUDADES = {
        'BANOS': {
            'nombre': 'Baños de Agua Santa',
            'lat': -1.3964,
            'lng': -78.4247,
            'radio_max_cobertura_km': 15.0 # Runtún, Río Verde, etc.
        },
        'TENA': {
            'nombre': 'Tena',
            'lat': -0.9938,
            'lng': -77.8129,
            'radio_max_cobertura_km': 20.0 # Puerto Napo, Archidona, etc.
        }
    }

    # --- CONFIGURACIÓN DE ZONAS TARIFARIAS ---
    # Zona Centro: 0-3 km desde el hub
    # Zona Periférica: 3-8 km desde el hub
    # Zona Rural: 8+ km desde el hub
    ZONA_CENTRO_MAX_KM = Decimal('3.0')
    ZONA_PERIFERICA_MAX_KM = Decimal('8.0')

    # --- TARIFARIO POR ZONA ---
    TARIFAS_ZONA = {
        'centro': {
            'tarifa_base': Decimal('1.50'),
            'km_incluidos': Decimal('1.5'),
            'precio_km_extra': Decimal('0.50'),
            'nombre_display': 'Centro (Urbano)'
        },
        'periferica': {
            'tarifa_base': Decimal('2.50'),
            'km_incluidos': Decimal('2.0'),
            'precio_km_extra': Decimal('0.70'),
            'nombre_display': 'Periferia Cercana'
        },
        'rural': {
            'tarifa_base': Decimal('4.00'),
            'km_incluidos': Decimal('3.0'),
            'precio_km_extra': Decimal('1.00'),
            'nombre_display': 'Fuera de Ciudad / Rural'
        }
    }

    # --- CONFIGURACIÓN NOCTURNA ---
    RECARGO_NOCTURNO = Decimal('1.00')  # Dólar extra en la noche
    HORA_INICIO_NOCHE = 20              # 8 PM (20:00)
    HORA_FIN_NOCHE = 6                  # 6 AM (06:00)

    @classmethod
    def cotizar_envio(cls, lat_destino, lng_destino, tipo_servicio='delivery'):
        """
        Proceso maestro de cotización.
        Usa Google Maps API como fuente principal de cálculo de distancia.
        Fallback matemático solo se usa en caso de error de la API.
        """
        # 1. Detectar ciudad de origen más cercana
        hub_origen = cls._detectar_hub_mas_cercano(lat_destino, lng_destino)
        
        lat_origen = hub_origen['lat']
        lng_origen = hub_origen['lng']
        ciudad_nombre = hub_origen['nombre']
        radio_cobertura = hub_origen['radio_max_cobertura_km']

        distancia_km = Decimal('0.0')
        tiempo_mins = 0
        metodo_calculo = "Google Maps API"
        usa_fallback = False
        error_maps = None

        # 2. Calcular Distancia (Google Maps PRIORITARIO)
        try:
            api_key = getattr(settings, 'GOOGLE_MAPS_API_KEY', None)
            if not api_key:
                raise ValueError("GOOGLE_MAPS_API_KEY no configurada en settings")

            gmaps = googlemaps.Client(key=api_key)

            resultado = gmaps.distance_matrix(
                origins=[(lat_origen, lng_origen)],
                destinations=[(lat_destino, lng_destino)],
                mode="driving",
                language="es",
                units="metric"
            )

            if resultado['status'] == 'OK':
                elemento = resultado['rows'][0]['elements'][0]
                if elemento['status'] == 'OK':
                    metros = elemento['distance']['value']
                    segundos = elemento['duration']['value']
                    distancia_km = Decimal(metros) / Decimal(1000)
                    tiempo_mins = int(segundos / 60)
                    logger.info(f"Google Maps: {distancia_km}km desde {ciudad_nombre}")
                else:
                    raise Exception(f"Ruta no disponible: {elemento['status']}")
            else:
                raise Exception(f"Error en respuesta de API: {resultado['status']}")

        except Exception as e:
            usa_fallback = True
            error_maps = str(e)
            logger.error(f"⚠️ Error Google Maps: {e}. Usando cálculo matemático de respaldo.")
            # Fallback matemático SOLO en caso de error
            distancia_km = cls._calcular_fallback_haversine(lat_origen, lng_origen, lat_destino, lng_destino)
            tiempo_mins = int(distancia_km * 5) + 5
            metodo_calculo = f"Estimación Matemática ({ciudad_nombre})"

        # 3. Determinar Zona Tarifaria
        distancia_km = distancia_km.quantize(Decimal('0.01'))
        zona_codigo = cls._determinar_zona(distancia_km)
        tarifa_zona = cls.TARIFAS_ZONA[zona_codigo]

        # 4. Calcular Costos Base + Distancia (según zona)
        tarifa_base = tarifa_zona['tarifa_base']
        km_incluidos = tarifa_zona['km_incluidos']
        precio_km_extra = tarifa_zona['precio_km_extra']

        costo_total = tarifa_base
        costo_extra_km = Decimal('0.00')

        if distancia_km > km_incluidos:
            kms_adicionales = distancia_km - km_incluidos
            costo_extra_km = kms_adicionales * precio_km_extra
            costo_total += costo_extra_km

        # 5. Aplicar Recargo Nocturno
        es_noche = cls._es_horario_nocturno()
        valor_nocturno = Decimal('0.00')

        if es_noche:
            valor_nocturno = cls.RECARGO_NOCTURNO
            costo_total += valor_nocturno

        # 6. PREPARAR RESULTADO CON INFORMACIÓN DE ZONA
        resultado_dict = {
            'distancia_km': float(distancia_km),
            'tiempo_mins': tiempo_mins,
            'costo_base': float(round(tarifa_base, 2)),
            'costo_km_extra': float(round(costo_extra_km, 2)),
            'recargo_nocturno': float(round(valor_nocturno, 2)),
            'total_envio': float(round(costo_total, 2)),
            'origen_referencia': f"Centro de {ciudad_nombre}",
            'ciudad_origen': ciudad_nombre,
            'zona_destino': zona_codigo,
            'zona_nombre': tarifa_zona['nombre_display'],
            'es_horario_nocturno': es_noche,
            'metodo_calculo': metodo_calculo,
            'usa_google_maps': not usa_fallback,  # True si usó Google Maps correctamente
        }

        # Agregar advertencia si se usó fallback
        if usa_fallback:
            resultado_dict['advertencia_calculo'] = (
                f"⚠️ No se pudo calcular la distancia con Google Maps ({error_maps}). "
                f"Se usó cálculo matemático de respaldo. La distancia puede variar de la real."
            )
            logger.warning(f"Cotización usando fallback para destino ({lat_destino}, {lng_destino})")

        # Verificar si excede el radio de cobertura
        if float(distancia_km) > radio_cobertura:
            resultado_dict['advertencia'] = (
                f"La distancia ({distancia_km} km) está fuera del radio de cobertura "
                f"de {ciudad_nombre} ({radio_cobertura} km). El servicio podría no estar disponible."
            )
            logger.warning(
                f"Solicitud fuera de cobertura: {distancia_km}km > {radio_cobertura}km en {ciudad_nombre}"
            )

        return resultado_dict

    @classmethod
    def _detectar_hub_mas_cercano(cls, lat_dest, lng_dest):
        """
        Determina si el cliente está más cerca de Baños o de Tena.
        """
        distancia_banos = cls._calcular_distancia_lineal(
            cls.CIUDADES['BANOS']['lat'], cls.CIUDADES['BANOS']['lng'], 
            lat_dest, lng_dest
        )
        distancia_tena = cls._calcular_distancia_lineal(
            cls.CIUDADES['TENA']['lat'], cls.CIUDADES['TENA']['lng'], 
            lat_dest, lng_dest
        )

        # Retornar la configuración de la ciudad más cercana
        if distancia_tena < distancia_banos:
            return cls.CIUDADES['TENA']
        return cls.CIUDADES['BANOS']

    @classmethod
    def _determinar_zona(cls, distancia_km):
        """
        Determina la zona tarifaria basándose en la distancia desde el hub.

        Args:
            distancia_km: Distancia en kilómetros desde el centro de la ciudad

        Returns:
            str: Código de zona ('centro', 'periferica', 'rural')
        """
        distancia = Decimal(str(distancia_km))

        if distancia <= cls.ZONA_CENTRO_MAX_KM:
            return 'centro'
        elif distancia <= cls.ZONA_PERIFERICA_MAX_KM:
            return 'periferica'
        else:
            return 'rural'

    @classmethod
    def _es_horario_nocturno(cls):
        """Verifica si la hora actual en Ecuador implica tarifa nocturna"""
        try:
            zona_horaria = pytz.timezone('America/Guayaquil')
            hora_actual = timezone.now().astimezone(zona_horaria).hour
            
            # Es noche si:
            # - Es mayor o igual a las 20:00 (8 PM)
            # - O es menor a las 06:00 (6 AM)
            return hora_actual >= cls.HORA_INICIO_NOCHE or hora_actual < cls.HORA_FIN_NOCHE
        except Exception:
            return False # En caso de error, cobrar tarifa normal

    @staticmethod
    def _calcular_distancia_lineal(lat1, lon1, lat2, lon2):
        """Cálculo Haversine puro (sin factor de corrección) para comparaciones"""
        try:
            lat1, lon1, lat2, lon2 = map(radians, [float(lat1), float(lon1), float(lat2), float(lon2)])
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
            c = 2 * asin(sqrt(a))
            return float(c * 6371)
        except:
            return 9999.0

    @classmethod
    def _calcular_fallback_haversine(cls, lat_origen, lng_origen, lat_dest, lng_dest):
        """Cálculo con factor de corrección por montaña (x1.3)"""
        distancia_lineal = cls._calcular_distancia_lineal(lat_origen, lng_origen, lat_dest, lng_dest)
        # Multiplicamos por 1.3 para simular curvas de carretera en zona Andina/Amazónica
        return Decimal(distancia_lineal * 1.3)