"""
Django settings for deliber project.
Optimized for Production & Ngrok Tunneling.
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

# Carga el archivo .env
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
# 2. CONFIGURACIÓN CORE (NGROK READY)
# ==========================================

SECRET_KEY = os.getenv("SECRET_KEY", "django-insecure-key-dev-mode")

# DEBUG: Mantenlo en True mientras pruebas con la App Móvil para ver errores
DEBUG = os.getenv("DEBUG", "True").lower() in ("true", "1", "yes")

# IMPORTANTE: El '*' permite que Ngrok funcione sin configurar dominios manuales
ALLOWED_HOSTS = ["*"]

# ==========================================
# 3. CORS & CSRF (CRÍTICO PARA MÓVIL)
# ==========================================

# Permite que la App Flutter haga peticiones desde cualquier origen
CORS_ALLOW_ALL_ORIGINS = True 
CORS_ALLOW_CREDENTIALS = True

# Permite peticiones POST/PUT desde Ngrok y Localhost
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

    # Local Apps (Tu Lógica de Negocio)
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

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/1")

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
    # Comentado para facilitar pruebas con passwords sencillos (123456)
    # {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    # {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# AllAuth Config (Updated for django-allauth 0.63+)
ACCOUNT_LOGIN_METHODS = {'email'}  # Replaces ACCOUNT_AUTHENTICATION_METHOD
ACCOUNT_SIGNUP_FIELDS = ['email*', 'password1*', 'password2*']  # Replaces EMAIL_REQUIRED and USERNAME_REQUIRED
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
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
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
# 12. SERVICIOS EXTERNOS & LOCALES
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

# Configuración Regional
LANGUAGE_CODE = "es"
TIME_ZONE = "America/Guayaquil"
USE_I18N = True
USE_TZ = True
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
IVA_ECUADOR = 0.15

# ==========================================
# 13. SEGURIDAD ADICIONAL
# ==========================================

# Desactivamos redirección SSL interna porque Ngrok ya maneja HTTPS por fuera
SECURE_SSL_REDIRECT = False