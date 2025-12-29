# pedidos/models.py (VERSIÓN OPTIMIZADA FINAL)

import logging
from decimal import Decimal
from django.db import models
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.db import transaction
from django.conf import settings  # Para referenciar al modelo User correctamente

# Importación de modelos externos (con precaución para evitar ciclos)
from usuarios.models import Perfil
from repartidores.models import Repartidor
from proveedores.models import Proveedor

logger = logging.getLogger('pedidos.models')


# ==========================================================
#  CONFIGURACIÓN CENTRALIZADA DE COMISIONES
# ==========================================================

class ConfiguracionComisiones:
    """
    Lógica financiera centralizada.
    Permite cambiar las tasas de comisión en un solo lugar.
    """
    TASA_PROVEEDOR = Decimal('0.15')       # 15%
    # Repartidor gana solo el costo de envío del pedido
    COMISION_APP_MINIMA = Decimal('0.50')

    @classmethod
    def calcular_comision_proveedor(cls, total):
        return round(total * cls.TASA_PROVEEDOR, 2) if total > 0 else Decimal('0.00')
    
    @classmethod
    def calcular_comision_repartidor(cls, costo_envio: Decimal = Decimal('0.00')) -> Decimal:
        """El repartidor gana solo el costo de envío del pedido."""
        return costo_envio
    
    @classmethod
    def calcular_ganancia_app(cls, total, comision_proveedor, comision_repartidor):
        """La app gana lo que sobra, respetando un mínimo."""
        ganancia = total - comision_proveedor - comision_repartidor
        return max(ganancia, cls.COMISION_APP_MINIMA)


# ==========================================================
#  ENUMS Y CHOICES
# ==========================================================

class TipoPedido(models.TextChoices):
    PROVEEDOR = 'proveedor', 'Pedido de Proveedor'
    DIRECTO = 'directo', 'Encargo Directo'

class EstadoPedido(models.TextChoices):
    PENDIENTE_REPARTIDOR = 'pendiente_repartidor', 'Pendiente de Repartidor'
    ACEPTADO_REPARTIDOR = 'aceptado_repartidor', 'Aceptado por Repartidor'
    ASIGNADO_REPARTIDOR = 'asignado_repartidor', 'Asignado a Repartidor'
    EN_PROCESO = 'en_proceso', 'En Proceso (Recogiendo)'
    EN_CAMINO = 'en_camino', 'En Camino (Entrega)'
    ENTREGADO = 'entregado', 'Entregado'
    CANCELADO = 'cancelado', 'Cancelado'

class EstadoPago(models.TextChoices):
    PENDIENTE = 'pendiente', 'Pendiente'
    PAGADO = 'pagado', 'Pagado'
    REEMBOLSADO = 'reembolsado', 'Reembolsado'

class MetodoPago(models.TextChoices):
    EFECTIVO = 'efectivo', 'Efectivo'
    TARJETA = 'tarjeta', 'Tarjeta'
    TRANSFERENCIA = 'transferencia', 'Transferencia'

# ==========================================================
#  MANAGER PERSONALIZADO
# ==========================================================

class PedidoManager(models.Manager):
    def get_queryset(self):
        """
        Optimización crítica: Carga siempre las relaciones clave para evitar N+1.
        """
        return super().get_queryset().select_related(
            'cliente__user',
            'proveedor',
            'repartidor__user'
        )

    def activos(self):
        """Pedidos en curso (no entregados ni cancelados)"""
        return self.filter(estado__in=[
            EstadoPedido.PENDIENTE_REPARTIDOR,
            EstadoPedido.ASIGNADO_REPARTIDOR,
            EstadoPedido.EN_PROCESO,
            EstadoPedido.EN_CAMINO
        ])

    def pendientes_asignacion(self):
        """Pedidos esperando que un repartidor los tome"""
        return self.filter(estado=EstadoPedido.PENDIENTE_REPARTIDOR, repartidor__isnull=True)


# ==========================================================
#  MODELO PRINCIPAL: PEDIDO
# ==========================================================

class Pedido(models.Model):
    """
    Modelo central de la operación.
    """
    
    # --- IDENTIFICACIÓN ---
    numero_pedido = models.CharField(
        max_length=20, unique=True, editable=False, null=True, blank=True, db_index=True,
        verbose_name='Número', help_text='Formato: JP-2024-000XXX'
    )

    # --- RELACIONES ---
    cliente = models.ForeignKey(
        Perfil, on_delete=models.CASCADE, related_name='pedidos',
        verbose_name='Cliente'
    )
    proveedor = models.ForeignKey(
        Proveedor, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='pedidos', verbose_name='Proveedor',
        help_text='Proveedor específico (null para pedidos multi-proveedor)'
    )
    repartidor = models.ForeignKey(
        Repartidor, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='pedidos', verbose_name='Repartidor'
    )

    # --- ESTADO Y TIPO ---
    tipo = models.CharField(
        max_length=20, choices=TipoPedido.choices, default=TipoPedido.PROVEEDOR,
        verbose_name='Tipo'
    )
    estado = models.CharField(
        max_length=30, choices=EstadoPedido.choices, default=EstadoPedido.PENDIENTE_REPARTIDOR,
        db_index=True, verbose_name='Estado'
    )
    estado_pago = models.CharField(
        max_length=20, choices=EstadoPago.choices, default=EstadoPago.PENDIENTE,
        db_index=True, verbose_name='Estado de Pago'
    )
    metodo_pago = models.CharField(
        max_length=20, choices=MetodoPago.choices, default=MetodoPago.EFECTIVO,
        verbose_name='Método de Pago'
    )

    # --- DETALLES ---
    descripcion = models.TextField(blank=True, verbose_name='Descripción')
    total = models.DecimalField(
        max_digits=10, decimal_places=2, default=0, verbose_name='Total'
    )
    imagen_evidencia = models.ImageField(
        upload_to='pedidos/evidencias/%Y/%m/', null=True, blank=True,
        verbose_name='Evidencia Entrega'
    )

    # --- UBICACIÓN ---
    direccion_origen = models.TextField(blank=True, null=True, verbose_name='Dir. Origen')
    latitud_origen = models.FloatField(blank=True, null=True)
    longitud_origen = models.FloatField(blank=True, null=True)

    direccion_entrega = models.TextField(verbose_name='Dir. Entrega')
    latitud_destino = models.FloatField(blank=True, null=True)
    longitud_destino = models.FloatField(blank=True, null=True)

    # --- FINANZAS (Snapshot del momento del pedido) ---
    comision_repartidor = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    comision_proveedor = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    ganancia_app = models.DecimalField(max_digits=8, decimal_places=2, default=0)

    tarifa_servicio = models.DecimalField(max_digits=6, decimal_places=2, default=0)

    # --- CONTROL ---
    aceptado_por_repartidor = models.BooleanField(default=False)
    # DEPRECADO: Ya no se usa, los proveedores no confirman pedidos
    confirmado_por_proveedor = models.BooleanField(default=False, editable=False)
    cancelado_por = models.CharField(max_length=100, blank=True)
    motivo_cancelacion = models.TextField(blank=True)

    # Nuevo: Instrucciones de entrega del cliente
    instrucciones_entrega = models.TextField(blank=True, verbose_name='Instrucciones de Entrega')

    # --- TIMESTAMPS ---
    creado_en = models.DateTimeField(auto_now_add=True, db_index=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    fecha_asignado = models.DateTimeField(null=True, blank=True, verbose_name='Fecha Asignado')
    fecha_en_proceso = models.DateTimeField(null=True, blank=True, verbose_name='Fecha En Proceso')
    fecha_en_camino = models.DateTimeField(null=True, blank=True, verbose_name='Fecha En Camino')
    fecha_entregado = models.DateTimeField(null=True, blank=True, verbose_name='Fecha Entregado')
    fecha_cancelado = models.DateTimeField(null=True, blank=True, verbose_name='Fecha Cancelado')

    objects = PedidoManager()

    class Meta:
        db_table = 'pedidos'
        ordering = ['-creado_en']
        indexes = [
            models.Index(fields=['estado', '-creado_en']),
            models.Index(fields=['cliente', '-creado_en']),
        ]
        verbose_name = 'Pedido'
        verbose_name_plural = 'Pedidos'

    def __str__(self):
        return f"{self.numero_pedido or 'S/N'} ({self.get_estado_display()})"

    # ==========================================================
    #  LOGICA DE NEGOCIO
    # ==========================================================

    # En backend/pedidos/models.py

    def generar_numero_pedido(self):
        """Genera secuencia única: JP-2024-000001"""
        if self.numero_pedido: return

        anio = timezone.now().year
        
        with transaction.atomic():
            ultimo = Pedido.objects.select_related(None).filter(
                numero_pedido__startswith=f"JP-{anio}-"
            ).select_for_update().order_by('-id').first()

            if ultimo and ultimo.numero_pedido:
                try:
                    secuencia = int(ultimo.numero_pedido.split('-')[-1]) + 1
                except ValueError:
                    secuencia = 1
            else:
                secuencia = 1
            
            self.numero_pedido = f"JP-{anio}-{secuencia:06d}"

    def save(self, *args, **kwargs):
        if not self.pk:
            self.generar_numero_pedido()
        super().save(*args, **kwargs)

    def _distribuir_ganancias(self):
        """Calcula comisiones basado en reglas actuales"""
        # Si tiene datos de envio (logistica), el costo de envio va al repartidor
        costo_envio = Decimal('0.00')
        if hasattr(self, 'datos_envio'):
            costo_envio = self.datos_envio.total_envio

        if self.tipo == TipoPedido.PROVEEDOR:
            # Para pedidos multi-proveedor, calcular comisiones por proveedor desde los items
            if self.proveedor is None:  # Pedido multi-proveedor
                # Calcular comisiones por cada proveedor basado en sus items
                comision_proveedores_total = Decimal('0.00')
                subtotal_sin_envio = self.total - costo_envio

                # Agrupar items por proveedor
                items_por_proveedor = {}
                for item in self.items.all():
                    prov_id = item.producto.proveedor_id
                    if prov_id not in items_por_proveedor:
                        items_por_proveedor[prov_id] = []
                    items_por_proveedor[prov_id].append(item)

                # Calcular comisión para cada proveedor
                for prov_id, items_prov in items_por_proveedor.items():
                    subtotal_proveedor = sum(item.subtotal for item in items_prov)
                    # Comisión proporcional al subtotal del proveedor
                    proporcion = subtotal_proveedor / subtotal_sin_envio if subtotal_sin_envio > 0 else Decimal('0')
                    comision_proveedor = ConfiguracionComisiones.calcular_comision_proveedor(subtotal_proveedor)
                    comision_proveedores_total += comision_proveedor

                self.comision_proveedor = comision_proveedores_total
            else:
                # Pedido de un solo proveedor (lógica original)
                self.comision_proveedor = ConfiguracionComisiones.calcular_comision_proveedor(self.total - costo_envio)

            # El repartidor gana solo el costo del envío
            self.comision_repartidor = costo_envio
        else:
            # Encargo directo: Repartidor también gana solo el costo de envío
            self.comision_proveedor = Decimal('0.00')
            self.comision_repartidor = costo_envio

        # Tarifa de servicio al usuario (solo multi-proveedor)
        self.tarifa_servicio = Decimal('0.00')
        num_proveedores = 0
        try:
            prov_ids = {item.producto.proveedor_id for item in self.items.all()}
            num_proveedores = len([p for p in prov_ids if p is not None])
        except Exception:
            num_proveedores = 0

        if num_proveedores >= 2:
            self.tarifa_servicio = Decimal('0.25') if num_proveedores == 2 else Decimal('0.50')

        # La app se queda con el resto (contable, no mostrar al usuario)
        self.ganancia_app = self.total - self.comision_proveedor - self.comision_repartidor - self.tarifa_servicio

        # Validar que no sea negativo (la app nunca pierde, en teoría)
        if self.ganancia_app < 0:
            logger.warning(f"Ganancia negativa en pedido {self.numero_pedido}. Ajustando.")
            self.ganancia_app = Decimal('0.00')

    # --- TRANSICIONES DE ESTADO ---

    def aceptar_por_repartidor(self, repartidor):
        """Repartidor acepta el pedido"""
        if self.estado != EstadoPedido.PENDIENTE_REPARTIDOR:
            raise ValidationError("El pedido no está disponible para aceptar.")

        self.repartidor = repartidor
        self.aceptado_por_repartidor = True
        self.estado = EstadoPedido.ASIGNADO_REPARTIDOR
        self.fecha_asignado = timezone.now()
        self.save()

    def marcar_en_proceso(self):
        """Repartidor está recogiendo/comprando"""
        if not self.repartidor:
            raise ValidationError("No se puede iniciar proceso sin repartidor.")
        if self.estado != EstadoPedido.ASIGNADO_REPARTIDOR:
            raise ValidationError("El pedido debe estar asignado primero.")

        self.estado = EstadoPedido.EN_PROCESO
        self.fecha_en_proceso = timezone.now()
        self.save()

    def marcar_en_camino(self):
        """Repartidor va hacia el cliente"""
        if not self.repartidor:
            raise ValidationError("No se puede iniciar entrega sin repartidor.")
        if self.estado not in [EstadoPedido.ASIGNADO_REPARTIDOR, EstadoPedido.EN_PROCESO]:
            raise ValidationError("El pedido debe estar asignado o en proceso.")

        self.estado = EstadoPedido.EN_CAMINO
        self.fecha_en_camino = timezone.now()
        self.save()

    def marcar_entregado(self, imagen_evidencia=None):
        self.estado = EstadoPedido.ENTREGADO
        self.estado_pago = EstadoPago.PAGADO
        self.fecha_entregado = timezone.now()
        if imagen_evidencia:
            self.imagen_evidencia = imagen_evidencia
        
        self._distribuir_ganancias()
        self.save()

    def cancelar(self, motivo, actor):
        if self.estado in [EstadoPedido.ENTREGADO, EstadoPedido.CANCELADO]:
            raise ValidationError("El pedido ya está finalizado.")
            
        self.estado = EstadoPedido.CANCELADO
        self.motivo_cancelacion = motivo
        self.cancelado_por = actor
        self.fecha_cancelado = timezone.now()
        
        # Lógica de reembolso si ya pagó (PENDIENTE DE IMPLEMENTAR CON GATEWAY)
        if self.estado_pago == EstadoPago.PAGADO:
            self.estado_pago = EstadoPago.REEMBOLSADO
            
        self.save()

    # --- PROPIEDADES ---

    @property
    def puede_ser_cancelado(self):
        """
        Regla de cancelación para clientes:
        - Solo puede cancelar si el pedido está PENDIENTE y nadie lo aceptó
        - Si un repartidor ya aceptó, NO se puede cancelar
        - Admin siempre puede cancelar
        """
        # No se puede cancelar si ya está entregado o cancelado
        if self.estado in [EstadoPedido.ENTREGADO, EstadoPedido.CANCELADO]:
            return False

        # Si hay un repartidor asignado, NO se puede cancelar (cliente)
        # Solo permitir cancelar en estado PENDIENTE_REPARTIDOR (antes de que alguien acepte)
        if self.repartidor is not None:
            return False

        return self.estado == EstadoPedido.PENDIENTE_REPARTIDOR

    @property
    def tiene_logistica(self):
        return hasattr(self, 'datos_envio')


# ==========================================================
#  MODELO DETALLE: ITEMS
# ==========================================================

class ItemPedido(models.Model):
    """
    Productos individuales dentro de un pedido.
    """
    pedido = models.ForeignKey(Pedido, on_delete=models.CASCADE, related_name='items')
    producto = models.ForeignKey(
        'productos.Producto', on_delete=models.PROTECT, related_name='items_pedido'
    )
    cantidad = models.PositiveIntegerField(default=1)
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    notas = models.TextField(blank=True, verbose_name="Notas (ej. sin cebolla)")

    class Meta:
        db_table = 'pedidos_items'
        verbose_name = 'Item'
        verbose_name_plural = 'Items'

    def save(self, *args, **kwargs):
        self.subtotal = self.cantidad * self.precio_unitario
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.cantidad}x {self.producto.nombre}"


# ==========================================================
#  HISTORIAL Y MÉTRICAS (Simplificado)
# ==========================================================

class HistorialPedido(models.Model):
    """Auditoría de cambios de estado"""
    pedido = models.ForeignKey(Pedido, on_delete=models.CASCADE, related_name='historial')
    estado_anterior = models.CharField(max_length=20)
    estado_nuevo = models.CharField(max_length=20)
    fecha_cambio = models.DateTimeField(auto_now_add=True)
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    observaciones = models.TextField(blank=True)

    class Meta:
        db_table = 'pedidos_historial'
        ordering = ['-fecha_cambio']
