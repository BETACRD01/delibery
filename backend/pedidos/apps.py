from django.apps import AppConfig
import logging

logger = logging.getLogger('pedidos.apps')

class PedidosConfig(AppConfig):
    """
    Configuración de la aplicación de Pedidos.
    Gestiona el ciclo de vida y la carga de señales.
    """
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'pedidos'
    verbose_name = 'Gestión de Pedidos'

    def ready(self):
        """
        Se ejecuta al iniciar la aplicación.
        Es CRÍTICO importar las señales aquí sin bloques try/except silenciosos.
        """
        try:
            import pedidos.signals
            logger.info("Señales de Pedidos cargadas correctamente.")
            
        except ImportError as e:
            logger.critical(f"ERROR CRÍTICO: No se pudieron cargar las señales de Pedidos: {e}")
            raise e 
   
        try:
            import pedidos.tasks
        except ImportError:
            pass