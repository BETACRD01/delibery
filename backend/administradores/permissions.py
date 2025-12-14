# -*- coding: utf-8 -*-
# administradores/permissions.py
"""
Permisos personalizados para el módulo de administradores
Control de acceso granular por tipo de acción
Validación de permisos específicos del administrador
Protección contra acciones no autorizadas
"""

import logging
from rest_framework import permissions
from rest_framework.exceptions import PermissionDenied

logger = logging.getLogger("administradores")

# ============================================
# CLASE BASE DE PERMISOS (CORE LOGIC)
# ============================================

class BaseAdminPermission(permissions.BasePermission):
    """
    Clase base abstracta para validar permisos de administrador.
    Centraliza la lógica de autenticación, estado activo y validación de campos.
    """
    permission_field = None  # El campo booleano en el modelo PerfilAdmin
    message = "No tienes permiso para realizar esta acción."

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # 1. Superusuarios siempre tienen acceso
        if request.user.is_superuser:
            return True

        # 2. Verificar si es staff o tiene método específico (para compatibilidad legacy)
        is_legacy_admin = request.user.is_staff or (
            hasattr(request.user, 'es_administrador') and request.user.es_administrador()
        )
        if not is_legacy_admin:
            self._log_warning(request.user, "No es administrador ni staff")
            return False

        # 3. Obtener perfil de forma segura (sin try/except costosos)
        admin_profile = getattr(request.user, 'perfil_admin', None)

        if not admin_profile:
            self._log_warning(request.user, "No tiene perfil de administrador asociado")
            return False

        # 4. Verificar que el administrador esté activo
        if not admin_profile.activo:
            self._log_warning(request.user, "Cuenta de administrador inactiva")
            return False

        # 5. Si no se requiere un campo específico, es suficiente con ser admin activo
        if self.permission_field is None:
            return True

        # 6. Verificar el permiso específico
        has_perm = getattr(admin_profile, self.permission_field, False)
        
        if not has_perm:
            self._log_warning(request.user, f"Falta el permiso requerido: {self.permission_field}")
        
        return has_perm

    def _log_warning(self, user, reason):
        """Helper para logs consistentes sin emojis en runtime"""
        logger.warning(f"Acceso denegado a {user.email}: {reason}")


# ============================================
# PERMISOS ESPECÍFICOS (IMPLEMENTACIÓN)
# ============================================

class EsAdministrador(BaseAdminPermission):
    """Solo valida que sea un administrador activo."""
    message = "Solo los administradores pueden acceder a esta funcionalidad."
    # permission_field es None, por lo que solo usa la validación base.


class PuedeGestionarUsuarios(BaseAdminPermission):
    permission_field = 'puede_gestionar_usuarios'
    message = "No tienes permiso para gestionar usuarios."


class PuedeGestionarProveedores(BaseAdminPermission):
    permission_field = 'puede_gestionar_proveedores'
    message = "No tienes permiso para gestionar proveedores."


class PuedeGestionarRepartidores(BaseAdminPermission):
    permission_field = 'puede_gestionar_repartidores'
    message = "No tienes permiso para gestionar repartidores."


class PuedeGestionarPedidos(BaseAdminPermission):
    permission_field = 'puede_gestionar_pedidos'
    message = "No tienes permiso para gestionar pedidos."


class PuedeGestionarRifas(BaseAdminPermission):
    permission_field = 'puede_gestionar_rifas'
    message = "No tienes permiso para gestionar rifas."


class PuedeVerReportes(BaseAdminPermission):
    permission_field = 'puede_ver_reportes'
    message = "No tienes permiso para ver reportes."


class PuedeGestionarSolicitudes(BaseAdminPermission):
    permission_field = 'puede_gestionar_solicitudes'
    message = "No tienes permiso para gestionar solicitudes de cambio de rol."


class PuedeConfigurarSistema(BaseAdminPermission):
    permission_field = 'puede_configurar_sistema'
    message = "Solo los super administradores o encargados pueden configurar el sistema."


# ============================================
# PERMISOS UTILITARIOS / ESPECIALES
# ============================================

class SoloLecturaAdmin(permissions.BasePermission):
    """
    Permite solo operaciones de lectura (GET, HEAD, OPTIONS).
    """
    message = "Solo tienes permisos de lectura."

    def has_permission(self, request, view):
        return request.method in permissions.SAFE_METHODS


class AdministradorActivo(BaseAdminPermission):
    """
    Alias explícito para verificar solo estado activo.
    """
    message = "Tu cuenta de administrador está inactiva."


# ============================================
# PERMISOS DINÁMICOS (VISTAS GENÉRICAS)
# ============================================

class PermisoDinamico(BaseAdminPermission):
    """
    Permiso configurado dinámicamente desde la vista.
    Requiere 'permiso_requerido' en la View Class.
    """
    def has_permission(self, request, view):
        # Inyectamos el campo requerido dinámicamente antes de llamar al padre
        self.permission_field = getattr(view, "permiso_requerido", None)
        
        if not self.permission_field:
            logger.error("View no especifica 'permiso_requerido'")
            return False
            
        return super().has_permission(request, view)


class RequiereMultiplesPermisos(BaseAdminPermission):
    """
    Requiere TODOS los permisos especificados en 'permisos_requeridos'.
    """
    def has_permission(self, request, view):
        # Primero validamos base (auth, superuser, activo)
        if not super().has_permission(request, view):
            return False
            
        # Si es superusuario, super().has_permission ya retornó True, 
        # pero necesitamos re-verificar para la lógica de lista específica si no es superuser
        if request.user.is_superuser:
            return True

        permisos = getattr(view, "permisos_requeridos", [])
        admin_profile = request.user.perfil_admin # Ya validado en super()

        for permiso in permisos:
            if not getattr(admin_profile, permiso, False):
                logger.warning(f"Acceso denegado {request.user.email}: Falta permiso '{permiso}'")
                return False
        return True


class RequiereCualquierPermiso(BaseAdminPermission):
    """
    Requiere AL MENOS UNO de los permisos en 'permisos_opcionales'.
    """
    def has_permission(self, request, view):
        # Validación base
        if not request.user or not request.user.is_authenticated:
            return False
        
        if request.user.is_superuser:
            return True
            
        admin_profile = getattr(request.user, 'perfil_admin', None)
        if not admin_profile or not admin_profile.activo:
            return False

        permisos = getattr(view, "permisos_opcionales", [])
        
        # Si no hay lista, se asume cerrado por seguridad
        if not permisos: 
            return False

        # Verificar si tiene alguno
        if any(getattr(admin_profile, p, False) for p in permisos):
            return True

        logger.warning(f"Acceso denegado {request.user.email}: No tiene ninguno de los permisos requeridos")
        return False


# ============================================
# VALIDADORES Y HELPERS
# ============================================

def validar_no_es_superusuario(usuario_objetivo):
    """
    Impide modificar superusuarios.
    """
    if usuario_objetivo.is_superuser:
        logger.warning(f"Intento de modificar superusuario: {usuario_objetivo.email}")
        raise PermissionDenied("No se puede modificar un superusuario desde esta interfaz.")


def validar_no_auto_modificacion_critica(usuario_actual, usuario_objetivo, accion):
    """
    Impide que un admin se bloquee a sí mismo.
    """
    if usuario_actual.id == usuario_objetivo.id:
        acciones_criticas = {"desactivar", "cambiar_rol", "eliminar"} # Set para búsqueda O(1)

        if accion in acciones_criticas:
            logger.warning(f"Administrador intentó {accion} su propia cuenta: {usuario_actual.email}")
            raise PermissionDenied(f"No puedes {accion} tu propia cuenta. Contacta a otro administrador.")


def obtener_perfil_admin(user):
    """Retorna el perfil o None de forma segura."""
    return getattr(user, 'perfil_admin', None)


def tiene_permiso_especifico(user, permiso):
    """Helper booleano para uso fuera de DRF Views (ej. templates o lógica interna)."""
    if not user or not user.is_authenticated:
        return False
    if user.is_superuser:
        return True
        
    admin = obtener_perfil_admin(user)
    if not admin or not admin.activo:
        return False
        
    return getattr(admin, permiso, False)


def requiere_permiso(permiso):
    """Decorator para vistas basadas en funciones (FBV)."""
    def decorator(func):
        def wrapper(request, *args, **kwargs):
            if not tiene_permiso_especifico(request.user, permiso):
                logger.warning(f"Permiso denegado (decorator): {request.user.email} falta '{permiso}'")
                raise PermissionDenied("No tienes permiso para realizar esta acción.")
            return func(request, *args, **kwargs)
        return wrapper
    return decorator