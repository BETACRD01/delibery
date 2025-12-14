import logging
import time
import json
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger('api_logger')

class LogAPIRequestsMiddleware(MiddlewareMixin):
    """
    Middleware para logging estructurado de peticiones HTTP.
    Optimizado para producción.
    """

    async_mode = False  # Django 5.1+

    def __init__(self, get_response):
        self.get_response = get_response
        
        self.log_body = getattr(settings, 'API_LOG_BODY', False)
        self.body_max_length = getattr(settings, 'API_LOG_BODY_MAX_LENGTH', 1000)
        self.colorize = getattr(settings, 'API_LOG_COLORIZE', settings.DEBUG)
        
        self.ignored_paths = tuple(getattr(settings, 'API_LOG_IGNORED_PATHS', [
            '/admin', '/static', '/media', '/favicon.ico', '/__debug__', '/health'
        ]))

        self.sensitive_fields = {
            'password', 'token', 'secret', 'api_key', 'credit_card',
            'access', 'refresh'
        }

    def process_request(self, request):
        if request.path.startswith(self.ignored_paths):
            return None

        request.start_time = time.time()

        return None

    def process_response(self, request, response):
        if not hasattr(request, 'start_time'):
            return response

        duration = time.time() - request.start_time

        # ✔ Ahora sí: usuario ya autenticado por DRF
        user = "Anonymous"
        if hasattr(request, "user") and request.user and request.user.is_authenticated:
            user = getattr(request.user, "email", None) or request.user.username

        ip = self._get_client_ip(request)

        status_code = response.status_code
        duration_ms = duration * 1000
        
        size_info = "Streaming" if getattr(response, "streaming", False) else self._format_size(len(response.content))

        log_msg = f"REQ+RES {request.method} {request.path} | User: {user} | IP: {ip} | {status_code} | {duration_ms:.2f}ms | {size_info}"

        if status_code >= 500:
            logger.error(log_msg)
        elif status_code >= 400:
            logger.warning(log_msg)
        else:
            logger.info(log_msg)

        return response

    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('HTTP_X_REAL_IP') or request.META.get('REMOTE_ADDR', 'unknown')

    def _format_size(self, size_bytes):
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.2f} TB"
