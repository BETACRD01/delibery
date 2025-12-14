# calificaciones/signals.py

import logging
from django.db.models.signals import post_save
from django.dispatch import receiver

logger = logging.getLogger('calificaciones')


@receiver(post_save, sender='pedidos.Pedido')
def solicitar_calificacion_al_entregar(sender, instance, **kwargs):
    """
    Cuando un pedido se marca como 'entregado', solicita calificaciones
    a todos los participantes.
    """
    # Solo actuar si el pedido está entregado
    if instance.estado != 'entregado':
        return

    # Evitar múltiples ejecuciones
    if getattr(instance, '_calificacion_solicitada', False):
        return

    instance._calificacion_solicitada = True

    # Importar el servicio aquí para evitar imports circulares
    from calificaciones.services import CalificacionService

    try:
        CalificacionService.solicitar_calificacion(instance)
        logger.info(f"⭐ Calificación solicitada para pedido #{instance.id}")
    except Exception as e:
        logger.error(f"Error solicitando calificación para pedido #{instance.id}: {e}")


@receiver(post_save, sender='authentication.User')
def crear_resumen_calificacion(sender, instance, created, **kwargs):
    """
    Crea el ResumenCalificacion cuando se crea un nuevo usuario.
    """
    if created:
        from calificaciones.models import ResumenCalificacion
        
        ResumenCalificacion.objects.get_or_create(user=instance)
        logger.debug(f"ResumenCalificacion creado para: {instance.email}")