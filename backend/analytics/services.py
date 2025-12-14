from django.core.cache import cache
import logging

logger = logging.getLogger('analytics')

def actualizar_metricas(metrica_key, incremento=1):
    """Incrementa contadores en Redis/Memcached"""
    try:
        if cache.get(metrica_key) is None:
            cache.set(metrica_key, 0, timeout=86400) # 24 horas
        
        nuevo_valor = cache.incr(metrica_key, delta=incremento)
        logger.debug(f"📊 [METRICA] {metrica_key} actualizada a {nuevo_valor}")
    except Exception as e:
        # Fallback silencioso si Redis falla
        logger.warning(f"No se pudo actualizar métrica {metrica_key}: {e}")

def registrar_cancelacion(pedido):
    """Registra eventos de cancelación"""
    logger.info(f"📊 [ANALYTICS] Cancelación registrada: ID {pedido.id}")
    actualizar_metricas('total_cancelaciones', 1)