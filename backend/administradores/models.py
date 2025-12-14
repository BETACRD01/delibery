# -*- coding: utf-8 -*-
# administradores/models.py
"""
Modelo de Administrador con perfil extendido y auditoría

Características:
- Perfil de administrador con permisos específicos
- Log de acciones administrativas
- Configuraciones del sistema
- Gestión de solicitudes de cambio de rol
"""

from django.db import models
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.core.cache import cache
from authentication.models import User
import uuid
import logging

logger = logging.getLogger("administradores")


# ============================================
# CONSTANTES
# ============================================

class PermisosAdmin:
    """Constantes para permisos de administrador"""
    GESTIONAR_USUARIOS = 'gestionar_usuarios'
    GESTIONAR_PEDIDOS = 'gestionar_pedidos'
    GESTIONAR_PROVEEDORES = 'gestionar_proveedores'
    GESTIONAR_REPARTIDORES = 'gestionar_repartidores'
    GESTIONAR_RIFAS = 'gestionar_rifas'
    VER_REPORTES = 'ver_reportes'
    CONFIGURAR_SISTEMA = 'configurar_sistema'
    GESTIONAR_SOLICITUDES = 'gestionar_solicitudes'


# ============================================
# MODELO: PERFIL DE ADMINISTRADOR
# ============================================


class Administrador(models.Model):
    """
    Perfil extendido para usuarios administradores
    
    Atributos principales:
    - user: Relación uno a uno con User
    - permisos: Booleanos para control de acceso
    - información adicional: cargo, departamento
    """

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="perfil_admin",
        verbose_name="Usuario",
    )

    # Información adicional
    cargo = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Cargo",
        help_text="Ej: Administrador General, Supervisor",
    )

    departamento = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Departamento",
        help_text="Ej: Operaciones, Finanzas",
    )

    # Permisos específicos
    puede_gestionar_usuarios = models.BooleanField(
        default=True, 
        verbose_name="Puede gestionar usuarios"
    )

    puede_gestionar_pedidos = models.BooleanField(
        default=True, 
        verbose_name="Puede gestionar pedidos"
    )

    puede_gestionar_proveedores = models.BooleanField(
        default=True, 
        verbose_name="Puede gestionar proveedores"
    )

    puede_gestionar_repartidores = models.BooleanField(
        default=True, 
        verbose_name="Puede gestionar repartidores"
    )

    puede_gestionar_rifas = models.BooleanField(
        default=True, 
        verbose_name="Puede gestionar rifas"
    )

    puede_ver_reportes = models.BooleanField(
        default=True, 
        verbose_name="Puede ver reportes"
    )

    puede_configurar_sistema = models.BooleanField(
        default=False,
        verbose_name="Puede configurar sistema",
        help_text="Solo super administradores",
    )

    puede_gestionar_solicitudes = models.BooleanField(
        default=True,
        verbose_name="Puede gestionar solicitudes",
        help_text="Puede aceptar/rechazar solicitudes de cambio de rol",
    )

    # Auditoría
    activo = models.BooleanField(
        default=True, 
        verbose_name="Activo", 
        help_text="Si el administrador está activo"
    )

    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "administradores"
        verbose_name = "Administrador"
        verbose_name_plural = "Administradores"
        ordering = ["-creado_en"]
        indexes = [
            models.Index(fields=["activo"]),
            models.Index(fields=["-creado_en"]),
        ]

    def __str__(self):
        return f"Admin: {self.user.get_full_name()} - {self.cargo}"

    def clean(self):
        """Validaciones del modelo"""
        # 💡 CORRECCIÓN CRÍTICA: Se ha eliminado la línea que usaba self.user.rol,
        # ya que el campo 'rol' no existe en el modelo User, causando AttributeError.
        # La verificación de permisos ahora se basa en el ViewSet.
        pass 

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    # ============================================
    # MÉTODOS DE PERMISOS
    # ============================================

    def tiene_permiso(self, permiso):
        """
        Verifica si tiene un permiso específico usando reflexión
        
        Args:
            permiso (str): Nombre del permiso (usar constantes PermisosAdmin)
        
        Returns:
            bool: True si tiene el permiso
        """
        campo_permiso = f"puede_{permiso}"
        return getattr(self, campo_permiso, False)

    @property
    def es_super_admin(self):
        """Verifica si es super administrador"""
        return self.user.is_superuser or self.puede_configurar_sistema

    @property
    def total_acciones(self):
        """Total de acciones registradas con cache"""
        cache_key = f"admin_acciones_{self.pk}"
        total = cache.get(cache_key)
        
        if total is None:
            total = self.acciones.count()
            cache.set(cache_key, total, 300)  # Cache por 5 minutos
        
        return total

    def invalidar_cache_acciones(self):
        """Invalida el cache de total de acciones"""
        cache_key = f"admin_acciones_{self.pk}"
        cache.delete(cache_key)


# ============================================
# MODELO: LOG DE ACCIONES ADMINISTRATIVAS
# ============================================


class AccionAdministrativa(models.Model):
    """
    Registro de auditoría de acciones administrativas
    
    Proporciona trazabilidad completa de todas las operaciones
    realizadas por administradores en el sistema.
    """

    # Tipos de acciones - Usuarios
    CREAR_USUARIO = 'crear_usuario'
    EDITAR_USUARIO = 'editar_usuario'
    DESACTIVAR_USUARIO = 'desactivar_usuario'
    ACTIVAR_USUARIO = 'activar_usuario'
    CAMBIAR_ROL = 'cambiar_rol'
    RESETEAR_PASSWORD = 'resetear_password'
    
    # Tipos de acciones - Proveedores
    VERIFICAR_PROVEEDOR = 'verificar_proveedor'
    RECHAZAR_PROVEEDOR = 'rechazar_proveedor'
    DESACTIVAR_PROVEEDOR = 'desactivar_proveedor'
    
    # Tipos de acciones - Repartidores
    VERIFICAR_REPARTIDOR = 'verificar_repartidor'
    RECHAZAR_REPARTIDOR = 'rechazar_repartidor'
    DESACTIVAR_REPARTIDOR = 'desactivar_repartidor'
    
    # Tipos de acciones - Pedidos
    CANCELAR_PEDIDO = 'cancelar_pedido'
    REASIGNAR_PEDIDO = 'reasignar_pedido'
    EDITAR_PEDIDO = 'editar_pedido'
    
    # Tipos de acciones - Rifas
    CREAR_RIFA = 'crear_rifa'
    REALIZAR_SORTEO = 'realizar_sorteo'
    CANCELAR_RIFA = 'cancelar_rifa'
    
    # Tipos de acciones - Solicitudes
    ACEPTAR_SOLICITUD_ROL = 'aceptar_solicitud_rol'
    RECHAZAR_SOLICITUD_ROL = 'rechazar_solicitud_rol'
    
    # Tipos de acciones - Sistema
    CONFIGURAR_SISTEMA = 'configurar_sistema'
    NOTIFICACION_MASIVA = 'notificacion_masiva'
    EXPORTAR_DATOS = 'exportar_datos'
    REVERTIR_CAMBIO_ROL = 'revertir_cambio_rol'

    TIPO_ACCION_CHOICES = [
        # Usuarios
        (CREAR_USUARIO, "Crear Usuario"),
        (EDITAR_USUARIO, "Editar Usuario"),
        (DESACTIVAR_USUARIO, "Desactivar Usuario"),
        (ACTIVAR_USUARIO, "Activar Usuario"),
        (CAMBIAR_ROL, "Cambiar Rol"),
        (RESETEAR_PASSWORD, "Resetear Contraseña"),
        # Proveedores
        (VERIFICAR_PROVEEDOR, "Verificar Proveedor"),
        (RECHAZAR_PROVEEDOR, "Rechazar Proveedor"),
        (DESACTIVAR_PROVEEDOR, "Desactivar Proveedor"),
        # Repartidores
        (VERIFICAR_REPARTIDOR, "Verificar Repartidor"),
        (RECHAZAR_REPARTIDOR, "Rechazar Repartidor"),
        (DESACTIVAR_REPARTIDOR, "Desactivar Repartidor"),
        # Pedidos
        (CANCELAR_PEDIDO, "Cancelar Pedido"),
        (REASIGNAR_PEDIDO, "Reasignar Pedido"),
        (EDITAR_PEDIDO, "Editar Pedido"),
        # Rifas
        (CREAR_RIFA, "Crear Rifa"),
        (REALIZAR_SORTEO, "Realizar Sorteo"),
        (CANCELAR_RIFA, "Cancelar Rifa"),
        # Solicitudes de Cambio de Rol
        (ACEPTAR_SOLICITUD_ROL, "Aceptar Solicitud de Rol"),
        (RECHAZAR_SOLICITUD_ROL, "Rechazar Solicitud de Rol"),
        # Sistema
        (CONFIGURAR_SISTEMA, "Configurar Sistema"),
        (NOTIFICACION_MASIVA, "Notificación Masiva"),
        (EXPORTAR_DATOS, "Exportar Datos"),
        (REVERTIR_CAMBIO_ROL, "Revertir Cambio de Rol"),
    ]

    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )

    administrador = models.ForeignKey(
        Administrador,
        on_delete=models.SET_NULL,
        null=True,
        related_name="acciones",
        verbose_name="Administrador",
    )

    tipo_accion = models.CharField(
        max_length=50,
        choices=TIPO_ACCION_CHOICES,
        verbose_name="Tipo de Acción",
        db_index=True,
    )

    descripcion = models.TextField(
        verbose_name="Descripción", 
        help_text="Descripción detallada de la acción"
    )

    # Datos de la acción
    modelo_afectado = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Modelo Afectado",
        help_text="Ej: User, Pedido, Proveedor",
        db_index=True,
    )

    objeto_id = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="ID del Objeto",
        help_text="ID del objeto afectado",
    )

    datos_anteriores = models.JSONField(
        default=dict,
        blank=True,
        verbose_name="Datos Anteriores",
        help_text="Estado anterior del objeto (opcional)",
    )

    datos_nuevos = models.JSONField(
        default=dict,
        blank=True,
        verbose_name="Datos Nuevos",
        help_text="Nuevo estado del objeto (opcional)",
    )

    # Metadatos
    ip_address = models.GenericIPAddressField(
        null=True, 
        blank=True, 
        verbose_name="Dirección IP"
    )

    user_agent = models.TextField(
        blank=True, 
        verbose_name="User Agent"
    )

    exitosa = models.BooleanField(
        default=True, 
        verbose_name="Acción Exitosa"
    )

    mensaje_error = models.TextField(
        blank=True, 
        verbose_name="Mensaje de Error", 
        help_text="Si la acción falló"
    )

    # Auditoría
    fecha_accion = models.DateTimeField(
        default=timezone.now, 
        verbose_name="Fecha de la Acción",
    )

    class Meta:
        db_table = "acciones_administrativas"
        verbose_name = "Acción Administrativa"
        verbose_name_plural = "Acciones Administrativas"
        ordering = ["-fecha_accion"]
        indexes = [
            models.Index(fields=["administrador", "-fecha_accion"]),
            models.Index(fields=["tipo_accion", "-fecha_accion"]),
            models.Index(fields=["modelo_afectado", "objeto_id"]),
            models.Index(fields=["-fecha_accion"]),
            models.Index(fields=["exitosa", "-fecha_accion"]),
        ]

    def __str__(self):
        admin_nombre = (
            self.administrador.user.get_full_name()
            if self.administrador
            else "Admin eliminado"
        )
        return (
            f"{admin_nombre} - {self.get_tipo_accion_display()} - "
            f"{self.fecha_accion.strftime('%Y-%m-%d %H:%M')}"
        )

    def save(self, *args, **kwargs):
        """Override save para invalidar cache del administrador"""
        super().save(*args, **kwargs)
        if self.administrador:
            self.administrador.invalidar_cache_acciones()

    @classmethod
    def registrar_accion(
        cls, 
        administrador, 
        tipo_accion, 
        descripcion, 
        **kwargs
    ):
        """
        Método helper para registrar acciones de forma segura
        
        Args:
            administrador: Instancia de Administrador
            tipo_accion: Tipo de acción (usar constantes de clase)
            descripcion: Descripción de la acción
            **kwargs: Campos adicionales opcionales
        
        Returns:
            AccionAdministrativa|None: Instancia creada o None si falla
        """
        try:
            accion = cls.objects.create(
                administrador=administrador,
                tipo_accion=tipo_accion,
                descripcion=descripcion,
                modelo_afectado=kwargs.get("modelo_afectado", ""),
                objeto_id=kwargs.get("objeto_id", ""),
                datos_anteriores=kwargs.get("datos_anteriores", {}),
                datos_nuevos=kwargs.get("datos_nuevos", {}),
                ip_address=kwargs.get("ip_address"),
                user_agent=kwargs.get("user_agent", ""),
                exitosa=kwargs.get("exitosa", True),
                mensaje_error=kwargs.get("mensaje_error", ""),
            )

            logger.info(
                f"Acción registrada: {administrador.user.email} - "
                f"{tipo_accion} - {descripcion}"
            )

            return accion

        except Exception as e:
            logger.error(
                f"Error registrando acción administrativa: {e}", 
                exc_info=True
            )
            return None

    @property
    def resumen(self):
        """Resumen corto de la acción (primeros 50 caracteres)"""
        return f"{self.get_tipo_accion_display()}: {self.descripcion[:50]}"

    @property
    def fue_exitosa(self):
        """Alias para mejor legibilidad"""
        return self.exitosa


# ============================================
# MODELO: CONFIGURACIÓN DEL SISTEMA
# ============================================


class ConfiguracionSistema(models.Model):
    """
    Configuración global del sistema (Singleton)
    
    Solo accesible por super administradores.
    Maneja todas las configuraciones centralizadas del sistema.
    """

    # Comisiones
    comision_app_proveedor = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=10.00,
        verbose_name="Comisión App - Pedidos Proveedor (%)",
        help_text="Porcentaje que se lleva la app de pedidos de proveedor",
    )

    comision_app_directo = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=15.00,
        verbose_name="Comisión App - Encargos Directos (%)",
        help_text="Porcentaje que se lleva la app de encargos directos",
    )

    comision_repartidor_proveedor = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=25.00,
        verbose_name="Comisión Repartidor - Pedidos Proveedor (%)",
    )

    comision_repartidor_directo = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=85.00,
        verbose_name="Comisión Repartidor - Encargos Directos (%)",
    )

    # Rifas
    pedidos_minimos_rifa = models.PositiveIntegerField(
        default=3,
        verbose_name="Pedidos Mínimos para Rifa",
        help_text="Cantidad mínima de pedidos para participar en rifa",
    )

    # Límites
    pedido_maximo = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=1000.00,
        verbose_name="Monto Máximo por Pedido",
        help_text="Monto máximo permitido por pedido",
    )

    pedido_minimo = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=5.00,
        verbose_name="Monto Mínimo por Pedido",
    )

    # Tiempos
    tiempo_maximo_entrega = models.PositiveIntegerField(
        default=60,
        verbose_name="Tiempo Máximo de Entrega (minutos)",
        help_text="Tiempo límite para marcar un pedido como retrasado",
    )

    # Contacto
    telefono_soporte = models.CharField(
        max_length=15, 
        blank=True, 
        verbose_name="Teléfono de Soporte"
    )

    email_soporte = models.EmailField(
        blank=True, 
        verbose_name="Email de Soporte"
    )

    # Estado
    mantenimiento = models.BooleanField(
        default=False,
        verbose_name="Modo Mantenimiento",
        help_text="Si está activado, solo admins pueden acceder",
    )

    mensaje_mantenimiento = models.TextField(
        blank=True, 
        verbose_name="Mensaje de Mantenimiento"
    )

    # Auditoría
    modificado_por = models.ForeignKey(
        Administrador,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,  # Permitir creación inicial sin admin explícito
        verbose_name="Modificado Por",
    )

    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "configuracion_sistema"
        verbose_name = "Configuración del Sistema"
        verbose_name_plural = "Configuraciones del Sistema"

    def __str__(self):
        fecha = self.actualizado_en.strftime('%Y-%m-%d %H:%M')
        return f"Configuración del Sistema (actualizado: {fecha})"

    def clean(self):
        """Validaciones personalizadas"""
        # Validar que las comisiones estén en rangos válidos
        if self.comision_app_proveedor < 0 or self.comision_app_proveedor > 100:
            raise ValidationError({
                'comision_app_proveedor': 'Debe estar entre 0 y 100'
            })
        
        if self.comision_app_directo < 0 or self.comision_app_directo > 100:
            raise ValidationError({
                'comision_app_directo': 'Debe estar entre 0 y 100'
            })
        
        # Validar montos de pedidos
        if self.pedido_minimo >= self.pedido_maximo:
            raise ValidationError({
                'pedido_minimo': 'Debe ser menor que el monto máximo'
            })

    def save(self, *args, **kwargs):
        """
        Implementación singleton robusta
        Previene creación de múltiples instancias
        """
        self.pk = 1
        self.full_clean()
        
        # Limpiar cache al guardar
        cache.delete('configuracion_sistema')
        
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        """Prevenir eliminación de la configuración"""
        raise ValidationError(
            "No se puede eliminar la configuración del sistema"
        )

    @classmethod
    def obtener(cls):
        """
        Obtiene la configuración del sistema con cache
        
        Returns:
            ConfiguracionSistema: Instancia única de configuración
        """
        # Intentar obtener del cache
        config = cache.get('configuracion_sistema')
        
        if config is None:
            config, created = cls.objects.get_or_create(
                pk=1,
                defaults={
                    'comision_app_proveedor': 10.00,
                    'comision_app_directo': 15.00,
                    'comision_repartidor_proveedor': 25.00,
                    'comision_repartidor_directo': 85.00,
                }
            )
            
            # Guardar en cache por 1 hora
            cache.set('configuracion_sistema', config, 3600)
            
            if created:
                logger.info(
                    "Configuración del sistema creada con valores por defecto"
                )
        
        return config

    @property
    def esta_en_mantenimiento(self):
        """Verifica si el sistema está en mantenimiento"""
        return self.mantenimiento

    def activar_mantenimiento(self, mensaje="", administrador=None):
        """
        Activa el modo mantenimiento
        
        Args:
            mensaje: Mensaje a mostrar a los usuarios
            administrador: Admin que activa el mantenimiento
        """
        self.mantenimiento = True
        self.mensaje_mantenimiento = mensaje
        if administrador:
            self.modificado_por = administrador
        self.save()
        
        logger.warning(f"Modo mantenimiento ACTIVADO por {administrador}")

    def desactivar_mantenimiento(self, administrador=None):
        """
        Desactiva el modo mantenimiento
        
        Args:
            administrador: Admin que desactiva el mantenimiento
        """
        self.mantenimiento = False
        self.mensaje_mantenimiento = ""
        if administrador:
            self.modificado_por = administrador
        self.save()
        
        logger.info(f"Modo mantenimiento DESACTIVADO por {administrador}")
