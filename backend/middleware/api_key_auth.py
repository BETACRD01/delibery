# middleware/api_key_auth.py

import os
import logging
from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings

logger = logging.getLogger('api_logger')


class ApiKeyAuthenticationMiddleware(MiddlewareMixin):
    """
    Middleware de seguridad MEJORADO para validación flexible.
    
    LÓGICA:
    1. Rutas públicas → Pasan sin verificación
    2. Tiene API Key válida → Marca como 'client_type' y continúa
    3. Tiene JWT Bearer → Permite que DRF lo valide (no bloquea)
    4. Sin credenciales → Rechaza (403)
    
    Esto permite que los tests usen force_authenticate() sin API Key.
    """

    # Rutas que NO requieren ni API Key ni JWT
    PUBLIC_PREFIXES = (
        '/admin/',
        '/api/auth/login/',
        '/api/auth/registro/',
        '/api/auth/google-login/',
        '/api/auth/token/',
        '/api/auth/solicitar-codigo',
        '/api/auth/verificar-codigo',
        '/api/auth/reset-password',
        '/accounts/',
        '/static/',  
        '/media/',   
        '/health/',
        '/api/swagger',
        '/api/redoc',
        '/api/health/',
    )

    PUBLIC_EXACT_PATHS = {
        '/',
        '/favicon.ico',   
        '/robots.txt',    
        '/sitemap.xml',   
        '/api/',         
    }

    # Rutas que requieren autenticación (API Key O JWT) pero ambos son válidos
    PROTECTED_PREFIXES = (
        '/api/envios/',
        '/api/pedidos/',
        '/api/productos/',
        '/api/usuarios/',
    )

    def __init__(self, get_response):
        import sys

        super().__init__(get_response)
        
        self.api_key_map = {}
        
        key_web = os.getenv('API_KEY_WEB')
        key_mobile = os.getenv('API_KEY_MOBILE')
        
        if key_web:
            self.api_key_map[key_web] = 'web'
        if key_mobile:
            self.api_key_map[key_mobile] = 'mobile'
            
        if not self.api_key_map:
            logger.warning("No se han configurado API Keys en el entorno.")

        self.debug_mode = getattr(settings, 'DEBUG', False)
        self.testing_mode = 'test' in sys.argv or getattr(settings, 'TESTING', False)

    def process_request(self, request):
        # 0. BYPASS TOTAL en modo testing
        if self.testing_mode:
            request.client_type = 'testing'
            request.api_key_validated = False
            return None

        # 1. Bypass endpoints completamente públicos
        if request.path in self.PUBLIC_EXACT_PATHS or request.path.startswith(self.PUBLIC_PREFIXES):
            return None

        # 2. Extracción de Headers
        api_key = request.META.get('HTTP_X_API_KEY')
        auth_header = request.META.get('HTTP_AUTHORIZATION')

        # 3. ¿Tiene API Key válida? → Marcar y permitir
        if api_key:
            client_type = self.api_key_map.get(api_key)
            if client_type:
                request.client_type = client_type
                request.api_key_validated = True
                logger.debug(f"✓ API Key válida ({client_type}): {request.path}")
                return None
            else:
                # API Key presente pero inválida → RECHAZAR
                logger.warning(f"✗ API Key inválida en {request.path}")
                return self._error_response('API Key inválida')

        # 4. ¿Tiene JWT Bearer Token? → Permitir que DRF lo valide
        if auth_header and auth_header.startswith('Bearer '):
            request.client_type = 'jwt_authenticated'
            request.api_key_validated = False
            logger.debug(f"✓ JWT Token detectado: {request.path}")
            return None

        # 5. Modo DEBUG sin credenciales → Permitir (facilita desarrollo)
        if self.debug_mode:
            logger.debug(f"DEBUG MODE: Bypass en {request.path}")
            request.client_type = 'debug'
            request.api_key_validated = False
            return None

        # 6. RECHAZO FINAL: Sin API Key ni JWT en ruta protegida
        logger.warning(f"Acceso denegado: Sin credenciales en {request.path}")
        return self._error_response('Se requiere autenticación')

    def _error_response(self, reason='Credenciales inválidas'):
        return JsonResponse({
            'error': f'{reason}. Incluye X-API-Key o Authorization: Bearer <token>.',
            'status': 'forbidden',
            'code': 403
        }, status=403)


class ClientTypePermissionMiddleware(MiddlewareMixin):
    """
    Restricción de endpoints basada en el tipo de cliente.
    Solo aplica restricciones si se identificó por API Key.
    """

    ADMIN_ONLY_PREFIXES = (
        '/api/admin/',
        '/api/reportes/',
    )

    def process_request(self, request):
        # Si no pasó por validación previa, ignorar
        if not hasattr(request, 'client_type'):
            return None

        # En modo debug, testing o JWT → Ser permisivo
        if request.client_type in ('debug', 'testing', 'jwt_authenticated'):
            return None

        # Validar acceso a rutas administrativas
        if request.path.startswith(self.ADMIN_ONLY_PREFIXES):
            if request.client_type != 'web':
                logger.warning(f"Intento de acceso admin desde {request.client_type}: {request.path}")
                return JsonResponse({
                    'error': 'Acceso restringido a clientes administrativos.',
                    'status': 'forbidden',
                    'code': 403
                }, status=403)

        return None
