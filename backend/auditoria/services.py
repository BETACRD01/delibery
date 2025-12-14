import logging
import json

# Logger específico para auditoría (puedes configurarlo en settings.py para que vaya a un archivo aparte)
audit_logger = logging.getLogger('auditoria')

def registrar_eliminacion(modelo, instancia_id, datos):
    """Guarda un registro JSON de lo que se eliminó"""
    registro = {
        'evento': 'ELIMINACION',
        'modelo': modelo,
        'id': instancia_id,
        'datos_respaldo': datos
    }
    audit_logger.critical(f"🗑️ [AUDITORIA] {json.dumps(registro)}")