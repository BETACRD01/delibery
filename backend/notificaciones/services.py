# notificaciones/services.py
"""
Servicio de Firebase Cloud Messaging (FCM) y Notificaciones
ESTADO: PRODUCCIÓN (Optimizado para Flutter + Django)
"""

import logging
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
from typing import Optional, Dict, Any
import os
from django.utils import timezone

logger = logging.getLogger('notificaciones')

# Variable global para cachear la inicialización y evitar recargas
_firebase_initialized = False


# ==========================================================
#  1. GESTIÓN DE FIREBASE (CORE)
# ==========================================================

def inicializar_firebase():
    """
    Inicializa el SDK de Firebase Admin (Singleton pattern).
    Maneja errores si el archivo JSON no existe.
    """
    global _firebase_initialized

    if _firebase_initialized:
        return

    try:
        # Si ya hay una app inicializada por otro proceso, la usamos
        if firebase_admin._apps:
            _firebase_initialized = True
            return

        # Ruta configurada en settings.py
        credentials_path = getattr(
            settings,
            'FIREBASE_CREDENTIALS_PATH',
            os.path.join(settings.BASE_DIR, 'firebase-credentials.json')
        )

        if not os.path.exists(credentials_path):
            logger.warning(f"Archivo Firebase no encontrado en: {credentials_path}. Push desactivado.")
            return 

        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)

        _firebase_initialized = True
        logger.info("Firebase inicializado correctamente.")

    except Exception as e:
        logger.error(f"Error crítico inicializando Firebase: {e}", exc_info=True)


def enviar_notificacion_push(
    usuario,
    titulo: str,
    mensaje: str,
    datos_extra: Optional[Dict[str, Any]] = None,
    guardar_en_bd: bool = True,
    tipo: str = 'sistema',
    pedido = None
) -> tuple[bool, Optional[str]]:
    """
    Envía una notificación push a un usuario específico y guarda el registro.
    Maneja la limpieza de tokens inválidos automáticamente.
    """
    # 1. Inicialización Lazy
    if not _firebase_initialized:
        inicializar_firebase()
        
    # 2. Validaciones de Usuario y Token
    perfil = getattr(usuario, 'perfil', None)
    token_fcm = None
    if perfil and getattr(perfil, 'fcm_token', None):
        token_fcm = perfil.fcm_token
    elif getattr(usuario, 'fcm_token', None):
        token_fcm = usuario.fcm_token

    if not token_fcm:
        error = "Usuario sin token FCM registrado"
        if guardar_en_bd:
            _guardar_notificacion_en_bd(usuario, titulo, mensaje, datos_extra, False, error, tipo, pedido)
        return False, error

    # Verificar preferencias (si tu modelo Perfil tiene este campo)
    if hasattr(perfil, 'recibir_notificaciones') and not perfil.recibir_notificaciones:
        return False, "Usuario tiene notificaciones desactivadas"

    # 3. Preparación de Datos (IMPORTANTE PARA FLUTTER)
    datos_extra = datos_extra or {}
    
    # Firebase exige que todos los valores en 'data' sean STRINGS.
    # Convertimos todo para evitar errores 500.
    datos_str = {str(k): str(v) for k, v in datos_extra.items()}
    
    # Estandarización para que Flutter sepa qué hacer al hacer clic
    if 'click_action' not in datos_str:
        datos_str['click_action'] = 'FLUTTER_NOTIFICATION_CLICK'
    
    # Añadir timestamp si no existe
    if 'timestamp' not in datos_str:
        datos_str['timestamp'] = str(timezone.now().timestamp())

    # 4. Construcción y Envío del Mensaje
    if not _firebase_initialized:
         # Fallback si falló la inicialización pero queremos guardar en BD
        if guardar_en_bd:
            _guardar_notificacion_en_bd(usuario, titulo, mensaje, datos_extra, False, "Firebase no init", tipo, pedido)
        return False, "Firebase no inicializado"

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=titulo, 
                body=mensaje
            ),
            data=datos_str,
            token=token_fcm,
            # Configuración específica para Android (Icono, Color, Canal)
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    color='#FF6B35', # Color naranja de tu marca
                    channel_id='pedidos_channel',
                    click_action='FLUTTER_NOTIFICATION_CLICK',
                    icon='ic_notification' # Asegúrate de tener este recurso en tu app Android
                )
            ),
            # Configuración básica para iOS
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound='default')
                )
            )
        )

        response = messaging.send(message)
        logger.info(f"Push enviado a {usuario.email}. ID: {response}")

        if guardar_en_bd:
            _guardar_notificacion_en_bd(usuario, titulo, mensaje, datos_extra, True, None, tipo, pedido)

        return True, None

    except messaging.UnregisteredError:
        # EL TOKEN YA NO SIRVE (Usuario desinstaló o borró datos)
        # Lo borramos para no intentar enviar de nuevo
        if perfil:
            perfil.fcm_token = None
            perfil.save(update_fields=['fcm_token'])
        
        error = "Token FCM inválido (eliminado automáticamente)"
        logger.warning(f"{error} para {usuario.email}")
        
        if guardar_en_bd:
            _guardar_notificacion_en_bd(usuario, titulo, mensaje, datos_extra, False, error, tipo, pedido)
        return False, error

    except Exception as e:
        error = str(e)
        logger.error(f"Error enviando push: {e}")
        if guardar_en_bd:
            _guardar_notificacion_en_bd(usuario, titulo, mensaje, datos_extra, False, error, tipo, pedido)
        return False, error


def _guardar_notificacion_en_bd(usuario, titulo, mensaje, datos_extra, enviada_push, error_envio, tipo, pedido):
    """Guarda el historial en la base de datos de forma segura"""
    try:
        from notificaciones.models import Notificacion
        Notificacion.objects.create(
            usuario=usuario,
            pedido=pedido,
            tipo=tipo,
            titulo=titulo,
            mensaje=mensaje,
            datos_extra=datos_extra or {},
            enviada_push=enviada_push,
            error_envio=error_envio
        )
    except Exception as e:
        logger.error(f"Error guardando notificación en BD: {e}")


# ==========================================================
#  2. FACHADA PARA SIGNALS (EL PUENTE CRÍTICO)
# ==========================================================

def crear_y_enviar_notificacion(
    usuario,
    titulo: str,
    mensaje: str,
    tipo: str = "general",
    pedido=None,
    datos_extra: Optional[Dict] = None,
):
    """
    Función principal llamada por signals.py y tasks.py.
    Orquesta el envío real y el registro.
    REEMPLAZA AL STUB QUE TENÍAS ANTES.
    """
    # Preparar metadatos útiles para la App
    datos = datos_extra or {}
    datos['tipo_evento'] = tipo
    
    if pedido:
        datos['pedido_id'] = str(pedido.id)
        # Añadir estado actual si existe
        if hasattr(pedido, 'estado'):
            datos['pedido_estado'] = str(pedido.estado)

    # Llamada al core real
    exito, error = enviar_notificacion_push(
        usuario=usuario,
        titulo=titulo,
        mensaje=mensaje,
        datos_extra=datos,
        guardar_en_bd=True,
        tipo=tipo,
        pedido=pedido
    )
    
    return exito


# ==========================================================
#  3. FUNCIONES DE NEGOCIO (HELPERS)
# ==========================================================

def notificar_repartidor_pedido_listo(pedido):
    """Avisa al repartidor que recoja el pedido"""
    if not pedido.repartidor: return
    
    crear_y_enviar_notificacion(
        usuario=pedido.repartidor.user,
        titulo="Pedido Listo",
        mensaje=f"El pedido #{pedido.numero_pedido} está listo para recoger.",
        tipo='repartidor',
        pedido=pedido
    )

def notificar_admin_pedidos_sin_asignar(queryset):
    """Loguea alerta para admins (o envía email/push si se implementa)"""
    count = queryset.count()
    logger.warning(f"ALERTA ADMIN: {count} pedidos sin asignar.")
    # Aquí podrías iterar sobre usuarios staff y enviarles push si quisieras.

def enviar_recordatorio_calificacion(pedido):
    """Envía push solicitando calificación"""
    crear_y_enviar_notificacion(
        usuario=pedido.cliente.user,
        titulo="¡Tu opinión importa!",
        mensaje=f"¿Qué tal estuvo tu pedido de {pedido.proveedor.nombre if pedido.proveedor else 'JP Express'}? Califícanos ⭐",
        tipo='sistema',
        pedido=pedido,
        datos_extra={'accion': 'abrir_calificacion'}
    )

def notificar_repartidores_nuevo_pedido(pedido):
    """
    Notifica a todos los repartidores disponibles sobre un nuevo pedido.
    Los repartidores pueden aceptar el pedido desde la notificación.
    """
    try:
        from repartidores.models import Repartidor, EstadoRepartidor

        # Obtener repartidores disponibles (activos y no en un pedido)
        repartidores_disponibles = Repartidor.objects.filter(
            estado=EstadoRepartidor.DISPONIBLE,
            activo=True
        )

        proveedor_nombre = pedido.proveedor.nombre if pedido.proveedor else "JP Express"

        for repartidor in repartidores_disponibles:
            crear_y_enviar_notificacion(
                usuario=repartidor.user,
                titulo="Nuevo pedido disponible",
                mensaje=f"Tienes un nuevo pedido para recoger y entregar de {proveedor_nombre}. Total: ${pedido.total}",
                tipo='repartidor',
                pedido=pedido,
                datos_extra={
                    'accion': 'ver_pedido_disponible',
                    'pedido_id': str(pedido.id),
                    'total': str(pedido.total)
                }
            )

        logger.info(f"Notificación de nuevo pedido enviada a {repartidores_disponibles.count()} repartidores")

    except Exception as e:
        logger.error(f"Error notificando repartidores: {e}", exc_info=True)


def notificar_comprobante_subido(pago):
    """
    Notifica al repartidor cuando el cliente sube un comprobante de pago.
    El repartidor puede ver el comprobante desde la notificación.
    """
    try:
        if not pago.repartidor_asignado:
            logger.warning(f"Pago #{pago.id} no tiene repartidor asignado")
            return

        # Obtener el pedido relacionado
        pedido = pago.pedido
        cliente_nombre = pedido.cliente.user.get_full_name() or pedido.cliente.user.email

        crear_y_enviar_notificacion(
            usuario=pago.repartidor_asignado.user,
            titulo="Comprobante de pago recibido",
            mensaje=f"{cliente_nombre} ha subido el comprobante de pago del pedido #{pedido.numero_pedido}. Monto: ${pago.monto}",
            tipo='pago',
            pedido=pedido,
            datos_extra={
                'accion': 'ver_comprobante',
                'pago_id': str(pago.id),
                'pedido_id': str(pedido.id),
                'monto': str(pago.monto)
            }
        )

        logger.info(f"Notificación de comprobante enviada al repartidor {pago.repartidor_asignado.user.email}")

    except Exception as e:
        logger.error(f"Error notificando comprobante subido: {e}", exc_info=True)
