"""
Django settings for deliber project.
Optimized for performance, scalability, and automatic network detection.
"""

import os
import sys
import logging
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv
from django.template import context as django_template_context
# ==========================================
# 1. INICIALIZACIÓN Y ENTORNO
# ==========================================

# Cargar variables de entorno
load_dotenv()

# Rutas base
BASE_DIR = Path(__file__).resolve().parent.parent

# Configuración de Logging para Settings
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('settings')

try:
    def _fixed_basecontext_copy(self):
        duplicate = object.__new__(type(self))
        duplicate.__dict__ = self.__dict__.copy()
        duplicate.dicts = self.dicts[:] if hasattr(self, "dicts") else []
        return duplicate

    django_template_context.BaseContext.__copy__ = _fixed_basecontext_copy
except Exception:
    logger.warning("No se aplicó el parche de compatibilidad BaseContext.__copy__ (django.template.context)", exc_info=True)

# Flag de entorno de pruebas
TESTING = "test" in sys.argv

# Detección de Red (Resilience Pattern)
try:
    from utils.network_detector import NetworkDetector, obtener_config_red
    NETWORK_DETECTION_ENABLED = True
    CONFIG_RED = obtener_config_red()
except ImportError:
    NETWORK_DETECTION_ENABLED = False
    CONFIG_RED = None
    logger.warning("Modulo network_detector no disponible. Usando configuración estática.")

# Helpers de Configuración
def get_env_bool(key: str, default: bool = False) -> bool:
    return os.getenv(key, str(default)).lower() in ("true", "1", "yes")

def get_env_list(key: str, default: str = "") -> list:
    value = os.getenv(key, default)
    return [item.strip() for item in value.split(",") if item.strip()]

def validate_required_env(*keys):
    missing = [key for key in keys if not os.getenv(key)]
    if missing:
        raise EnvironmentError(f"Faltan variables de entorno críticas: {', '.join(missing)}")

# ==========================================
# 2. CONFIGURACIÓN CORE
# ==========================================

# Validación de seguridad (se omite en modo testing)
if not TESTING:
    validate_required_env("SECRET_KEY", "POSTGRES_DB", "POSTGRES_USER", "POSTGRES_PASSWORD", "GOOGLE_MAPS_API_KEY") # <-- Validación de clave de Google Maps

SECRET_KEY = os.getenv("SECRET_KEY", "test-secret-key" if TESTING else None)
DEBUG = get_env_bool("DEBUG", True)
SITE_ID = 1

# Configuración Dinámica de Hosts y CORS
ALLOWED_HOSTS = get_env_list("ALLOWED_HOSTS", "localhost,127.0.0.1")
CORS_ALLOWED_ORIGINS = get_env_list("CORS_ALLOWED_ORIGINS", "http://localhost:8000,http://localhost:5173")
CSRF_TRUSTED_ORIGINS = get_env_list("CSRF_TRUSTED_ORIGINS", "http://localhost:8000")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:8000")

if NETWORK_DETECTION_ENABLED and CONFIG_RED:
    # Hosts
    dynamic_hosts = NetworkDetector.obtener_allowed_hosts(CONFIG_RED)
    ALLOWED_HOSTS = list(set(ALLOWED_HOSTS + dynamic_hosts))
    
    # CORS & CSRF
    dynamic_origins = NetworkDetector.obtener_cors_origins(
        CONFIG_RED, puerto=int(os.getenv("BACKEND_PORT", 8000))
    )
    if not DEBUG:
        CORS_ALLOWED_ORIGINS = dynamic_origins
        CSRF_TRUSTED_ORIGINS = dynamic_origins
    else:
        # En debug mezclamos estáticos y dinámicos
        CORS_ALLOWED_ORIGINS = list(set(CORS_ALLOWED_ORIGINS + dynamic_origins))
        CSRF_TRUSTED_ORIGINS = list(set(CSRF_TRUSTED_ORIGINS + dynamic_origins))
        
    # Frontend
    FRONTEND_URL = NetworkDetector.obtener_frontend_url(
        CONFIG_RED, puerto=int(os.getenv("BACKEND_PORT", 8000))
    )

# Añadir comodines seguros
ALLOWED_HOSTS.extend(["0.0.0.0", "10.0.2.2", "backend"])
if "*" not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append("*")

# ==========================================
# 3. APLICACIONES INSTALADAS
# ==========================================

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.sites",
    # "django.contrib.gis",  # <-- Desactivado temporalmente (requiere GDAL instalado)
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    "allauth",
    "allauth.account",
    "allauth.socialaccount",
    "allauth.socialaccount.providers.google",
    "django_celery_beat",
    "django_celery_results",
    "django_redis",
    "django_filters",
    "drf_yasg",
]

LOCAL_APPS = [
    "authentication.apps.AuthenticationConfig",
    "usuarios.apps.UsuariosConfig",
    "proveedores.apps.ProveedoresConfig",
    "repartidores.apps.RepartidoresConfig",
    "productos.apps.ProductosConfig",
    "envios.apps.EnviosConfig", # <-- Aplicación de envíos
    "pedidos.apps.PedidosConfig",
    "pagos.apps.PagosConfig",
    "rifas.apps.RifasConfig",
    "chat.apps.ChatConfig",
    "notificaciones.apps.NotificacionesConfig",
    "administradores.apps.AdministradoresConfig",
    "reportes.apps.ReportesConfig",
    "calificaciones.apps.CalificacionesConfig",
    "super_categorias.apps.SuperCategoriasConfig",  # <-- Aplicación Super
]
INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# ==========================================
# 4. MIDDLEWARE & URLS
# ==========================================

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "middleware.api_key_auth.ApiKeyAuthenticationMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "allauth.account.middleware.AccountMiddleware",
    "middleware.log_api_requests.LogAPIRequestsMiddleware",
]

ROOT_URLCONF = "settings.urls"
WSGI_APPLICATION = "settings.wsgi.application"

# ==========================================
# 5. BASE DE DATOS & CACHÉ
# ==========================================

def _get_conn_max_age():
    try:
        return int(os.getenv("DB_CONN_MAX_AGE", "0"))
    except ValueError:
        return 0

DATABASES = {
    "default": {
        # Si usas PostGIS, cambia el motor: 'django.contrib.gis.db.backends.postgis'
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("POSTGRES_DB"),
        "USER": os.getenv("POSTGRES_USER"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD"),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "5432"),
        "CONN_MAX_AGE": _get_conn_max_age(),
        "OPTIONS": {"connect_timeout": 10},
    }
}

# Redis / Cache distribuida
USE_REDIS_CACHE = get_env_bool("USE_REDIS_CACHE", not DEBUG)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/1")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")

if USE_REDIS_CACHE:
    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": REDIS_URL,
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
                "PASSWORD": REDIS_PASSWORD,
                "SOCKET_CONNECT_TIMEOUT": 5,
                "SOCKET_TIMEOUT": 5,
                "RETRY_ON_TIMEOUT": True,
                "CONNECTION_POOL_KWARGS": {"max_connections": 50},
            },
            "KEY_PREFIX": "deliber",
            "TIMEOUT": 300,
        }
    }
else:
    logger.warning("Redis deshabilitado. Usando cache en memoria local para desarrollo.")
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "deliber-localcache",
            "TIMEOUT": 300,
        }
    }

# Simplificar configuración en modo pruebas
if TESTING:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.test.sqlite3",
        }
    }
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        }
    }

if USE_REDIS_CACHE:
    SESSION_ENGINE = "django.contrib.sessions.backends.cache"
    SESSION_CACHE_ALIAS = "default"
else:
    SESSION_ENGINE = "django.contrib.sessions.backends.db"

# ==========================================
# 6. CELERY (TAREAS ASÍNCRONAS)
# ==========================================

default_broker = REDIS_URL if USE_REDIS_CACHE else "memory://"
default_result_backend = REDIS_URL if USE_REDIS_CACHE else "cache+memory://"
CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", default_broker)
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", default_result_backend)
CELERY_TIMEZONE = "America/Guayaquil"
CELERY_ENABLE_UTC = True
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"

# Optimización Celery
CELERY_WORKER_PREFETCH_MULTIPLIER = 4
CELERY_TASK_ACKS_LATE = True
CELERY_TASK_REJECT_ON_WORKER_LOST = True
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True

# ==========================================
# 7. AUTENTICACIÓN & SEGURIDAD
# ==========================================

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
    "allauth.account.auth_backends.AuthenticationBackend",
]

AUTH_USER_MODEL = "authentication.User"

# ==========================================
# AllAuth - CONFIGURACIÓN ACTUALIZADA (v0.63+)
# ==========================================

# Método de autenticación: Solo email (sin username)
ACCOUNT_LOGIN_METHODS = {'email'}

# Campos requeridos en el formulario de registro
# Sintaxis: 'campo*' = requerido, 'campo' = opcional
ACCOUNT_SIGNUP_FIELDS = [
    'email*',       # Email obligatorio
    'password1*',   # Contraseña obligatoria
    'password2*',   # Confirmación obligatoria
    'first_name*',  # Nombre obligatorio
    'last_name*',   # Apellido obligatorio
]

# Configuraciones adicionales
ACCOUNT_EMAIL_VERIFICATION = "optional"  # Verificación de email opcional
ACCOUNT_UNIQUE_EMAIL = True              # Email debe ser único
SOCIALACCOUNT_AUTO_SIGNUP = True         # Auto-registro con redes sociales

# Seguridad Producción
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = "DENY"
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_PRELOAD = True

# Rate Limiting
RATE_LIMIT_CONFIG = {
    # Cambia el 10 por 100 o 1000 mientras desarrollas
    "LOGIN_ATTEMPTS": 100 if DEBUG else 5, 
    "LOGIN_WINDOW": 60,
    "BURST_REQUESTS": 50 if DEBUG else 10,
    "BURST_WINDOW": 10,
}
# ==========================================
# 8. REST FRAMEWORK & JWT
# ==========================================

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_FILTER_BACKENDS": [
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ],
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PARSER_CLASSES": [
        "rest_framework.parsers.JSONParser",
        "rest_framework.parsers.MultiPartParser",
        "rest_framework.parsers.FormParser",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 100,
    "DEFAULT_THROTTLE_CLASSES": [] if DEBUG else [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "user": "5000/hour",
        "anon": "100/hour",
        "login": "10/minute",
        "register": "5/hour",
        "upload": "50/hour",
        "fcm": "50/hour",
    }
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=24) if DEBUG else timedelta(hours=2),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
    "ALGORITHM": "HS256",
    "SIGNING_KEY": SECRET_KEY,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
}

# ==========================================
# 9. EXTERNAL SERVICES & ASSETS
# ==========================================

# Email
EMAIL_BACKEND = os.getenv("EMAIL_BACKEND", "django.core.mail.backends.smtp.EmailBackend")
EMAIL_HOST = os.getenv("EMAIL_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", 587))
EMAIL_USE_TLS = get_env_bool("EMAIL_USE_TLS", True)
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL", EMAIL_HOST_USER)

# Static & Media
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")
Path(MEDIA_ROOT).mkdir(parents=True, exist_ok=True)

# Templates
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# Firebase Configuration Path
FIREBASE_CREDENTIALS_PATH = BASE_DIR / "firebase-credentials.json"

# API Keys
API_KEY_WEB = os.getenv("API_KEY_WEB", "")
API_KEY_MOBILE = os.getenv("API_KEY_MOBILE", "")

# CONFIGURACIÓN DE ENVÍOS Y TARIFAS 
# --- Clave de Google Maps (Requerida para calcular distancia en envios/services.py)
# Se obtiene del .env
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", None)

# --- Impuesto de Negocio Local (IVA de Ecuador)
IVA_ECUADOR = 0.12 # <-- Constante para el cálculo del 12%

# Logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {"format": "{levelname} {asctime} {message}", "style": "{"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "verbose", "level": "INFO"},
    },
    "loggers": {
        "django": {"handlers": ["console"], "level": "INFO", "propagate": False},
        "api_logger": {"handlers": ["console"], "level": "DEBUG" if DEBUG else "INFO"},
        "rifas": {"handlers": ["console"], "level": "DEBUG" if DEBUG else "INFO", "propagate": False},
    },
}

# Internationalization
LANGUAGE_CODE = "es"
TIME_ZONE = "America/Guayaquil"
USE_I18N = True
USE_TZ = True
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# ==========================================
# 10. RESUMEN DE ARRANQUE
# ==========================================

if "runserver" in sys.argv or "run_gunicorn" in sys.argv:
    print("-" * 60)
    print("DELIBER BACKEND - CONFIGURACIÓN CARGADA")
    print("-" * 60)
    print(f"Modo:           {'DEBUG' if DEBUG else 'PRODUCCIÓN'}")
    print(f"Base de Datos:  {DATABASES['default']['HOST']}")
    print(f"Red Detectada:  {CONFIG_RED.get('nombre', 'Estática') if CONFIG_RED else 'Estática'}")
    print(f"Frontend URL:   {FRONTEND_URL}")
    print(f"Firebase Creds: {'Presente' if FIREBASE_CREDENTIALS_PATH.exists() else 'Faltante'}")
    print(f"Google Maps Key: {'Cargada' if GOOGLE_MAPS_API_KEY else '¡FALTANTE! La tarificación fallará.'}")
    print("-" * 60)
