# backend/pagos/models.py
"""
Modelo de Pagos para sistema de delivery.

CARACTERÍSTICAS:
- Soporte para flujos: Proveedor -> Cliente y Compra -> Cliente.
- Estados intermedios para verificación de transferencias.
- Auditoría completa (quién verificó el dinero).
- Soporte para evidencias (fotos de comprobantes).
"""
from django.db import models, transaction
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.db.models import Q, Sum, Count
from django.core.validators import MinValueValidator
from decimal import Decimal
import uuid
import logging

logger = logging.getLogger('pagos')


# ==========================================================
#  ENUMS Y CHOICES
# ==========================================================

class TipoMetodoPago(models.TextChoices):
    """Tipos de métodos de pago disponibles"""
    EFECTIVO = 'efectivo', 'Efectivo'
    TRANSFERENCIA = 'transferencia', 'Transferencia Bancaria'
    TARJETA_CREDITO = 'tarjeta_credito', 'Tarjeta de Crédito'
    TARJETA_DEBITO = 'tarjeta_debito', 'Tarjeta de Débito'


class EstadoPago(models.TextChoices):
    """Estados del ciclo de vida de un pago"""
    PENDIENTE = 'pendiente', 'Pendiente'  # Estado inicial
    ESPERANDO_VERIFICACION = 'esperando_verificacion', 'Esperando Verificación (Chofer/Admin)'  # Cliente subió foto
    PROCESANDO = 'procesando', 'Procesando'  # Para pasarelas automáticas
    COMPLETADO = 'completado', 'Completado'  # Dinero confirmado en mano o banco
    FALLIDO = 'fallido', 'Fallido'
    REEMBOLSADO = 'reembolsado', 'Reembolsado'
    CANCELADO = 'cancelado', 'Cancelado'


class TipoTransaccion(models.TextChoices):
    """Tipos de transacciones"""
    PAGO = 'pago', 'Pago'
    REEMBOLSO = 'reembolso', 'Reembolso'
    AJUSTE = 'ajuste', 'Ajuste'
    PROPINA = 'propina', 'Propina'


# ==========================================================
#  MANAGER PERSONALIZADO
# ==========================================================

class PagoManager(models.Manager):
    """Manager personalizado con querysets optimizados"""

    def get_queryset(self):
        """Queryset base optimizado"""
        return super().get_queryset().select_related(
            'pedido',
            'pedido__cliente__user',
            'metodo_pago'
        )

    def pendientes_verificacion(self):
        """Pagos donde el cliente ya subió foto y espera al chofer/admin"""
        return self.filter(estado=EstadoPago.ESPERANDO_VERIFICACION)

    def del_dia(self):
        """Pagos creados hoy"""
        hoy = timezone.now().date()
        return self.filter(creado_en__date=hoy)


# ==========================================================
# MODELO: MÉTODO DE PAGO
# ==========================================================

class MetodoPago(models.Model):
    """
    Catálogo de métodos de pago disponibles.
    """
    tipo = models.CharField(
        max_length=20,
        choices=TipoMetodoPago.choices,
        unique=True,
        verbose_name='Tipo'
    )

    nombre = models.CharField(
        max_length=100,
        verbose_name='Nombre'
    )

    descripcion = models.TextField(
        blank=True,
        verbose_name='Descripción'
    )

    activo = models.BooleanField(
        default=True,
        verbose_name='Activo'
    )

    requiere_verificacion = models.BooleanField(
        default=False,
        verbose_name='Requiere Verificación',
        help_text='Si es True, el pago no se completa automáticamente (ej. Transferencia)'
    )

    permite_reembolso = models.BooleanField(
        default=True,
        verbose_name='Permite Reembolso'
    )

    # Configuración para pasarelas externas (Stripe, etc.)
    pasarela_nombre = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='Nombre de Pasarela'
    )

    pasarela_api_key = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='API Key'
    )

    pasarela_configuracion = models.JSONField(
        default=dict,
        blank=True,
        verbose_name='Configuración Pasarela'
    )

    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'pagos_metodo_pago'
        verbose_name = 'Método de Pago'
        verbose_name_plural = 'Métodos de Pago'

    def __str__(self):
        return self.nombre


# ==========================================================
# MODELO PRINCIPAL: PAGO
# ==========================================================

class Pago(models.Model):
    """
    Modelo principal de Pago.
    Vincula el Pedido con el dinero y el estado de la transacción.
    """
    # Identificador único
    referencia = models.UUIDField(
        default=uuid.uuid4,
        editable=False,
        unique=True,
        verbose_name='Referencia',
        db_index=True
    )

    # Relaciones
    pedido = models.OneToOneField(
        'pedidos.Pedido',
        on_delete=models.PROTECT,
        related_name='pago',
        verbose_name='Pedido'
    )

    metodo_pago = models.ForeignKey(
        MetodoPago,
        on_delete=models.PROTECT,
        related_name='pagos',
        verbose_name='Método de Pago'
    )

    # Montos
    monto = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Monto Total'
    )

    monto_reembolsado = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name='Monto Reembolsado'
    )

    # Estado del Pago
    estado = models.CharField(
        max_length=30,  # Aumentado para soportar 'esperando_verificacion'
        choices=EstadoPago.choices,
        default=EstadoPago.PENDIENTE,
        verbose_name='Estado',
        db_index=True
    )

    # --- EVIDENCIA DE TRANSFERENCIA (Lógica 1B y 2B) ---
    transferencia_comprobante = models.ImageField(
        upload_to='pagos/comprobantes/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='Comprobante (Foto)',
        help_text='Foto del comprobante subida por el cliente'
    )

    transferencia_banco_origen = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Banco Origen (Cliente)'
    )

    transferencia_numero_operacion = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='Num. Operación'
    )

    # --- RELACIÓN CON REPARTIDOR PARA COMPROBANTES ---
    repartidor_asignado = models.ForeignKey(
        'repartidores.Repartidor',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pagos_asignados',
        verbose_name='Repartidor Asignado',
        help_text='Repartidor que debe verificar el comprobante'
    )

    comprobante_visible_repartidor = models.BooleanField(
        default=False,
        verbose_name='Comprobante Visible para Repartidor',
        help_text='Indica si el comprobante está disponible para que el repartidor lo vea'
    )

    fecha_visualizacion_repartidor = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Fecha Visualización Repartidor',
        help_text='Fecha en que el repartidor vio el comprobante'
    )
    
    # ==========================================================
    #  PROPIEDADES (Calculadas al vuelo)
    # ==========================================================

    @property
    def monto_pendiente_reembolso(self):
        """Calcula cuánto dinero falta por reembolsar"""
        return self.monto - self.monto_reembolsado

    @property
    def fue_reembolsado_parcialmente(self):
        """Verifica si hubo reembolso parcial"""
        return self.monto_reembolsado > 0 and self.monto_reembolsado < self.monto

    @property
    def fue_reembolsado_totalmente(self):
        """Verifica si fue reembolsado totalmente"""
        return self.monto_reembolsado >= self.monto
    

    # Datos de Tarjeta (Solo informativos/auditoría)
    tarjeta_ultimos_digitos = models.CharField(max_length=4, blank=True)
    tarjeta_marca = models.CharField(max_length=20, blank=True)

    # Pasarelas externas
    pasarela_id_transaccion = models.CharField(max_length=255, blank=True, db_index=True)
    pasarela_respuesta = models.JSONField(default=dict, blank=True)

    # Metadata y Auditoría
    metadata = models.JSONField(default=dict, blank=True)
    notas = models.TextField(blank=True, verbose_name='Notas de Auditoría')

    # Auditoría de Verificación (¿Quién confirmó el dinero?)
    verificado_por = models.ForeignKey(
        'authentication.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pagos_verificados',
        verbose_name='Verificado Por',
        help_text='Usuario (Chofer o Admin) que confirmó la recepción del dinero'
    )
    
    fecha_verificacion = models.DateTimeField(null=True, blank=True)
    fecha_completado = models.DateTimeField(null=True, blank=True)
    fecha_reembolso = models.DateTimeField(null=True, blank=True)

    creado_en = models.DateTimeField(default=timezone.now, db_index=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    objects = PagoManager()

    class Meta:
        db_table = 'pagos'
        ordering = ['-creado_en']
        verbose_name = 'Pago'
        verbose_name_plural = 'Pagos'

    def __str__(self):
        return f"Pago #{self.referencia} - {self.get_estado_display()} (${self.monto})"

    # ==========================================================
    #  LÓGICA DE ESTADOS
    # ==========================================================

    def marcar_completado(self, verificado_por=None, pasarela_respuesta=None):
        """
        Finaliza el pago exitosamente.
        Usado cuando:
        1. Chofer recibe efectivo.
        2. Chofer confirma transferencia en su banco.
        3. Admin fuerza la confirmación.
        """
        if self.estado in [EstadoPago.COMPLETADO, EstadoPago.REEMBOLSADO]:
            # Idempotencia: Si ya está completado, no hacemos nada (o lanzamos error)
            return

        self.estado = EstadoPago.COMPLETADO
        self.fecha_completado = timezone.now()

        if verificado_por:
            self.verificado_por = verificado_por
            self.fecha_verificacion = timezone.now()

        if pasarela_respuesta:
            self.pasarela_respuesta = pasarela_respuesta

        self.save(update_fields=[
            'estado', 'fecha_completado', 'verificado_por', 
            'fecha_verificacion', 'pasarela_respuesta', 'actualizado_en'
        ])
        
        # Registrar transacción
        self._crear_transaccion(
            tipo=TipoTransaccion.PAGO,
            monto=self.monto,
            exitosa=True,
            descripcion=f"Pago completado por {verificado_por.get_full_name() if verificado_por else 'Sistema'}"
        )

    def marcar_fallido(self, motivo):
        """Marca el pago como fallido"""
        self.estado = EstadoPago.FALLIDO
        self.notas = f"{self.notas}\n[FALLO] {motivo}".strip()
        self.save()
        
        self._crear_transaccion(
            tipo=TipoTransaccion.PAGO,
            monto=self.monto,
            exitosa=False,
            descripcion=f"Fallo: {motivo}"
        )

    def _crear_transaccion(self, tipo, monto, exitosa, descripcion=''):
        """Crea registro histórico de transacción"""
        try:
            Transaccion.objects.create(
                pago=self,
                tipo=tipo,
                monto=monto,
                exitosa=exitosa,
                descripcion=descripcion
            )
        except Exception as e:
            logger.error(f"Error creando transacción: {e}")

    @transaction.atomic
    def procesar_reembolso(self, monto, motivo='', usuario=None):
        """
        Aplica reembolso con control de montos y registra transacción.
        """
        if monto <= 0:
            raise ValidationError("El monto a reembolsar debe ser mayor a 0.")
        pendiente = self.monto_pendiente_reembolso
        if monto > pendiente:
            raise ValidationError(f"El monto a reembolsar (${monto}) excede lo pendiente (${pendiente}).")

        self.monto_reembolsado += monto
        self.estado = EstadoPago.REEMBOLSADO if self.monto_reembolsado >= self.monto else EstadoPago.COMPLETADO
        self.fecha_reembolso = timezone.now()
        self.notas = f"{self.notas}\n[REEMBOLSO] ${monto}: {motivo}".strip()
        self.save(update_fields=[
            'monto_reembolsado', 'estado', 'fecha_reembolso', 'notas', 'actualizado_en'
        ])

        self._crear_transaccion(
            tipo=TipoTransaccion.REEMBOLSO,
            monto=monto,
            exitosa=True,
            descripcion=f"Reembolso registrado por {usuario.get_full_name() if usuario else 'Sistema'}: {motivo}"
        )


# ==========================================================
# MODELO: TRANSACCIÓN (Historial)
# ==========================================================

class Transaccion(models.Model):
    """
    Historial inmutable de intentos y eventos del pago.
    """
    pago = models.ForeignKey(
        Pago,
        on_delete=models.CASCADE,
        related_name='transacciones'
    )

    tipo = models.CharField(
        max_length=20,
        choices=TipoTransaccion.choices
    )

    monto = models.DecimalField(max_digits=10, decimal_places=2)
    
    exitosa = models.BooleanField(
        null=True, 
        blank=True,
        help_text='True=Exitosa, False=Fallida, Null=En Proceso'
    )

    descripcion = models.TextField(blank=True)
    
    codigo_respuesta = models.CharField(max_length=50, blank=True)
    mensaje_respuesta = models.TextField(blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)

    creado_en = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = 'pagos_transacciones'
        ordering = ['-creado_en']

    def __str__(self):
        return f"Transacción {self.pk} - {self.get_tipo_display()}"


# ==========================================================
# MODELO: ESTADÍSTICAS (Para Dashboard Admin)
# ==========================================================

class EstadisticasPago(models.Model):
    """
    Tabla de resumen diario para no saturar la base con queries pesados.
    """
    fecha = models.DateField(unique=True, db_index=True)

    total_pagos = models.IntegerField(default=0)
    pagos_completados = models.IntegerField(default=0)
    pagos_pendientes = models.IntegerField(default=0)
    pagos_fallidos = models.IntegerField(default=0)
    pagos_reembolsados = models.IntegerField(default=0)

    monto_total = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    monto_efectivo = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    monto_transferencias = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    monto_tarjetas = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    monto_reembolsado = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))

    ticket_promedio = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    tasa_exito = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))

    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'pagos_estadisticas'
        verbose_name = 'Estadística Diaria'
        verbose_name_plural = 'Estadísticas Diarias'

    @classmethod
    def calcular_y_guardar(cls, fecha=None):
        if fecha is None:
            fecha = timezone.now().date()
        
        pagos = Pago.objects.filter(creado_en__date=fecha)
        
        stats = pagos.aggregate(
            total=Count('id'),
            completados=Count('id', filter=Q(estado=EstadoPago.COMPLETADO)),
            pendientes=Count('id', filter=Q(estado=EstadoPago.PENDIENTE)),
            fallidos=Count('id', filter=Q(estado=EstadoPago.FALLIDO)),
            reembolsados=Count('id', filter=Q(estado=EstadoPago.REEMBOLSADO)),
            monto_total=Sum('monto', filter=Q(estado=EstadoPago.COMPLETADO)),
            monto_efectivo=Sum('monto', filter=Q(estado=EstadoPago.COMPLETADO, metodo_pago__tipo=TipoMetodoPago.EFECTIVO)),
            monto_transf=Sum('monto', filter=Q(estado=EstadoPago.COMPLETADO, metodo_pago__tipo=TipoMetodoPago.TRANSFERENCIA)),
            monto_tarjeta=Sum('monto', filter=Q(estado=EstadoPago.COMPLETADO, metodo_pago__tipo__in=[TipoMetodoPago.TARJETA_CREDITO, TipoMetodoPago.TARJETA_DEBITO])),
            monto_reembolsado=Sum('monto_reembolsado')
        )
        
        # Cálculos seguros
        total = stats['total'] or 0
        completados = stats['completados'] or 0
        monto_total = stats['monto_total'] or Decimal('0.00')
        
        tasa = (completados / total * 100) if total > 0 else 0
        ticket = (monto_total / completados) if completados > 0 else 0

        obj, _ = cls.objects.update_or_create(
            fecha=fecha,
            defaults={
                'total_pagos': total,
                'pagos_completados': completados,
                'pagos_pendientes': stats['pendientes'] or 0,
                'pagos_fallidos': stats['fallidos'] or 0,
                'pagos_reembolsados': stats['reembolsados'] or 0,
                'monto_total': monto_total,
                'monto_efectivo': stats['monto_efectivo'] or Decimal('0.00'),
                'monto_transferencias': stats['monto_transf'] or Decimal('0.00'),
                'monto_tarjetas': stats['monto_tarjeta'] or Decimal('0.00'),
                'monto_reembolsado': stats['monto_reembolsado'] or Decimal('0.00'),
                'tasa_exito': tasa,
                'ticket_promedio': ticket
            }
        )
        return obj
