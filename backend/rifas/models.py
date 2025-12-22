# -*- coding: utf-8 -*-
# rifas/models.py
"""
Sistema de Rifas con Múltiples Premios

FUNCIONALIDAD:
- Rifas con 1 a 3 premios (1er, 2do, 3er lugar)
- Cada premio tiene su propia imagen y descripción
- Participación requiere 3+ pedidos entregados
- Sorteo automático 5 minutos después de la fecha_fin
- Los premios se muestran del 3ro al 1ro (1ro es el mayor)
"""

from django.db import models
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.db.models import Q, Count
from authentication.models import User
from pedidos.models import Pedido, EstadoPedido
import uuid
import random
import logging
from datetime import datetime, timedelta

logger = logging.getLogger("rifas")


# ============================================
#  ENUMS
# ============================================


class EstadoRifa(models.TextChoices):
    """Estados de la rifa"""

    ACTIVA = "activa", "Activa"
    FINALIZADA = "finalizada", "Finalizada"
    CANCELADA = "cancelada", "Cancelada"


class TipoSorteo(models.TextChoices):
    """Define si el sorteo es automático o manual"""

    AUTOMATICO = "automatico", "Automático"
    MANUAL = "manual", "Manual"


class EstadoPremio(models.TextChoices):
    """Estados de un premio individual"""

    ACTIVO = "activo", "Activo"
    CANCELADO = "cancelado", "Cancelada"


# ============================================
# MODELO: RIFA
# ============================================


class Rifa(models.Model):
    """
    Rifa con múltiples premios

    CAMBIOS:
    - Eliminado: premio, valor_premio, ganador, fecha_sorteo
    - Los premios ahora son entidades separadas (modelo Premio)
    - Sorteo automático 5 min después de fecha_fin
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # ============================================
    # INFORMACIÓN BÁSICA
    # ============================================

    titulo = models.CharField(
        max_length=200, verbose_name="Título", help_text="Ej: Rifa Diciembre 2024"
    )

    descripcion = models.TextField(
        verbose_name="Descripción", help_text="Descripción general de la rifa"
    )

    imagen = models.ImageField(
        upload_to="rifas/%Y/%m/",
        null=True,
        blank=True,
        verbose_name="Imagen Principal",
        help_text="Imagen promocional de la rifa",
    )

    # ============================================
    # FECHAS
    # ============================================

    fecha_inicio = models.DateTimeField(
        verbose_name="Fecha de Inicio", help_text="Cuándo inicia la rifa"
    )

    fecha_fin = models.DateTimeField(
        verbose_name="Fecha de Fin",
        help_text="Cuándo finaliza - sorteo automático 5 min después",
    )

    # ============================================
    # REQUISITOS
    # ============================================

    pedidos_minimos = models.PositiveIntegerField(
        default=3,
        verbose_name="Pedidos Mínimos",
        help_text="Cantidad mínima de pedidos para participar",
    )

    # ============================================
    # ESTADO
    # ============================================

    estado = models.CharField(
        max_length=20,
        choices=EstadoRifa.choices,
        default=EstadoRifa.ACTIVA,
        verbose_name="Estado",
        db_index=True,
    )

    tipo_sorteo = models.CharField(
        max_length=20,
        choices=TipoSorteo.choices,
        default=TipoSorteo.MANUAL,
        verbose_name="Tipo de Sorteo",
        help_text="Automático (se sortea tras fecha_fin) o Manual (requiere acción de admin)",
    )

    # ============================================
    # METADATA
    # ============================================

    mes = models.PositiveIntegerField(
        verbose_name="Mes", help_text="Mes de la rifa (1-12)", db_index=True
    )

    anio = models.PositiveIntegerField(
        verbose_name="Año", help_text="Año de la rifa", db_index=True
    )

    # ============================================
    # AUDITORÍA
    # ============================================

    creado_por = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="rifas_creadas",
        verbose_name="Creado Por",
        help_text="Admin que creó la rifa",
    )

    creado_en = models.DateTimeField(
        auto_now_add=True, verbose_name="Fecha de Creación"
    )

    actualizado_en = models.DateTimeField(
        auto_now=True, verbose_name="Última Actualización"
    )

    class Meta:
        db_table = "rifas"
        verbose_name = "Rifa"
        verbose_name_plural = "Rifas"
        ordering = ["-fecha_inicio"]
        indexes = [
            models.Index(fields=["estado", "fecha_inicio"]),
            models.Index(fields=["mes", "anio"]),
            models.Index(fields=["-fecha_inicio"]),
        ]
        constraints = [
            # Solo una rifa activa por mes
            models.UniqueConstraint(
                fields=["mes", "anio", "estado"],
                condition=Q(estado=EstadoRifa.ACTIVA),
                name="una_rifa_activa_por_mes",
            ),
        ]

    def __str__(self):
        return f"{self.titulo} - {self.get_estado_display()}"

    # ============================================
    #  VALIDACIONES
    # ============================================

    def clean(self):
        """Validaciones personalizadas"""
        super().clean()

        errors = {}

        # Validar fechas
        if self.fecha_inicio and self.fecha_fin:
            if self.fecha_inicio >= self.fecha_fin:
                errors["fecha_fin"] = (
                    "La fecha de fin debe ser posterior a la de inicio"
                )

        # Validar pedidos mínimos
        if self.pedidos_minimos < 1:
            errors["pedidos_minimos"] = "Debe requerir al menos 1 pedido"

        if errors:
            raise ValidationError(errors)

    def save(self, *args, **kwargs):
        """Override save para calcular mes/año"""
        if self.fecha_inicio:
            self.mes = self.fecha_inicio.month
            self.anio = self.fecha_inicio.year

        super().save(*args, **kwargs)

    # ============================================
    # MÉTODOS DE NEGOCIO
    # ============================================

    def obtener_participantes_elegibles(self):
        """
        Obtiene usuarios elegibles para participar

        Returns:
            QuerySet: Usuarios con pedidos mínimos entregados
        """
        usuarios_elegibles = (
            User.objects.filter(
                rol_activo=User.RolChoices.CLIENTE,
                is_active=True,
                cuenta_desactivada=False,
            )
            .annotate(
                pedidos_completados=Count(
                    "perfil__pedidos",
                    filter=Q(
                        perfil__pedidos__estado=EstadoPedido.ENTREGADO,
                        perfil__pedidos__fecha_entregado__gte=self.fecha_inicio,
                        perfil__pedidos__fecha_entregado__lte=self.fecha_fin,
                    ),
                )
            )
            .filter(pedidos_completados__gte=self.pedidos_minimos)
            .distinct()
        )

        return usuarios_elegibles

    def obtener_participaciones(self):
        """
        Obtiene participaciones registradas para la rifa.

        Returns:
            QuerySet: Participaciones con datos de usuario.
        """
        return self.participaciones.select_related("usuario")

    def usuario_es_elegible(self, usuario):
        """
        Verifica si un usuario específico es elegible

        Args:
            usuario (User): Usuario a verificar

        Returns:
            dict: {'elegible': bool, 'pedidos': int, 'faltantes': int}
        """
        # Contar pedidos entregados en el rango
        pedidos_completados = Pedido.objects.filter(
            cliente__user=usuario,
            estado=EstadoPedido.ENTREGADO,
            fecha_entregado__gte=self.fecha_inicio,
            fecha_entregado__lte=self.fecha_fin,
        ).count()

        faltantes = max(0, self.pedidos_minimos - pedidos_completados)

        if usuario.rol_activo != User.RolChoices.CLIENTE:
            return {
                "elegible": False,
                "pedidos": pedidos_completados,
                "faltantes": faltantes,
                "razon": "Solo usuarios regulares pueden participar",
            }
        if not usuario.perfil.participa_en_sorteos:
            return {
                "elegible": False,
                "pedidos": pedidos_completados,
                "faltantes": faltantes,
                "razon": "Tu cuenta no está habilitada para rifas",
            }

        elegible = pedidos_completados >= self.pedidos_minimos

        return {
            "elegible": elegible,
            "pedidos": pedidos_completados,
            "faltantes": faltantes,
            "razon": (
                "Cumples los requisitos"
                if elegible
                else f"Te faltan {faltantes} pedidos"
            ),
        }

    def realizar_sorteo(self):
        """
        Realiza el sorteo y selecciona ganadores para cada premio
        Los premios se sortean del menor al mayor (3ro, 2do, 1ro)

        Returns:
            dict: {'premios_ganados': list, 'sin_participantes': bool}
        """
        if self.estado != EstadoRifa.ACTIVA:
            raise ValidationError("Solo se puede sortear una rifa activa")

        # Verificar que no haya ganadores ya asignados
        if self.premios.filter(ganador__isnull=False).exists():
            raise ValidationError("Esta rifa ya tiene ganadores asignados")

        # Obtener participantes registrados
        participaciones = list(self.obtener_participaciones())

        if not participaciones:
            logger.warning(
                f"No hay participantes registrados para la rifa {self.titulo}"
            )
            self.estado = EstadoRifa.FINALIZADA
            self.save()
            return {"premios_ganados": [], "sin_participantes": True}

        # Obtener premios activos ordenados del 3ro al 1ro
        premios = self.premios.filter(estado=EstadoPremio.ACTIVO).order_by(
            "-posicion"
        )  # 3, 2, 1

        if not premios:
            raise ValidationError("Esta rifa no tiene premios activos para sortear")

        premios_ganados = []
        participantes_disponibles = participaciones.copy()

        # Sortear cada premio
        for premio in premios:
            if not participantes_disponibles:
                logger.warning(
                    f"No hay más participantes para el premio {premio.posicion}"
                )
                break

            # Seleccionar ganador aleatorio
            participacion = random.choice(participantes_disponibles)
            ganador = participacion.usuario
            premio.ganador = ganador
            premio.save()

            # Remover ganador de la lista para que no gane dos veces
            participantes_disponibles.remove(participacion)

            premios_ganados.append(
                {
                    "posicion": premio.posicion,
                    "descripcion": premio.descripcion,
                    "ganador": ganador,
                }
            )

            # Crear registro de participación
            if not participacion.ganador:
                participacion.ganador = True
                participacion.posicion_premio = premio.posicion
                participacion.save()

            logger.info(
                f"Premio {premio.posicion} ({premio.descripcion}) ganado por: "
                f"{ganador.get_full_name()} ({ganador.email})"
            )

        # Finalizar rifa
        self.estado = EstadoRifa.FINALIZADA
        self.save()

        return {"premios_ganados": premios_ganados, "sin_participantes": False}

    def cancelar_rifa(self, motivo=None):
        """Cancela la rifa"""
        if self.estado == EstadoRifa.FINALIZADA:
            raise ValidationError("No se puede cancelar una rifa finalizada")

        self.estado = EstadoRifa.CANCELADA
        self.save()

        logger.warning(f"Rifa cancelada: {self.titulo}. Motivo: {motivo}")

    @classmethod
    def obtener_rifa_activa(cls):
        """
        Obtiene la rifa activa actual

        Returns:
            Rifa: Rifa activa o None
        """
        return (
            cls.objects.filter(estado=EstadoRifa.ACTIVA)
            .order_by("-fecha_inicio")
            .first()
        )

    @classmethod
    def obtener_historial_ganadores(cls, limit=10):
        """
        Obtiene historial de rifas finalizadas

        Args:
            limit (int): Cantidad de registros

        Returns:
            QuerySet: Rifas finalizadas
        """
        return (
            cls.objects.filter(estado=EstadoRifa.FINALIZADA)
            .prefetch_related("premios__ganador")
            .order_by("-fecha_fin")[:limit]
        )

    # ============================================
    #  PROPIEDADES
    # ============================================

    @property
    def esta_activa(self):
        """Verifica si la rifa está activa"""
        return self.estado == EstadoRifa.ACTIVA

    @property
    def dias_restantes(self):
        """Calcula días restantes"""
        if self.estado != EstadoRifa.ACTIVA:
            return 0

        diff = self.fecha_fin - timezone.now()
        return max(0, diff.days)

    @property
    def total_participantes(self):
        """Cuenta participantes registrados"""
        return self.participaciones.count()

    @property
    def mes_nombre(self):
        """Nombre del mes en español"""
        meses = [
            "",
            "Enero",
            "Febrero",
            "Marzo",
            "Abril",
            "Mayo",
            "Junio",
            "Julio",
            "Agosto",
            "Septiembre",
            "Octubre",
            "Noviembre",
            "Diciembre",
        ]
        return meses[self.mes]


# ============================================
# MODELO: PREMIO
# ============================================


class Premio(models.Model):
    """
    Premio individual de una rifa

    POSICIONES:
    1 = Primer lugar (premio mayor)
    2 = Segundo lugar
    3 = Tercer lugar

    Se muestran del 3 al 1 (orden inverso)
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    rifa = models.ForeignKey(
        Rifa, on_delete=models.CASCADE, related_name="premios", verbose_name="Rifa"
    )

    posicion = models.PositiveIntegerField(
        verbose_name="Posición",
        help_text="1=Primer lugar, 2=Segundo, 3=Tercero",
        choices=[(1, "1er Lugar"), (2, "2do Lugar"), (3, "3er Lugar")],
    )

    descripcion = models.CharField(
        max_length=300, verbose_name="Descripción", help_text="Descripción del premio"
    )

    imagen = models.ImageField(
        upload_to="rifas/premios/%Y/%m/",
        null=True,
        blank=True,
        verbose_name="Imagen del Premio",
        help_text="Imagen específica de este premio",
    )

    ganador = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="premios_ganados",
        verbose_name="Ganador",
        help_text="Usuario ganador de este premio",
    )

    estado = models.CharField(
        max_length=20,
        choices=EstadoPremio.choices,
        default=EstadoPremio.ACTIVO,
        verbose_name="Estado del Premio",
        help_text="Indica si el premio está activo o ha sido cancelado",
    )

    creado_en = models.DateTimeField(
        auto_now_add=True, verbose_name="Fecha de Creación"
    )

    class Meta:
        db_table = "rifas_premios"
        verbose_name = "Premio"
        verbose_name_plural = "Premios"
        ordering = ["rifa", "posicion"]
        constraints = [
            # Solo un premio por posición por rifa
            models.UniqueConstraint(
                fields=["rifa", "posicion"], name="premio_unico_por_posicion"
            ),
        ]
        indexes = [
            models.Index(fields=["rifa", "posicion"]),
            models.Index(fields=["ganador"]),
            models.Index(fields=["estado"]),
        ]

    def __str__(self):
        posicion_str = {1: "1er", 2: "2do", 3: "3er"}.get(
            self.posicion, f"{self.posicion}°"
        )
        return f"{self.rifa.titulo} - {posicion_str} Lugar: {self.descripcion}"

    def clean(self):
        """Validaciones personalizadas"""
        super().clean()

        errors = {}

        # Validar posición
        if self.posicion not in [1, 2, 3]:
            errors["posicion"] = "La posición debe ser 1, 2 o 3"

        if errors:
            raise ValidationError(errors)


# ============================================
#  MODELO: PARTICIPACIÓN
# ============================================


class Participacion(models.Model):
    """
    Registro de participación en rifas

    Guarda historial de quién participó y si ganó
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    rifa = models.ForeignKey(
        Rifa,
        on_delete=models.CASCADE,
        related_name="participaciones",
        verbose_name="Rifa",
    )

    usuario = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="participaciones_rifas",
        verbose_name="Usuario",
    )

    ganador = models.BooleanField(
        default=False,
        verbose_name="Ganador",
        help_text="Indica si este usuario ganó un premio",
    )

    posicion_premio = models.PositiveIntegerField(
        null=True,
        blank=True,
        verbose_name="Posición del Premio",
        help_text="Qué premio ganó (1, 2, 3) si aplica",
    )

    pedidos_completados = models.PositiveIntegerField(
        default=0,
        verbose_name="Pedidos Completados",
        help_text="Cantidad de pedidos al momento del sorteo",
    )

    fecha_registro = models.DateTimeField(
        auto_now_add=True, verbose_name="Fecha de Registro"
    )

    class Meta:
        db_table = "rifas_participaciones"
        verbose_name = "Participación"
        verbose_name_plural = "Participaciones"
        ordering = ["-fecha_registro"]
        unique_together = [["rifa", "usuario"]]
        indexes = [
            models.Index(fields=["rifa", "usuario"]),
            models.Index(fields=["ganador"]),
        ]

    def __str__(self):
        ganador_str = (
            f" - GANADOR {self.posicion_premio}° LUGAR" if self.ganador else ""
        )
        return f"{self.usuario.email} - {self.rifa.titulo}{ganador_str}"

    def save(self, *args, **kwargs):
        """Calcular pedidos completados al guardar"""
        if not self.pedidos_completados:
            elegibilidad = self.rifa.usuario_es_elegible(self.usuario)
            self.pedidos_completados = elegibilidad["pedidos"]

        super().save(*args, **kwargs)
