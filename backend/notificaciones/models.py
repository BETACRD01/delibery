# notificaciones/models.py (VERSIÓN OPTIMIZADA)
"""
Modelo de Notificaciones con Managers personalizados y optimización de índices.
"""

import uuid
import logging
from django.db import models
from django.utils import timezone
from django.conf import settings # Para referenciar al modelo User correctamente

logger = logging.getLogger('notificaciones')


# ==========================================================
#  1. MANAGER Y QUERYSET PERSONALIZADO
# ==========================================================

class NotificacionQuerySet(models.QuerySet):
    """
    Permite encadenar filtros personalizados.
    Ej: Notificacion.objects.filter(usuario=user).no_leidas()
    """
    
    def para_usuario(self, usuario):
        return self.filter(usuario=usuario)

    def leidas(self):
        return self.filter(leida=True)

    def no_leidas(self):
        return self.filter(leida=False)

    def recientes(self):
        return self.order_by('-creada_en')

    def marcar_como_leidas(self):
        """Optimización: Update masivo en una sola consulta SQL"""
        return self.update(leida=True, leida_en=timezone.now())


class NotificacionManager(models.Manager):
    """Manager principal para encapsular lógica de negocio"""
    
    def get_queryset(self):
        return NotificacionQuerySet(self.model, using=self._db)

    def no_leidas(self):
        return self.get_queryset().no_leidas()

    def contar_no_leidas(self, usuario):
        """Cuenta rápida usando índices"""
        return self.get_queryset().para_usuario(usuario).no_leidas().count()

    def limpiar_antiguas(self, dias=30):
        """Elimina notificaciones viejas para mantener la BD ligera"""
        from datetime import timedelta
        fecha_limite = timezone.now() - timedelta(days=dias)
        # Solo borramos las que ya fueron leídas o son muy viejas
        count, _ = self.get_queryset().filter(
            creada_en__lt=fecha_limite
        ).delete()
        return count


# ==========================================================
#  2. TIPOS DE NOTIFICACIÓN (ENUM)
# ==========================================================

class TipoNotificacion(models.TextChoices):
    PEDIDO = 'pedido', 'Pedido'
    SISTEMA = 'sistema', 'Sistema'
    PROMOCION = 'promocion', 'Promoción'
    REPARTIDOR = 'repartidor', 'Repartidor'
    PAGO = 'pago', 'Pago'


# ==========================================================
#  3. MODELO PRINCIPAL
# ==========================================================

class Notificacion(models.Model):
    """
    Historial de notificaciones Push e In-App.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # RELACIONES
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='notificaciones',
        db_index=True
    )
    
    # Opcional: Vinculación con un pedido específico
    pedido = models.ForeignKey(
        'pedidos.Pedido', 
        on_delete=models.CASCADE, # Si se borra el pedido, se borra la notificación (limpieza auto)
        null=True, 
        blank=True,
        related_name='notificaciones'
    )

    # CONTENIDO
    tipo = models.CharField(
        max_length=20, 
        choices=TipoNotificacion.choices, 
        default=TipoNotificacion.SISTEMA
    )
    titulo = models.CharField(max_length=150)
    mensaje = models.TextField()
    
    # Datos técnicos para que Flutter navegue (ej: { "screen": "chat", "id": "5" })
    datos_extra = models.JSONField(default=dict, blank=True)

    # ESTADO
    leida = models.BooleanField(default=False, db_index=True)
    leida_en = models.DateTimeField(null=True, blank=True)

    # AUDITORÍA DE PUSH (Firebase)
    enviada_push = models.BooleanField(default=False)
    error_envio = models.TextField(blank=True, null=True)

    # TIMESTAMPS
    creada_en = models.DateTimeField(auto_now_add=True, db_index=True)

    # Conectamos el Manager
    objects = NotificacionManager()

    class Meta:
        db_table = 'notificaciones'
        verbose_name = 'Notificación'
        verbose_name_plural = 'Notificaciones'
        ordering = ['-creada_en']
        
        # ÍNDICES COMPUESTOS (Clave para velocidad)
        indexes = [
            # Para: "Dame las notificaciones de Juan ordenadas por fecha"
            models.Index(fields=['usuario', '-creada_en']),
            # Para: "Dame las no leídas de Juan"
            models.Index(fields=['usuario', 'leida']),
        ]

    def __str__(self):
        return f"{self.get_tipo_display()}: {self.titulo} ({self.usuario.email})"

    # ==========================================================
    #  MÉTODOS DE INSTANCIA
    # ==========================================================

    def marcar_leida(self):
        """Marca como leída de forma eficiente"""
        if not self.leida:
            self.leida = True
            self.leida_en = timezone.now()
            # update_fields es vital para no sobrescribir otros datos concurrentes
            self.save(update_fields=['leida', 'leida_en'])

    @property
    def hace_cuanto(self):
        """Helper para mostrar tiempo relativo (ej: '5 min')"""
        ahora = timezone.now()
        diferencia = ahora - self.creada_en
        
        segundos = diferencia.total_seconds()
        
        if segundos < 60:
            return "Ahora"
        elif segundos < 3600:
            return f"{int(segundos // 60)} min"
        elif segundos < 86400:
            return f"{int(segundos // 3600)} h"
        else:
            dias = int(segundos // 86400)
            return f"{dias} d"