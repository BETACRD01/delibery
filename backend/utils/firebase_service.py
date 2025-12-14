# utils/firebase_service.py

import logging
import os
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings

logger = logging.getLogger('firebase')

class FirebaseService:
    """
    Servicio centralizado para envío de notificaciones push (FCM).
    """

    _initialized = False
    _app = None
    
    # Configuración predeterminada
    DEFAULT_ANDROID_COLOR = '#4FC3F7'
    DEFAULT_CHANNEL_ID = 'pedidos'
    BATCH_SIZE = 500

    @classmethod
    def initialize(cls):
        """Inicializa el SDK de Firebase Admin."""
        if cls._initialized:
            return True

        try:
            cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)
            if not cred_path:
                cred_path = os.path.join(settings.BASE_DIR, 'firebase-credentials.json')

            if not os.path.exists(cred_path):
                logger.warning(f"Archivo de credenciales no encontrado en: {cred_path}")
                return False

            cred = credentials.Certificate(cred_path)
            cls._app = firebase_admin.initialize_app(cred)
            cls._initialized = True
            logger.info("Firebase inicializado correctamente.")
            return True

        except Exception as e:
            logger.error(f"Error inicializando Firebase: {e}", exc_info=True)
            return False

    @classmethod
    def is_initialized(cls):
        return cls._initialized

    # ==========================================
    # MÉTODOS AUXILIARES (DRY)
    # ==========================================

    @staticmethod
    def _get_android_config(priority='high'):
        """Genera la configuración estándar para Android."""
        return messaging.AndroidConfig(
            priority=priority,
            notification=messaging.AndroidNotification(
                sound='default',
                color=getattr(settings, 'FCM_ANDROID_COLOR', FirebaseService.DEFAULT_ANDROID_COLOR),
                channel_id=getattr(settings, 'FCM_ANDROID_CHANNEL_ID', FirebaseService.DEFAULT_CHANNEL_ID)
            )
        )

    @staticmethod
    def _get_apns_config():
        """Genera la configuración estándar para iOS (APNS)."""
        return messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound='default', badge=1)
            )
        )

    # ==========================================
    # ENVÍO DE BAJO NIVEL
    # ==========================================

    @staticmethod
    def enviar_notificacion(token, titulo, mensaje, data=None, imagen_url=None):
        """Envía notificación a un solo dispositivo."""
        if not FirebaseService.is_initialized():
            return {'success': False, 'error': 'Firebase no inicializado'}

        if not token:
            return {'success': False, 'error': 'Token vacío'}

        try:
            message = messaging.Message(
                notification=messaging.Notification(title=titulo, body=mensaje, image=imagen_url),
                data=data if isinstance(data, dict) else {},
                token=token,
                android=FirebaseService._get_android_config(),
                apns=FirebaseService._get_apns_config()
            )

            response = messaging.send(message)
            return {'success': True, 'message_id': response}

        except messaging.UnregisteredError:
            logger.info(f"Token no registrado (invalido/expirado): {token[:15]}...")
            return {'success': False, 'error': 'Token invalido', 'token_invalido': True}
        except Exception as e:
            logger.error(f"Error enviando notificacion: {e}")
            return {'success': False, 'error': str(e)}

    @staticmethod
    def enviar_notificacion_multiple(tokens, titulo, mensaje, data=None, imagen_url=None):
        """Envía notificación multicast (máx 500 tokens por lote)."""
        if not FirebaseService.is_initialized() or not tokens:
            return {'success': 0, 'failure': 0, 'tokens_invalidos': [], 'total': 0}

        # Procesamiento por lotes si excede el límite
        batch_size = getattr(settings, 'FCM_BATCH_SIZE', FirebaseService.BATCH_SIZE)
        if len(tokens) > batch_size:
            return FirebaseService._enviar_notificacion_lotes(tokens, titulo, mensaje, data, imagen_url, batch_size)

        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(title=titulo, body=mensaje, image=imagen_url),
                data=data if isinstance(data, dict) else {},
                tokens=tokens,
                android=FirebaseService._get_android_config(),
                apns=FirebaseService._get_apns_config()
            )

            response = messaging.send_multicast(message)
            
            tokens_invalidos = [
                tokens[idx] for idx, resp in enumerate(response.responses) 
                if not resp.success and isinstance(resp.exception, messaging.UnregisteredError)
            ]

            return {
                'success': response.success_count,
                'failure': response.failure_count,
                'tokens_invalidos': tokens_invalidos,
                'total': len(tokens)
            }

        except Exception as e:
            logger.error(f"Error en envio multiple: {e}", exc_info=True)
            return {'success': 0, 'failure': len(tokens), 'tokens_invalidos': [], 'total': len(tokens)}

    @staticmethod
    def _enviar_notificacion_lotes(tokens, titulo, mensaje, data, imagen_url, batch_size):
        """Helper para dividir envíos masivos."""
        stats = {'success': 0, 'failure': 0, 'tokens_invalidos': [], 'total': len(tokens)}
        
        for i in range(0, len(tokens), batch_size):
            batch = tokens[i:i + batch_size]
            result = FirebaseService.enviar_notificacion_multiple(batch, titulo, mensaje, data, imagen_url)
            
            stats['success'] += result['success']
            stats['failure'] += result['failure']
            stats['tokens_invalidos'].extend(result['tokens_invalidos'])
            
        return stats

    # ==========================================
    # INTEGRACIÓN CON MODELOS DJANGO
    # ==========================================

    @staticmethod
    def enviar_a_usuario(user_id, titulo, mensaje, data=None, imagen_url=None):
        """Busca el token del usuario en BD y envía la notificación."""
        from usuarios.models import Perfil

        try:
            # Consulta optimizada
            perfil = Perfil.objects.filter(
                user_id=user_id, 
                fcm_token__isnull=False
            ).exclude(fcm_token='').only('fcm_token', 'notificaciones_pedido').first()

            if not perfil:
                return {'success': False, 'message': 'Usuario sin dispositivo registrado'}

            if not perfil.puede_recibir_notificaciones:
                return {'success': False, 'message': 'Notificaciones desactivadas por usuario'}

            result = FirebaseService.enviar_notificacion(
                perfil.fcm_token, titulo, mensaje, data, imagen_url
            )

            if not result['success'] and result.get('token_invalido'):
                perfil.eliminar_fcm_token()

            return result

        except Exception as e:
            logger.error(f"Error enviando a usuario {user_id}: {e}")
            return {'success': False, 'error': str(e)}

    @staticmethod
    def enviar_a_usuarios(user_ids, titulo, mensaje, data=None, imagen_url=None):
        """Envío masivo consultando tokens en BD."""
        from usuarios.models import Perfil

        try:
            # Consulta optimizada: solo traer el campo fcm_token
            tokens = list(Perfil.objects.filter(
                user_id__in=user_ids,
                fcm_token__isnull=False,
                notificaciones_pedido=True
            ).exclude(fcm_token='').values_list('fcm_token', flat=True))

            if not tokens:
                return {'success': False, 'message': 'Sin destinatarios validos'}

            result = FirebaseService.enviar_notificacion_multiple(
                tokens, titulo, mensaje, data, imagen_url
            )

            # Limpieza masiva de tokens inválidos
            if result['tokens_invalidos']:
                Perfil.objects.filter(fcm_token__in=result['tokens_invalidos']).update(
                    fcm_token=None, fcm_token_actualizado=None
                )

            return result

        except Exception as e:
            logger.error(f"Error en notificacion masiva a usuarios: {e}")
            return {'success': False, 'error': str(e)}

    # ==========================================
    # NOTIFICACIONES TRANSACCIONALES (PEDIDOS)
    # ==========================================

    @staticmethod
    def _enviar_transaccional(perfil, titulo, mensaje, data):
        """Helper privado para notificaciones de pedidos."""
        if not perfil.puede_recibir_notificaciones:
            return {'success': False, 'message': 'Notificaciones desactivadas'}

        result = FirebaseService.enviar_notificacion(
            token=perfil.fcm_token,
            titulo=titulo,
            mensaje=mensaje,
            data=data
        )

        if not result['success'] and result.get('token_invalido'):
            perfil.eliminar_fcm_token()
        
        return result

    @staticmethod
    def notificar_pedido_confirmado(perfil, pedido):
        return FirebaseService._enviar_transaccional(
            perfil,
            'Pedido Confirmado',
            f'Tu pedido #{pedido.numero_pedido} ha sido confirmado.',
            {
                'tipo': 'pedido_confirmado',
                'pedido_id': str(pedido.id),
                'numero_pedido': pedido.numero_pedido,
                'accion': 'abrir_detalle'
            }
        )

    @staticmethod
    def notificar_pedido_en_camino(perfil, pedido, repartidor_nombre):
        return FirebaseService._enviar_transaccional(
            perfil,
            'Tu pedido está en camino',
            f'{repartidor_nombre} lleva tu pedido #{pedido.numero_pedido}.',
            {
                'tipo': 'pedido_en_camino',
                'pedido_id': str(pedido.id),
                'numero_pedido': pedido.numero_pedido,
                'repartidor': repartidor_nombre,
                'accion': 'rastrear_pedido'
            }
        )

    @staticmethod
    def notificar_pedido_entregado(perfil, pedido):
        return FirebaseService._enviar_transaccional(
            perfil,
            'Pedido Entregado',
            'Tu pedido ha sido entregado. Gracias por tu compra.',
            {
                'tipo': 'pedido_entregado',
                'pedido_id': str(pedido.id),
                'numero_pedido': pedido.numero_pedido,
                'accion': 'calificar_servicio'
            }
        )

    @staticmethod
    def notificar_pedido_cancelado(perfil, pedido, razon=''):
        cuerpo = f'Tu pedido #{pedido.numero_pedido} ha sido cancelado.'
        if razon:
            cuerpo += f' Razón: {razon}'
            
        return FirebaseService._enviar_transaccional(
            perfil,
            'Pedido Cancelado',
            cuerpo,
            {
                'tipo': 'pedido_cancelado',
                'pedido_id': str(pedido.id),
                'numero_pedido': pedido.numero_pedido,
                'razon': razon,
                'accion': 'ver_detalle'
            }
        )

    @staticmethod
    def notificar_promocion(perfil, titulo, mensaje, imagen_url=None, data=None):
        if not perfil.notificaciones_promociones or not perfil.fcm_token:
            return {'success': False, 'message': 'Promociones desactivadas'}

        result = FirebaseService.enviar_notificacion(
            token=perfil.fcm_token,
            titulo=titulo,
            mensaje=mensaje,
            imagen_url=imagen_url,
            data=data or {'tipo': 'promocion', 'accion': 'ver_promociones'}
        )

        if not result['success'] and result.get('token_invalido'):
            perfil.eliminar_fcm_token()

        return result

    @staticmethod
    def validar_token(token):
        """Valida si un token es real enviando un mensaje dry_run."""
        if not token or len(token) < 50:
            return False
        try:
            message = messaging.Message(data={'test': 'true'}, token=token)
            messaging.send(message, dry_run=True)
            return True
        except Exception:
            return False