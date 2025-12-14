# proveedores/models.py
from django.db import models
from django.core.validators import RegexValidator
from django.core.exceptions import ValidationError
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone
from authentication.models import User
import logging
from django.core.validators import MinValueValidator, MaxValueValidator

logger = logging.getLogger('proveedores')


# ============================================
# MANAGER PERSONALIZADO (DEFINIR ANTES DE LA CLASE)
# ============================================
class ProveedorManager(models.Manager):
    """Manager personalizado para Proveedor"""

    def activos(self):
        """Retorna solo proveedores activos"""
        return self.filter(activo=True, deleted_at__isnull=True)

    def verificados(self):
        """Retorna solo proveedores verificados"""
        return self.filter(verificado=True, deleted_at__isnull=True)

    def activos_y_verificados(self):
        """Retorna proveedores activos y verificados"""
        return self.filter(activo=True, verificado=True, deleted_at__isnull=True)

    def sin_usuario(self):
        """Retorna proveedores sin usuario vinculado"""
        return self.filter(user__isnull=True)

    def con_usuario(self):
        """Retorna proveedores con usuario vinculado"""
        return self.filter(user__isnull=False)

    def desincronizados(self):
        """Retorna proveedores con datos desincronizados"""
        from django.db.models import Q, F
        return self.filter(
            user__isnull=False
        ).exclude(
            Q(email=F('user__email')) &
            Q(telefono=F('user__celular'))
        )


class Proveedor(models.Model):
    """
    Modelo para gestionar proveedores de la plataforma

    ACTUALIZADO CON:
    - Control de cambios de RUC (maximo 3 veces)
    - Validaciones de fecha minima entre cambios (30 dias)
    - Auditoria de cambios
    - Relacion OneToOne con User
    - Sincronizacion automatica con User
    - Validaciones mejoradas
    """
    # ============================================
    # RELACION CON USER
    # ============================================
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='proveedor',
        null=True,
        blank=True,
        verbose_name='Usuario',
        help_text='Usuario vinculado al proveedor (creado al registrarse)'
    )

    # Validador para telefono
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="El telefono debe tener el formato: '+593999999999'. Hasta 15 digitos."
    )

    # ============================================
    # INFORMACION BASICA
    # ============================================
    nombre = models.CharField(
        max_length=200,
        verbose_name='Nombre del Proveedor',
        help_text='Nombre completo o razon social'
    )

    ruc = models.CharField(
        max_length=13,
        unique=True,
        verbose_name='RUC/Cedula',
        help_text='RUC o cedula del proveedor (13 digitos)',
        db_index=True
    )

    # ============================================
    # CONTROL DE CAMBIOS DE RUC
    # ============================================
    ultima_modificacion_ruc = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Ultima Modificacion de RUC',
        help_text='Fecha del ultimo cambio de RUC'
    )

    total_cambios_ruc = models.PositiveIntegerField(
        default=0,
        verbose_name='Total de Cambios de RUC',
        help_text='Contador de cambios de RUC realizados (maximo 3)'
    )

    # ============================================
    # CONTACTO (DEPRECADOS - Usar User)
    # ============================================
    telefono = models.CharField(
        validators=[phone_regex],
        max_length=17,
        blank=True,
        verbose_name='Telefono',
        help_text='DEPRECADO: Se sincroniza con user.celular'
    )

    email = models.EmailField(
        blank=True,
        verbose_name='Email',
        help_text='DEPRECADO: Se sincroniza con user.email'
    )

    # ============================================
    # DIRECCION
    # ============================================
    direccion = models.TextField(
        blank=True,
        verbose_name='Direccion'
    )

    ciudad = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Ciudad',
        db_index=True
    )

    # ============================================
    # INFORMACION ADICIONAL
    # ============================================
    tipo_proveedor = models.CharField(
        max_length=50,
        choices=[
            ('restaurante', 'Restaurante'),
            ('farmacia', 'Farmacia'),
            ('supermercado', 'Supermercado'),
            ('tienda', 'Tienda'),
            ('otro', 'Otro'),
        ],
        default='restaurante',
        verbose_name='Tipo de Proveedor',
        db_index=True
    )

    descripcion = models.TextField(
        blank=True,
        verbose_name='Descripcion',
        help_text='Descripcion del negocio'
    )

    # ============================================
    # CONFIGURACION
    # ============================================
    activo = models.BooleanField(
        default=True,
        verbose_name='Activo',
        help_text='Si el proveedor esta activo en la plataforma',
        db_index=True
    )

    verificado = models.BooleanField(
        default=False,
        verbose_name='Verificado',
        help_text='Si el proveedor ha sido verificado por un administrador',
        db_index=True
    )

    comision_porcentaje = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=10.00,
        verbose_name='Comision (%)',
        help_text='Porcentaje de comision por pedido'
    )

    # ============================================
    # HORARIOS
    # ============================================
    horario_apertura = models.TimeField(
        null=True,
        blank=True,
        verbose_name='Hora de Apertura'
    )

    horario_cierre = models.TimeField(
        null=True,
        blank=True,
        verbose_name='Hora de Cierre'
    )

    # ============================================
    # GEOLOCALIZACION
    # ============================================
    latitud = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        verbose_name='Latitud'
    )

    longitud = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        verbose_name='Longitud'
    )

    # ============================================
    # LOGO/IMAGEN
    # ============================================
    logo = models.ImageField(
        upload_to='proveedores/logos/',
        null=True,
        blank=True,
        verbose_name='Logo'
    )

    # ============================================
    # AUDITORIA
    # ============================================
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Fecha de Creacion'
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Ultima Actualizacion'
    )

    # ============================================
    # SOFT DELETE (OPCIONAL)
    # ============================================
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Fecha de Eliminacion',
        help_text='Si esta lleno, el proveedor esta eliminado (soft delete)'
    )

    # ============================================
    # MANAGER PERSONALIZADO (DENTRO DE LA CLASE)
    # ============================================
    objects = ProveedorManager()

    # ============================================
    # META
    # ============================================
    class Meta:
        db_table = 'proveedores'
        verbose_name = 'Proveedor'
        verbose_name_plural = 'Proveedores'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['ruc']),
            models.Index(fields=['activo']),
            models.Index(fields=['tipo_proveedor']),
            models.Index(fields=['verificado']),
            models.Index(fields=['user']),
            models.Index(fields=['ciudad']),
            models.Index(fields=['deleted_at']),
            models.Index(fields=['total_cambios_ruc']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['user'],
                condition=models.Q(user__isnull=False),
                name='unique_user_proveedor'
            )
        ]

    # ============================================
    # METODOS BASICOS
    # ============================================
    def __str__(self):
        if self.user:
            return f"{self.nombre} - {self.user.email}"
        return f"{self.nombre} - {self.ruc}"

    def __repr__(self):
        return f"<Proveedor: {self.nombre} (ID: {self.id}, User: {self.user_id})>"

    # ============================================
    # MÉTODOS DE NEGOCIO
    # ============================================
    MAX_CAMBIOS_RUC = 3

    def cambiar_estado_activo(self, nuevo_estado):
        """
        Activa/desactiva el proveedor.
        Solo permite activarlo si está verificado.
        """
        if nuevo_estado and not self.verificado:
            raise ValidationError("No se puede activar un proveedor no verificado.")
        self.activo = nuevo_estado
        self.save(update_fields=["activo", "updated_at"])

    def actualizar_ruc(self, nuevo_ruc):
        """
        Actualiza el RUC respetando el límite de cambios.
        """
        if nuevo_ruc == self.ruc:
            return

        if self.total_cambios_ruc >= self.MAX_CAMBIOS_RUC:
            raise ValidationError(f"Se ha alcanzado el límite de {self.MAX_CAMBIOS_RUC} cambios de RUC.")

        self.ruc = nuevo_ruc
        self.total_cambios_ruc += 1
        self.ultima_modificacion_ruc = timezone.now()
        self.save(update_fields=["ruc", "total_cambios_ruc", "ultima_modificacion_ruc", "updated_at"])

    # ============================================
    # PROPIEDADES PARA ACCESO A DATOS DE USER
    # ============================================
    @property
    def email_actual(self):
        """Retorna el email actual (prioriza User sobre campo local)"""
        if self.user:
            return self.user.email
        return self.email

    @property
    def celular_actual(self):
        """Retorna el celular actual (prioriza User sobre campo local)"""
        if self.user:
            return self.user.celular
        return self.telefono

    @property
    def nombre_completo_usuario(self):
        """Retorna el nombre completo del usuario vinculado"""
        if self.user:
            return self.user.get_full_name()
        return None

    @property
    def esta_sincronizado(self):
        """Verifica si los datos estan sincronizados con User"""
        if not self.user:
            return True

        email_sync = self.email == self.user.email
        telefono_sync = self.telefono == self.user.celular

        return email_sync and telefono_sync

    # ============================================
    # METODOS: CONTROL DE RUC
    # ============================================
    def puede_cambiar_ruc(self):
        """
        Valida si el proveedor puede cambiar su RUC

        Reglas:
        - Solo si esta verificado
        - Maximo 3 cambios en la vida util
        - Minimo 30 dias entre cambios

        Returns:
            tuple: (puede_cambiar: bool, razon: str)
        """
        if not self.verificado:
            return (False, "[ERROR] Debes estar verificado para cambiar tu RUC")

        if self.total_cambios_ruc >= 3:
            return (False, "[ERROR] Ya has alcanzado el limite de cambios de RUC (maximo 3)")

        if self.ultima_modificacion_ruc:
            hace_30_dias = timezone.now() - timezone.timedelta(days=30)

            if self.ultima_modificacion_ruc > hace_30_dias:
                proximo_cambio = self.ultima_modificacion_ruc + timezone.timedelta(days=30)
                dias_faltantes = (proximo_cambio - timezone.now()).days + 1

                return (False, f"[ERROR] Debes esperar {dias_faltantes} dia(s) mas para cambiar tu RUC")

        return (True, "[OK] Puedes cambiar tu RUC")

    def cambiar_ruc(self, nuevo_ruc):
        """
        Cambia el RUC del proveedor con validaciones

        Args:
            nuevo_ruc (str): Nuevo RUC (13 digitos)

        Returns:
            dict: Resultado del cambio con detalles

        Raises:
            ValidationError: Si no puede cambiar o validacion falla
        """
        puede_cambiar, razon = self.puede_cambiar_ruc()
        if not puede_cambiar:
            logger.warning(f"[ERROR] Intento de cambio de RUC rechazado: {razon}")
            raise ValidationError(razon)

        if not nuevo_ruc or len(nuevo_ruc) != 13:
            raise ValidationError("[ERROR] RUC debe tener exactamente 13 digitos")

        if not nuevo_ruc.isdigit():
            raise ValidationError("[ERROR] RUC solo debe contener numeros")

        if Proveedor.objects.filter(ruc=nuevo_ruc).exclude(id=self.id).exists():
            raise ValidationError("[ERROR] Este RUC ya esta registrado en el sistema")

        if self.ruc == nuevo_ruc:
            raise ValidationError("[ERROR] El nuevo RUC es igual al actual")

        ruc_anterior = self.ruc

        self.ruc = nuevo_ruc
        self.ultima_modificacion_ruc = timezone.now()
        self.total_cambios_ruc += 1
        self.save(update_fields=['ruc', 'ultima_modificacion_ruc', 'total_cambios_ruc', 'updated_at'])

        logger.info(
            f"[OK] RUC cambio para proveedor {self.id} ({self.nombre}): "
            f"{ruc_anterior} -> {nuevo_ruc} (cambio #{self.total_cambios_ruc}/3)"
        )

        return {
            'exitoso': True,
            'ruc_anterior': ruc_anterior,
            'ruc_nuevo': nuevo_ruc,
            'total_cambios': self.total_cambios_ruc,
            'cambios_restantes': 3 - self.total_cambios_ruc,
            'mensaje': f"[OK] RUC actualizado exitosamente. Cambios realizados: {self.total_cambios_ruc}/3"
        }

    @property
    def info_cambios_ruc(self):
        """Informacion sobre cambios de RUC disponibles"""
        puede_cambiar, razon = self.puede_cambiar_ruc()

        return {
            'puede_cambiar': puede_cambiar,
            'razon': razon,
            'cambios_realizados': self.total_cambios_ruc,
            'cambios_permitidos': 3,
            'cambios_restantes': 3 - self.total_cambios_ruc,
            'ultima_modificacion': self.ultima_modificacion_ruc.isoformat() if self.ultima_modificacion_ruc else None,
        }

    # ============================================
    # METODOS HELPER
    # ============================================
    def esta_abierto(self):
        """Verifica si el proveedor esta abierto en este momento"""
        if not self.horario_apertura or not self.horario_cierre:
            return True

        from datetime import datetime
        now = datetime.now().time()
        return self.horario_apertura <= now <= self.horario_cierre

    def get_nombre_usuario(self):
        """Obtiene el nombre del usuario vinculado"""
        if self.user:
            return self.user.get_full_name()
        return "Sin usuario vinculado"

    def get_email_usuario(self):
        """Obtiene el email del usuario vinculado"""
        if self.user:
            return self.user.email
        return self.email

    def get_celular_usuario(self):
        """Obtiene el celular del usuario vinculado"""
        if self.user:
            return self.user.celular
        return self.telefono

    def sincronizar_con_user(self, campos=None):
        """
        Sincroniza datos manualmente desde User

        Args:
            campos (list): Lista de campos a sincronizar ['email', 'telefono']
                          Si es None, sincroniza todos
        """
        if not self.user:
            logger.warning(f"Proveedor {self.id} no tiene usuario vinculado")
            return False

        cambios = False

        if campos is None or 'email' in campos:
            if self.email != self.user.email:
                self.email = self.user.email
                cambios = True

        if campos is None or 'telefono' in campos:
            if self.telefono != self.user.celular:
                self.telefono = self.user.celular
                cambios = True

        if cambios:
            self.save(update_fields=['email', 'telefono'])
            logger.info(f"[OK] Proveedor {self.id} sincronizado con User {self.user.id}")

        return cambios

    def verificar(self):
        """Verifica el proveedor y su usuario"""
        self.verificado = True
        self.save(update_fields=['verificado'])

        if self.user:
            # Agregar rol de proveedor al usuario
            self.user.agregar_rol('proveedor')
            logger.info(f"[OK] Rol 'proveedor' agregado a usuario {self.user.id}")

    def desverificar(self):
        """Quita verificacion del proveedor"""
        self.verificado = False
        self.save(update_fields=['verificado'])

        if self.user:
            self.user.remover_rol('proveedor')
            logger.info(f"[WARNING] Rol 'proveedor' removido de usuario {self.user.id}")

    def soft_delete(self):
        """Eliminacion suave (no borra, marca como eliminado)"""
        self.deleted_at = timezone.now()
        self.activo = False
        self.save(update_fields=['deleted_at', 'activo'])
        logger.warning(f"[DELETE] Proveedor {self.id} marcado como eliminado")

    def restore(self):
        """Restaura un proveedor eliminado suavemente"""
        self.deleted_at = None
        self.activo = True
        self.save(update_fields=['deleted_at', 'activo'])
        logger.info(f"[RESTORE] Proveedor {self.id} restaurado")

    # ============================================
    # VALIDACIONES
    # ============================================
    def clean(self):
        """Validaciones antes de guardar"""
        super().clean()

        if self.ruc:
            if not self.ruc.isdigit():
                raise ValidationError({'ruc': 'El RUC debe contener solo numeros'})
            if len(self.ruc) != 13:
                raise ValidationError({'ruc': 'El RUC debe tener exactamente 13 digitos'})

        if self.horario_apertura and self.horario_cierre:
            if self.horario_apertura >= self.horario_cierre:
                raise ValidationError({'horario_cierre': 'El horario de cierre debe ser posterior al de apertura'})

        if self.comision_porcentaje < 0 or self.comision_porcentaje > 100:
            raise ValidationError({'comision_porcentaje': 'La comision debe estar entre 0 y 100'})

    def save(self, *args, **kwargs):
        """Override save para sincronizacion automatica"""
        # Sincronizacion automatica si hay usuario
        if self.user:
            force_sync = kwargs.pop('force_sync', False)

            if force_sync or not self.email:
                self.email = self.user.email

            if force_sync or not self.telefono:
                self.telefono = self.user.celular

        super().save(*args, **kwargs)


# ============================================
# SIGNALS PARA SINCRONIZACION AUTOMATICA
# ============================================
@receiver(pre_save, sender=Proveedor)
def proveedor_pre_save(sender, instance, **kwargs):
    """Signal antes de guardar Proveedor"""
    if instance.user:
        if instance.email != instance.user.email:
            old_email = instance.email
            instance.email = instance.user.email
            logger.debug(f"[SYNC] Email sincronizado: {old_email} -> {instance.email}")

        if instance.telefono != instance.user.celular:
            old_telefono = instance.telefono
            instance.telefono = instance.user.celular
            logger.debug(f"[SYNC] Telefono sincronizado: {old_telefono} -> {instance.telefono}")


@receiver(post_save, sender=Proveedor)
def proveedor_post_save(sender, instance, created, **kwargs):
    """Signal despues de guardar Proveedor"""
    if getattr(instance, '_syncing', False):
        return

    if kwargs.get('raw', False):
        return

    if created:
        logger.info(f"[OK] Proveedor creado: {instance.nombre} (ID: {instance.id}, User: {instance.user_id})")

        # Si el proveedor está verificado, agregar rol al usuario
        if instance.user and instance.verificado:
            try:
                instance.user._syncing = True
                instance.user.agregar_rol('proveedor')
                logger.info(f"[OK] Rol 'proveedor' agregado a usuario {instance.user.id}")
            except Exception as e:
                logger.error(f"[ERROR] Error agregando rol a usuario {instance.user.id}: {e}")
            finally:
                instance.user._syncing = False
    else:
        logger.debug(f"[SYNC] Proveedor actualizado: {instance.nombre} (ID: {instance.id})")


# ════════════════════════════════════════════════════════════════════════════
# MODELO DE ACCIONES ADMINISTRATIVAS
# ════════════════════════════════════════════════════════════════════════════
class AccionAdministrativa(models.Model):
    """
    Modelo para auditar acciones administrativas en proveedores y repartidores
    """
    
    TIPOS_ACCION = [
        ('editar_proveedor', 'Editar Proveedor'),
        ('editar_proveedor_contacto', 'Editar Contacto Proveedor'),
        ('verificar_proveedor', 'Verificar Proveedor'),
        ('rechazar_proveedor', 'Rechazar Proveedor'),
        ('activar_proveedor', 'Activar Proveedor'),
        ('desactivar_proveedor', 'Desactivar Proveedor'),
        ('editar_repartidor', 'Editar Repartidor'),
        ('editar_repartidor_contacto', 'Editar Contacto Repartidor'),
        ('verificar_repartidor', 'Verificar Repartidor'),
        ('rechazar_repartidor', 'Rechazar Repartidor'),
        ('activar_repartidor', 'Activar Repartidor'),
        ('desactivar_repartidor', 'Desactivar Repartidor'),
    ]
    
    administrador = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='acciones_administrativas',
        verbose_name='Administrador',
        help_text='Usuario administrador que realizó la acción'
    )
    
    tipo_accion = models.CharField(
        max_length=50,
        choices=TIPOS_ACCION,
        verbose_name='Tipo de Acción',
        db_index=True
    )
    
    descripcion = models.TextField(
        verbose_name='Descripción',
        help_text='Descripción detallada de la acción realizada'
    )
    
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        verbose_name='Dirección IP',
        help_text='IP desde donde se realizó la acción'
    )
    
    user_agent = models.TextField(
        blank=True,
        verbose_name='User Agent',
        help_text='Información del navegador/cliente'
    )
    
    modelo_afectado = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        verbose_name='Modelo Afectado',
        help_text='Nombre del modelo afectado (Proveedor, Repartidor, User)'
    )
    
    objeto_id = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        verbose_name='ID del Objeto',
        help_text='ID del objeto afectado'
    )
    
    datos_anteriores = models.JSONField(
        null=True,
        blank=True,
        verbose_name='Datos Anteriores',
        help_text='Datos antes de la acción (para auditoría)'
    )
    
    datos_nuevos = models.JSONField(
        null=True,
        blank=True,
        verbose_name='Datos Nuevos',
        help_text='Datos después de la acción'
    )
    
    creado_en = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Fecha de Creación',
        db_index=True
    )
    
    class Meta:
        db_table = 'proveedores_accion_administrativa'
        verbose_name = 'Acción Administrativa'
        verbose_name_plural = 'Acciones Administrativas'
        ordering = ['-creado_en']
        indexes = [
            models.Index(fields=['administrador', '-creado_en']),
            models.Index(fields=['tipo_accion', '-creado_en']),
            models.Index(fields=['modelo_afectado', 'objeto_id']),
        ]
    
    def __str__(self):
        admin_email = self.administrador.email if self.administrador else 'Unknown'
        return f"{self.get_tipo_accion_display()} - {admin_email} - {self.creado_en.strftime('%Y-%m-%d %H:%M')}"
    
    def __repr__(self):
        return f"<AccionAdministrativa: {self.tipo_accion} ({self.id})>"
    
    @classmethod
    def registrar_accion(cls, administrador, tipo_accion, descripcion, 
                        ip_address=None, user_agent=None, modelo_afectado=None,
                        objeto_id=None, datos_anteriores=None, datos_nuevos=None):
        """Método de clase para registrar una acción administrativa"""
        accion = cls(
            administrador=administrador,
            tipo_accion=tipo_accion,
            descripcion=descripcion,
            ip_address=ip_address,
            user_agent=user_agent,
            modelo_afectado=modelo_afectado,
            objeto_id=objeto_id,
            datos_anteriores=datos_anteriores,
            datos_nuevos=datos_nuevos,
        )
        accion.save()
        
        logger.info(
            f"[AUDIT] {tipo_accion} registrado: {descripcion} "
            f"por {administrador.email if administrador else 'Unknown'}"
        )
        
        return accion
    
    @classmethod
    def listar_acciones_usuario(cls, usuario, limite=50):
        """Lista todas las acciones realizadas por un administrador"""
        return cls.objects.filter(administrador=usuario).order_by('-creado_en')[:limite]
    
    @classmethod
    def listar_acciones_modelo(cls, modelo_afectado, objeto_id=None, limite=50):
        """Lista todas las acciones realizadas sobre un modelo/objeto específico"""
        query = cls.objects.filter(modelo_afectado=modelo_afectado)
        
        if objeto_id:
            query = query.filter(objeto_id=str(objeto_id))
        
        return query.order_by('-creado_en')[:limite]
    
    @classmethod
    def obtener_estadisticas(cls, dias=30):
        """Obtiene estadísticas de acciones en los últimos N días"""
        from django.db.models import Count
        
        fecha_inicio = timezone.now() - timezone.timedelta(days=dias)
        
        acciones = cls.objects.filter(
            creado_en__gte=fecha_inicio
        ).values('tipo_accion').annotate(
            total=Count('id')
        ).order_by('-total')
        
        return {
            'total_acciones': cls.objects.filter(creado_en__gte=fecha_inicio).count(),
            'por_tipo': list(acciones),
            'periodo_dias': dias,
        }
# ============================================
# CALIFICACIONES (NUEVO)
# ============================================
    calificacion_promedio = models.DecimalField(
    max_digits=3,
    decimal_places=2,
    default=5.00,
    validators=[MinValueValidator(0), MaxValueValidator(5)],
    verbose_name='Calificación Promedio'
    )

    total_resenas = models.PositiveIntegerField(
    default=0,
    verbose_name='Total de Reseñas'
    )
