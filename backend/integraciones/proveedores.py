import logging
import time
import random

logger = logging.getLogger('integraciones')

def sincronizar_pedido(pedido):
    """
    Simula una petición API al sistema externo del proveedor.
    """
    logger.info(f"[INTEGRACIÓN] Conectando con sistema de {pedido.proveedor.nombre}...")
    
    # Simular latencia de red
    time.sleep(0.5)
    
    # Simular respuesta exitosa
    external_id = f"EXT-{pedido.id}-{random.randint(1000, 9999)}"
    logger.info(f"[INTEGRACIÓN] Pedido #{pedido.id} sincronizado. ID Externo: {external_id}")
    
    return {
        'sincronizado': True,
        'external_id': external_id,
        'status_remoto': 'RECEIVED'
    }