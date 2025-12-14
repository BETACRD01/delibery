# chat/signals.py
from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from django.db import transaction
from pedidos.models import Pedido
from .models import Chat, TipoChat
import logging

logger = logging.getLogger('chat')

@receiver(pre_save, sender=Pedido)
def capturar_repartidor_anterior(sender, instance, **kwargs):
    """Detecta si se está cambiando el repartidor"""
    if instance.pk:
        try:
            old = Pedido.objects.get(pk=instance.pk)
            instance._repartidor_antiguo = old.repartidor
        except Pedido.DoesNotExist:
            instance._repartidor_antiguo = None
    else:
        instance._repartidor_antiguo = None

@receiver(post_save, sender=Pedido)
def gestionar_chats_pedido(sender, instance, created, **kwargs):
    """
    Crea o actualiza los chats cuando se asigna/cambia repartidor.
    """
    if kwargs.get('raw', False): return

    # Si no hay repartidor nuevo, no hacemos nada (o podríamos cerrar chats)
    if not instance.repartidor:
        return

    # Lógica de Cambio de Repartidor
    repartidor_nuevo = instance.repartidor.user
    repartidor_antiguo = getattr(instance, '_repartidor_antiguo', None)
    
    # 1. Si ya existen chats, verificar si hay que cambiar participantes
    chats_existentes = instance.chats.all()
    
    if chats_existentes.exists():
        if repartidor_antiguo and repartidor_antiguo != instance.repartidor:
            logger.info(f"Cambio de repartidor en pedido #{instance.id}. Actualizando chats...")
            
            for chat in chats_existentes:
                # Sacar al antiguo
                chat.participantes.remove(repartidor_antiguo.user)
                # Meter al nuevo
                chat.participantes.add(repartidor_nuevo)
                
                # Avisar en el chat
                chat.enviar_mensaje_sistema(
                    f"El repartidor ha cambiado. Ahora te atiende {repartidor_nuevo.get_full_name()}."
                )
        return

    # 2. Si no existen chats y hay repartidor, crearlos (Caso inicial)
    transaction.on_commit(lambda: Chat.crear_chats_para_pedido(instance))