# envios/models.py
from django.db import models
from django.utils import timezone
from decimal import Decimal

# Importamos el modelo Pedido para hacer la relación
from pedidos.models import Pedido 

class Envio(models.Model):
    """
    Información logística asociada a un pedido.
    """
    # Opciones de Zona de Envío
    ZONA_CENTRO = 'centro'
    ZONA_PERIFERICA = 'periferica'
    ZONA_RURAL = 'rural'

    ZONAS_CHOICES = [
        (ZONA_CENTRO, 'Centro (Urbano)'),
        (ZONA_PERIFERICA, 'Periferia Cercana'),
        (ZONA_RURAL, 'Fuera de Ciudad / Rural'),
    ]

    # Relación 1 a 1: Un pedido tiene exactamente un registro de envío
    pedido = models.OneToOneField(
        Pedido,
        on_delete=models.CASCADE,
        related_name='datos_envio',
        verbose_name='Pedido Asociado'
    )

    # Datos de Ubicación y Zona
    ciudad_origen = models.CharField(
        max_length=50,
        verbose_name='Ciudad de Origen',
        help_text='Ciudad desde donde se realiza el envío (Baños, Tena, etc.)',
        null=True,
        blank=True
    )
    zona_destino = models.CharField(
        max_length=20,
        choices=ZONAS_CHOICES,
        verbose_name='Zona de Destino',
        help_text='Zona tarifaria calculada automáticamente',
        null=True,
        blank=True
    )

    # Datos Calculados (Google Maps)
    distancia_km = models.DecimalField(
        max_digits=10, decimal_places=2,
        verbose_name='Distancia (KM)'
    )
    tiempo_estimado_mins = models.IntegerField(
        verbose_name='Tiempo Estimado (min)',
        default=0
    )

    # Desglose de Costos
    costo_base = models.DecimalField(
        max_digits=10, decimal_places=2,
        verbose_name='Tarifa Base'
    )
    costo_km_adicional = models.DecimalField(
        max_digits=10, decimal_places=2,
        default=0,
        verbose_name='Costo KM Extra'
    )
    recargo_nocturno = models.DecimalField(
        max_digits=10, decimal_places=2,
        default=0,
        verbose_name='Recargo Nocturno'
    )
    
    # Costo FINAL del envío (Suma de todo lo anterior)
    total_envio = models.DecimalField(
        max_digits=10, decimal_places=2,
        verbose_name='Total Envío'
    )

    # Datos de Rastreo
    en_camino = models.BooleanField(default=False)
    fecha_salida = models.DateTimeField(null=True, blank=True)
    fecha_llegada = models.DateTimeField(null=True, blank=True)
    
    # Coordenadas exactas usadas para el cálculo (Auditoría)
    lat_origen_calc = models.FloatField(null=True)
    lng_origen_calc = models.FloatField(null=True)
    lat_destino_calc = models.FloatField(null=True)
    lng_destino_calc = models.FloatField(null=True)

    class Meta:
        verbose_name = 'Envío / Logística'
        verbose_name_plural = 'Envíos'

    def __str__(self):
        return f"Logística Pedido #{self.pedido.numero_pedido} (${self.total_envio})"