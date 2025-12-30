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

from .models import (
    CiudadEnvio,
    ConfiguracionEnvios,
    ZonaTarifariaEnvio,
    DEFAULT_CIUDADES,
    DEFAULT_ZONAS,
)

logger = logging.getLogger("envios")


class CalculadoraEnvioService:
    """
    Calculadora de envíos inteligente.
    1. Detecta la ciudad (Baños o Tena).
    2. Calcula distancia real (Google Maps).
    3. Aplica recargos (Distancia y Horario Nocturno).
    3. Aplica recargos (Distancia y Horario Nocturno).
    4. Valida cobertura máxima.
    """

    # Constantes para Courier (Podrían ir en DB en el futuro)
    COURIER_TARIFA_BASE = Decimal("1.50")
    COURIER_PRECIO_KM = Decimal("0.50") 
    COURIER_TARIFA_MINIMA = Decimal("2.00")

    @classmethod
    def cotizar_envio(cls, lat_destino, lng_destino, lat_origen=None, lng_origen=None, tipo_servicio="delivery"):
        """
        Lógica Híbrida:
        1. Delivery (Comida): Calcula desde Hub (Baños/Tena) -> Cliente.
        2. Courier (Paquete): Calcula desde Cliente A -> Cliente B.
        """
        
        # 1. DEFINICIÓN DE PUNTOS A y B
        es_courier = (tipo_servicio == 'courier')
        
        if es_courier and lat_origen is not None and lng_origen is not None:
            # MODO COURIER: El origen lo define el usuario
            origen_lat = lat_origen
            origen_lng = lng_origen
            ciudad_nombre = "Ubicación Personalizada"
            radio_cobertura = 50.0 # Cobertura amplia para envíos
        else:
            # MODO DELIVERY: El origen es el Hub más cercano
            hub_origen = cls._detectar_hub_mas_cercano(lat_destino, lng_destino)
            origen_lat = hub_origen["lat"]
            origen_lng = hub_origen["lng"]
            ciudad_nombre = hub_origen["nombre"]
            radio_cobertura = hub_origen["radio_max_cobertura_km"]

        config_envios = cls._obtener_configuracion()

        distancia_km = Decimal("0.0")
        tiempo_mins = 0
        metodo_calculo = "Google Maps API"
        usa_fallback = False
        error_maps = None

        # 2. Calcular Distancia (Google Maps PRIORITARIO)
        try:
            api_key = getattr(settings, "GOOGLE_MAPS_API_KEY", None)
            if not api_key:
                raise ValueError("GOOGLE_MAPS_API_KEY no configurada en settings")

            gmaps = googlemaps.Client(key=api_key)

            resultado = gmaps.distance_matrix(
                origins=[(origen_lat, origen_lng)],
                destinations=[(lat_destino, lng_destino)],
                mode="driving",
                language="es",
                units="metric",
            )

            if resultado["status"] == "OK":
                elemento = resultado["rows"][0]["elements"][0]
                if elemento["status"] == "OK":
                    metros = elemento["distance"]["value"]
                    segundos = elemento["duration"]["value"]
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
            logger.error(
                f"⚠️ Error Google Maps: {e}. Usando cálculo matemático de respaldo."
            )
            # Fallback matemático SOLO en caso de error
            distancia_km = cls._calcular_fallback_haversine(
                origen_lat, origen_lng, lat_destino, lng_destino
            )
            tiempo_mins = int(distancia_km * 5) + 5
            metodo_calculo = f"Estimación Matemática ({ciudad_nombre})"

        if es_courier:
            # --- FÓRMULA LINEAL PARA COURIER ---
            # Precio = Base + (Km * Precio)
            tarifa_base = cls.COURIER_TARIFA_BASE
            costo_extra_km = distancia_km * cls.COURIER_PRECIO_KM
            
            calculado = tarifa_base + costo_extra_km
            # Aplicar tarifa mínima
            costo_total = max(calculado, cls.COURIER_TARIFA_MINIMA)
            
            zona_actual = {"codigo": "courier", "nombre_display": "Tarifa por Distancia"}
            
        else:
            # 4. Calcular Costos Base + Distancia (según zona) - MODO DELIVERY
            zona_actual = cls._determinar_zona(distancia_km)
            tarifa_base = zona_actual["tarifa_base"]
            km_incluidos = zona_actual["km_incluidos"]
            precio_km_extra = zona_actual["precio_km_extra"]

            costo_total = tarifa_base
            costo_extra_km = Decimal("0.00")

            if distancia_km > km_incluidos:
                kms_adicionales = distancia_km - km_incluidos
                costo_extra_km = kms_adicionales * precio_km_extra
                costo_total += costo_extra_km

        # 5. Aplicar Recargo Nocturno
        es_noche = cls._es_horario_nocturno(config_envios)
        valor_nocturno = Decimal("0.00")

        if es_noche:
            valor_nocturno = config_envios.recargo_nocturno
            costo_total += valor_nocturno

        # 6. PREPARAR RESULTADO CON INFORMACIÓN DE ZONA
        resultado_dict = {
            "distancia_km": float(distancia_km),
            "tiempo_mins": tiempo_mins,
            "costo_base": float(round(tarifa_base, 2)),
            "costo_km_extra": float(round(costo_extra_km, 2)),
            "recargo_nocturno": float(round(valor_nocturno, 2)),
            "total_envio": float(round(costo_total, 2)),
            "origen_referencia": f"Centro de {ciudad_nombre}",
            "ciudad_origen": ciudad_nombre,
            "zona_destino": zona_actual.get("codigo", "courier"),
            "zona_nombre": zona_actual.get("nombre_display", "Tarifa por Distancia"),
            "es_horario_nocturno": es_noche,
            "metodo_calculo": metodo_calculo,
            "tipo_servicio": tipo_servicio,
            "ganancia_repartidor_estimada": float(round(costo_total, 2)), # Por ahora 100%
            "comision_app_estimada": 0.0,
            "usa_google_maps": not usa_fallback,  # True si usó Google Maps correctamente
        }

        # Agregar advertencia si se usó fallback
        if usa_fallback:
            resultado_dict["advertencia_calculo"] = (
                f"No se pudo calcular la distancia con Google Maps ({error_maps}). "
                f"Se usó cálculo matemático de respaldo. La distancia puede variar de la real."
            )
            logger.warning(
                f"Cotización usando fallback para destino ({lat_destino}, {lng_destino})"
            )

        # Verificar si excede el radio de cobertura
        if float(distancia_km) > radio_cobertura:
            resultado_dict["advertencia"] = (
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
        ciudades = cls._obtener_ciudades_configuradas()
        mejor_ciudad = None
        menor_distancia = float("inf")

        for ciudad in ciudades:
            distancia = cls._calcular_distancia_lineal(
                ciudad["lat"], ciudad["lng"], lat_dest, lng_dest
            )
            if distancia < menor_distancia:
                menor_distancia = distancia
                mejor_ciudad = ciudad

        return mejor_ciudad or ciudades[0]

    @classmethod
    def _determinar_zona(cls, distancia_km):
        """
        Determina la zona tarifaria basándose en la distancia desde el hub.

        Args:
            distancia_km: Distancia en kilómetros desde el centro de la ciudad

        Returns:
            dict: Configuración completa de la zona aplicable
        """
        zonas = cls._obtener_zonas_configuradas()
        distancia = Decimal(str(distancia_km))

        for zona in zonas:
            max_distancia = zona["max_distancia_km"]
            if max_distancia is None or distancia <= max_distancia:
                return zona

        return zonas[-1] if zonas else {
            "codigo": "centro",
            "nombre_display": "Centro (Urbano)",
            "tarifa_base": Decimal("1.50"),
            "km_incluidos": Decimal("1.5"),
            "precio_km_extra": Decimal("0.50"),
            "max_distancia_km": Decimal("3.0"),
        }

    @classmethod
    def _es_horario_nocturno(cls, config=None):
        """Verifica si la hora actual en Ecuador implica tarifa nocturna"""
        try:
            if config is None:
                config = cls._obtener_configuracion()
            zona_horaria = pytz.timezone("America/Guayaquil")
            hora_actual = timezone.now().astimezone(zona_horaria).hour

            # Es noche si:
            # - Es mayor o igual a la hora de inicio nocturno
            # - O es menor a la hora de fin nocturno
            return (
                hora_actual >= config.hora_inicio_nocturno
                or hora_actual < config.hora_fin_nocturno
            )
        except Exception:
            return False  # En caso de error, cobrar tarifa normal

    @staticmethod
    def _calcular_distancia_lineal(lat1, lon1, lat2, lon2):
        """Cálculo Haversine puro (sin factor de corrección) para comparaciones"""
        try:
            lat1, lon1, lat2, lon2 = map(
                radians, [float(lat1), float(lon1), float(lat2), float(lon2)]
            )
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            return float(c * 6371)
        except:
            return 9999.0

    @classmethod
    def _calcular_fallback_haversine(cls, lat_origen, lng_origen, lat_dest, lng_dest):
        """Cálculo con factor de corrección por montaña (x1.3)"""
        distancia_lineal = cls._calcular_distancia_lineal(
            lat_origen, lng_origen, lat_dest, lng_dest
        )
        # Multiplicamos por 1.3 para simular curvas de carretera en zona Andina/Amazónica
        return Decimal(distancia_lineal * 1.3)

    @classmethod
    def _obtener_configuracion(cls):
        return ConfiguracionEnvios.obtener()

    @classmethod
    def _obtener_ciudades_configuradas(cls):
        ciudades_qs = CiudadEnvio.objects.filter(activo=True).order_by("nombre")
        if ciudades_qs.exists():
            return [
                cls._normalizar_ciudad(
                    {
                        "codigo": ciudad.codigo,
                        "nombre": ciudad.nombre,
                        "lat": ciudad.lat,
                        "lng": ciudad.lng,
                        "radio_max_cobertura_km": ciudad.radio_max_cobertura_km,
                    }
                )
                for ciudad in ciudades_qs
            ]

        return [cls._normalizar_ciudad(ciudad) for ciudad in DEFAULT_CIUDADES]

    @classmethod
    def _obtener_zonas_configuradas(cls):
        zonas_qs = ZonaTarifariaEnvio.objects.order_by("orden")
        if zonas_qs.exists():
            return [
                cls._normalizar_zona(
                    {
                        "codigo": zona.codigo,
                        "nombre_display": zona.nombre_display,
                        "tarifa_base": zona.tarifa_base,
                        "km_incluidos": zona.km_incluidos,
                        "precio_km_extra": zona.precio_km_extra,
                        "max_distancia_km": zona.max_distancia_km,
                    }
                )
                for zona in zonas_qs
            ]

        return [cls._normalizar_zona(zona) for zona in DEFAULT_ZONAS]

    @staticmethod
    def _normalizar_ciudad(datos):
        return {
            "codigo": datos["codigo"],
            "nombre": datos["nombre"],
            "lat": float(datos["lat"]),
            "lng": float(datos["lng"]),
            "radio_max_cobertura_km": float(datos["radio_max_cobertura_km"]),
        }

    @staticmethod
    def _normalizar_zona(datos):
        def to_decimal(valor):
            return Decimal(str(valor)) if valor is not None else None

        return {
            "codigo": datos["codigo"],
            "nombre_display": datos["nombre_display"],
            "tarifa_base": to_decimal(datos["tarifa_base"]),
            "km_incluidos": to_decimal(datos["km_incluidos"]),
            "precio_km_extra": to_decimal(datos["precio_km_extra"]),
            "max_distancia_km": to_decimal(datos.get("max_distancia_km")),
        }
