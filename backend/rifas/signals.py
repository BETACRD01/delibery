# Crear: rifas/signals.py
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .models import Rifa, Participacion
import logging

logger = logging.getLogger('rifas')

@receiver(post_save, sender=Rifa)
def rifa_post_save(sender, instance, created, **kwargs):
    """Signal después de guardar rifa"""
    if created:
        logger.info(f"Nueva rifa creada: {instance.titulo}")
    else:
        ganadores = instance.premios.filter(ganador__isnull=False)
        for premio in ganadores:
            logger.info(
                f"Ganador asignado a {instance.titulo} | Premio {premio.posicion}: {premio.ganador.email}"
            )

@receiver(post_save, sender=Participacion)
def participacion_ganador(sender, instance, created, **kwargs):
    """Notificar cuando hay un ganador"""
    ganador_previo = getattr(instance, "_ganador_prev", False)
    if instance.ganador and not ganador_previo:
        logger.info(f"GANADOR: {instance.usuario.email} ganó {instance.rifa.titulo}")
        _notificar_ganador_rifa(instance)


@receiver(pre_save, sender=Participacion)
def participacion_pre_save(sender, instance, **kwargs):
    """Guardar estado anterior de ganador para evitar notificaciones duplicadas."""
    if instance.pk:
        instance._ganador_prev = (
            Participacion.objects.filter(pk=instance.pk)
            .values_list("ganador", flat=True)
            .first()
            or False
        )
    else:
        instance._ganador_prev = False


def _notificar_ganador_rifa(participacion):
    usuario = participacion.usuario
    rifa = participacion.rifa
    premio = None
    if participacion.posicion_premio:
        premio = rifa.premios.filter(posicion=participacion.posicion_premio).first()

    premio_desc = premio.descripcion if premio else "Premio"
    posicion = (
        f"{participacion.posicion_premio}er lugar"
        if participacion.posicion_premio == 1
        else f"{participacion.posicion_premio}do lugar"
        if participacion.posicion_premio == 2
        else f"{participacion.posicion_premio}er lugar"
        if participacion.posicion_premio == 3
        else ""
    )

    titulo = "Ganaste la rifa"
    mensaje = (
        f'Felicidades, ganaste "{rifa.titulo}". '
        f"Premio: {premio_desc}. {posicion}".strip()
    )

    datos_extra = {
        "rifa_id": str(rifa.id),
        "rifa_titulo": rifa.titulo,
        "premio_posicion": str(participacion.posicion_premio or ""),
        "premio_descripcion": premio_desc,
    }

    try:
        from notificaciones.services import crear_y_enviar_notificacion

        crear_y_enviar_notificacion(
            usuario=usuario,
            titulo=titulo,
            mensaje=mensaje,
            tipo="rifa",
            datos_extra=datos_extra,
        )
    except Exception as e:
        logger.error(f"Error enviando push de rifa: {e}", exc_info=True)

    try:
        from authentication.email_utils import EmailService

        EmailService.enviar_rifa_ganada(
            user=usuario,
            rifa=rifa,
            premio=premio,
            posicion=participacion.posicion_premio,
        )
    except Exception as e:
        logger.error(f"Error enviando email de rifa: {e}", exc_info=True)
