from django.apps import AppConfig

class ChatConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'chat'
    verbose_name = 'Sistema de Chat'

    def ready(self):
        """
        Este método se ejecuta cuando Django inicia.
        Es OBLIGATORIO importar los signals aquí para que funcionen.
        """
        try:
            import chat.signals
        except ImportError:
            pass