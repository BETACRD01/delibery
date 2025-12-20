from decimal import Decimal
import logging

from django.core.cache import cache
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

from pedidos.models import Pedido

logger = logging.getLogger("envios.config")

DEFAULT_CIUDADES = [
    {
        "codigo": "BANOS",
        "nombre": "Baños de Agua Santa",
        "lat": Decimal("-1.3964"),
        "lng": Decimal("-78.4247"),
        "radio_max_cobertura_km": Decimal("15.0"),
    },
    {
        "codigo": "TENA",
        "nombre": "Tena",
        "lat": Decimal("-0.9938"),
        "lng": Decimal("-77.8129"),
        "radio_max_cobertura_km": Decimal("20.0"),
    },
]

DEFAULT_ZONAS = [
    {
        "codigo": "centro",
        "nombre_display": "Centro (Urbano)",
        "tarifa_base": Decimal("1.50"),
        "km_incluidos": Decimal("1.5"),
        "precio_km_extra": Decimal("0.50"),
        "max_distancia_km": Decimal("3.0"),
        "orden": 1,
    },
    {
        "codigo": "periferica",
        "nombre_display": "Periferia Cercana",
        "tarifa_base": Decimal("2.50"),
        "km_incluidos": Decimal("2.0"),
        "precio_km_extra": Decimal("0.70"),
        "max_distancia_km": Decimal("8.0"),
        "orden": 2,
    },
    {
        "codigo": "rural",
        "nombre_display": "Fuera de Ciudad / Rural",
        "tarifa_base": Decimal("4.00"),
        "km_incluidos": Decimal("3.0"),
        "precio_km_extra": Decimal("1.00"),
        "max_distancia_km": None,
        "orden": 3,
    },
]

DEFAULT_CONFIGURACION_ENVIO = {
    "recargo_nocturno": Decimal("1.00"),
    "hora_inicio_nocturno": 20,
    "hora_fin_nocturno": 6,
}

CIUDADES_CACHE_KEY = "envios_ciudades"
ZONAS_CACHE_KEY = "envios_zonas"
CONFIG_CACHE_KEY = "envios_configuracion"
CACHE_TTL = 3600


class ZonaTarifariaEnvio(models.Model):
    """
    Define cada zona tarifaria que la app puede usar para cálculo de envíos.
    """
    ZONA_CENTRO = "centro"
    ZONA_PERIFERICA = "periferica"
    ZONA_RURAL = "rural"

    ZONAS_CHOICES = [
        (ZONA_CENTRO, "Centro (Urbano)"),
        (ZONA_PERIFERICA, "Periferia Cercana"),
        (ZONA_RURAL, "Fuera de Ciudad / Rural"),
    ]

    codigo = models.CharField(
        max_length=32,
        unique=True,
        choices=ZONAS_CHOICES,
        verbose_name="Código de Zona",
        help_text="Identificador interno de la zona tarifaria"
    )
    nombre_display = models.CharField(
        max_length=80,
        verbose_name="Nombre para mostrar",
        help_text="Texto que verá el usuario en el breakdown"
    )
    tarifa_base = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Tarifa base",
        help_text="Costo mínimo por la prestación del servicio dentro de esta zona"
    )
    km_incluidos = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Kilómetros incluidos",
        help_text="Distancia cubierta por la tarifa base"
    )
    precio_km_extra = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Precio por km extra",
        help_text="Costo por cada kilómetro adicional después del límite"
    )
    max_distancia_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        verbose_name="Distancia máxima (km)",
        help_text="Distancia máxima para pertenecer a esta zona (dejar vacío para zona abierta)",
        null=True,
        blank=True,
    )
    orden = models.PositiveSmallIntegerField(
        default=0,
        verbose_name="Orden de evaluación",
        help_text="Determina la prioridad al clasificarse las zonas"
    )

    class Meta:
        ordering = ["orden"]
        verbose_name = "Zona Tarifaria"
        verbose_name_plural = "Zonas Tarifarias"

    def __str__(self):
        return f"{self.get_codigo_display()}"

    def save(self, *args, **kwargs):
        """Limpiar cache al actualizar zonas."""
        super().save(*args, **kwargs)
        cache.delete(ZONAS_CACHE_KEY)


class CiudadEnvio(models.Model):
    """
    Centros logísticos (hubs) desde donde se calcula la logística.
    """
    codigo = models.CharField(
        max_length=32,
        unique=True,
        verbose_name="Código de ciudad"
    )
    nombre = models.CharField(
        max_length=120,
        verbose_name="Nombre oficial"
    )
    lat = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        verbose_name="Latitud"
    )
    lng = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        verbose_name="Longitud"
    )
    radio_max_cobertura_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        verbose_name="Radio máximo de cobertura (km)"
    )
    activo = models.BooleanField(
        default=True,
        verbose_name="Activo",
        help_text="Solo las ciudades activas son consideradas durante la cotización"
    )

    class Meta:
        verbose_name = "Ciudad de Envío"
        verbose_name_plural = "Ciudades de Envío"

    def __str__(self):
        return self.nombre

    def save(self, *args, **kwargs):
        """Limpiar cache al actualizar centros logísticos."""
        super().save(*args, **kwargs)
        cache.delete(CIUDADES_CACHE_KEY)


class ConfiguracionEnvios(models.Model):
    """
    Configuración global de recargos y horarios.
    Singleton for the shipping calculator.
    """
    recargo_nocturno = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=DEFAULT_CONFIGURACION_ENVIO["recargo_nocturno"],
        verbose_name="Recargo nocturno",
        help_text="Valor adicional que se suma durante la franja nocturna"
    )
    hora_inicio_nocturno = models.PositiveSmallIntegerField(
        default=DEFAULT_CONFIGURACION_ENVIO["hora_inicio_nocturno"],
        validators=[MinValueValidator(0), MaxValueValidator(23)],
        verbose_name="Hora inicio nocturno",
        help_text="Hora en formato 24h en la que aplica el recargo (inclusive)"
    )
    hora_fin_nocturno = models.PositiveSmallIntegerField(
        default=DEFAULT_CONFIGURACION_ENVIO["hora_fin_nocturno"],
        validators=[MinValueValidator(0), MaxValueValidator(23)],
        verbose_name="Hora fin nocturno",
        help_text="Hora en formato 24h en la que termina el recargo"
    )
    actualizado_en = models.DateTimeField(
        auto_now=True,
        verbose_name="Actualizado en"
    )

    class Meta:
        verbose_name = "Configuración de Envíos"
        verbose_name_plural = "Configuraciones de Envíos"

    def __str__(self):
        return f"Configuración de Envíos (actualizado: {self.actualizado_en:%Y-%m-%d %H:%M})"

    def save(self, *args, **kwargs):
        """
        Garantiza existencia única de la configuración y limpia cache.
        """
        self.pk = 1
        self.full_clean()
        cache.delete(CONFIG_CACHE_KEY)
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        """No se puede eliminar esta configuración."""
        raise ValidationError("La configuración de envíos no puede eliminarse.")

    @classmethod
    def obtener(cls):
        """Obtiene la instancia singleton con cache."""
        config = cache.get(CONFIG_CACHE_KEY)
        if config is None:
            config, created = cls.objects.get_or_create(
                pk=1,
                defaults=DEFAULT_CONFIGURACION_ENVIO
            )
            cache.set(CONFIG_CACHE_KEY, config, CACHE_TTL)
            if created:
                logger.info("Configuración de envíos creada con valores por defecto.")
        return config


class Envio(models.Model):
    """
    Información logística asociada a un pedido.
    """
    pedido = models.OneToOneField(
        Pedido,
        on_delete=models.CASCADE,
        related_name="datos_envio",
        verbose_name="Pedido Asociado"
    )

    ciudad_origen = models.CharField(
        max_length=50,
        verbose_name="Ciudad de Origen",
        help_text="Ciudad desde donde se realiza el envío (Baños, Tena, etc.)",
        null=True,
        blank=True,
    )
    zona_destino = models.CharField(
        max_length=20,
        choices=ZonaTarifariaEnvio.ZONAS_CHOICES,
        verbose_name="Zona de Destino",
        help_text="Zona tarifaria calculada automáticamente",
        null=True,
        blank=True,
    )

    distancia_km = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Distancia (KM)"
    )
    tiempo_estimado_mins = models.IntegerField(
        verbose_name="Tiempo Estimado (min)",
        default=0
    )

    costo_base = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Tarifa Base"
    )
    costo_km_adicional = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        verbose_name="Costo KM Extra"
    )
    recargo_nocturno = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        verbose_name="Recargo Nocturno"
    )
    total_envio = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name="Total Envío"
    )

    en_camino = models.BooleanField(default=False)
    fecha_salida = models.DateTimeField(null=True, blank=True)
    fecha_llegada = models.DateTimeField(null=True, blank=True)

    lat_origen_calc = models.FloatField(null=True)
    lng_origen_calc = models.FloatField(null=True)
    lat_destino_calc = models.FloatField(null=True)
    lng_destino_calc = models.FloatField(null=True)

    class Meta:
        verbose_name = "Envío / Logística"
        verbose_name_plural = "Envíos"

    def __str__(self):
        return f"Logística Pedido #{self.pedido.numero_pedido} (${self.total_envio})"
