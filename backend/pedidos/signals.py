# pedidos/signals.py (VERSIÓN OPTIMIZADA + LOGÍSTICA)

import logging
from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.utils import timezone
from django.db import transaction

from .models import Pedido, EstadoPedido, HistorialPedido

# Intentamos importar Envio para actualizaciones de logística
try:
    from envios.models import Envio
    ENVIOS_ACTIVE = True
except ImportError:
    ENVIOS_ACTIVE = False

logger = logging.getLogger('pedidos.signals')

# ==========================================================
#  CLASE DE PROTECCIÓN (SIGNAL GUARD)
# ==========================================================
class SignalGuard:
    """
    Evita bucles infinitos (recursión) cuando un signal guarda el mismo modelo.
    """
    _processing = set()

    @classmethod
    def run(cls, key, func, *args, **kwargs):
        if key in cls._processing:
            return
        
        cls._processing.add(key)
        try:
            func(*args, **kwargs)
        finally:
            cls._processing.discard(key)

# ==========================================================
#  SEÑALES PERSONALIZADAS
# ==========================================================
pedido_retrasado = Signal() # sender, pedido, tiempo_retraso


# ==========================================================
#  1. PRE-SAVE: AUDITORÍA Y DETECCIÓN DE CAMBIOS
# ==========================================================
@receiver(pre_save, sender=Pedido)
def auditar_cambios_previos(sender, instance, **kwargs):
    """
    Detecta cambios de estado y asignaciones antes de guardar.
    Registra en el historial automáticamente.
    """
    if not instance.pk: 
        return # Es creación, se maneja en post_save

    try:
        old_instance = Pedido.objects.get(pk=instance.pk)
        
        # A. Registrar Historial de Cambios de Estado
        if old_instance.estado != instance.estado:
            HistorialPedido.objects.create(
                pedido=instance,
                estado_anterior=old_instance.estado,
                estado_nuevo=instance.estado,
                observaciones=f"Cambio automático o manual: {instance.get_estado_display()}"
            )
            # Marcar timestamps automáticamente
            if instance.estado == EstadoPedido.ASIGNADO_REPARTIDOR:
                instance.fecha_asignado = timezone.now()
            elif instance.estado == EstadoPedido.EN_PROCESO:
                instance.fecha_en_proceso = timezone.now()
            elif instance.estado == EstadoPedido.EN_CAMINO:
                instance.fecha_en_camino = timezone.now()
            elif instance.estado == EstadoPedido.ENTREGADO:
                instance.fecha_entregado = timezone.now()
            elif instance.estado == EstadoPedido.CANCELADO:
                instance.fecha_cancelado = timezone.now()

        # B. Detectar Asignación de Repartidor
        if not old_instance.repartidor and instance.repartidor:
            logger.info(f"Repartidor {instance.repartidor} asignado al pedido {instance.numero_pedido}")
            # Aquí podrías disparar una notificación específica si quisieras

    except Pedido.DoesNotExist:
        pass
    except Exception as e:
        logger.error(f"Error en pre_save pedido: {e}")


# ==========================================================
#  2. POST-SAVE: ORQUESTADOR PRINCIPAL
# ==========================================================
@receiver(post_save, sender=Pedido)
def orquestador_eventos_pedido(sender, instance, created, **kwargs):
    """
    Maneja toda la lógica reactiva después de guardar un pedido.
    Usa SignalGuard para evitar recursión.
    """
    unique_key = f"pedido_{instance.id}_post_save"

    def _procesar():
        # --- CASO 1: NUEVO PEDIDO ---
        if created:
            handle_nuevo_pedido(instance)
            return

        # --- CASO 2: CAMBIO DE ESTADO ---
        # Actualizamos logística (App Envios)
        if ENVIOS_ACTIVE:
            actualizar_logistica(instance)

        # Lógica específica por estado
        if instance.estado == EstadoPedido.EN_CAMINO:
            notificar_cliente(instance, "Tu pedido va en camino")

        elif instance.estado == EstadoPedido.ENTREGADO:
            handle_pedido_entregado(instance)

        elif instance.estado == EstadoPedido.CANCELADO:
            handle_pedido_cancelado(instance)

    # Ejecutar protegido
    SignalGuard.run(unique_key, _procesar)


# ==========================================================
#  HANDLERS (LÓGICA DETALLADA)
# ==========================================================

def handle_nuevo_pedido(pedido):
    """Lógica cuando se crea un pedido nuevo"""
    logger.info(f"Nuevo Pedido: {pedido.numero_pedido} - Total: ${pedido.total}")

    # 1. Notificar a REPARTIDORES disponibles (NO a proveedores)
    try:
        from notificaciones.services import notificar_repartidores_nuevo_pedido
        notificar_repartidores_nuevo_pedido(pedido)
    except ImportError:
        logger.warning("Servicio de notificaciones no disponible")

    # 2. Analytics
    try:
        from analytics.services import registrar_venta
        registrar_venta(pedido.total)
    except ImportError:
        pass


def actualizar_logistica(pedido):
    """
    INTEGRACIÓN CLAVE: Sincroniza el estado del pedido con la tabla de Envíos.
    """
    if not hasattr(pedido, 'datos_envio'):
        return

    envio = pedido.datos_envio
    cambio = False

    # Si el pedido sale EN_CAMINO, la logística también
    if pedido.estado == EstadoPedido.EN_CAMINO and not envio.en_camino:
        envio.en_camino = True
        envio.fecha_salida = timezone.now()
        cambio = True
        logger.info(f"Logística iniciada para {pedido.numero_pedido}")

    # Si se entrega, cerramos la logística
    elif pedido.estado == EstadoPedido.ENTREGADO and envio.en_camino:
        envio.en_camino = False
        envio.fecha_llegada = timezone.now()
        cambio = True
        logger.info(f"Logística finalizada para {pedido.numero_pedido}")

    if cambio:
        envio.save()


def handle_pedido_entregado(pedido):
    """Lógica cuando se entrega"""
    logger.info(f"Pedido {pedido.numero_pedido} ENTREGADO. Procesando cierre.")

    # 1. Actualizar Stats del Repartidor
    if pedido.repartidor:
        try:
            pedido.repartidor.incrementar_entregas()
        except Exception as e:
            logger.error(f"Error actualizando stats repartidor: {e}")

    # 2. Notificar al Cliente
    notificar_cliente(pedido, "Tu pedido ha sido entregado. ¡Buen provecho!")

    # 3. Solicitar Calificación (si existe el módulo)
    try:
        from calificaciones.services import solicitar_calificacion
        solicitar_calificacion(pedido)
    except ImportError:
        pass


def handle_pedido_cancelado(pedido):
    """Lógica cuando se cancela"""
    logger.warning(f"Pedido {pedido.numero_pedido} CANCELADO.")
    
    # 1. Liberar Repartidor
    if pedido.repartidor:
        pedido.repartidor.marcar_disponible()
    
    # 2. Notificar
    notificar_cliente(pedido, "Tu pedido ha sido cancelado. Revisa los detalles en la app.")


def notificar_cliente(pedido, mensaje):
    """Helper para enviar push notifications"""
    try:
        from notificaciones.services import enviar_push
        enviar_push(usuario=pedido.cliente.user, titulo="Actualización de Pedido", cuerpo=mensaje)
    except ImportError:
        logger.debug(f"Simulando Push a {pedido.cliente.user.email}: {mensaje}")


# ==========================================================
#  SEÑALES ESPECIALES
# ==========================================================

@receiver(pedido_retrasado)
def on_pedido_retrasado(sender, pedido, tiempo_retraso, **kwargs):
    """Reacciona a la señal personalizada de tareas asíncronas"""
    logger.warning(f"ALERTA: Pedido {pedido.numero_pedido} retrasado por {tiempo_retraso} min")
    # Aquí podrías generar un cupón de compensación automáticamente
    
@receiver(post_delete, sender=Pedido)
def auditar_eliminacion(sender, instance, **kwargs):
    """Registro de seguridad si se borra un pedido"""
    logger.critical(f"¡ALERTA DE SEGURIDAD! Pedido eliminado: {instance.numero_pedido} (ID: {instance.id})")