# -*- coding: utf-8 -*-
# authentication/models.py

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import date, timedelta
import phonenumbers
import re
import logging

logger = logging.getLogger('authentication')


def validar_celular(value):
    """
    Validador personalizado para números de celular
    Soporta números ecuatorianos e internacionales
    
    Formatos aceptados:
    - Ecuador: 0987654321, +593987654321
    - Internacional: +1234567890, +521234567890, etc.
    """
    try:
        if not value:
            raise ValidationError("El número es requerido")

        raw = str(value).strip()

        # Aceptar formato local ecuatoriano 09xxxxxxxx (solo para validación)
        if re.match(r'^09\d{8}$', raw):
            return

        # Aceptar formato internacional ecuatoriano +5939xxxxxxxx
        if re.match(r'^\+5939\d{8}$', raw):
            return

        # Intentar parsear primero como ecuatoriano
        numero = phonenumbers.parse(raw, "EC")
        
        # Validar que sea un número válido
        if not phonenumbers.is_valid_number(numero):
            raise ValidationError(
                'Número de celular inválido. '
                'Formato Ecuador: 09XXXXXXXX o +593XXXXXXXXX | '
                'Internacional: +código país + número'
            )
        
        # Validar que sea un número móvil
        tipo_numero = phonenumbers.number_type(numero)
        if tipo_numero not in [
            phonenumbers.PhoneNumberType.MOBILE,
            phonenumbers.PhoneNumberType.FIXED_LINE_OR_MOBILE
        ]:
            raise ValidationError(
                'El número debe ser un celular válido'
            )
            
    except phonenumbers.NumberParseException as e:
        raise ValidationError(
            f'Formato de número inválido. '
            f'Formato Ecuador: 09XXXXXXXX o +593XXXXXXXXX | '
            f'Internacional: +código país + número'
        )


class User(AbstractUser):
    """
    Modelo de usuario personalizado para Deliber/JP Express
    
    Soporta:
    - Autenticación por email
    - Sistema de roles múltiples (cliente, proveedor, repartidor, admin)
    - Gestión de términos y condiciones
    - Control de intentos de login
    - Notificaciones configurables
    """

    # ==========================================
    # CAMPOS BÁSICOS DE USUARIO
    # ==========================================
    first_name = models.CharField(
        max_length=150,
        verbose_name='Nombre',
        help_text='Nombre del usuario'
    )

    last_name = models.CharField(
        max_length=150,
        verbose_name='Apellido',
        help_text='Apellido del usuario'
    )

    username = models.CharField(
        max_length=150,
        unique=True,
        verbose_name='Usuario',
        help_text='Nombre de usuario único',
        error_messages={
            'unique': 'Este nombre de usuario ya está en uso.',
        }
    )

    # ==========================================
    # EMAIL (CAMPO PRINCIPAL PARA LOGIN)
    # ==========================================
    email = models.EmailField(
        unique=True,
        verbose_name='Correo electrónico',
        help_text='Email único para login',
        error_messages={
            'unique': 'Este correo electrónico ya está registrado.',
        }
    )

    # ==========================================
    # CELULAR
    # ==========================================
    celular = models.CharField(
        max_length=20,
        validators=[validar_celular],
        verbose_name='Número de celular',
        help_text='Formato Ecuador: 09XXXXXXXX o +593XXXXXXXXX | Internacional: +código país + número'
    )

    # ==========================================
    # CAMPOS OPCIONALES
    # ==========================================
    fecha_nacimiento = models.DateField(
        blank=True,
        null=True,
        verbose_name='Fecha de nacimiento',
        help_text='Opcional: Fecha de nacimiento del usuario'
    )

    # ==========================================
    # SISTEMA DE ROLES
    # ==========================================

    class RolChoices(models.TextChoices):
        """Roles disponibles en el sistema"""
        CLIENTE = 'cliente', 'Cliente'
        PROVEEDOR = 'proveedor', 'Proveedor'
        REPARTIDOR = 'repartidor', 'Repartidor'
        ADMIN = 'admin', 'Administrador'

    tipo_usuario = models.CharField(
        max_length=20,
        choices=RolChoices.choices,
        default=RolChoices.CLIENTE,
        verbose_name='Tipo de Usuario',
        help_text='Tipo principal de cuenta del usuario'
    )

    roles_aprobados = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Roles Aprobados',
        help_text='Lista de roles aprobados: ["cliente", "proveedor", "repartidor", "admin"]'
    )

    rol_activo = models.CharField(
        max_length=20,
        choices=RolChoices.choices,
        default=RolChoices.CLIENTE,
        verbose_name='Rol Activo',
        help_text='Rol actualmente seleccionado por el usuario'
    )

    # ==========================================
    # TÉRMINOS Y CONDICIONES
    # ==========================================
    terminos_aceptados = models.BooleanField(
        default=False,
        verbose_name='Términos y condiciones',
        help_text='Usuario acepta términos y condiciones'
    )

    terminos_fecha_aceptacion = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Fecha de aceptación de términos',
        help_text='Fecha y hora cuando el usuario aceptó los términos'
    )

    terminos_version_aceptada = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        default='1.0',
        verbose_name='Versión de términos aceptada',
        help_text='Versión de los términos y condiciones aceptados'
    )

    terminos_ip_aceptacion = models.GenericIPAddressField(
        blank=True,
        null=True,
        verbose_name='IP de aceptación',
        help_text='Dirección IP desde donde se aceptaron los términos'
    )

    # ==========================================
    # PREFERENCIAS DE NOTIFICACIONES
    # ==========================================
    notificaciones_email = models.BooleanField(
        default=True,
        verbose_name='Recibir notificaciones por email',
        help_text='Si está desactivado, no recibirá correos de la plataforma'
    )

    notificaciones_marketing = models.BooleanField(
        default=True,
        verbose_name='Recibir emails de marketing',
        help_text='Promociones, ofertas especiales y novedades'
    )

    notificaciones_push = models.BooleanField(
        default=True,
        verbose_name='Notificaciones push',
        help_text='Notificaciones push en la aplicación móvil'
    )

    modo_silencio = models.BooleanField(
        default=False,
        verbose_name='Modo silencio',
        help_text='Si está activado, la app no emitirá sonidos'
    )

    # ==========================================
    # RECUPERACIÓN DE CONTRASEÑA (SEGURA)
    # ==========================================
    reset_password_code = models.CharField(
        max_length=128,
        blank=True,
        null=True,
        verbose_name='Código de recuperación (hasheado)',
        help_text='Hash del código de 6 dígitos para resetear contraseña'
    )

    reset_password_expire = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Expiración del código',
        help_text='Fecha límite para usar el código (15 minutos)',
        db_index=True
    )

    reset_password_attempts = models.IntegerField(
        default=0,
        verbose_name='Intentos de verificación del código',
        help_text='Contador de intentos fallidos al verificar código de recuperación'
    )

    # ==========================================
    # AUDITORÍA Y TIMESTAMPS
    # ==========================================
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Fecha de creación'
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Última actualización'
    )

    # ==========================================
    # ESTADO DE CUENTA
    # ==========================================
    cuenta_desactivada = models.BooleanField(
        default=False,
        verbose_name='Cuenta desactivada',
        help_text='Usuario desactivó su cuenta voluntariamente'
    )

    fecha_desactivacion = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Fecha de desactivación',
        help_text='Fecha cuando el usuario desactivó su cuenta'
    )

    razon_desactivacion = models.TextField(
        blank=True,
        null=True,
        verbose_name='Razón de desactivación',
        help_text='Motivo por el cual el usuario desactivó su cuenta'
    )

    # ==========================================
    # SEGURIDAD Y LOGS
    # ==========================================
    intentos_login_fallidos = models.IntegerField(
        default=0,
        verbose_name='Intentos de login fallidos',
        help_text='Contador de intentos fallidos de inicio de sesión'
    )

    cuenta_bloqueada_hasta = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name='Cuenta bloqueada hasta',
        help_text='Fecha hasta la cual la cuenta está temporalmente bloqueada'
    )

    ultimo_login_ip = models.GenericIPAddressField(
        blank=True,
        null=True,
        verbose_name='IP del último login',
        help_text='Dirección IP del último inicio de sesión exitoso'
    )

    # ==========================================
    # CONFIGURACIÓN DEL MODELO
    # ==========================================
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name', 'celular']

    class Meta:
        db_table = 'users'
        verbose_name = 'Usuario'
        verbose_name_plural = 'Usuarios'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['username']),
            models.Index(fields=['celular']),
            models.Index(fields=['tipo_usuario']),
            models.Index(fields=['rol_activo']),
            models.Index(fields=['cuenta_desactivada']),
            models.Index(fields=['reset_password_expire']),
        ]

    def __str__(self):
        return f"{self.email} - {self.get_full_name()} ({self.get_tipo_usuario_display()})"

    # ==========================================
    # MÉTODOS DE INFORMACIÓN BÁSICA
    # ==========================================

    def get_full_name(self):
        """Retorna el nombre completo del usuario"""
        return f"{self.first_name} {self.last_name}".strip()

    def get_short_name(self):
        """Retorna el nombre corto del usuario"""
        return self.first_name

    def get_edad(self):
        """Calcula la edad del usuario basándose en su fecha de nacimiento"""
        if not self.fecha_nacimiento:
            return None
        
        hoy = date.today()
        edad = hoy.year - self.fecha_nacimiento.year
        
        # Ajustar si aún no ha cumplido años este año
        if (hoy.month, hoy.day) < (self.fecha_nacimiento.month, self.fecha_nacimiento.day):
            edad -= 1
        
        return edad

    @property
    def nombre_completo(self):
        """Alias para get_full_name"""
        return self.get_full_name()

    @property
    def iniciales(self):
        """Retorna las iniciales del usuario"""
        if self.first_name and self.last_name:
            return f"{self.first_name[0]}{self.last_name[0]}".upper()
        return self.email[0:2].upper()

    # ==========================================
    # PROPIEDADES DE ROLES
    # ==========================================

    @property
    def es_cliente(self):
        """Verifica si el usuario tiene rol de cliente"""
        return 'cliente' in self.roles_aprobados

    @property
    def es_proveedor(self):
        """Verifica si el usuario tiene rol de proveedor"""
        return 'proveedor' in self.roles_aprobados

    @property
    def es_repartidor(self):
        """Verifica si el usuario tiene rol de repartidor"""
        return 'repartidor' in self.roles_aprobados

    @property
    def es_admin(self):
        """Verifica si el usuario tiene rol de administrador"""
        return 'admin' in self.roles_aprobados or self.is_superuser

    @property
    def rol_activo_es_cliente(self):
        """Verifica si el rol activo es cliente"""
        return self.rol_activo == 'cliente'

    @property
    def rol_activo_es_proveedor(self):
        """Verifica si el rol activo es proveedor"""
        return self.rol_activo == 'proveedor'

    @property
    def rol_activo_es_repartidor(self):
        """Verifica si el rol activo es repartidor"""
        return self.rol_activo == 'repartidor'

    @property
    def rol_activo_es_admin(self):
        """Verifica si el rol activo es administrador"""
        return self.rol_activo == 'admin'

    # ==========================================
    # MÉTODOS DE GESTIÓN DE ROLES
    # ==========================================

    def agregar_rol(self, rol):
        """
        Agrega un rol a la lista de roles aprobados
        
        Args:
            rol (str): Rol a agregar ('cliente', 'proveedor', 'repartidor', 'admin')
        
        Returns:
            bool: True si se agregó, False si ya existía
        """
        roles_validos = ['cliente', 'proveedor', 'repartidor', 'admin']
        if rol not in roles_validos:
            logger.warning(f"Intento de agregar rol inválido: {rol}")
            return False
        
        if rol not in self.roles_aprobados:
            self.roles_aprobados = self.roles_aprobados + [rol]
            self.save(update_fields=['roles_aprobados', 'updated_at'])
            logger.info(f"Rol '{rol}' agregado a usuario {self.email}")
            return True
        return False

    def remover_rol(self, rol):
        """
        Remueve un rol de la lista de roles aprobados
        
        Args:
            rol (str): Rol a remover
        
        Returns:
            bool: True si se removió, False si no existía o es cliente
        """
        # No permitir remover el rol cliente
        if rol == 'cliente':
            logger.warning(f"Intento de remover rol 'cliente' de {self.email}")
            return False
        
        if rol in self.roles_aprobados:
            self.roles_aprobados = [r for r in self.roles_aprobados if r != rol]
            
            # Si el rol activo era el removido, cambiar a cliente
            if self.rol_activo == rol:
                self.rol_activo = 'cliente'
            
            self.save(update_fields=['roles_aprobados', 'rol_activo', 'updated_at'])
            logger.info(f"Rol '{rol}' removido de usuario {self.email}")
            return True
        return False

    def cambiar_rol_activo(self, nuevo_rol):
        """
        Cambia el rol activo del usuario
        
        Args:
            nuevo_rol (str): Nuevo rol a activar
        
        Returns:
            bool: True si se cambió, False si no tiene el rol
        """
        if nuevo_rol not in self.roles_aprobados:
            logger.warning(
                f"Usuario {self.email} intentó cambiar a rol '{nuevo_rol}' "
                f"sin tenerlo aprobado. Roles: {self.roles_aprobados}"
            )
            return False
        
        self.rol_activo = nuevo_rol
        self.save(update_fields=['rol_activo', 'updated_at'])
        logger.info(f"Usuario {self.email} cambió rol activo a '{nuevo_rol}'")
        return True

    def tiene_rol(self, rol):
        """
        Verifica si el usuario tiene un rol específico
        
        Args:
            rol (str): Rol a verificar
        
        Returns:
            bool: True si tiene el rol
        """
        return rol in self.roles_aprobados

    def obtener_roles_disponibles(self):
        """
        Retorna los roles que el usuario puede activar
        
        Returns:
            list: Lista de roles aprobados
        """
        return self.roles_aprobados.copy()

    # ==========================================
    # MÉTODOS DE SEGURIDAD
    # ==========================================

    def registrar_login_exitoso(self, ip_address=None):
        """
        Registra un login exitoso y resetea contadores de seguridad
        
        Args:
            ip_address (str): Dirección IP del login
        """
        self.intentos_login_fallidos = 0
        self.cuenta_bloqueada_hasta = None
        
        if ip_address:
            self.ultimo_login_ip = ip_address
        
        self.last_login = timezone.now()
        self.save(update_fields=[
            'intentos_login_fallidos',
            'cuenta_bloqueada_hasta',
            'ultimo_login_ip',
            'last_login',
            'updated_at'
        ])
        
        logger.info(f"Login exitoso: {self.email} desde IP {ip_address}")

    def registrar_login_fallido(self):
        """
        Registra un intento de login fallido y bloquea la cuenta si es necesario
        """
        self.intentos_login_fallidos += 1
        
        # Bloquear cuenta después de 5 intentos fallidos
        if self.intentos_login_fallidos >= 5:
            self.cuenta_bloqueada_hasta = timezone.now() + timedelta(minutes=30)
            logger.warning(
                f"Cuenta bloqueada por intentos fallidos: {self.email} "
                f"({self.intentos_login_fallidos} intentos)"
            )
        
        self.save(update_fields=[
            'intentos_login_fallidos',
            'cuenta_bloqueada_hasta',
            'updated_at'
        ])

    def esta_bloqueado(self):
        """
        Verifica si la cuenta está temporalmente bloqueada
        
        Returns:
            bool: True si está bloqueada
        """
        if not self.cuenta_bloqueada_hasta:
            return False
        
        if timezone.now() < self.cuenta_bloqueada_hasta:
            return True
        
        # Si ya pasó el tiempo de bloqueo, resetear
        self.intentos_login_fallidos = 0
        self.cuenta_bloqueada_hasta = None
        self.save(update_fields=[
            'intentos_login_fallidos',
            'cuenta_bloqueada_hasta',
            'updated_at'
        ])
        
        return False

    # ==========================================
    # MÉTODOS DE RECUPERACIÓN DE CONTRASEÑA
    # ==========================================

    def generar_codigo_recuperacion(self):
        """
        Genera y guarda un código de 6 dígitos para recuperación de contraseña
        
        Returns:
            str: Código de 6 dígitos en texto plano (para enviar por email)
        """
        from django.contrib.auth.hashers import make_password
        import random
        
        # Generar código aleatorio de 6 dígitos
        codigo = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        
        # Guardar hash del código (nunca guardar en texto plano)
        self.reset_password_code = make_password(codigo)
        self.reset_password_expire = timezone.now() + timedelta(minutes=15)
        self.reset_password_attempts = 0
        
        self.save(update_fields=[
            'reset_password_code',
            'reset_password_expire',
            'reset_password_attempts',
            'updated_at'
        ])
        
        logger.info(f"Código de recuperación generado para: {self.email}")
        
        return codigo  # Retornar código en texto plano para enviar por email

    def verificar_codigo_recuperacion(self, codigo):
        """
        Verifica si el código de recuperación es válido
        
        Args:
            codigo (str): Código de 6 dígitos a verificar
        
        Returns:
            tuple: (es_valido: bool, mensaje: str)
        """
        from django.contrib.auth.hashers import check_password
        
        # Verificar si hay un código generado
        if not self.reset_password_code:
            return (False, "No hay código de recuperación activo")
        
        # Verificar expiración
        if not self.reset_password_expire or timezone.now() > self.reset_password_expire:
            return (False, "El código ha expirado")
        
        # Verificar intentos
        if self.reset_password_attempts >= 5:
            return (False, "Demasiados intentos fallidos. Solicita un nuevo código")
        
        # Verificar código
        if check_password(codigo, self.reset_password_code):
            logger.info(f"Código verificado correctamente: {self.email}")
            return (True, "Código válido")
        
        # Incrementar intentos fallidos
        self.reset_password_attempts += 1
        self.save(update_fields=['reset_password_attempts', 'updated_at'])
        
        logger.warning(
            f"Código incorrecto para {self.email} "
            f"(intento {self.reset_password_attempts}/5)"
        )
        
        return (False, "Código incorrecto")

    def limpiar_codigo_recuperacion(self):
        """Limpia el código de recuperación después de usar"""
        self.reset_password_code = None
        self.reset_password_expire = None
        self.reset_password_attempts = 0
        self.save(update_fields=[
            'reset_password_code',
            'reset_password_expire',
            'reset_password_attempts',
            'updated_at'
        ])

    # ==========================================
    # MÉTODOS DE GESTIÓN DE CUENTA
    # ==========================================

    def desactivar_cuenta(self, razon=''):
        """
        Desactiva la cuenta del usuario
        
        Args:
            razon (str): Razón de desactivación
        """
        self.cuenta_desactivada = True
        self.fecha_desactivacion = timezone.now()
        self.razon_desactivacion = razon
        self.is_active = False
        
        self.save(update_fields=[
            'cuenta_desactivada',
            'fecha_desactivacion',
            'razon_desactivacion',
            'is_active',
            'updated_at'
        ])
        
        logger.info(f"Cuenta desactivada: {self.email}")

    def reactivar_cuenta(self):
        """Reactiva una cuenta previamente desactivada"""
        self.cuenta_desactivada = False
        self.fecha_desactivacion = None
        self.razon_desactivacion = None
        self.is_active = True
        
        self.save(update_fields=[
            'cuenta_desactivada',
            'fecha_desactivacion',
            'razon_desactivacion',
            'is_active',
            'updated_at'
        ])
        
        logger.info(f"Cuenta reactivada: {self.email}")

    # ==========================================
    # MÉTODOS DE NOTIFICACIONES
    # ==========================================

    def puede_recibir_emails(self):
        """
        Verifica si el usuario puede recibir emails
        
        Returns:
            bool: True si puede recibir emails
        """
        return (
            self.is_active and 
            not self.cuenta_desactivada and 
            self.notificaciones_email
        )

    def puede_recibir_marketing(self):
        """
        Verifica si el usuario acepta emails de marketing
        
        Returns:
            bool: True si acepta marketing
        """
        return (
            self.puede_recibir_emails() and 
            self.notificaciones_marketing
        )

    def puede_recibir_push(self):
        """
        Verifica si el usuario acepta notificaciones push
        
        Returns:
            bool: True si acepta push
        """
        return (
            self.is_active and 
            not self.cuenta_desactivada and 
            self.notificaciones_push
        )

    # ==========================================
    # VALIDACIONES
    # ==========================================

    def clean(self):
        """Validaciones personalizadas del modelo"""
        super().clean()
        
        # Validar formato de email
        if self.email:
            self.email = self.email.lower().strip()
        
        # Validar edad mínima
        if self.fecha_nacimiento:
            edad = self.get_edad()
            if edad and edad < 18:
                raise ValidationError({
                    'fecha_nacimiento': 'Debes ser mayor de 18 años para registrarte'
                })
        
        # Validar rol activo está en roles aprobados
        if self.rol_activo and self.roles_aprobados:
            if self.rol_activo not in self.roles_aprobados:
                raise ValidationError({
                    'rol_activo': f"El rol '{self.rol_activo}' no está en los roles aprobados"
                })

    def save(self, *args, **kwargs):
        """Override save para normalizar datos y asegurar consistencia"""
        # Limpiar espacios en blanco
        if self.first_name:
            self.first_name = self.first_name.strip()
        if self.last_name:
            self.last_name = self.last_name.strip()
        if self.username:
            self.username = self.username.strip().lower()
        if self.email:
            self.email = self.email.strip().lower()
        
        # Asegurar que roles_aprobados sea una lista válida
        if not self.roles_aprobados:
            self.roles_aprobados = ['cliente']
        
        # Asegurar que cliente siempre esté en roles_aprobados
        if 'cliente' not in self.roles_aprobados:
            self.roles_aprobados = ['cliente'] + self.roles_aprobados
        
        # Asegurar que rol_activo esté en roles_aprobados
        if self.rol_activo not in self.roles_aprobados:
            self.rol_activo = 'cliente'
        
        # Generar username si no existe
        if not self.username and self.email:
            base_username = self.email.split('@')[0]
            username = base_username
            counter = 1
            while User.objects.filter(username=username).exclude(pk=self.pk).exists():
                username = f"{base_username}{counter}"
                counter += 1
            self.username = username

        super().save(*args, **kwargs)

    # ==========================================
    # MÉTODOS ESTÁTICOS
    # ==========================================

    @staticmethod
    def validar_password(password):
        """
        Valida que la contraseña tenga al menos 5 caracteres

        Args:
            password (str): Contraseña a validar

        Returns:
            bool: True si es válida

        Raises:
            ValidationError: Si no cumple requisitos
        """
        if len(password) < 5:
            raise ValidationError('La contraseña debe tener al menos 5 caracteres')

        return True
