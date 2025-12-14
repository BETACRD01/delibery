import logging

logger = logging.getLogger('reportes')

def enviar_reporte_diario(estadisticas):
    """
    Simula el envío de un reporte diario por correo electrónico.
    """
    logger.info("📊 [REPORTE DIARIO] Generando PDF y enviando a administradores...")
    logger.info(f"Datos del reporte: {estadisticas}")
    # Aquí iría lógica real: generar PDF, adjuntar a email, send_mail()

def enviar_reporte_semanal(estadisticas):
    """
    Simula el envío de un reporte semanal.
    """
    logger.info("📈 [REPORTE SEMANAL] Enviando análisis de rendimiento...")
    logger.info(f"Top Proveedores: {estadisticas.get('top_proveedores')}")