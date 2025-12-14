# usuarios/serializers.py

import os
import re
import logging
from datetime import date
from rest_framework import serializers
from django.db import transaction
from django.utils import timezone
from .models import (
    Perfil,
    DireccionFavorita,
    MetodoPago,
    UbicacionUsuario,
    SolicitudCambioRol,
)
from django.contrib.auth import get_user_model
User = get_user_model()

logger = logging.getLogger("usuarios")

# ============================================
# CONSTANTES Y CONFIGURACIÓN
# ============================================

MAX_FILE_SIZE_MB = 5
MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024
ALLOWED_IMAGE_EXTENSIONS = [".jpg", ".jpeg", ".png", ".webp"]
ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp", "image/jpg"]

# Límites geográficos (Ecuador)
LAT_MIN, LAT_MAX = -5.0, 2.0
LON_MIN, LON_MAX = -92.0, -75.0

# ============================================
# MIXINS Y UTILIDADES
# ============================================

class ImageFieldMixin:
    """Mixin para procesar URLs absolutas de imágenes."""
    
    def get_image_url(self, image_field):
        if image_field:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(image_field.url)
            return image_field.url
        return None

def validar_archivo_imagen(value):
    """Validador reutilizable para imágenes."""
    if not value:
        return value

    if value.size > MAX_FILE_SIZE_BYTES:
        raise serializers.ValidationError(
            f"El archivo excede el tamaño máximo permitido de {MAX_FILE_SIZE_MB}MB."
        )

    ext = os.path.splitext(value.name)[1].lower()
    if ext not in ALLOWED_IMAGE_EXTENSIONS:
        raise serializers.ValidationError(
            f"Formato no permitido. Use: {', '.join(ALLOWED_IMAGE_EXTENSIONS)}"
        )

    if hasattr(value, "content_type") and value.content_type not in ALLOWED_MIME_TYPES:
         # Permitir PDF solo si es explícitamente necesario en otros contextos, 
         # aquí restringimos a imágenes por defecto.
        raise serializers.ValidationError("El archivo no es una imagen válida.")
    
    return value

# ============================================
# SERIALIZERS: PERFIL
# ============================================
# Modificación en usuarios/serializers.py
class PerfilSerializer(ImageFieldMixin, serializers.ModelSerializer):
    usuario_email = serializers.CharField(source="user.email", read_only=True)
    usuario_nombre = serializers.CharField(source="user.get_full_name", read_only=True)
    telefono = serializers.CharField(source="user.celular", read_only=True)
    edad = serializers.IntegerField(read_only=True)
    foto_perfil = serializers.SerializerMethodField()
    total_direcciones = serializers.SerializerMethodField()
    total_metodos_pago = serializers.SerializerMethodField()
    
    class Meta:
        model = Perfil
        fields = [
            "id", "usuario_email", "usuario_nombre", "foto_perfil", "telefono",
            "fecha_nacimiento", "edad", "calificacion", "total_resenas",
            "total_pedidos", "pedidos_mes_actual",
            "es_cliente_frecuente", "puede_participar_rifa",
            "notificaciones_pedido", "notificaciones_promociones",
            "fcm_token_actualizado",
            "total_direcciones", "total_metodos_pago",
            "creado_en", "actualizado_en",
        ]
        read_only_fields = fields  

    def get_foto_perfil(self, obj):
        return self.get_image_url(obj.foto_perfil)
   
    def get_total_direcciones(self, obj):
        """Calcula el total de direcciones activas del usuario."""
        return obj.user.direcciones_favoritas.filter(activa=True).count()
        
    def get_total_metodos_pago(self, obj):
        return obj.user.metodos_pago.filter(activo=True).count()
class PerfilPublicoSerializer(ImageFieldMixin, serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source="user.get_full_name", read_only=True)
    foto_perfil = serializers.SerializerMethodField()

    class Meta:
        model = Perfil
        fields = ["usuario_nombre", "foto_perfil", "calificacion", "total_resenas", "total_pedidos"]

    def get_foto_perfil(self, obj):
        return self.get_image_url(obj.foto_perfil)


class ActualizarPerfilSerializer(serializers.ModelSerializer):
    # 1. Mapeamos los campos del modelo User para que sean editables
    first_name = serializers.CharField(source='user.first_name', required=False, label="Nombre")
    last_name = serializers.CharField(source='user.last_name', required=False, label="Apellido")
    email = serializers.EmailField(source='user.email', required=False, label="Correo Electrónico")

    class Meta:
        model = Perfil
        fields = [
            "first_name", "last_name", "email", # <--- Nuevos campos editables
            "foto_perfil", "fecha_nacimiento", 
            "notificaciones_pedido", "notificaciones_promociones", 
            "participa_en_sorteos"
        ]

    # 2. Validación de seguridad para el Email
    def validate_email(self, value):
        """Evita que el usuario use un correo que ya pertenece a otro."""
        user = self.instance.user
        if User.objects.filter(email=value).exclude(pk=user.pk).exists():
            raise serializers.ValidationError("Este correo electrónico ya está en uso por otro usuario.")
        return value

    def validate_fecha_nacimiento(self, value):
        if not value:
            return value
            
        today = date.today()
        if value > today:
            raise serializers.ValidationError("La fecha de nacimiento no puede ser futura.")

        edad = today.year - value.year - ((today.month, today.day) < (value.month, value.day))
        if edad < 13:
            raise serializers.ValidationError("Debes tener al menos 13 años para usar la aplicación.")
        return value

    def validate_foto_perfil(self, value):
        return validar_archivo_imagen(value)

    # 3. Lógica de Guardado en dos tablas (User y Perfil)
    @transaction.atomic
    def update(self, instance, validated_data):
        # Extraemos los datos anidados del usuario (vienen en el diccionario 'user')
        user_data = validated_data.pop('user', {})
        
        # A. Actualizamos el modelo User (Tabla de autenticación)
        user = instance.user
        has_user_changes = False
        
        if 'first_name' in user_data:
            user.first_name = user_data['first_name']
            has_user_changes = True
            
        if 'last_name' in user_data:
            user.last_name = user_data['last_name']
            has_user_changes = True
            
        if 'email' in user_data:
            user.email = user_data['email']
            # Opcional: user.username = user_data['email'] # Si usas email como username
            has_user_changes = True

        if has_user_changes:
            user.save()

        # B. Actualizamos el modelo Perfil (Tabla de datos extra)
        # El método super().update maneja los campos restantes (foto, fecha, notificaciones)
        return super().update(instance, validated_data)


# ============================================
# SERIALIZERS: DIRECCIONES
# ============================================

class DireccionFavoritaSerializer(serializers.ModelSerializer):
    direccion_completa = serializers.CharField(read_only=True)
    tipo_display = serializers.CharField(source="get_tipo_display", read_only=True)

    class Meta:
        model = DireccionFavorita
        fields = [
            "id", "tipo", "tipo_display", "etiqueta", "direccion", "referencia",
            "calle_secundaria", "piso_apartamento", "telefono_contacto", "indicaciones",
            "latitud", "longitud", "ciudad", "es_predeterminada", "activa",
            "veces_usada", "ultimo_uso", "direccion_completa", "created_at", "updated_at"
        ]
        read_only_fields = ["id", "veces_usada", "ultimo_uso", "direccion_completa", "created_at", "updated_at"]


class CrearDireccionSerializer(serializers.ModelSerializer):
    etiqueta = serializers.CharField(required=False, allow_blank=True, max_length=50)

    class Meta:
        model = DireccionFavorita
        fields = [
            "tipo", "etiqueta", "direccion", "referencia",
            "calle_secundaria", "piso_apartamento", "telefono_contacto", "indicaciones",
            "latitud", "longitud", "ciudad", "es_predeterminada"
        ]

    def validate_latitud(self, value):
        if not (LAT_MIN <= value <= LAT_MAX):
            raise serializers.ValidationError("La latitud está fuera del territorio permitido.")
        return value

    def validate_longitud(self, value):
        if not (LON_MIN <= value <= LON_MAX):
            raise serializers.ValidationError("La longitud está fuera del territorio permitido.")
        return value

    def validate(self, data):
        user = self.context["request"].user
        etiqueta = data.get("etiqueta")

        # Generación o validación de etiqueta
        if not etiqueta or not str(etiqueta).strip():
            data["etiqueta"] = self._generar_etiqueta_optimizada(user)
        else:
            etiqueta = str(etiqueta).strip()
            data["etiqueta"] = etiqueta
            if DireccionFavorita.objects.filter(user=user, etiqueta__iexact=etiqueta).exists():
                raise serializers.ValidationError({"etiqueta": f"Ya existe una dirección con la etiqueta '{etiqueta}'."})

        return data

    def _generar_etiqueta_optimizada(self, user):
        """
        Genera etiqueta única usando un algoritmo en memoria para evitar múltiples hits a la DB.
        """
        # Obtenemos TODAS las etiquetas existentes en UNA sola consulta
        etiquetas_existentes = set(
            DireccionFavorita.objects.filter(user=user).values_list("etiqueta", flat=True)
        )

        # Buscamos el primer hueco disponible en memoria (mucho más rápido que iterar queries)
        for numero in range(1, 101):
            candidata = f"Dirección {numero}"
            if candidata not in etiquetas_existentes:
                return candidata
        
        # Fallback por seguridad
        return f"Dirección {timezone.now().strftime('%d%m%H%M')}"

    @transaction.atomic
    def create(self, validated_data):
        user = self.context["request"].user
        if validated_data.get("es_predeterminada"):
            user.direcciones_favoritas.filter(activa=True).update(es_predeterminada=False)
        return DireccionFavorita.objects.create(user=user, **validated_data)


class ActualizarDireccionSerializer(serializers.ModelSerializer):
    etiqueta = serializers.CharField(required=False, allow_blank=True, max_length=50)

    class Meta:
        model = DireccionFavorita
        fields = [
            "tipo", "etiqueta", "direccion", "referencia",
            "calle_secundaria", "piso_apartamento", "telefono_contacto", "indicaciones",
            "latitud", "longitud", "ciudad", "es_predeterminada", "activa"
        ]

    def validate(self, data):
        # Si la etiqueta viene vacía, la eliminamos del dict para no sobreescribir la existente
        if "etiqueta" in data and not str(data.get("etiqueta", "")).strip():
            data.pop("etiqueta")
        
        # Validación de duplicados si la etiqueta cambió
        if "etiqueta" in data:
            user = self.context["request"].user
            nueva_etiqueta = data["etiqueta"].strip()
            if DireccionFavorita.objects.filter(user=user, etiqueta__iexact=nueva_etiqueta).exclude(pk=self.instance.pk).exists():
                raise serializers.ValidationError({"etiqueta": "Ya existe otra dirección con esta etiqueta."})
            data["etiqueta"] = nueva_etiqueta

        return data


# ============================================
# SERIALIZERS: MÉTODOS DE PAGO
# ============================================

class MetodoPagoSerializer(ImageFieldMixin, serializers.ModelSerializer):
    tipo_display = serializers.CharField(source="get_tipo_display", read_only=True)
    comprobante_pago = serializers.SerializerMethodField()

    class Meta:
        model = MetodoPago
        fields = [
            "id", "tipo", "tipo_display", "alias", "comprobante_pago", 
            "observaciones", "tiene_comprobante", "requiere_verificacion", 
            "es_predeterminado", "activo", "created_at"
        ]

    def get_comprobante_pago(self, obj):
        return self.get_image_url(obj.comprobante_pago)


class BaseMetodoPagoSerializer(serializers.ModelSerializer):
    """Lógica compartida para crear y actualizar métodos de pago."""
    
    def validate_comprobante_pago(self, value):
        # Permitir PDF también para comprobantes
        if value and hasattr(value, 'content_type') and value.content_type == 'application/pdf':
            if value.size > MAX_FILE_SIZE_BYTES:
                raise serializers.ValidationError(f"El archivo excede {MAX_FILE_SIZE_MB}MB.")
            return value
        return validar_archivo_imagen(value)

    def validate(self, data):
        # Lógica para manejar actualización parcial o creación
        tipo = data.get("tipo", getattr(self.instance, "tipo", None))
        comprobante = data.get("comprobante_pago", getattr(self.instance, "comprobante_pago", None))

        if tipo == "transferencia" and not comprobante:
            raise serializers.ValidationError({
                "comprobante_pago": "El comprobante es obligatorio para transferencias."
            })

        if tipo == "efectivo":
            data["comprobante_pago"] = None  # Limpiar si cambió a efectivo

        return data


class CrearMetodoPagoSerializer(BaseMetodoPagoSerializer):
    class Meta:
        model = MetodoPago
        fields = ["tipo", "alias", "comprobante_pago", "observaciones", "es_predeterminado"]

    def validate_alias(self, value):
        user = self.context["request"].user
        if MetodoPago.objects.filter(user=user, alias__iexact=value.strip(), activo=True).exists():
            raise serializers.ValidationError("Ya existe un método de pago activo con este nombre.")
        return value.strip()

    @transaction.atomic
    def create(self, validated_data):
        user = self.context["request"].user
        if validated_data.get("es_predeterminado"):
            user.metodos_pago.filter(activo=True).update(es_predeterminado=False)
        return MetodoPago.objects.create(user=user, **validated_data)


class ActualizarMetodoPagoSerializer(BaseMetodoPagoSerializer):
    class Meta:
        model = MetodoPago
        fields = ["tipo", "alias", "comprobante_pago", "observaciones", "es_predeterminado"]

    def validate_alias(self, value):
        user = self.context["request"].user
        if MetodoPago.objects.filter(user=user, alias__iexact=value.strip(), activo=True).exclude(pk=self.instance.pk).exists():
            raise serializers.ValidationError("Ya existe un método de pago activo con este nombre.")
        return value.strip()


# ============================================
# SERIALIZERS: NOTIFICACIONES Y UBICACIÓN
# ============================================

class FCMTokenSerializer(serializers.Serializer):
    fcm_token = serializers.CharField(min_length=50, max_length=255)

class ActualizarUbicacionSerializer(serializers.Serializer):
    latitud = serializers.FloatField(min_value=LAT_MIN, max_value=LAT_MAX)
    longitud = serializers.FloatField(min_value=LON_MIN, max_value=LON_MAX)

class UbicacionUsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = UbicacionUsuario
        fields = ["latitud", "longitud", "actualizado_en"]


# ============================================
# SERIALIZERS: SOLICITUDES DE ROL
# ============================================

class SolicitudCambioRolListSerializer(serializers.ModelSerializer):
    rol_solicitado_display = serializers.CharField(source="get_rol_solicitado_display", read_only=True)
    estado_display = serializers.CharField(source="get_estado_display", read_only=True)
    dias_pendiente = serializers.IntegerField(read_only=True)

    class Meta:
        model = SolicitudCambioRol
        fields = [
            "id", "rol_solicitado", 
            "rol_solicitado_display", 
            "motivo",
            'tipo_vehiculo',
            "estado", 
            "estado_display", 
            "creado_en", 
            "dias_pendiente",
            "nombre_comercial", 
            "ruc",              
            "tipo_negocio",      
            "descripcion_negocio",
            "horario_apertura",
            "horario_cierre"
            
        ]
        read_only_fields = fields


class SolicitudCambioRolDetalleSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source="user.get_full_name", read_only=True)
    usuario_email = serializers.CharField(source="user.email", read_only=True)
    rol_solicitado_display = serializers.CharField(source="get_rol_solicitado_display", read_only=True)
    estado_display = serializers.CharField(source="get_estado_display", read_only=True)

    class Meta:
        model = SolicitudCambioRol
        fields = "__all__"


class BaseSolicitudRolSerializer(serializers.Serializer):
    """Base para validar unicidad de solicitudes pendientes."""
    
    motivo = serializers.CharField(min_length=10, max_length=500)
    
    def validate(self, data):
        user = self.context["request"].user
        rol = self.get_rol_objetivo()
        user_rol = getattr(user, 'rol', '')  
        if user_rol == rol:
         raise serializers.ValidationError(f"Ya tienes el rol de {rol}.")
            
        if SolicitudCambioRol.objects.filter(user=user, rol_solicitado=rol, estado="PENDIENTE").exists():
            raise serializers.ValidationError(f"Ya tienes una solicitud pendiente para {rol}.")
            
        return data

    def create(self, validated_data):
        user = self.context["request"].user
        return SolicitudCambioRol.objects.create(
            user=user,
            rol_solicitado=self.get_rol_objetivo(),
            **validated_data
        )


class CrearSolicitudProveedorSerializer(BaseSolicitudRolSerializer):
    ruc = serializers.CharField(min_length=13, max_length=13)
    nombre_comercial = serializers.CharField(min_length=3, max_length=200)
    tipo_negocio = serializers.ChoiceField(choices=["restaurante", "farmacia", "supermercado", "tienda", "otro"])
    descripcion_negocio = serializers.CharField(min_length=10, max_length=500)
    horario_apertura = serializers.TimeField(required=False, allow_null=True)
    horario_cierre = serializers.TimeField(required=False, allow_null=True)

    def get_rol_objetivo(self):
        return "PROVEEDOR"

    def validate_ruc(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("El RUC debe contener solo números.")
        return value


class CrearSolicitudRepartidorSerializer(BaseSolicitudRolSerializer):
    cedula_identidad = serializers.CharField(min_length=10, max_length=20)
    tipo_vehiculo = serializers.ChoiceField(choices=["bicicleta", "moto", "auto", "camion", "otro"])
    zona_cobertura = serializers.CharField(min_length=3, max_length=200)
    disponibilidad = serializers.JSONField(required=False, default=dict)

    def get_rol_objetivo(self):
        return "REPARTIDOR"

    def validate_cedula_identidad(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("La cédula debe contener solo números.")
        return value
class EstadisticasUsuarioSerializer(serializers.Serializer):
    """
    Serializer para las estadísticas del dashboard de usuario.
    No está vinculado a un modelo específico, sino a un diccionario de datos.
    """
    total_pedidos = serializers.IntegerField()
    pedidos_mes_actual = serializers.IntegerField()
    calificacion = serializers.FloatField()
    total_resenas = serializers.IntegerField()
    es_cliente_frecuente = serializers.BooleanField()
    puede_participar_rifa = serializers.BooleanField()
    total_direcciones = serializers.IntegerField()
    total_metodos_pago = serializers.IntegerField()
class EstadoNotificacionesSerializer(serializers.Serializer):
    """
    Serializer para devolver el estado actual de las notificaciones del usuario.
    """
    puede_recibir_notificaciones = serializers.BooleanField()
    notificaciones_pedido = serializers.BooleanField()
    notificaciones_promociones = serializers.BooleanField()
    token_actualizado = serializers.BooleanField()
