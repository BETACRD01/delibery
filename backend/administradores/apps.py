# -*- coding: utf-8 -*-
# administradores/apps.py
"""
Configuración de la app de administradores
Inicialización segura sin queries durante app startup
Creación de configuración del sistema via Signals (post_migrate)
Signals para auditoría
"""

from django.apps import AppConfig
class AdministradoresConfig(AppConfig):
    """
    Configuración central de la aplicación de administradores.
    Define el namespace y carga los disparadores (signals) al inicio.
    """

    default_auto_field = "django.db.models.BigAutoField"
    name = "administradores"
    verbose_name = "Administradores y Gestión"

    def ready(self):
        """
        Método ejecutado cuando Django finaliza la carga inicial.
        Se utiliza estrictamente para registrar signals.
        """
        # Importación de efectos secundarios (Side-effects import)
        # Esto conecta los listeners de signals definidos en signals.py
        # No envolvemos esto en try-except: si falla, la app NO debe iniciar.
        import administradores.signals