# -*- coding: utf-8 -*-
# usuarios/models.py

import uuid
import logging
from django.db import models, transaction
from django.core.validators import (
    MinValueValidator,
    MaxValueValidator,
    FileExtensionValidator,
)
from django.core.exceptions import ValidationError
from django.db.models.signals import post_save, pre_save, pre_delete
from django.dispatch import receiver
from django.core.files.storage import default_storage
from django.utils import timezone
from authentication.models import User

# Configuración de Logging
logger = logging.getLogger("usuarios")


# ============================================
# VALIDADORES PERSONALIZADOS
# ============================================

def validar_tamano_imagen(imagen):
    """Valida que la imagen no exceda 5MB."""
    limite_mb = 5
    if imagen.size > limite_mb * 1024 * 1024:
        raise ValidationError(f"La imagen no puede superar {limite_mb}MB.")


def validar_coordenadas_ecuador(latitud, longitud):
    """
    Valida que las coordenadas estén dentro del territorio ecuatoriano
    continental o insular (Galápagos).
    """
    # Validación de punto cero (error común de GPS)
    if latitud == 0.0 and longitud == 0.0:
        raise ValidationError({
            "latitud": "Coordenadas invalidas (0,0).",
            "longitud": "Por favor, selecciona una ubicacion valida."
        })

    # Límites geográficos aproximados (Bounding Boxes)
    es_continental = (-5.0 <= latitud <= 2.0) and (-81.0 <= longitud <= -75.0)
    es_galapagos = (-1.5 <= latitud <= 1.5) and (-92.0 <= longitud <= -89.0)

    if not (es_continental or es_galapagos):
        raise ValidationError({
            "latitud": "Las coordenadas estan fuera del territorio ecuatoriano.",
            "longitud": "Verifica tu ubicacion en el mapa."
        })


# ============================================
# MODELO: PERFIL
# ============================================

class Perfil(models.Model):
    """
    Perfil extendido del usuario. Maneja estadísticas,
    notificaciones push (FCM) y datos de fidelización.
    """
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="perfil"
    )

    foto_perfil = models.ImageField(
        upload_to="perfiles/%Y/%m/",
        blank=True,
        null=True,
        verbose_name="Foto de perfil",
        validators=[
            FileExtensionValidator(["jpg", "jpeg", "png", "webp"]),
            validar_tamano_imagen,
        ],
    )

    fecha_nacimiento = models.DateField(
        blank=True, null=True, verbose_name="Fecha de nacimiento"
    )

    # --- Notificaciones Push (FCM) ---
    fcm_token = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        db_index=True,
        verbose_name="Token FCM",
        help_text="Token para notificaciones push"
    )
    fcm_token_actualizado = models.DateTimeField(
        null=True, blank=True, verbose_name="Ultima actualizacion token"
    )

    # --- Sistema de Calificaciones ---
    calificacion = models.FloatField(
        default=5.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)],
        verbose_name="Calificacion promedio",
        db_index=True
    )
    total_resenas = models.IntegerField(default=0, verbose_name="Total de resenas")

    # --- Estadísticas y Fidelización ---
    total_pedidos = models.IntegerField(default=0, verbose_name="Total pedidos")
    
    pedidos_mes_actual = models.IntegerField(
        default=0,
        verbose_name="Pedidos mes actual",
        db_index=True
    )
    ultima_actualizacion_mes = models.DateField(
        auto_now_add=True, verbose_name="Ultima actualizacion mes"
    )
    participa_en_sorteos = models.BooleanField(
        default=True, verbose_name="Participa en sorteos"
    )

    # --- Preferencias ---
    notificaciones_pedido = models.BooleanField(
        default=True, verbose_name="Notificaciones de pedido"
    )
    notificaciones_promociones = models.BooleanField(
        default=True, verbose_name="Notificaciones de promociones"
    )

    # --- Auditoría ---
    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "perfiles_usuario"
        verbose_name = "Perfil de Usuario"
        verbose_name_plural = "Perfiles de Usuarios"
        indexes = [
            models.Index(fields=["user", "participa_en_sorteos"]),
        ]

    def __str__(self):
        return f"Perfil: {self.user.email}"

    # --- Lógica de Negocio ---

    def actualizar_fcm_token(self, token):
        """Actualiza el token FCM asegurando unicidad."""
        if not token or not token.strip():
            return False

        try:
            with transaction.atomic():
                # Evitar duplicados: limpiar este token de otros usuarios
                if self.fcm_token != token:
                    Perfil.objects.select_for_update().filter(fcm_token=token).exclude(
                        user=self.user
                    ).update(fcm_token=None, fcm_token_actualizado=None)

                self.fcm_token = token
                self.fcm_token_actualizado = timezone.now()
                self.save(update_fields=["fcm_token", "fcm_token_actualizado", "actualizado_en"])
            
            return True
        except Exception as e:
            logger.error(f"Error actualizando FCM para {self.user.email}: {e}")
            return False

    def eliminar_fcm_token(self):
        """Elimina el token FCM (Logout)."""
        self.fcm_token = None
        self.fcm_token_actualizado = None
        self.save(update_fields=["fcm_token", "fcm_token_actualizado", "actualizado_en"])

    def actualizar_calificacion(self, nueva_calificacion):
        """Recalcula el promedio de calificación de forma incremental."""
        if not (1 <= nueva_calificacion <= 5):
            raise ValidationError("Calificacion debe estar entre 1 y 5")

        # Cálculo incremental para precisión
        total_puntos = (self.calificacion * self.total_resenas) + nueva_calificacion
        self.total_resenas += 1
        self.calificacion = round(total_puntos / self.total_resenas, 2)
        self.save(update_fields=["calificacion", "total_resenas", "actualizado_en"])

    def incrementar_pedidos(self):
        """Incrementa contadores y maneja el reset mensual."""
        hoy = timezone.now().date()
        
        # Reset mensual si cambio el mes
        if (self.ultima_actualizacion_mes.month != hoy.month or 
            self.ultima_actualizacion_mes.year != hoy.year):
            self.pedidos_mes_actual = 0
            self.ultima_actualizacion_mes = hoy

        self.total_pedidos += 1
        self.pedidos_mes_actual += 1
        self.save(update_fields=["total_pedidos", "pedidos_mes_actual", "ultima_actualizacion_mes", "actualizado_en"])

    def resetear_mes(self):
        """Reseteo manual/administrativo del contador mensual."""
        self.pedidos_mes_actual = 0
        self.ultima_actualizacion_mes = timezone.now().date()
        self.save(update_fields=["pedidos_mes_actual", "ultima_actualizacion_mes", "actualizado_en"])

    # --- Propiedades ---

    @property
    def puede_participar_rifa(self):
        return self.participa_en_sorteos and self.pedidos_mes_actual >= 3

    @property
    def es_cliente_frecuente(self):
        return self.total_pedidos >= 10

    @property
    def edad(self):
        if self.fecha_nacimiento:
            today = timezone.now().date()
            return today.year - self.fecha_nacimiento.year - (
                (today.month, today.day) < (self.fecha_nacimiento.month, self.fecha_nacimiento.day)
            )
        return None

    def clean(self):
        if self.fecha_nacimiento and self.fecha_nacimiento > timezone.now().date():
            raise ValidationError({"fecha_nacimiento": "La fecha no puede ser futura."})
        if self.edad is not None and self.edad < 13:
            raise ValidationError({"fecha_nacimiento": "Edad minima requerida: 13 años."})


# ============================================
# MODELO: DIRECCIÓN FAVORITA
# ============================================

class DireccionFavorita(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="direcciones_favoritas")
    
    TIPO_CHOICES = [("casa", "Casa"), ("trabajo", "Trabajo"), ("otro", "Otro")]
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default="otro")
    
    etiqueta = models.CharField(max_length=50, blank=True)
    direccion = models.TextField(verbose_name="Dirección completa")
    referencia = models.CharField(max_length=200, blank=True)
    calle_secundaria = models.CharField(max_length=200, blank=True)
    piso_apartamento = models.CharField(max_length=100, blank=True)
    telefono_contacto = models.CharField(max_length=30, blank=True)
    indicaciones = models.CharField(max_length=300, blank=True)
    ciudad = models.CharField(max_length=100, blank=True)

    latitud = models.FloatField(validators=[MinValueValidator(-90.0), MaxValueValidator(90.0)])
    longitud = models.FloatField(validators=[MinValueValidator(-180.0), MaxValueValidator(180.0)])

    es_predeterminada = models.BooleanField(default=False, db_index=True)
    activa = models.BooleanField(default=True, db_index=True)
    
    veces_usada = models.IntegerField(default=0)
    ultimo_uso = models.DateTimeField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "direcciones_favoritas"
        verbose_name = "Dirección Favorita"
        unique_together = [["user", "etiqueta"]]
        ordering = ["-es_predeterminada", "-ultimo_uso"]

    def __str__(self):
        return f"{self.etiqueta} - {self.user.email}"

    def clean(self):
        validar_coordenadas_ecuador(self.latitud, self.longitud)
        if self.es_predeterminada and self.pk:
            # Validar que no haya duplicados al editar
            conflictos = DireccionFavorita.objects.filter(
                user=self.user, es_predeterminada=True, activa=True
            ).exclude(pk=self.pk)
            if conflictos.exists():
                raise ValidationError("Ya existe una dirección predeterminada.")

    def save(self, *args, **kwargs):
        self.full_clean()
        with transaction.atomic():
            # Auto-asignar predeterminada si es la primera activa
            if not self.pk and not DireccionFavorita.objects.filter(user=self.user, activa=True).exists():
                self.es_predeterminada = True

            # Gestión de exclusividad de predeterminada
            if self.es_predeterminada:
                DireccionFavorita.objects.select_for_update().filter(
                    user=self.user, es_predeterminada=True
                ).exclude(pk=self.pk).update(es_predeterminada=False)

            super().save(*args, **kwargs)

    @property
    def direccion_completa_texto(self):
        partes = [self.direccion]
        if self.calle_secundaria:
            partes.append(self.calle_secundaria)
        if self.piso_apartamento:
            partes.append(self.piso_apartamento)
        if self.referencia:
            partes.append(self.referencia)
        return " - ".join(partes)


# ============================================
# MODELO: MÉTODO DE PAGO
# ============================================

class MetodoPago(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="metodos_pago")
    
    TIPO_CHOICES = [("efectivo", "Efectivo"), ("transferencia", "Transferencia")]
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default="efectivo")
    alias = models.CharField(max_length=50)
    
    comprobante_pago = models.ImageField(
        upload_to="comprobantes/%Y/%m/", blank=True, null=True,
        validators=[FileExtensionValidator(["jpg", "jpeg", "png", "pdf"]), validar_tamano_imagen]
    )
    observaciones = models.CharField(max_length=100, blank=True)
    
    es_predeterminado = models.BooleanField(default=False, db_index=True)
    activo = models.BooleanField(default=True, db_index=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "metodos_pago"
        verbose_name = "Método de Pago"
        unique_together = [["user", "alias"]]
        ordering = ["-es_predeterminado", "-created_at"]

    def clean(self):
        if self.tipo == "transferencia" and not self.comprobante_pago:
            raise ValidationError({"comprobante_pago": "Comprobante obligatorio para transferencias."})
        if self.tipo == "efectivo" and self.comprobante_pago:
            raise ValidationError({"comprobante_pago": "Efectivo no requiere comprobante."})

    def save(self, *args, **kwargs):
        self.full_clean()
        with transaction.atomic():
            if not self.pk and not MetodoPago.objects.filter(user=self.user, activo=True).exists():
                self.es_predeterminado = True

            if self.es_predeterminado:
                MetodoPago.objects.select_for_update().filter(
                    user=self.user, es_predeterminado=True
                ).exclude(pk=self.pk).update(es_predeterminado=False)

            super().save(*args, **kwargs)

    @property
    def tiene_comprobante(self):
        return bool(self.comprobante_pago)


# ============================================
# MODELO: UBICACIÓN DE USUARIO
# ============================================

class UbicacionUsuario(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="ubicacion_actual")
    latitud = models.FloatField()
    longitud = models.FloatField()
    actualizado_en = models.DateTimeField(auto_now=True, db_index=True)

    class Meta:
        db_table = "ubicaciones_usuario"
        verbose_name = "Ubicación de Usuario"

    def clean(self):
        validar_coordenadas_ecuador(self.latitud, self.longitud)


# ============================================
# MODELO: SOLICITUD CAMBIO ROL
# ============================================

class SolicitudCambioRol(models.Model):
    """
    Gestiona el flujo de aprobación para cambiar roles (Proveedor/Repartidor).
    Mantiene historial y permite reversión.
    """
    ESTADO_CHOICES = [
        ("PENDIENTE", "Pendiente"),
        ("ACEPTADA", "Aceptada"),
        ("RECHAZADA", "Rechazada"),
        ("REVERTIDA", "Revertida"),
    ]
    ROL_CHOICES = [
        ("PROVEEDOR", "Proveedor"),
        ("REPARTIDOR", "Repartidor"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="solicitudes_cambio_rol")
    
    rol_solicitado = models.CharField(max_length=20, choices=ROL_CHOICES)
    motivo = models.TextField(max_length=500)
    rol_anterior = models.CharField(max_length=20, blank=True)

    # --- Datos de Respuesta ---
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default="PENDIENTE", db_index=True)
    admin_responsable = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name="solicitudes_procesadas"
    )
    motivo_respuesta = models.TextField(blank=True)
    
    # --- Datos de Reversión ---
    revertido_en = models.DateTimeField(null=True, blank=True)
    revertido_por = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name="solicitudes_revertidas"
    )
    motivo_reversion = models.TextField(blank=True)

    # --- Campos Específicos (Proveedor) ---
    ruc = models.CharField(max_length=13, blank=True, null=True, db_index=True)
    nombre_comercial = models.CharField(max_length=200, blank=True)
    tipo_negocio = models.CharField(max_length=50, blank=True) # Choices simplificados
    descripcion_negocio = models.TextField(blank=True)
    horario_apertura = models.TimeField(blank=True, null=True)
    horario_cierre = models.TimeField(blank=True, null=True)

    # --- Campos Específicos (Repartidor) ---
    cedula_identidad = models.CharField(max_length=20, blank=True)
    tipo_vehiculo = models.CharField(max_length=50, blank=True)
    zona_cobertura = models.CharField(max_length=200, blank=True)
    disponibilidad = models.JSONField(default=dict, blank=True)

    # --- Auditoría ---
    creado_en = models.DateTimeField(auto_now_add=True, db_index=True)
    respondido_en = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "solicitudes_cambio_rol"
        verbose_name = "Solicitud Cambio Rol"
        verbose_name_plural = "Solicitudes Cambio Rol"
        ordering = ["-creado_en"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "rol_solicitado"],
                condition=models.Q(estado="PENDIENTE"),
                name="unique_pending_request"
            )
        ]

    def __str__(self):
        return f"{self.user.email} -> {self.rol_solicitado} ({self.estado})"

    # --- Lógica de Negocio (Encapsulada) ---

    def aceptar(self, admin, motivo=""):
        """Aprueba la solicitud y actualiza el rol del usuario."""
        with transaction.atomic():
            # Guardar rol actual para posible reversión
            self.rol_anterior = self.user.rol if hasattr(self.user, 'rol') else ''
            
            # Actualizar estado solicitud
            self.estado = "ACEPTADA"
            self.admin_responsable = admin
            self.motivo_respuesta = motivo
            self.respondido_en = timezone.now()
            self.save()

            # Aplicar cambio al usuario
            if hasattr(self.user, 'agregar_rol'):
                self.user.agregar_rol(self.rol_solicitado)
            else:
                # Fallback si no existe método helper
                self.user.rol = self.rol_solicitado 
                self.user.save(update_fields=['rol'])

    def rechazar(self, admin, motivo=""):
        """Rechaza la solicitud."""
        self.estado = "RECHAZADA"
        self.admin_responsable = admin
        self.motivo_respuesta = motivo
        self.respondido_en = timezone.now()
        self.save()

    def revertir(self, admin, motivo_reversion=""):
        """Revierte los cambios de una solicitud aceptada."""
        if self.estado != "ACEPTADA":
            raise ValidationError("Solo solicitudes ACEPTADAS pueden revertirse.")
        
        with transaction.atomic():
            # Restaurar rol usuario
            if self.rol_anterior:
                self.user.rol = self.rol_anterior
                self.user.save(update_fields=["rol"])
            
            # Actualizar estado solicitud
            self.estado = "REVERTIDA"
            self.revertido_por = admin
            self.revertido_en = timezone.now()
            self.motivo_reversion = motivo_reversion
            self.save()


# ============================================
# SEÑALES (Limpieza de Archivos)
# ============================================

@receiver(post_save, sender=User)
def crear_perfil_usuario(sender, instance, created, **kwargs):
    if created:
        Perfil.objects.get_or_create(user=instance)

@receiver(pre_save, sender=Perfil)
def limpiar_foto_perfil_update(sender, instance, **kwargs):
    """Borra la imagen anterior del storage si se actualiza."""
    if not instance.pk: return
    try:
        old = Perfil.objects.get(pk=instance.pk)
        if old.foto_perfil and old.foto_perfil != instance.foto_perfil:
            default_storage.delete(old.foto_perfil.name)
    except Perfil.DoesNotExist: pass

@receiver(pre_delete, sender=Perfil)
def limpiar_foto_perfil_delete(sender, instance, **kwargs):
    """Borra la imagen si se elimina el perfil."""
    if instance.foto_perfil:
        default_storage.delete(instance.foto_perfil.name)

@receiver(pre_save, sender=MetodoPago)
def limpiar_comprobante_update(sender, instance, **kwargs):
    if not instance.pk: return
    try:
        old = MetodoPago.objects.get(pk=instance.pk)
        if old.comprobante_pago and old.comprobante_pago != instance.comprobante_pago:
            default_storage.delete(old.comprobante_pago.name)
    except MetodoPago.DoesNotExist: pass

@receiver(pre_delete, sender=MetodoPago)
def limpiar_comprobante_delete(sender, instance, **kwargs):
    if instance.comprobante_pago:
        default_storage.delete(instance.comprobante_pago.name)
