import logging
from django.contrib.auth import get_user_model
# from django.core.mail import send_mail  # Descomentar cuando tengas SMTP configurado

User = get_user_model()
logger = logging.getLogger('notificaciones')

def notificar_admin_evento(titulo, mensaje, prioridad="media"):
    """
    Busca a todos los administradores (Superusers) y les envía una alerta.
    Útil para: Retrasos críticos, errores de sistema, stock bajo crítico.
    """
    try:
        # 1. Buscar a QUIÉN avisar: Usuarios activos que sean Superuser o Staff
        # Esto te incluye a ti (el dueño del sistema)
        admins = User.objects.filter(is_superuser=True, is_active=True)
        
        # Si tienes roles definidos, también podrías filtrar por rol:
        # admins = User.objects.filter(rol='ADMIN', is_active=True)

        count = admins.count()
        if count == 0:
            logger.warning(f"Se intentó notificar al admin: '{titulo}', pero no hay superusuarios activos.")
            return

        # 2. Recopilar emails (si quisieras enviar correo)
        emails_destino = [admin.email for admin in admins if admin.email]

        # 3. Acción de Notificación (MVP: Log Consola + Simulación Email)
        logger.info(f"[NOTIFICACIÓN ADMIN] Enviando a {count} administradores.")
        logger.info(f"   ASUNTO: {titulo}")
        logger.info(f"   MENSAJE: {mensaje}")

        # --- ZONA DE ENVÍO REAL (Cuando configures correos) ---
        # if emails_destino:
        #     send_mail(
        #         subject=f"[ALERTA SISTEMA] {titulo}",
        #         message=mensaje,
        #         from_email='sistema@tuapp.com',
        #         recipient_list=emails_destino,
        #         fail_silently=True
        #     )
        
    except Exception as e:
        logger.error(f"Error al intentar notificar admin: {e}")

# ... (Aquí irían tus otras funciones como notificar_admin_nuevo_pedido, etc.)