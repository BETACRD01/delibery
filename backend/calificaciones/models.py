# calificaciones/models.py

import logging
from django.db import models, transaction
from django.db.models import Avg, Count, Q
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from authentication.models import User

logger = logging.getLogger('calificaciones')


# ============================================
# ENUMS
# ============================================

class TipoCalificacion(models.TextChoices):
    """Tipos de calificación disponibles en el sistema"""
    CLIENTE_A_REPARTIDOR = 'cliente_a_repartidor', 'Cliente califica a Repartidor'
    REPARTIDOR_A_CLIENTE = 'repartidor_a_cliente', 'Repartidor califica a Cliente'
    CLIENTE_A_PROVEEDOR = 'cliente_a_proveedor', 'Cliente califica a Proveedor'
    PROVEEDOR_A_REPARTIDOR = 'proveedor_a_repartidor', 'Proveedor califica a Repartidor'
    REPARTIDOR_A_PROVEEDOR = 'repartidor_a_proveedor', 'Repartidor califica a Proveedor'


# ============================================
# MANAGER PERSONALIZADO
# ============================================

class CalificacionManager(models.Manager):
    """Manager con métodos útiles para calificaciones"""

    def get_queryset(self):
        return super().get_queryset().select_related(
            'pedido', 'calificador', 'calificado'
        )

    def por_tipo(self, tipo):
        """Filtra por tipo de calificación"""
        return self.filter(tipo=tipo)

    def de_usuario(self, user):
        """Calificaciones dadas por un usuario"""
        return self.filter(calificador=user)

    def para_usuario(self, user):
        """Calificaciones recibidas por un usuario"""
        return self.filter(calificado=user)

    def del_pedido(self, pedido_id):
        """Todas las calificaciones de un pedido"""
        return self.filter(pedido_id=pedido_id)

    def pendientes_del_pedido(self, pedido, user):
        """
        Retorna los tipos de calificación que el usuario aún puede dar
        para un pedido específico.
        """
        calificaciones_existentes = self.filter(
            pedido=pedido,
            calificador=user
        ).values_list('tipo', flat=True)

        return [t for t in TipoCalificacion.values if t not in calificaciones_existentes]

    def promedio_usuario(self, user):
        """Calcula el promedio de calificaciones recibidas por un usuario"""
        resultado = self.filter(calificado=user).aggregate(
            promedio=Avg('estrellas'),
            total=Count('id')
        )
        return {
            'promedio': round(resultado['promedio'] or 5.0, 2),
            'total_resenas': resultado['total'] or 0
        }


# ============================================
# MODELO PRINCIPAL: CALIFICACIÓN
# ============================================

class Calificacion(models.Model):
    """
    Modelo unificado para todas las calificaciones del sistema.
    
    Permite calificaciones bidireccionales entre:
    - Cliente ↔ Repartidor
    - Cliente → Proveedor
    - Proveedor ↔ Repartidor
    """

    # --- Relación con el Pedido ---
    pedido = models.ForeignKey(
        'pedidos.Pedido',
        on_delete=models.CASCADE,
        related_name='calificaciones',
        verbose_name='Pedido',
        help_text='Pedido asociado a esta calificación'
    )

    # --- Quién califica ---
    calificador = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='calificaciones_dadas',
        verbose_name='Calificador',
        help_text='Usuario que da la calificación'
    )

    # --- Quién recibe la calificación ---
    calificado = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='calificaciones_recibidas',
        verbose_name='Calificado',
        help_text='Usuario que recibe la calificación'
    )

    # --- Tipo de calificación ---
    tipo = models.CharField(
        max_length=30,
        choices=TipoCalificacion.choices,
        verbose_name='Tipo de Calificación',
        db_index=True
    )

    # --- Puntuación (1-5 estrellas) ---
    estrellas = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name='Estrellas',
        help_text='Puntuación de 1 a 5 estrellas'
    )

    # --- Comentario opcional ---
    comentario = models.TextField(
        blank=True,
        null=True,
        max_length=500,
        verbose_name='Comentario',
        help_text='Comentario opcional (máximo 500 caracteres)'
    )

    # --- Categorías de calificación (opcional) ---
    # Útil para desglosar la calificación
    puntualidad = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name='Puntualidad'
    )

    amabilidad = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name='Amabilidad'
    )

    calidad_producto = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name='Calidad del Producto',
        help_text='Solo aplica para calificaciones a proveedores'
    )

    # --- Metadatos ---
    es_anonima = models.BooleanField(
        default=False,
        verbose_name='Calificación Anónima',
        help_text='Si es True, el nombre del calificador no se muestra'
    )

    editada = models.BooleanField(
        default=False,
        verbose_name='Fue Editada'
    )

    # --- Auditoría ---
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Fecha de Creación',
        db_index=True
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Última Actualización'
    )

    # Manager personalizado
    objects = CalificacionManager()

    class Meta:
        db_table = 'calificaciones'
        verbose_name = 'Calificación'
        verbose_name_plural = 'Calificaciones'
        ordering = ['-created_at']

        # Evita calificaciones duplicadas del mismo tipo por pedido
        constraints = [
            models.UniqueConstraint(
                fields=['pedido', 'calificador', 'tipo'],
                name='unique_calificacion_por_pedido_tipo'
            ),
            # Validar rango de estrellas a nivel de BD
            models.CheckConstraint(
                check=Q(estrellas__gte=1) & Q(estrellas__lte=5),
                name='calificacion_estrellas_rango'
            ),
        ]

        indexes = [
            models.Index(fields=['pedido', 'tipo']),
            models.Index(fields=['calificador', '-created_at']),
            models.Index(fields=['calificado', '-created_at']),
            models.Index(fields=['tipo', '-created_at']),
            models.Index(fields=['estrellas']),
        ]

    def __str__(self):
        return f"{self.calificador} → {self.calificado}: {self.estrellas}⭐ ({self.get_tipo_display()})"

    def __repr__(self):
        return f"<Calificacion: {self.tipo} - {self.estrellas}⭐ (Pedido #{self.pedido_id})>"

    # ============================================
    # VALIDACIONES
    # ============================================

    def clean(self):
        """Validaciones de negocio"""
        super().clean()

        # No puede calificarse a sí mismo
        if self.calificador_id == self.calificado_id:
            raise ValidationError("No puedes calificarte a ti mismo.")

        # Validar que el pedido esté entregado
        if self.pedido and self.pedido.estado != 'entregado':
            raise ValidationError(
                "Solo puedes calificar pedidos que hayan sido entregados."
            )

        # Validar coherencia del tipo con los participantes del pedido
        self._validar_participantes()

    def _validar_participantes(self):
        """Valida que calificador y calificado sean participantes válidos del pedido"""
        if not self.pedido:
            return

        pedido = self.pedido
        cliente_user = pedido.cliente.user if pedido.cliente else None
        repartidor_user = pedido.repartidor.user if pedido.repartidor else None
        proveedor_user = pedido.proveedor.user if pedido.proveedor else None

        validaciones = {
            TipoCalificacion.CLIENTE_A_REPARTIDOR: (cliente_user, repartidor_user),
            TipoCalificacion.REPARTIDOR_A_CLIENTE: (repartidor_user, cliente_user),
            TipoCalificacion.CLIENTE_A_PROVEEDOR: (cliente_user, proveedor_user),
            TipoCalificacion.PROVEEDOR_A_REPARTIDOR: (proveedor_user, repartidor_user),
            TipoCalificacion.REPARTIDOR_A_PROVEEDOR: (repartidor_user, proveedor_user),
        }

        esperado = validaciones.get(self.tipo)
        if esperado:
            calificador_esperado, calificado_esperado = esperado

            if calificador_esperado and self.calificador_id != calificador_esperado.id:
                raise ValidationError(
                    f"Para el tipo '{self.get_tipo_display()}', el calificador debe ser el participante correcto."
                )

            if calificado_esperado is None:
                raise ValidationError(
                    f"Este pedido no tiene un participante válido para recibir esta calificación."
                )

            if self.calificado_id != calificado_esperado.id:
                raise ValidationError(
                    f"Para el tipo '{self.get_tipo_display()}', el calificado debe ser el participante correcto."
                )

    def save(self, *args, **kwargs):
        """Override save para actualizar promedios automáticamente"""
        self.full_clean()

        is_new = self.pk is None
        is_update = not is_new

        if is_update:
            self.editada = True

        super().save(*args, **kwargs)

        # Actualizar promedio del usuario calificado
        self._actualizar_promedio_calificado()

        # Log
        accion = "creada" if is_new else "actualizada"
        logger.info(
            f"⭐ Calificación {accion}: {self.calificador} → {self.calificado} "
            f"({self.estrellas}⭐) - Pedido #{self.pedido_id}"
        )

    def _actualizar_promedio_calificado(self):
        """Actualiza el promedio de calificaciones del usuario calificado"""
        from calificaciones.services import CalificacionService
        CalificacionService.actualizar_promedio_usuario(self.calificado)

    # ============================================
    # PROPIEDADES
    # ============================================

    @property
    def es_positiva(self):
        """Calificación de 4 o 5 estrellas"""
        return self.estrellas >= 4

    @property
    def es_negativa(self):
        """Calificación de 1 o 2 estrellas"""
        return self.estrellas <= 2

    @property
    def es_neutral(self):
        """Calificación de 3 estrellas"""
        return self.estrellas == 3

    @property
    def tiempo_desde_creacion(self):
        """Tiempo transcurrido desde la creación"""
        delta = timezone.now() - self.created_at
        minutos = int(delta.total_seconds() / 60)

        if minutos < 60:
            return f"hace {minutos} min"
        elif minutos < 1440:
            horas = minutos // 60
            return f"hace {horas} h"
        else:
            dias = minutos // 1440
            return f"hace {dias} días"

    @property
    def nombre_calificador_display(self):
        """Nombre a mostrar del calificador (considera anonimato)"""
        if self.es_anonima:
            return "Usuario Anónimo"
        return self.calificador.get_full_name() or self.calificador.email


# ============================================
# MODELO: RESUMEN DE CALIFICACIONES
# ============================================

class ResumenCalificacion(models.Model):
    """
    Tabla desnormalizada para consultas rápidas de promedios.
    Se actualiza automáticamente cuando se crea/edita una calificación.
    """

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='resumen_calificaciones',
        verbose_name='Usuario'
    )

    # --- Promedios generales ---
    promedio_general = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=5.00,
        validators=[MinValueValidator(0), MaxValueValidator(5)],
        verbose_name='Promedio General'
    )

    total_calificaciones = models.PositiveIntegerField(
        default=0,
        verbose_name='Total de Calificaciones Recibidas'
    )

    # --- Desglose por estrellas ---
    total_5_estrellas = models.PositiveIntegerField(default=0)
    total_4_estrellas = models.PositiveIntegerField(default=0)
    total_3_estrellas = models.PositiveIntegerField(default=0)
    total_2_estrellas = models.PositiveIntegerField(default=0)
    total_1_estrella = models.PositiveIntegerField(default=0)

    # --- Promedios por categoría ---
    promedio_puntualidad = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        null=True,
        blank=True
    )

    promedio_amabilidad = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        null=True,
        blank=True
    )

    promedio_calidad_producto = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        null=True,
        blank=True
    )

    # --- Auditoría ---
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'calificaciones_resumen'
        verbose_name = 'Resumen de Calificaciones'
        verbose_name_plural = 'Resúmenes de Calificaciones'

    def __str__(self):
        return f"{self.user.email}: {self.promedio_general}⭐ ({self.total_calificaciones} reseñas)"

    def recalcular(self):
        """Recalcula todos los valores del resumen"""
        calificaciones = Calificacion.objects.filter(calificado=self.user)

        # Totales por estrellas
        self.total_5_estrellas = calificaciones.filter(estrellas=5).count()
        self.total_4_estrellas = calificaciones.filter(estrellas=4).count()
        self.total_3_estrellas = calificaciones.filter(estrellas=3).count()
        self.total_2_estrellas = calificaciones.filter(estrellas=2).count()
        self.total_1_estrella = calificaciones.filter(estrellas=1).count()

        self.total_calificaciones = calificaciones.count()

        # Promedio general
        if self.total_calificaciones > 0:
            agregados = calificaciones.aggregate(
                promedio=Avg('estrellas'),
                puntualidad=Avg('puntualidad'),
                amabilidad=Avg('amabilidad'),
                calidad=Avg('calidad_producto')
            )
            self.promedio_general = round(agregados['promedio'] or 5.0, 2)
            self.promedio_puntualidad = round(agregados['puntualidad'], 2) if agregados['puntualidad'] else None
            self.promedio_amabilidad = round(agregados['amabilidad'], 2) if agregados['amabilidad'] else None
            self.promedio_calidad_producto = round(agregados['calidad'], 2) if agregados['calidad'] else None
        else:
            self.promedio_general = 5.00

        self.save()

    @property
    def porcentaje_positivas(self):
        """Porcentaje de calificaciones de 4-5 estrellas"""
        if self.total_calificaciones == 0:
            return 100.0
        positivas = self.total_5_estrellas + self.total_4_estrellas
        return round((positivas / self.total_calificaciones) * 100, 1)