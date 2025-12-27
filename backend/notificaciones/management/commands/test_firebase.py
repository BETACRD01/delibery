# notificaciones/management/commands/test_firebase.py
"""
Comando para probar el envío de notificaciones push de Firebase.
Uso: python manage.py test_firebase <email_usuario>
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Prueba el envío de notificaciones push de Firebase'

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='Email del usuario para enviar la prueba')
        parser.add_argument(
            '--titulo',
            type=str,
            default='Test de Firebase',
            help='Título de la notificación'
        )
        parser.add_argument(
            '--mensaje',
            type=str,
            default='Si ves esta notificación, Firebase funciona correctamente.',
            help='Mensaje de la notificación'
        )

    def handle(self, *args, **options):
        email = options['email']
        titulo = options['titulo']
        mensaje = options['mensaje']

        self.stdout.write(self.style.NOTICE(f'Buscando usuario: {email}'))

        # 1. Buscar usuario
        try:
            usuario = User.objects.get(email=email)
            self.stdout.write(self.style.SUCCESS(f'Usuario encontrado: {usuario.get_full_name() or email}'))
        except User.DoesNotExist:
            raise CommandError(f'Usuario con email "{email}" no encontrado.')

        # 2. Verificar perfil y token FCM
        perfil = getattr(usuario, 'perfil', None)
        if not perfil:
            raise CommandError(f'El usuario no tiene perfil asociado.')

        self.stdout.write(f'\n📱 Estado del dispositivo:')
        if perfil.fcm_token:
            token_preview = perfil.fcm_token[:30] + '...' if len(perfil.fcm_token) > 30 else perfil.fcm_token
            self.stdout.write(f'   Token FCM: {token_preview}')
            self.stdout.write(f'   Actualizado: {perfil.fcm_token_actualizado or "Desconocido"}')
        else:
            self.stdout.write(self.style.ERROR('   ❌ SIN TOKEN FCM - El usuario no ha registrado dispositivo'))
            self.stdout.write(self.style.WARNING('   💡 El usuario debe abrir la app para registrar su token'))
            return

        # 3. Verificar preferencias de notificación
        self.stdout.write(f'Configuración de notificaciones:')
        self.stdout.write(f'Notificaciones pedido: {perfil.notificaciones_pedido}')
        self.stdout.write(f'Notificaciones promociones: {perfil.notificaciones_promociones}')
        puede = getattr(perfil, 'puede_recibir_notificaciones', True)
        self.stdout.write(f'Puede recibir: {puede}')

        # 4. Verificar inicialización de Firebase
        self.stdout.write(f'Estado de Firebase:')
        from notificaciones.services import inicializar_firebase, _firebase_initialized
        inicializar_firebase()
        
        if _firebase_initialized:
            self.stdout.write(self.style.SUCCESS('Firebase inicializado correctamente'))
        else:
            self.stdout.write(self.style.ERROR('Firebase NO inicializado'))
            self.stdout.write(self.style.WARNING('Verifica que exista firebase-credentials.json'))
            return

        # 5. Enviar notificación de prueba
        self.stdout.write(f'Enviando notificación...')
        self.stdout.write(f'Título: {titulo}')
        self.stdout.write(f'Mensaje: {mensaje}')

        from notificaciones.services import enviar_notificacion_push

        exito, error = enviar_notificacion_push(
            usuario=usuario,
            titulo=titulo,
            mensaje=mensaje,
            datos_extra={
                'tipo': 'test',
                'timestamp': 'ahora',
                'accion': 'test_push'
            },
            guardar_en_bd=True,
            tipo='sistema'
        )

        if exito:
            self.stdout.write(self.style.SUCCESS(f'NOTIFICACIÓN ENVIADA EXITOSAMENTE'))
            self.stdout.write(f'Revisa el dispositivo del usuario para confirmar la recepción.')
        else:
            self.stdout.write(self.style.ERROR(f'ERROR AL ENVIAR'))
            self.stdout.write(self.style.ERROR(f'Detalle: {error}'))
            
            if 'Token' in str(error):
                self.stdout.write(self.style.WARNING('El token posiblemente expiró o el usuario desinstaló la app'))
            elif 'Firebase' in str(error):
                self.stdout.write(self.style.WARNING('Problema con la configuración de Firebase'))
