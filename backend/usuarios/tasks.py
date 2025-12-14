# usuarios/tasks.py

"""
Tareas asíncronas de Celery para envío de notificaciones push.
Optimizado para escalabilidad y bajo consumo de recursos.
"""
from celery import shared_task
from django.db import transaction
from utils.firebase_service import FirebaseService
import logging

logger = logging.getLogger(__name__)

# Configuración de constantes
MAX_RETRIES_DEFAULT = 3
RETRY_DELAY_BASE = 60  # Segundos
BATCH_SIZE = 500  # Tamaño del lote para envíos masivos

# ==========================================
# TAREAS CORE (GENÉRICAS)
# ==========================================

@shared_task(bind=True, max_retries=MAX_RETRIES_DEFAULT)
def tarea_enviar_notificacion_individual(self, user_id, titulo, mensaje, data=None, imagen_url=None):
    """
    Envía una notificación push a un solo usuario.
    """
    try:
        result = FirebaseService.enviar_a_usuario(
            user_id=user_id,
            titulo=titulo,
            mensaje=mensaje,
            data=data or {},
            imagen_url=imagen_url
        )

        if not result.get('success'):
            logger.warning(f"Fallo envio notificacion usuario {user_id}: {result.get('message')}")
        
        return result

    except Exception as exc:
        logger.error(f"Error critico enviando notificacion a {user_id}: {exc}")
        raise self.retry(exc=exc, countdown=RETRY_DELAY_BASE * (2 ** self.request.retries))


@shared_task(bind=True, max_retries=2)
def tarea_enviar_notificacion_masiva(self, user_ids, titulo, mensaje, data=None, imagen_url=None):
    """
    Envía notificaciones a una lista de IDs de usuarios.
    """
    try:
        logger.info(f"Iniciando envio masivo a {len(user_ids)} usuarios")
        
        # Firebase suele manejar batches, pero delegamos al servicio
        result = FirebaseService.enviar_a_usuarios(
            user_ids=user_ids,
            titulo=titulo,
            mensaje=mensaje,
            data=data or {},
            imagen_url=imagen_url
        )

        log_msg = f"Envio masivo finalizado. Exito: {result.get('success_count', 0)}/{result.get('total', 0)}"
        logger.info(log_msg)
        return result

    except Exception as exc:
        logger.error(f"Error en envio masivo: {exc}")
        raise self.retry(exc=exc, countdown=120)


# ==========================================
# GESTIÓN UNIFICADA DE PEDIDOS
# ==========================================

@shared_task(bind=True, max_retries=MAX_RETRIES_DEFAULT)
def procesar_evento_pedido(self, pedido_id, evento, **kwargs):
    """
    Manejador centralizado para notificaciones de cambio de estado de pedidos.
    
    Args:
        pedido_id (int): ID del pedido.
        evento (str): Tipo de evento ('nuevo', 'confirmado', 'en_preparacion', 'en_camino', 'entregado', 'cancelado').
        **kwargs: Datos adicionales (ej: 'razon_cancelacion', 'nombre_repartidor').
    """
    try:
        from pedidos.models import Pedido
        
        # Optimización: Carga selectiva de relaciones necesarias
        try:
            pedido = Pedido.objects.select_related('usuario').get(id=pedido_id)
        except Pedido.DoesNotExist:
            logger.error(f"Pedido {pedido_id} no encontrado. Abortando notificacion.")
            return

        usuario = pedido.usuario
        numero = pedido.numero_pedido
        
        # Configuración de mensajes por evento (Estrategia Dictionary Dispatch)
        configuracion_eventos = {
            'nuevo': {
                'titulo': "Pedido Recibido",
                'mensaje': f"Hemos recibido tu pedido #{numero}. Esperando confirmación.",
                'data_type': 'pedido_nuevo'
            },
            'confirmado': {
                'titulo': "Pedido Confirmado",
                'mensaje': f"Tu pedido #{numero} ha sido aceptado y está siendo procesado.",
                'data_type': 'pedido_confirmado'
            },
            'en_preparacion': {
                'titulo': "En Preparación",
                'mensaje': f"Estamos preparando tu pedido #{numero}.",
                'data_type': 'pedido_preparacion'
            },
            'en_camino': {
                'titulo': "Pedido en Camino",
                'mensaje': f"El repartidor {kwargs.get('nombre_repartidor', '')} va en camino con tu pedido #{numero}.",
                'data_type': 'pedido_en_camino'
            },
            'entregado': {
                'titulo': "Pedido Entregado",
                'mensaje': f"Disfruta tu pedido #{numero}. Gracias por tu compra.",
                'data_type': 'pedido_entregado'
            },
            'cancelado': {
                'titulo': "Pedido Cancelado",
                'mensaje': f"Pedido #{numero} cancelado. Motivo: {kwargs.get('razon_cancelacion', 'Sin motivo especificado')}.",
                'data_type': 'pedido_cancelado'
            }
        }

        config = configuracion_eventos.get(evento)
        if not config:
            logger.warning(f"Evento de pedido desconocido: {evento}")
            return

        # Construcción del payload
        payload_data = {
            'tipo': config['data_type'],
            'pedido_id': str(pedido.id),
            'numero_pedido': numero,
            'accion': 'abrir_detalle_pedido'
        }

        # Ejecución del envío
        logger.info(f"Procesando notificacion pedido {numero} - Evento: {evento}")
        
        return FirebaseService.enviar_a_usuario(
            user_id=usuario.id,
            titulo=config['titulo'],
            mensaje=config['mensaje'],
            data=payload_data
        )

    except Exception as exc:
        logger.error(f"Error procesando evento {evento} para pedido {pedido_id}: {exc}")
        # Reintento exponencial
        raise self.retry(exc=exc, countdown=RETRY_DELAY_BASE * (2 ** self.request.retries))


# ==========================================
# TAREAS DE MARKETING Y PROMOCIONES
# ==========================================

@shared_task
def tarea_procesar_campana_promocional(titulo, mensaje, imagen_url=None, filtro_usuarios=None):
    """
    Procesa el envío de promociones masivas utilizando iteradores y lotes (chunks)
    para optimizar el uso de memoria RAM.
    """
    try:
        from usuarios.models import Perfil
        
        logger.info("Iniciando procesamiento de campana promocional")

        # Query base optimizada
        queryset = Perfil.objects.filter(
            notificaciones_promociones=True,
            fcm_token__isnull=False
        ).exclude(fcm_token='').values_list('fcm_token', flat=True)

        # Si hay filtros adicionales (ej: usuarios de cierta ciudad), aplicarlos aquí
        if filtro_usuarios:
             queryset = queryset.filter(**filtro_usuarios)

        total_enviados = 0
        tokens_batch = []

        # Uso de iterator() para no cargar todos los tokens en memoria RAM a la vez
        for token in queryset.iterator(chunk_size=BATCH_SIZE):
            tokens_batch.append(token)

            if len(tokens_batch) >= BATCH_SIZE:
                _enviar_lote_promocion(tokens_batch, titulo, mensaje, imagen_url)
                total_enviados += len(tokens_batch)
                tokens_batch = [] # Limpiar lote
        
        # Enviar remanente
        if tokens_batch:
            _enviar_lote_promocion(tokens_batch, titulo, mensaje, imagen_url)
            total_enviados += len(tokens_batch)

        logger.info(f"Campana finalizada. Total mensajes procesados: {total_enviados}")
        return {'total_procesado': total_enviados}

    except Exception as e:
        logger.error(f"Error en campana promocional: {e}", exc_info=True)


def _enviar_lote_promocion(tokens, titulo, mensaje, imagen_url):
    """Función auxiliar sincrónica para enviar un lote."""
    result = FirebaseService.enviar_notificacion_multiple(
        tokens=tokens,
        titulo=titulo,
        mensaje=mensaje,
        imagen_url=imagen_url,
        data={'tipo': 'promocion', 'accion': 'ver_promociones'}
    )
    
    # Manejo de limpieza de tokens (Side effect controlado)
    if result.get('tokens_invalidos'):
        from usuarios.models import Perfil
        Perfil.objects.filter(
            fcm_token__in=result['tokens_invalidos']
        ).update(fcm_token=None, fcm_token_actualizado=None)


# ==========================================
# MANTENIMIENTO DEL SISTEMA
# ==========================================

@shared_task
def tarea_mantenimiento_tokens():
    """
    Valida y limpia tokens FCM inválidos periódicamente.
    Recomendado ejecutar diariamente en horas de bajo tráfico.
    """
    from usuarios.models import Perfil
    
    logger.info("Iniciando mantenimiento de tokens FCM")
    
    tokens_eliminados = 0
    
    # Se procesan en lotes para no bloquear la DB
    queryset = Perfil.objects.filter(fcm_token__isnull=False).exclude(fcm_token='')
    
    for perfil in queryset.iterator(chunk_size=100):
        if not FirebaseService.validar_token(perfil.fcm_token):
            perfil.eliminar_fcm_token()
            tokens_eliminados += 1
            
    logger.info(f"Mantenimiento completado. Tokens purgados: {tokens_eliminados}")
    return {'tokens_eliminados': tokens_eliminados}