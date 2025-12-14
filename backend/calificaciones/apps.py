# calificaciones/apps.py

from django.apps import AppConfig


class CalificacionesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'calificaciones'
    verbose_name = 'Sistema de Calificaciones'

    def ready(self):
        """Importar signals cuando la app esté lista"""
        try:
            import calificaciones.signals  # noqa
        except ImportError:
            pass