"""
Django settings for deliber project.
Optimizado para Producción con Ngrok.
Solo cambia NGROK_URL en .env y todo se ajusta automáticamente.
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

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

# Parche de compatibilidad para Python 3.10+ y Django antiguo
try:
    def _fixed_basecontext_copy(self):
        duplicate = object.__new__(type(self))
        duplicate.__dict__ = self.__dict__.copy()
        duplicate.dicts = self.dicts[:] if hasattr(self, "dicts") else []
        return duplicate
    django_template_context.BaseContext.__copy__ = _fixed_basecontext_copy
except Exception:
    pass

# ==========================================
# 2. CONFIGURACIÓN CORE (AUTO-DETECCIÓN)
# ==========================================

SECRET_KEY = os.getenv("SECRET_KEY", "django-insecure-key-dev-mode")
DEBUG = os.getenv("DEBUG", "True").lower() in ("true", "1", "yes")

# Auto-detectar modo según variables configuradas
PRODUCTION_DOMAIN = os.getenv("PRODUCTION_DOMAIN", "")
NGROK_URL = os.getenv("NGROK_URL", "")
PRODUCTION_FRONTEND = os.getenv("PRODUCTION_FRONTEND", "")

# Prioridad: PRODUCTION_DOMAIN > NGROK_URL
if PRODUCTION_DOMAIN:
    # MODO PRODUCCIÓN
    BASE_URL = PRODUCTION_DOMAIN
    FRONTEND_URL = PRODUCTION_FRONTEND if PRODUCTION_FRONTEND else PRODUCTION_DOMAIN
    print("Modo: PRODUCCIÓN")
elif NGROK_URL:
    # MODO NGROK
    BASE_URL = NGROK_URL
    FRONTEND_URL = NGROK_URL
    print("Modo: NGROK")
else:
    # MODO DESARROLLO LOCAL
    BASE_URL = ""
    FRONTEND_URL = ""
    print("Modo: DESARROLLO LOCAL")

# ALLOWED_HOSTS dinámico
if BASE_URL:
    domain = BASE_URL.replace("https://", "").replace("http://", "")
    ALLOWED_HOSTS = [domain, "localhost", "127.0.0.1", "0.0.0.0", ".ngrok-free.app"]
    if FRONTEND_URL and FRONTEND_URL != BASE_URL:
        frontend_domain = FRONTEND_URL.replace("https://", "").replace("http://", "")
        ALLOWED_HOSTS.append(frontend_domain)
else:
    ALLOWED_HOSTS = ["*", ".ngrok-free.app"]

# ==========================================
# 3. CORS & CSRF (Configuración dinámica)
# ==========================================

if BASE_URL:
    # Configuración con dominio específico
    origins = [BASE_URL]
    if FRONTEND_URL and FRONTEND_URL != BASE_URL:
        origins.append(FRONTEND_URL)
    
    CORS_ALLOWED_ORIGINS = origins
    CORS_ALLOW_CREDENTIALS = True
    CSRF_TRUSTED_ORIGINS = origins
else:
    # Modo desarrollo: Permitir todo
    CORS_ALLOW_ALL_ORIGINS = True
    CORS_ALLOW_CREDENTIALS = True
    CSRF_TRUSTED_ORIGINS = [
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "https://*.ngrok-free.app",
    ]

# ==========================================
# 4. APLICACIONES INSTALADAS
# ==========================================

INSTALLED_APPS = [
    # Django Apps
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.sites",

    # Third Party Apps
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

    # Local Apps
    "authentication.apps.AuthenticationConfig",
    "usuarios.apps.UsuariosConfig",
    "proveedores.apps.ProveedoresConfig",
    "repartidores.apps.RepartidoresConfig",
    "productos.apps.ProductosConfig",
    "envios.apps.EnviosConfig",
    "pedidos.apps.PedidosConfig",
    "pagos.apps.PagosConfig",
    "rifas.apps.RifasConfig",
    "chat.apps.ChatConfig",
    "notificaciones.apps.NotificacionesConfig",
    "administradores.apps.AdministradoresConfig",
    "reportes.apps.ReportesConfig",
    "calificaciones.apps.CalificacionesConfig",
    "super_categorias.apps.SuperCategoriasConfig",
    "legal.apps.LegalConfig",
]

SITE_ID = 1

# ==========================================
# 5. MIDDLEWARE
# ==========================================

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "allauth.account.middleware.AccountMiddleware",
    "middleware.api_key_auth.ApiKeyAuthenticationMiddleware",
    "middleware.log_api_requests.LogAPIRequestsMiddleware",
]

ROOT_URLCONF = "settings.urls"
WSGI_APPLICATION = "settings.wsgi.application"

# ==========================================
# 6. BASE DE DATOS (PostgreSQL)
# ==========================================

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("POSTGRES_DB", "deliber_db"),
        "USER": os.getenv("POSTGRES_USER", "postgres"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD", "password"),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "5432"),
    }
}

# ==========================================
# 7. CACHÉ & REDIS
# ==========================================

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": REDIS_URL,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}

SESSION_ENGINE = "django.contrib.sessions.backends.cache"
SESSION_CACHE_ALIAS = "default"

# ==========================================
# 8. CELERY (Tareas Asíncronas)
# ==========================================

CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_TIMEZONE = "America/Guayaquil"
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"

# ==========================================
# 9. AUTENTICACIÓN & PASSWORD
# ==========================================

AUTH_USER_MODEL = "authentication.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
]

# AllAuth Config
ACCOUNT_LOGIN_METHODS = {'email'}
ACCOUNT_SIGNUP_FIELDS = ['email*', 'password1*', 'password2*']
ACCOUNT_UNIQUE_EMAIL = True
ACCOUNT_EMAIL_VERIFICATION = "optional"

# ==========================================
# 10. API REST FRAMEWORK & JWT
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
    ],
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
        "rest_framework.renderers.BrowsableAPIRenderer",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 50,
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(days=1),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "SIGNING_KEY": SECRET_KEY,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
}

# ==========================================
# 11. STATIC, MEDIA & TEMPLATES
# ==========================================

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = []  # Django collectstatic works correctly with this empty

# MEDIA configuración - siempre usar ruta relativa para que Django sirva archivos
# El frontend construye la URL completa con la base URL
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

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

# ==========================================
# 12. SERVICIOS EXTERNOS
# ==========================================

# Email
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = "smtp.gmail.com"
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
DEFAULT_FROM_EMAIL = EMAIL_HOST_USER

# Google Maps
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")

# ==========================================
# 13. CONFIGURACIÓN REGIONAL
# ==========================================

LANGUAGE_CODE = "es"
TIME_ZONE = "America/Guayaquil"
USE_I18N = True
USE_TZ = True
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
IVA_ECUADOR = 0.15

# ==========================================
# 14. SEGURIDAD
# ==========================================

SECURE_SSL_REDIRECT = False  # Ngrok maneja HTTPS externamente