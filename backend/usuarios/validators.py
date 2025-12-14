# -*- coding: utf-8 -*-
# usuarios/validators.py

import logging
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

logger = logging.getLogger('usuarios')


class ValidadorSolicitudCambioRol:
    """
    Servicio de validación centralizado para cambios de rol.
    Evita lógica de negocio duplicada en vistas y serializers.
    """
    
    # Configuración (Set para búsqueda O(1))
    ROLES_PERMITIDOS = {'PROVEEDOR', 'REPARTIDOR'}
    LONGITUD_MOTIVO = (10, 500)  # (Min, Max)
    
    @classmethod
    def validar_usuario_puede_solicitar(cls, usuario):
        """
        Verifica elegibilidad del usuario para nueva solicitud.
        Revisa estado activo y solicitudes concurrentes.
        """
        # 1. Validar estado de cuenta
        if not usuario.is_active:
            logger.warning(f"Solicitud rechazada - Usuario inactivo: {usuario.email}")
            raise ValidationError({
                'usuario': _('Tu cuenta debe estar activa para solicitar cambios de rol.')
            })
        
        # 2. Validar concurrencia (evitar spam de solicitudes)
        from .models import SolicitudCambioRol
        
        # Optimización: .exists() es más eficiente que count() > 0 en SQL
        tiene_pendiente = SolicitudCambioRol.objects.filter(
            user=usuario,
            estado='PENDIENTE'
        ).exists()
        
        if tiene_pendiente:
            logger.info(f"Solicitud rechazada - Pendiente existente: {usuario.email}")
            raise ValidationError({
                'usuario': _('Ya tienes una solicitud pendiente en proceso.')
            })
    
    @classmethod
    def validar_rol_solicitado(cls, usuario, rol_solicitado):
        """
        Verifica validez del rol y si el usuario ya lo posee.
        """
        # 1. Validar existencia del rol en sistema
        if rol_solicitado not in cls.ROLES_PERMITIDOS:
            logger.error(f"Intento de rol no permitido: {rol_solicitado} por {usuario.email}")
            raise ValidationError({
                'rol_solicitado': _(f'Rol no válido. Permitidos: {", ".join(cls.ROLES_PERMITIDOS)}')
            })
        
        # 2. Validar redundancia
        if usuario.tiene_rol(rol_solicitado):
            logger.info(f"Solicitud redundante: {usuario.email} ya es {rol_solicitado}")
            raise ValidationError({
                'rol_solicitado': _(f'Ya tienes asignado el rol de {rol_solicitado}.')
            })
    
    @classmethod
    def validar_motivo(cls, motivo):
        """
        Valida longitud y contenido del motivo.
        """
        if not motivo or not str(motivo).strip():
            raise ValidationError({'motivo': _('El motivo es obligatorio.')})
        
        motivo_limpio = str(motivo).strip()
        longitud = len(motivo_limpio)
        min_len, max_len = cls.LONGITUD_MOTIVO
        
        if longitud < min_len:
            raise ValidationError({
                'motivo': _(f'El motivo es muy corto (mínimo {min_len} caracteres).')
            })
        
        if longitud > max_len:
            raise ValidationError({
                'motivo': _(f'El motivo excede el límite de {max_len} caracteres.')
            })
    
    @classmethod
    def validar_solicitud_completa(cls, usuario, rol_solicitado, motivo):
        """
        Fachada para ejecutar todas las validaciones secuencialmente.
        Utilizado por views y serializers antes de crear el objeto.
        """
        cls.validar_usuario_puede_solicitar(usuario)
        cls.validar_rol_solicitado(usuario, rol_solicitado)
        cls.validar_motivo(motivo)
        
        logger.info(f"Validacion exitosa para solicitud: {usuario.email} -> {rol_solicitado}")