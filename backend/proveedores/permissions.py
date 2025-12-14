# -*- coding: utf-8 -*-
# proveedores/permissions.py
"""
Permisos personalizados para gestión de proveedores y repartidores
"""

from rest_framework.permissions import BasePermission
from authentication.models import User
import logging

logger = logging.getLogger('proveedores')


class EsAdministrador(BasePermission):
    """
    Verifica que el usuario sea administrador
    """
    message = 'Solo los administradores pueden acceder a este recurso'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        return request.user.rol_activo == User.RolChoices.ADMIN


class AdministradorActivo(BasePermission):
    """
    Verifica que el administrador esté activo
    """
    message = 'Tu cuenta de administrador está inactiva'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # El usuario debe estar activo
        if not request.user.is_active:
            return False

        # Si es admin, debe estar activo
        if request.user.rol_activo == User.RolChoices.ADMIN:
            return request.user.is_active and not request.user.cuenta_desactivada

        return True


class PuedeGestionarProveedores(BasePermission):
    """
    Verifica permisos específicos para gestionar proveedores
    """
    message = 'No tienes permiso para gestionar proveedores'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # Solo administradores pueden gestionar proveedores
        return request.user.rol_activo == User.RolChoices.ADMIN


class PuedeGestionarRepartidores(BasePermission):
    """
    Verifica permisos específicos para gestionar repartidores
    """
    message = 'No tienes permiso para gestionar repartidores'

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False

        # Solo administradores pueden gestionar repartidores
        return request.user.rol_activo == User.RolChoices.ADMIN


def obtener_perfil_admin(usuario):
    """
    Obtiene el perfil de administrador del usuario

    Args:
        usuario: Usuario (User model)

    Returns:
        AdministradorProfile o None si no existe
    """
    if not usuario or not usuario.is_authenticated:
        return None

    if usuario.rol_activo != User.RolChoices.ADMIN:
        return None
    
    try:
        # Si existe un perfil de administrador, retornarlo
        # Si no, crear uno simple
        if hasattr(usuario, 'administrador'):
            return usuario.administrador
        
        # Retornar el usuario como perfil admin básico
        return usuario
    except Exception as e:
        logger.error(f"Error obteniendo perfil admin para {usuario.email}: {e}")
        return None