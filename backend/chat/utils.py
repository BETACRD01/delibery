# chat/utils.py
"""
Utilidades para notificaciones de chat.
INTEGRACIÓN: Usa el servicio centralizado de 'notificaciones'.
"""

import logging
try:
    from notificaciones.services import crear_y_enviar_notificacion
    NOTIFICACIONES_ACTIVAS = True
except ImportError:
    NOTIFICACIONES_ACTIVAS = False

logger = logging.getLogger('chat')

def enviar_notificacion_nuevo_mensaje(mensaje, remitente):
    """
    Envía push al destinatario usando el módulo central de notificaciones.
    """
    if not NOTIFICACIONES_ACTIVAS:
        logger.warning("Módulo de notificaciones no disponible.")
        return

    try:
        chat = mensaje.chat
        # Identificar destinatarios (todos menos el que envió)
        destinatarios = chat.participantes.exclude(id=remitente.id)

        nombre_remitente = remitente.get_full_name() or "Usuario"
        texto_preview = "Foto" if mensaje.es_imagen else ("🎤 Audio" if mensaje.es_audio else mensaje.contenido[:50])

        for destinatario in destinatarios:
            # Título dinámico según quién recibe
            titulo = f"Mensaje de {nombre_remitente}"
            
            # Personalizar título si es el cliente recibiendo del repartidor
            if chat.tipo == 'pedido_cliente':
                if remitente == chat.pedido.repartidor.user:
                    titulo = "El Repartidor dice:"
            
            crear_y_enviar_notificacion(
                usuario=destinatario,
                titulo=titulo,
                mensaje=texto_preview,
                tipo='chat',
                pedido=chat.pedido, # Vinculamos al pedido para que al tocar vaya a la orden
                datos_extra={
                    'chat_id': str(chat.id),
                    'tipo_chat': chat.tipo,
                    'accion': 'abrir_chat' # Para que Flutter sepa abrir la pantalla de chat
                }
            )
            
    except Exception as e:
        logger.error(f"Error notificando mensaje chat: {e}")