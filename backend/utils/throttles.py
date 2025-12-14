# utils/throttles.py
"""
Throttles personalizados que respetan DEBUG mode.
En desarrollo (DEBUG=True), los throttles se desactivan automáticamente.
"""

from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from django.conf import settings


class DebugBypassThrottleMixin:
    """Mixin que desactiva throttle cuando DEBUG=True"""
    
    def allow_request(self, request, view):
        if settings.DEBUG:
            return True
        return super().allow_request(request, view)


# ==========================================================
# THROTTLES BASE
# ==========================================================

class DebugBypassUserThrottle(DebugBypassThrottleMixin, UserRateThrottle):
    """UserRateThrottle que se desactiva en DEBUG"""
    pass


class DebugBypassAnonThrottle(DebugBypassThrottleMixin, AnonRateThrottle):
    """AnonRateThrottle que se desactiva en DEBUG"""
    pass


# ==========================================================
# THROTTLES PARA PEDIDOS
# ==========================================================

class PedidoThrottle(DebugBypassUserThrottle):
    """Límite para operaciones de pedidos"""
    rate = "60/hour"


# ==========================================================
# THROTTLES PARA REPARTIDORES
# ==========================================================

class PerfilThrottle(DebugBypassUserThrottle):
    """Límite para consultas de perfil"""
    rate = "120/hour"


class EstadoThrottle(DebugBypassUserThrottle):
    """Límite para cambios de estado"""
    rate = "60/hour"


class UbicacionThrottle(DebugBypassUserThrottle):
    """Límite para actualizaciones de ubicación"""
    rate = "300/hour"


class VehiculoThrottle(DebugBypassUserThrottle):
    """Límite para operaciones de vehículos"""
    rate = "30/hour"


class CalificacionThrottle(DebugBypassUserThrottle):
    """Límite para calificaciones"""
    rate = "20/hour"


class EditarPerfilThrottle(DebugBypassUserThrottle):
    """Límite para edición de perfil"""
    rate = "30/hour"


# ==========================================================
# THROTTLES PARA PROVEEDORES
# ==========================================================

class ProveedorThrottle(DebugBypassUserThrottle):
    """Límite para operaciones de proveedor"""
    rate = "120/hour"


# ==========================================================
# THROTTLES PARA USUARIOS / AUTH
# ==========================================================

class FCMThrottle(DebugBypassUserThrottle):
    """Límite para registro de tokens FCM"""
    rate = "50/hour"


class LoginThrottle(DebugBypassUserThrottle):
    """Límite para intentos de login"""
    rate = "10/minute"


class RegisterThrottle(DebugBypassAnonThrottle):
    """Límite para registro de usuarios"""
    rate = "5/hour"
    
# ==========================================================
# THROTTLES PARA USUARIOS
# ==========================================================

class UploadThrottle(DebugBypassUserThrottle):
    """Límite para subida de archivos"""
    rate = "50/hour"