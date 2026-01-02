# notificaciones/signals.py (VERSIÓN CORREGIDA Y FINAL)
"""
Automatización de Notificaciones basada en eventos del modelo Pedido.
CORRECCIÓN: Solucionado conflicto de ORM (.select_related vs .only)
"""

import logging
from django.db import transaction
from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from django.conf import settings

# Modelos
from pedidos.models import Pedido, EstadoPedido, TipoPedido

# Servicios
from notificaciones.services import crear_y_enviar_notificacion

logger = logging.getLogger('notificaciones.signals')


# ==========================================================
#  1. PRE-SAVE: DETECTAR ESTADO PREVIO
# ==========================================================

@receiver(pre_save, sender=Pedido)
def capturar_estado_anterior(sender, instance, **kwargs):
    """
    Antes de guardar, memorizamos el estado actual para
    poder compararlo después y saber si hubo un cambio.
    """
    if instance.pk:
        try:
            # CORRECCIÓN CRÍTICA AQUÍ:
            # Usamos .select_related(None) para anular cualquier optimización automática
            # que tenga el modelo Pedido (como traer al cliente) y evitar el error:
            # "cannot be both deferred and traversed using select_related"
            old_instance = Pedido.objects.select_related(None).only('estado').get(pk=instance.pk)
            instance._estado_anterior = old_instance.estado
        except Pedido.DoesNotExist:
            instance._estado_anterior = None
    else:
        instance._estado_anterior = None


# ==========================================================
#  2. POST-SAVE: DISPARADOR (TRIGGER)
# ==========================================================

@receiver(post_save, sender=Pedido)
def gestionar_notificacion_cambio_estado(sender, instance, created, **kwargs):
    """
    Evalúa si el cambio merece una notificación y la programa
    para después del commit de base de datos.
    """
    # Evitar enviar notificaciones durante tests unitarios
    if getattr(settings, 'TESTING', False):
        return

    # Caso 1: Nuevo Pedido
    if created:
        transaction.on_commit(lambda: _procesar_notificacion(instance, 'creado'))
        return

    # Caso 2: Cambio de Estado
    estado_nuevo = instance.estado
    estado_viejo = getattr(instance, '_estado_anterior', None)

    if estado_viejo and estado_nuevo != estado_viejo:
        # Usamos lambda para pasar argumentos a la función diferida
        transaction.on_commit(
            lambda: _procesar_notificacion(instance, 'cambio_estado', estado_viejo)
        )


# ==========================================================
#  3. LÓGICA DE NEGOCIO (PROCESAMIENTO)
# ==========================================================

def _procesar_notificacion(pedido, evento, estado_anterior=None):
    """
    Construye el mensaje y llama al servicio de envío.
    """
    try:
        # Refrescamos el objeto para asegurar datos frescos post-transacción
        pedido.refresh_from_db()
        
        datos = _obtener_plantilla_mensaje(pedido, evento, estado_anterior)
        
        if not datos:
            return # No hay notificación configurada para este caso

        # Llamada al servicio principal
        crear_y_enviar_notificacion(
            usuario=pedido.cliente.user,
            titulo=datos['titulo'],
            mensaje=datos['mensaje'],
            tipo='pedido',
            pedido=pedido,
            datos_extra={
                'accion': 'ver_pedido',
                'pedido_id': str(pedido.id),
                'estado': pedido.estado
            }
        )
        logger.info(f"Notificación enviada: Pedido #{pedido.numero_pedido} -> {pedido.estado}")

    except Exception as e:
        logger.error(f"Error procesando notificación señal: {e}", exc_info=True)


def _obtener_plantilla_mensaje(pedido, evento, estado_anterior):
    """
    Diccionario centralizado de textos para notificaciones.
    Define qué se dice en cada situación.
    """
    estado = pedido.estado
    numero = pedido.numero_pedido or f"#{pedido.id}"
    proveedor = pedido.proveedor.nombre if pedido.proveedor else "JP Express"

    # --- NUEVO PEDIDO ---
    if evento == 'creado':
        es_courier = pedido.tipo == TipoPedido.DIRECTO
        
        if es_courier:
            return {
                'titulo': "¡Encargo Recibido!",
                'mensaje': f"Tu encargo {numero} ha sido creado. Buscando repartidor cercano..."
            }
        else:
            return {
                'titulo': "¡Pedido Recibido!",
                'mensaje': f"Tu pedido {numero} ha sido creado. Un repartidor lo tomará pronto."
            }

    # --- CAMBIOS DE ESTADO ---

    if estado == EstadoPedido.ASIGNADO_REPARTIDOR:
        nombre_repartidor = pedido.repartidor.user.first_name if pedido.repartidor else "Un repartidor"
        
        es_courier = pedido.tipo == TipoPedido.DIRECTO
        tipo_texto = "encargo" if es_courier else "pedido"
        
        if pedido.metodo_pago == 'transferencia':
            return {
                'titulo': f"Repartidor aceptó tu {tipo_texto}",
                'mensaje': f"{nombre_repartidor} aceptó tu {tipo_texto} #{numero}. Transfiere ${pedido.total} y sube el comprobante."
            }
        return {
            'titulo': "Repartidor Asignado",
            'mensaje': f"{nombre_repartidor} ha aceptado tu {tipo_texto} y está en camino a recogerlo."
        }

    elif estado == EstadoPedido.EN_PROCESO:
        return {
            'titulo': "Recogiendo tu pedido",
            'mensaje': f"El repartidor está recogiendo tus productos de {proveedor}."
        }

    elif estado == EstadoPedido.EN_CAMINO:
        nombre_repartidor = pedido.repartidor.user.first_name if pedido.repartidor else "El repartidor"
        return {
            'titulo': "¡Va en camino!",
            'mensaje': f"{nombre_repartidor} está en camino a tu ubicación."
        }

    elif estado == EstadoPedido.ENTREGADO:
        return {
            'titulo': "¡Pedido Entregado!",
            'mensaje': "Esperamos que disfrutes tu compra. ¡Gracias por confiar en nosotros!"
        }

    elif estado == EstadoPedido.CANCELADO:
        motivo = f": {pedido.motivo_cancelacion}" if pedido.motivo_cancelacion else "."
        return {
            'titulo': "Pedido Cancelado",
            'mensaje': f"Lo sentimos, el pedido {numero} fue cancelado{motivo}"
        }

    # Si es un estado intermedio sin importancia para el usuario, retornamos None
    return None
