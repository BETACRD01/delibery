# -*- coding: utf-8 -*-
# backend/usuarios/solicitudes.py

import logging
import random
from django.db import transaction
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.apps import apps
from django.conf import settings
from django.db.models import Q
from django.db import IntegrityError

from .models import SolicitudCambioRol

logger = logging.getLogger("usuarios")

# ============================================
# VALIDADOR DE SOLICITUDES
# ============================================

class ValidadorSolicitudCambioRol:

    ROLES_VALIDOS = {"PROVEEDOR", "REPARTIDOR"}
    DIAS_ESPERA_RECHAZO = 30

    @classmethod
    def validar_usuario_puede_solicitar(cls, usuario):
        if not usuario:
            raise ValidationError("Usuario no encontrado.")
        
        # Validaciones básicas de cuenta
        if getattr(usuario, 'cuenta_desactivada', False):
            raise ValidationError({"usuario": "La cuenta está desactivada."})
        if not usuario.is_active:
            raise ValidationError({"usuario": "La cuenta está deshabilitada por administración."})
        if not usuario.email:
            raise ValidationError({"usuario": "El perfil debe tener un email registrado."})
        
        # Validar celular (es crítico para contactar)
        celular = getattr(usuario, 'celular', None)
        if not celular:
            raise ValidationError({"usuario": "El perfil debe tener un número de celular."})
        
        return True

    @classmethod
    def validar_rol_solicitado(cls, usuario, rol_solicitado):
        if rol_solicitado not in cls.ROLES_VALIDOS:
            raise ValidationError({"rol_solicitado": f"Rol inválido. Permitidos: {', '.join(cls.ROLES_VALIDOS)}"})

        # Verificar si ya tiene el rol
        rol_actual = getattr(usuario, 'rol', '')
        if rol_actual == rol_solicitado:
             raise ValidationError({"rol_solicitado": f"El usuario ya posee el rol {rol_solicitado}."})
        
        if rol_solicitado == "PROVEEDOR" and hasattr(usuario, "proveedor"):
             raise ValidationError({"rol_solicitado": "El usuario ya es Proveedor."})
        if rol_solicitado == "REPARTIDOR" and hasattr(usuario, "repartidor"):
             raise ValidationError({"rol_solicitado": "El usuario ya es Repartidor."})

        # Verificar si ya tiene una solicitud pendiente (del mismo usuario)
        if SolicitudCambioRol.objects.filter(user=usuario, rol_solicitado=rol_solicitado, estado="PENDIENTE").exists():
            raise ValidationError({"rol_solicitado": f"Ya tienes una solicitud pendiente para ser {rol_solicitado}."})

        # Verificar tiempo de espera tras rechazo
        ultimo_rechazo = SolicitudCambioRol.objects.filter(
            user=usuario, rol_solicitado=rol_solicitado, estado="RECHAZADA"
        ).order_by("-respondido_en").first()

        if ultimo_rechazo and ultimo_rechazo.respondido_en:
            tiempo_transcurrido = timezone.now() - ultimo_rechazo.respondido_en
            if tiempo_transcurrido.days < cls.DIAS_ESPERA_RECHAZO:
                dias_restantes = cls.DIAS_ESPERA_RECHAZO - tiempo_transcurrido.days
                raise ValidationError({"rol_solicitado": f"Solicitud rechazada recientemente. Espere {dias_restantes} días."})

        return True

    @staticmethod
    def validar_motivo(motivo):
        if not motivo or not str(motivo).strip():
            raise ValidationError({"motivo": "El motivo es obligatorio."})

        motivo = str(motivo).strip()
        if len(motivo) < 10:
            raise ValidationError({"motivo": "El motivo debe tener al menos 10 caracteres."})
        if len(motivo) > 500:
            raise ValidationError({"motivo": "El motivo no puede exceder 500 caracteres."})
        return True


# ============================================
# GESTOR DE SOLICITUDES (LÓGICA PRINCIPAL)
# ============================================

class GestorSolicitudCambioRol:

    @staticmethod
    @transaction.atomic
    def crear_solicitud(usuario, rol_solicitado, motivo, **datos_adicionales):
        """
        Crea una nueva solicitud de cambio de rol.
        INCLUYE: Validación estricta de duplicados (Activos y Pendientes).
        """
        logger.info(f"Iniciando solicitud de rol: {usuario.email} -> {rol_solicitado}")

        # 1. Validaciones básicas de usuario y motivo
        ValidadorSolicitudCambioRol.validar_usuario_puede_solicitar(usuario)
        ValidadorSolicitudCambioRol.validar_rol_solicitado(usuario, rol_solicitado)
        ValidadorSolicitudCambioRol.validar_motivo(motivo)

        # ==============================================================================
        # 🔥 BLOQUE DE SEGURIDAD: VALIDACIÓN DE DUPLICADOS EN TODO EL SISTEMA
        # ==============================================================================
        
        if rol_solicitado == "REPARTIDOR":
            cedula = datos_adicionales.get('cedula_identidad')
            
            if cedula:
                # Importación local para evitar ciclos
                from repartidores.models import Repartidor
                
                # A. Verificar colisión con Repartidores ACTIVOS (que no sea yo mismo)
                if Repartidor.objects.filter(cedula=cedula).exclude(user=usuario).exists():
                    raise ValidationError({"cedula_identidad": f"Esta cédula ya pertenece a un repartidor activo."})

                # B. Verificar colisión con OTRAS solicitudes PENDIENTES (que no sea yo mismo)
                if SolicitudCambioRol.objects.filter(
                    cedula_identidad=cedula, 
                    estado='PENDIENTE'
                ).exclude(user=usuario).exists():
                    raise ValidationError({"cedula_identidad": f"Ya existe una solicitud en espera con esta cédula."})

        elif rol_solicitado == "PROVEEDOR":
            ruc = datos_adicionales.get('ruc')
            
            if ruc:
                from proveedores.models import Proveedor
                
                # A. Verificar colisión con Proveedores ACTIVOS
                if Proveedor.objects.filter(ruc=ruc).exclude(user=usuario).exists():
                     raise ValidationError({"ruc": f"Este RUC ya pertenece a un proveedor activo."})

                # B. Verificar colisión con OTRAS solicitudes PENDIENTES
                if SolicitudCambioRol.objects.filter(
                    ruc=ruc, 
                    estado='PENDIENTE'
                ).exclude(user=usuario).exists():
                     raise ValidationError({"ruc": f"Ya existe una solicitud en espera con este RUC."})
        
        # ==============================================================================

        # 2. Crear la solicitud si pasó todas las validaciones
        solicitud = SolicitudCambioRol.objects.create(
            user=usuario,
            rol_solicitado=rol_solicitado,
            motivo=motivo.strip(),
            estado="PENDIENTE",
            # Campos Proveedor
            ruc=datos_adicionales.get('ruc'),
            nombre_comercial=datos_adicionales.get('nombre_comercial', ''),
            tipo_negocio=datos_adicionales.get('tipo_negocio', ''),
            descripcion_negocio=datos_adicionales.get('descripcion_negocio', ''),
            horario_apertura=datos_adicionales.get('horario_apertura'),
            horario_cierre=datos_adicionales.get('horario_cierre'),
            # Campos Repartidor
            cedula_identidad=datos_adicionales.get('cedula_identidad', ''),
            tipo_vehiculo=datos_adicionales.get('tipo_vehiculo', ''),
            zona_cobertura=datos_adicionales.get('zona_cobertura', ''),
            disponibilidad=datos_adicionales.get('disponibilidad', {})
        )

        logger.info(f"Solicitud creada exitosamente: ID {solicitud.id}")
        
        # 3. Notificar creación
        try:
            NotificadorSolicitud.notificar_solicitud_creada(solicitud)
        except Exception as e:
            logger.error(f"Error notificando creación: {e}")

        return solicitud

    @classmethod
    @transaction.atomic
    def aceptar_solicitud(cls, solicitud, admin, motivo_respuesta=""):
        """
        Aprueba la solicitud y crea los perfiles necesarios.
        IMPORTANTE: Construye update_fields dinámicamente para evitar errores si faltan campos.
        """
        if solicitud.estado != "PENDIENTE":
            raise ValidationError(f"La solicitud no está pendiente (Estado: {solicitud.estado}).")

        logger.info(f"Aceptando solicitud {solicitud.id} por admin {admin.email}")

        usuario = solicitud.user
        rol_solicitado_lower = solicitud.rol_solicitado.lower()

        # -----------------------------------------------------------------
        # PASO 1: INTENTAR CREAR EL PERFIL EN BASE DE DATOS
        # -----------------------------------------------------------------
        perfil_creado = False
        error_perfil = None

        if solicitud.rol_solicitado == "PROVEEDOR":
            perfil_creado, error_perfil = cls._crear_proveedor(solicitud, verificado_por_admin=True)
        elif solicitud.rol_solicitado == "REPARTIDOR":
            perfil_creado, error_perfil = cls._crear_repartidor(solicitud, verificado_por_admin=True)

        # Si la creación del perfil falló, detenemos todo y lanzamos error.
        if not perfil_creado:
            raise ValidationError(f"No se pudo aceptar la solicitud: {error_perfil}")

        # -----------------------------------------------------------------
        # PASO 2: ACTUALIZAR ROLES DEL USUARIO
        # -----------------------------------------------------------------
        
        # Respaldo del rol anterior para posibles reversiones
        solicitud.rol_anterior = getattr(usuario, 'rol', 'SIN_ROL')

        # Lista dinámica de campos a actualizar
        campos_actualizar = ['updated_at']

        # Actualizar rol legacy (Solo si el modelo tiene el campo 'rol')
        if hasattr(usuario, 'rol'):
            usuario.rol = solicitud.rol_solicitado
            campos_actualizar.append('rol')
        
        # Actualizar rol_activo
        if hasattr(usuario, 'rol_activo'):
            usuario.rol_activo = rol_solicitado_lower
            campos_actualizar.append('rol_activo')
        
        # Agregar a roles_aprobados (ArrayField)
        if hasattr(usuario, 'roles_aprobados'):
            roles_actuales = usuario.roles_aprobados or []
            if rol_solicitado_lower not in roles_actuales:
                roles_actuales.append(rol_solicitado_lower)
                usuario.roles_aprobados = roles_actuales
                campos_actualizar.append('roles_aprobados')
        
        # Guardar solo los campos que existen y fueron modificados
        usuario.save(update_fields=campos_actualizar)
        
        # -----------------------------------------------------------------
        # PASO 3: FINALIZAR SOLICITUD
        # -----------------------------------------------------------------
        solicitud.estado = "ACEPTADA"
        solicitud.admin_responsable = admin
        solicitud.motivo_respuesta = motivo_respuesta or "Solicitud aceptada por administración."
        solicitud.respondido_en = timezone.now()
        solicitud.save()

        # Auditoría
        cls._registrar_auditoria(
            admin=admin,
            tipo_accion="aceptar_solicitud_rol",
            descripcion=f"Aceptada solicitud para {solicitud.rol_solicitado}",
            solicitud=solicitud
        )
        
        # Notificación Push
        try:
            NotificadorSolicitud.notificar_solicitud_aceptada(solicitud)
        except Exception:
            pass

        logger.info(f"Solicitud {solicitud.id} aceptada exitosamente para {usuario.email}")

        return {"mensaje": "Solicitud aceptada y perfiles generados."}

    @classmethod
    @transaction.atomic
    def rechazar_solicitud(cls, solicitud, admin, motivo_respuesta):
        if solicitud.estado != "PENDIENTE":
            raise ValidationError(f"No se puede rechazar una solicitud en estado {solicitud.estado}.")

        logger.info(f"Rechazando solicitud {solicitud.id}. Motivo: {motivo_respuesta}")

        solicitud.estado = "RECHAZADA"
        solicitud.admin_responsable = admin
        solicitud.motivo_respuesta = motivo_respuesta or "No especificado"
        solicitud.respondido_en = timezone.now()
        solicitud.save()

        cls._registrar_auditoria(
            admin=admin,
            tipo_accion="rechazar_solicitud_rol",
            descripcion=f"Rechazada por: {motivo_respuesta}",
            solicitud=solicitud
        )

        try:
            NotificadorSolicitud.notificar_solicitud_rechazada(solicitud)
        except Exception:
            pass

        return {"mensaje": "Solicitud rechazada correctamente."}

    @classmethod
    @transaction.atomic
    def revertir_solicitud(cls, solicitud, admin, motivo_reversion):
        """
        Revierte una solicitud previamente aceptada.
        """
        if solicitud.estado != "ACEPTADA":
            raise ValidationError(f"Solo se pueden revertir solicitudes aceptadas. Estado actual: {solicitud.estado}")

        usuario = solicitud.user
        rol_a_revertir = solicitud.rol_solicitado.lower()
        rol_anterior = solicitud.rol_anterior or 'cliente'

        campos_actualizar = ['updated_at']

        # 1. Restaurar rol_activo
        if hasattr(usuario, 'rol_activo'):
            usuario.rol_activo = rol_anterior.lower()
            campos_actualizar.append('rol_activo')

        # 2. Quitar rol de roles_aprobados
        if hasattr(usuario, 'roles_aprobados'):
            roles_actuales = usuario.roles_aprobados or []
            if rol_a_revertir in roles_actuales:
                roles_actuales.remove(rol_a_revertir)
                usuario.roles_aprobados = roles_actuales
                campos_actualizar.append('roles_aprobados')

        usuario.save(update_fields=campos_actualizar)

        # 3. Desactivar perfil creado
        if solicitud.rol_solicitado == "PROVEEDOR" and hasattr(usuario, 'proveedor'):
            usuario.proveedor.activo = False
            usuario.proveedor.verificado = False
            usuario.proveedor.save()
        elif solicitud.rol_solicitado == "REPARTIDOR" and hasattr(usuario, 'repartidor'):
            usuario.repartidor.activo = False
            usuario.repartidor.verificado = False
            usuario.repartidor.save()

        # 4. Actualizar solicitud
        solicitud.estado = "REVERTIDA"
        solicitud.motivo_respuesta = f"REVERTIDA: {motivo_reversion}"
        solicitud.respondido_en = timezone.now()
        solicitud.save()

        # 5. Auditoría
        cls._registrar_auditoria(
            admin=admin,
            tipo_accion="revertir_solicitud_rol",
            descripcion=f"Revertida solicitud {solicitud.rol_solicitado}: {motivo_reversion}",
            solicitud=solicitud
        )

        return {
            "mensaje": "Solicitud revertida exitosamente",
            "usuario": usuario.email,
            "rol_actual": getattr(usuario, 'rol_activo', 'desconocido')
        }

    # ---------------------------------------------------------------------------
    # CREACIÓN DE PERFILES (HELPERS)
    # ---------------------------------------------------------------------------
    
    @staticmethod
    def _crear_proveedor(solicitud, verificado_por_admin=False):
        try:
            Proveedor = apps.get_model('proveedores', 'Proveedor')
            usuario = solicitud.user
            
            debe_verificar = verificado_por_admin or getattr(usuario, 'verificado', False)
            ruc = solicitud.ruc or f"TEMP{usuario.id}"
            
            # Verificar duplicados de RUC (Doble chequeo por seguridad)
            duplicado = Proveedor.objects.filter(ruc=ruc).exclude(user=usuario).first()
            if duplicado:
                return False, f"Error: El RUC {ruc} ya está registrado por el proveedor '{duplicado.nombre}'."

            if not hasattr(usuario, 'proveedor'):
                Proveedor.objects.create(
                    user=usuario,
                    nombre=solicitud.nombre_comercial or usuario.get_full_name(),
                    ruc=ruc,
                    tipo_proveedor=solicitud.tipo_negocio or "otro",
                    activo=True,
                    verificado=debe_verificar
                )
                return True, None
            else:
                # Reactivación
                proveedor = usuario.proveedor
                proveedor.ruc = ruc
                proveedor.verificado = debe_verificar
                proveedor.activo = True
                proveedor.save()
                return True, None

        except Exception as e:
            logger.error(f"Error creando proveedor: {e}")
            return False, str(e)

    @staticmethod
    def _crear_repartidor(solicitud, verificado_por_admin=False):
        try:
            from repartidores.models import Repartidor
            usuario = solicitud.user
            
            debe_verificar = verificado_por_admin or getattr(usuario, 'verificado', False)
            celular = getattr(usuario, 'celular', '') or getattr(solicitud, 'celular', '')
            cedula = solicitud.cedula_identidad
            
            if not cedula:
                return False, "La solicitud no tiene cédula de identidad."

            # Verificar duplicados en la tabla real (Doble chequeo)
            repartidor_conflictivo = Repartidor.objects.filter(cedula=cedula).exclude(user=usuario).first()
            if repartidor_conflictivo:
                return False, f"Error: La cédula {cedula} ya está registrada por el usuario {repartidor_conflictivo.user.email}."

            # Reactivación o Actualización
            if hasattr(usuario, 'repartidor'):
                repartidor = usuario.repartidor
                repartidor.cedula = cedula
                repartidor.activo = True
                repartidor.verificado = debe_verificar
                if debe_verificar:
                    repartidor.estado = 'disponible'
                repartidor.save()
                return True, None
            
            # Determinar vehiculo (obligatorio)
            vehiculo = datos_adicionales.get('tipo_vehiculo') or usuario.tipo_vehiculo
            if not vehiculo:
                return False, "Debes especificar el vehículo del repartidor."

            # Creación Nueva
            Repartidor.objects.create(
                user=usuario,
                cedula=cedula,
                telefono=celular,
                vehiculo=vehiculo,
                estado='disponible' if debe_verificar else 'fuera_servicio',
                verificado=debe_verificar,
                activo=True
            )
            return True, None

        except IntegrityError as e:
            return False, f"Error de base de datos: La cédula ya existe en el sistema."
        except Exception as e:
            logger.error(f"Error creando repartidor: {e}")
            return False, str(e)

    @staticmethod
    def _registrar_auditoria(admin, tipo_accion, descripcion, solicitud=None, request=None):
        try:
            from administradores.models import AccionAdministrativa
            perfil_admin = getattr(admin, 'perfil_admin', None)
            if perfil_admin:
                AccionAdministrativa.registrar_accion(
                    administrador=perfil_admin,
                    tipo_accion=tipo_accion,
                    descripcion=descripcion,
                    modelo_afectado="SolicitudCambioRol",
                    objeto_id=str(solicitud.id) if solicitud else None
                )
        except Exception:
            pass # No bloquear por fallos de auditoría


# ============================================
# NOTIFICADOR
# ============================================

class NotificadorSolicitud:
    @staticmethod
    def _enviar_notificacion(usuario, titulo, cuerpo, tipo, metadata):
        # Aquí iría tu lógica de FCM o notificaciones push
        logger.info(f"[PUSH] A {usuario.email}: {titulo} - {cuerpo}")

    @classmethod
    def notificar_solicitud_creada(cls, solicitud):
        cls._enviar_notificacion(solicitud.user, "Solicitud Recibida", "Tu solicitud está en revisión.", "solicitud_creada", {})

    @classmethod
    def notificar_solicitud_aceptada(cls, solicitud):
        cls._enviar_notificacion(solicitud.user, "¡Felicidades!", "Tu solicitud ha sido aprobada.", "solicitud_aceptada", {})

    @classmethod
    def notificar_solicitud_rechazada(cls, solicitud):
        cls._enviar_notificacion(solicitud.user, "Solicitud Rechazada", f"Motivo: {solicitud.motivo_respuesta}", "solicitud_rechazada", {})
