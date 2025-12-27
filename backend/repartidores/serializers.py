from rest_framework import serializers
from django.core.validators import RegexValidator
from django.utils import timezone
from django.conf import settings
from django.db.models import Count, Q, F
from math import radians, cos, sin, sqrt, atan2
from decimal import Decimal

from .models import (
    Repartidor,
    RepartidorVehiculo,
    HistorialUbicacion,
    RepartidorEstadoLog,
    CalificacionRepartidor,
    CalificacionCliente,
    EstadoRepartidor,
    TipoVehiculo,
)
from django.core.exceptions import ValidationError as DjangoValidationError
from authentication.models import User, validar_celular


# ==========================================================
# UTILIDAD: Calcular distancia (kilómetros)
# ==========================================================
def calcular_distancia(lat1, lon1, lat2, lon2):
    """
    Calcula la distancia en kilómetros entre dos puntos geográficos
    usando la fórmula de Haversine.

    Args:
        lat1, lon1: Coordenadas del primer punto
        lat2, lon2: Coordenadas del segundo punto

    Returns:
        float: Distancia en kilómetros, o None si faltan datos
    """
    if not all([lat1, lon1, lat2, lon2]):
        return None

    try:
        R = 6371.0  # radio de la Tierra en km
        dlat = radians(float(lat2) - float(lat1))
        dlon = radians(float(lon2) - float(lon1))

        a = (sin(dlat / 2)**2 +
             cos(radians(float(lat1))) * cos(radians(float(lat2))) * sin(dlon / 2)**2)
        c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return round(R * c, 2)
    except (ValueError, TypeError):
        return None


# ==========================================================
#  HELPER: Construir URL completa de archivo media
# ==========================================================
def construir_url_media(file_field, request=None):
    """
    Construye URL completa para un archivo media (FileField/ImageField).
    
    Args:
        file_field: Campo de archivo (FileField/ImageField)
        request: Request HTTP (opcional, para usar build_absolute_uri)
    
    Returns:
        str: URL completa del archivo, o None si no hay archivo
    """
    if not file_field:
        return None
    
    try:
        url = file_field.url
        
        # Si ya es una URL completa HTTP/HTTPS, retornarla
        if url.startswith('http://') or url.startswith('https://'):
            return url
        
        # Si request está disponible, usar build_absolute_uri (RECOMENDADO)
        if request is not None:
            return request.build_absolute_uri(url)
        
        # Fallback: Si la URL empieza con file://, extraer la ruta
        if url.startswith('file://'):
            path = url.replace('file://', '')
            # Extraer solo la parte después de /media/
            if '/media/' in path:
                relative_path = path.split('/media/')[-1]
                url = f"{settings.MEDIA_URL}{relative_path}"
        
        # Construir URL manualmente usando FRONTEND_URL o configuración
        base_url = getattr(settings, 'FRONTEND_URL', 'http://localhost:8000')
        base_url = base_url.rstrip('/')
        
        return f"{base_url}{url}"
        
    except Exception as e:
        # Log del error si tienes logging configurado
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error construyendo URL de media: {e}")
        return None


# ==========================================================
# VEHÍCULO
# ==========================================================
class RepartidorVehiculoSerializer(serializers.ModelSerializer):
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    licencia_foto = serializers.SerializerMethodField() 

    class Meta:
        model = RepartidorVehiculo
        fields = ['id', 'tipo', 'tipo_display', 'placa', 'activo', 'licencia_foto', 'creado_en']
        read_only_fields = ['id', 'tipo_display', 'creado_en']

    def get_licencia_foto(self, obj):
        """ Construye URL completa para licencia_foto"""
        request = self.context.get('request')
        return construir_url_media(obj.licencia_foto, request)

    def validate_placa(self, value):
        """Valida formato básico de placa (opcional, ajusta según tu país)."""
        if value and len(value.strip()) < 3:
            raise serializers.ValidationError("La placa debe tener al menos 3 caracteres.")
        return value.strip().upper() if value else value


# ==========================================================
# HISTORIAL DE UBICACIÓN
# ==========================================================
class HistorialUbicacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistorialUbicacion
        fields = ['id', 'latitud', 'longitud', 'timestamp']
        read_only_fields = ['id', 'timestamp']


# ==========================================================
# CALIFICACIONES (CLIENTE → REPARTIDOR)
# ==========================================================
class CalificacionRepartidorSerializer(serializers.ModelSerializer):
    cliente_nombre = serializers.CharField(source='cliente.get_full_name', read_only=True)
    cliente_email = serializers.EmailField(source='cliente.email', read_only=True)

    class Meta:
        model = CalificacionRepartidor
        fields = [
            'id', 'cliente_nombre', 'cliente_email',
            'puntuacion', 'comentario', 'pedido_id', 'creado_en'
        ]
        read_only_fields = ['id', 'cliente_nombre', 'cliente_email', 'creado_en']

    def validate_puntuacion(self, value):
        """Valida que la puntuación esté en el rango correcto."""
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La puntuación debe estar entre 1 y 5.")
        return value


class CalificacionRepartidorCreateSerializer(serializers.ModelSerializer):
    """Serializer para crear calificaciones (sin exponer datos sensibles)."""

    class Meta:
        model = CalificacionRepartidor
        fields = ['puntuacion', 'comentario']

    def validate_puntuacion(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La puntuación debe estar entre 1 y 5.")
        return value

    def validate_comentario(self, value):
        if value and len(value) > 500:
            raise serializers.ValidationError("El comentario no puede exceder 500 caracteres.")
        return value


# ==========================================================
# CALIFICACIONES (REPARTIDOR → CLIENTE)
# ==========================================================
class CalificacionClienteSerializer(serializers.ModelSerializer):
    repartidor_nombre = serializers.CharField(source='repartidor.user.get_full_name', read_only=True)

    class Meta:
        model = CalificacionCliente
        fields = [
            'id', 'repartidor_nombre',
            'puntuacion', 'comentario', 'pedido_id', 'creado_en'
        ]
        read_only_fields = ['id', 'repartidor_nombre', 'creado_en']

    def validate_puntuacion(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La puntuación debe estar entre 1 y 5.")
        return value


class CalificacionClienteCreateSerializer(serializers.ModelSerializer):
    """Serializer para que repartidores califiquen clientes."""

    class Meta:
        model = CalificacionCliente
        fields = ['puntuacion', 'comentario']

    def validate_puntuacion(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La puntuación debe estar entre 1 y 5.")
        return value

    def validate_comentario(self, value):
        if value and len(value) > 500:
            raise serializers.ValidationError("El comentario no puede exceder 500 caracteres.")
        return value


# ==========================================================
#  PERFIL COMPLETO DEL REPARTIDOR (PROPIO) - ACTUALIZADO
# ==========================================================
class RepartidorPerfilSerializer(serializers.ModelSerializer):
    nombre_completo = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    foto_perfil = serializers.SerializerMethodField()  
    vehiculos = RepartidorVehiculoSerializer(many=True, read_only=True)
    calificaciones_recientes = serializers.SerializerMethodField()
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    total_calificaciones = serializers.SerializerMethodField()

    class Meta:
        model = Repartidor
        fields = [
            'id', 'nombre_completo', 'email', 'foto_perfil',
            'cedula', 'telefono',
            'vehiculo',
            'estado', 'estado_display', 'verificado', 'activo',
            'latitud', 'longitud', 'ultima_localizacion',
            'entregas_completadas', 'calificacion_promedio', 'total_calificaciones',
            'vehiculos', 'calificaciones_recientes',
            'creado_en', 'actualizado_en'
        ]
        read_only_fields = [
            'id', 'nombre_completo', 'email', 'cedula',
            'estado', 'verificado', 'activo',
            'latitud', 'longitud', 'ultima_localizacion',
            'entregas_completadas', 'calificacion_promedio',
            'creado_en', 'actualizado_en'
        ]

    def get_foto_perfil(self, obj):
        """ Construye URL completa para foto_perfil"""
        request = self.context.get('request')
        return construir_url_media(obj.foto_perfil, request)

    def get_calificaciones_recientes(self, obj):
        """Retorna las últimas 5 calificaciones."""
        calificaciones = obj.calificaciones.order_by('-creado_en')[:5]
        return CalificacionRepartidorSerializer(calificaciones, many=True).data

    def get_total_calificaciones(self, obj):
        """Retorna el total de calificaciones recibidas."""
        return obj.calificaciones.count()


# ==========================================================
# PERFIL PARA EDICIÓN (PROPIO)
# ==========================================================
class RepartidorUpdateSerializer(serializers.ModelSerializer):
    telefono = serializers.CharField(
        required=False,
        validators=[
            RegexValidator(
                r'^\+?[0-9]{7,15}$',
                message="Número de teléfono inválido. Formato: +593987654321 o 0987654321"
            )
        ]
    )

    vehiculo = serializers.ChoiceField(
        required=False,
        choices=TipoVehiculo.choices,
        help_text="Medio de transporte principal",
    )

    class Meta:
        model = Repartidor
        fields = ['foto_perfil', 'telefono', 'vehiculo']
        extra_kwargs = {
            'foto_perfil': {'required': False},
            'telefono': {'required': False},
            'vehiculo': {'required': False},
        }

    def validate_foto_perfil(self, value):
        """Valida tamaño y tipo de imagen."""
        if value:
            # Validar tamaño (máximo 5MB)
            if value.size > 5 * 1024 * 1024:
                raise serializers.ValidationError("La imagen no puede superar 5MB.")

            # Validar extensión
            valid_extensions = ['jpg', 'jpeg', 'png', 'webp']
            ext = value.name.split('.')[-1].lower()
            if ext not in valid_extensions:
                raise serializers.ValidationError(
                    f"Formato no válido. Usa: {', '.join(valid_extensions)}"
                )

        return value


# ==========================================================
# ESTADO (disponible / ocupado / fuera_servicio)
# ==========================================================
class RepartidorEstadoSerializer(serializers.Serializer):
    estado = serializers.ChoiceField(choices=EstadoRepartidor.choices)

    def validate_estado(self, value):
        """Valida que el repartidor pueda cambiar a ese estado."""
        repartidor = self.context.get('repartidor')

        if not repartidor:
            raise serializers.ValidationError("No se pudo identificar al repartidor.")

        if not repartidor.activo:
            raise serializers.ValidationError(
                "No puedes cambiar de estado: tu cuenta está desactivada."
            )

        if value in (EstadoRepartidor.DISPONIBLE, EstadoRepartidor.OCUPADO):
            if not repartidor.verificado:
                raise serializers.ValidationError(
                    "No puedes cambiar a ese estado: no estás verificado por un administrador."
                )

        return value


# ==========================================================
# UBICACIÓN
# ==========================================================
class RepartidorUbicacionSerializer(serializers.Serializer):
    latitud = serializers.FloatField()
    longitud = serializers.FloatField()

    def validate(self, data):
        """Valida que las coordenadas sean válidas (rango mundial)."""
        lat, lon = data['latitud'], data['longitud']

        if not (-90.0 <= lat <= 90.0):
            raise serializers.ValidationError({
                'latitud': 'Latitud fuera de rango (-90° a 90°)'
            })

        if not (-180.0 <= lon <= 180.0):
            raise serializers.ValidationError({
                'longitud': 'Longitud fuera de rango (-180° a 180°)'
            })

        return data


# ==========================================================
#  PERFIL PÚBLICO (CLIENTE VE AL REPARTIDOR) - ACTUALIZADO
# ==========================================================
class RepartidorPublicoSerializer(serializers.ModelSerializer):
    nombre = serializers.CharField(source='user.get_full_name', read_only=True)
    foto_perfil = serializers.SerializerMethodField()  # ✅ Cambiado a SerializerMethodField
    tipo_vehiculo_activo = serializers.SerializerMethodField()
    placa_vehiculo_activa = serializers.SerializerMethodField()
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    total_calificaciones = serializers.SerializerMethodField()
    desglose_calificaciones = serializers.SerializerMethodField()
    porcentaje_5_estrellas = serializers.SerializerMethodField()

    class Meta:
        model = Repartidor
        fields = [
            'id', 'nombre', 'foto_perfil',
            'calificacion_promedio', 'entregas_completadas',
            'total_calificaciones', 'desglose_calificaciones',
            'porcentaje_5_estrellas',
            'estado', 'estado_display',
            'latitud', 'longitud', 'ultima_localizacion',
            'tipo_vehiculo_activo', 'placa_vehiculo_activa'
        ]

    def get_foto_perfil(self, obj):
        """ Construye URL completa para foto_perfil"""
        request = self.context.get('request')
        return construir_url_media(obj.foto_perfil, request)

    def get_tipo_vehiculo_activo(self, obj):
        """Retorna el tipo de vehículo activo."""
        vehiculo = obj.vehiculos.filter(activo=True).first()
        return vehiculo.get_tipo_display() if vehiculo else None

    def get_placa_vehiculo_activa(self, obj):
        """Retorna la placa del vehículo activo."""
        vehiculo = obj.vehiculos.filter(activo=True).first()
        return vehiculo.placa if vehiculo else None

    def _obtener_estadisticas(self, obj):
        if not hasattr(self, '_estadisticas_cache'):
            self._estadisticas_cache = {}
        if obj.pk not in self._estadisticas_cache:
            self._estadisticas_cache[obj.pk] = obj.calificaciones.aggregate(
                total=Count('id'),
                cinco=Count('id', filter=Q(puntuacion=5)),
                cuatro=Count('id', filter=Q(puntuacion=4)),
                tres=Count('id', filter=Q(puntuacion=3)),
                dos=Count('id', filter=Q(puntuacion=2)),
                uno=Count('id', filter=Q(puntuacion=1)),
            )
        return self._estadisticas_cache[obj.pk]

    def get_total_calificaciones(self, obj):
        stats = self._obtener_estadisticas(obj)
        return stats.get('total') or 0

    def get_desglose_calificaciones(self, obj):
        stats = self._obtener_estadisticas(obj)
        return {
            '5_estrellas': stats.get('cinco') or 0,
            '4_estrellas': stats.get('cuatro') or 0,
            '3_estrellas': stats.get('tres') or 0,
            '2_estrellas': stats.get('dos') or 0,
            '1_estrella': stats.get('uno') or 0,
        }

    def get_porcentaje_5_estrellas(self, obj):
        stats = self._obtener_estadisticas(obj)
        total = stats.get('total') or 0
        if total == 0:
            return 0.0
        cinco = stats.get('cinco') or 0
        return round((cinco / total) * 100, 1)


# ==========================================================
# PERFIL PÚBLICO CON DISTANCIA AL CLIENTE (para tracking)
# ==========================================================
class RepartidorPublicoDistanciaSerializer(RepartidorPublicoSerializer):
    distancia_cliente = serializers.SerializerMethodField()
    tiempo_estimado_minutos = serializers.SerializerMethodField()

    class Meta(RepartidorPublicoSerializer.Meta):
        fields = RepartidorPublicoSerializer.Meta.fields + [
            'distancia_cliente',
            'tiempo_estimado_minutos'
        ]

    def get_distancia_cliente(self, obj):
        """Calcula distancia en km entre repartidor y cliente."""
        lat_cliente = self.context.get('lat_cliente')
        lon_cliente = self.context.get('lon_cliente')

        if lat_cliente is not None and lon_cliente is not None:
            if obj.latitud and obj.longitud:
                return calcular_distancia(
                    obj.latitud,
                    obj.longitud,
                    lat_cliente,
                    lon_cliente
                )

        return None

    def get_tiempo_estimado_minutos(self, obj):
        """Estima tiempo de llegada en minutos (velocidad promedio 30 km/h)."""
        distancia = self.get_distancia_cliente(obj)

        if distancia is not None:
            # Velocidad promedio en ciudad: 30 km/h
            velocidad_kmh = 30
            tiempo_horas = distancia / velocidad_kmh
            tiempo_minutos = int(tiempo_horas * 60)
            return max(tiempo_minutos, 1)  # Mínimo 1 minuto

        return None


# ==========================================================
# LOG DE ESTADO (solo lectura)
# ==========================================================
class RepartidorEstadoLogSerializer(serializers.ModelSerializer):
    estado_anterior_display = serializers.CharField(
        source='get_estado_anterior_display',
        read_only=True
    )
    estado_nuevo_display = serializers.CharField(
        source='get_estado_nuevo_display',
        read_only=True
    )
    timestamp_local = serializers.SerializerMethodField()

    class Meta:
        model = RepartidorEstadoLog
        fields = [
            'id',
            'estado_anterior',
            'estado_anterior_display',
            'estado_nuevo',
            'estado_nuevo_display',
            'motivo',
            'timestamp',
            'timestamp_local'
        ]
        read_only_fields = fields

    def get_timestamp_local(self, obj):
        """Retorna timestamp en zona horaria local."""
        from django.utils.timezone import localtime
        return localtime(obj.timestamp).isoformat()


# ==========================================================
# ESTADÍSTICAS DEL REPARTIDOR
# ==========================================================
class RepartidorEstadisticasSerializer(serializers.ModelSerializer):
    """Serializer para dashboard con métricas del repartidor."""

    total_calificaciones = serializers.IntegerField(read_only=True)
    calificaciones_5_estrellas = serializers.IntegerField(read_only=True)
    tasa_aceptacion = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        read_only=True
    )

    class Meta:
        model = Repartidor
        fields = [
            'entregas_completadas',
            'calificacion_promedio',
            'total_calificaciones',
            'calificaciones_5_estrellas',
            'tasa_aceptacion'
        ]
        
# ============================================
# VALIDADORES COMPARTIDOS
# ============================================

class ValidadorCedula:
    """Validador para cédula ecuatoriana"""
    
    @staticmethod
    def validar_formato(cedula):
        """Valida formato de cédula (10 dígitos)"""
        if not cedula:
            return True
        
        if not isinstance(cedula, str):
            raise serializers.ValidationError('Cédula debe ser texto')
        
        cedula = cedula.strip()
        
        if len(cedula) != 10:
            raise serializers.ValidationError(
                'Cédula debe tener exactamente 10 dígitos'
            )
        
        if not cedula.isdigit():
            raise serializers.ValidationError(
                'Cédula solo debe contener números'
            )
        
        return True
    
    @staticmethod
    def validar_duplicado(cedula, repartidor_id=None):
        """Valida que la cédula no esté duplicada"""
        if not cedula:
            return True
        
        query = Repartidor.objects.filter(cedula=cedula)
        
        if repartidor_id:
            query = query.exclude(id=repartidor_id)
        
        if query.exists():
            raise serializers.ValidationError(
                'Esta cédula ya está registrada en el sistema'
            )
        
        return True


class ValidadorContacto:
    """Validador para datos de contacto"""
    
    @staticmethod
    def validar_email_duplicado(email, usuario_id=None):
        """Valida que el email no esté duplicado"""
        if not email:
            return True
        
        query = User.objects.filter(email=email)
        
        if usuario_id:
            query = query.exclude(id=usuario_id)
        
        if query.exists():
            raise serializers.ValidationError(
                'Este email ya está registrado en el sistema'
            )
        
        return True
    
    @staticmethod
    def validar_telefono(telefono):
        """Valida formato de teléfono ecuatoriano"""
        if not telefono:
            return True

        try:
            validar_celular(telefono)
        except DjangoValidationError as exc:
            mensaje = exc.message if hasattr(exc, 'message') and exc.message else None
            if not mensaje and exc.messages:
                mensaje = exc.messages[0]
            raise serializers.ValidationError(mensaje or 'Teléfono inválido')

        return True


# ============================================
# SERIALIZER: EDITAR PERFIL REPARTIDOR
# ============================================

class RepartidorEditarPerfilSerializer(serializers.ModelSerializer):
    """
    Serializer para editar el PERFIL del repartidor autenticado.
    
    Campos editables:
    - cedula: Cédula del repartidor
    - telefono: Teléfono de contacto
    - foto_perfil: Imagen de perfil (opcional)
    - vehiculo: Medio de transporte principal
    """
    vehiculo = serializers.ChoiceField(
        choices=TipoVehiculo.choices,
        required=False,
        allow_blank=False,
        help_text='Vehículo principal'
    )
    
    class Meta:
        model = Repartidor
        fields = [
            'cedula',
            'telefono',
            'foto_perfil',
            'vehiculo',
        ]
        extra_kwargs = {
            'cedula': {'required': False},
            'telefono': {'required': False},
            'foto_perfil': {'required': False},
            'vehiculo': {'required': False},
        }
    
    # -------- VALIDADORES DE CAMPOS --------
    
    def validate_cedula(self, value):
        """Valida formato y unicidad de cédula"""
        if value:
            value = value.strip()
            ValidadorCedula.validar_formato(value)
            
            repartidor_id = self.instance.id if self.instance else None
            ValidadorCedula.validar_duplicado(value, repartidor_id)
        
        return value
    
    def validate_telefono(self, value):
        """Valida formato del teléfono"""
        if value:
            value = value.strip()
            ValidadorContacto.validar_telefono(value)
        
        return value
    
    def validate_foto_perfil(self, value):
        """Valida tamaño y tipo de imagen"""
        if value:
            # Validar tamaño (máximo 5MB)
            if value.size > 5 * 1024 * 1024:
                raise serializers.ValidationError(
                    'La imagen no puede superar 5MB'
                )
            
            # Validar extensión
            valid_extensions = ['jpg', 'jpeg', 'png', 'webp']
            ext = value.name.split('.')[-1].lower()
            if ext not in valid_extensions:
                raise serializers.ValidationError(
                    f'Formato no válido. Usa: {", ".join(valid_extensions)}'
                )
        
        return value
    
    def validate(self, data):
        """Validación a nivel de objeto"""
        if not data:
            raise serializers.ValidationError(
                'Debe proporcionar al menos un campo para actualizar'
            )
        
        return data


# ============================================
# SERIALIZER: EDITAR CONTACTO REPARTIDOR
# ============================================

class RepartidorEditarContactoSerializer(serializers.Serializer):
    """
    Serializer para editar los DATOS DE CONTACTO del usuario
    vinculado al repartidor.
    
    Campos editables:
    - email: Email del usuario
    - first_name: Nombre del usuario
    - last_name: Apellido del usuario
    """
    
    email = serializers.EmailField(
        required=False,
        allow_blank=False,
        help_text='Email del repartidor'
    )
    
    first_name = serializers.CharField(
        required=False,
        max_length=100,
        allow_blank=False,
        help_text='Nombre del repartidor'
    )
    
    last_name = serializers.CharField(
        required=False,
        max_length=100,
        allow_blank=False,
        help_text='Apellido del repartidor'
    )
    
    # -------- VALIDADORES DE CAMPOS --------
    
    def validate_email(self, value):
        """Valida que el email sea único en el sistema"""
        if value:
            value = value.strip().lower()
            usuario = self.context.get('usuario')
            usuario_id = usuario.id if usuario else None
            ValidadorContacto.validar_email_duplicado(value, usuario_id)
        
        return value
    
    def validate_first_name(self, value):
        """Valida nombre del repartidor"""
        if value:
            value = value.strip()
            
            if len(value) < 2:
                raise serializers.ValidationError(
                    'El nombre debe tener al menos 2 caracteres'
                )
            
            if len(value) > 100:
                raise serializers.ValidationError(
                    'El nombre no puede exceder 100 caracteres'
                )
        
        return value
    
    def validate_last_name(self, value):
        """Valida apellido del repartidor"""
        if value:
            value = value.strip()
            
            if len(value) < 2:
                raise serializers.ValidationError(
                    'El apellido debe tener al menos 2 caracteres'
                )
            
            if len(value) > 100:
                raise serializers.ValidationError(
                    'El apellido no puede exceder 100 caracteres'
                )
        
        return value
    
    def validate(self, data):
        """Validación a nivel de objeto"""
        if not data:
            raise serializers.ValidationError(
                'Debe proporcionar al menos un campo para actualizar (email, first_name o last_name)'
            )
        
        return data


# ============================================
# SERIALIZER: RESPUESTA PERFIL COMPLETO
# ============================================

class RepartidorPerfilCompletoSerializer(serializers.ModelSerializer):
    """
    Serializer para retornar el perfil COMPLETO del repartidor
    después de una actualización.
    
    Incluye datos del User vinculado.
    """
    
    # Datos del User
    nombre_completo = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    
    # Datos del Repartidor
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    foto_perfil_url = serializers.SerializerMethodField()
    vehiculo = serializers.CharField(read_only=True)
    
    # Vehículo activo
    vehiculo_activo = serializers.SerializerMethodField()
    
    class Meta:
        model = Repartidor
        fields = [
            # User
            'id',
            'nombre_completo',
            'email',
            'first_name',
            'last_name',
            
            # Repartidor
            'cedula',
            'telefono',
            'foto_perfil',
            'foto_perfil_url',
            'vehiculo',
            'estado',
            'estado_display',
            'verificado',
            'activo',
            'latitud',
            'longitud',
            'ultima_localizacion',
            'entregas_completadas',
            'calificacion_promedio',
            
            # Vehículo
            'vehiculo_activo',
            
            # Timestamps
            'creado_en',
            'actualizado_en',
        ]
        read_only_fields = fields
    
    def get_foto_perfil_url(self, obj):
        """Construye URL completa de la foto de perfil"""
        if not obj.foto_perfil:
            return None
        
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.foto_perfil.url)
        
        return obj.foto_perfil.url
    
    def get_vehiculo_activo(self, obj):
        """Retorna datos del vehículo activo"""
        vehiculo = obj.vehiculos.filter(activo=True).first()
        
        if not vehiculo:
            return None
        
        request = self.context.get('request')
        licencia_url = None
        
        if vehiculo.licencia_foto:
            if request:
                licencia_url = request.build_absolute_uri(vehiculo.licencia_foto.url)
            else:
                licencia_url = vehiculo.licencia_foto.url
        
        return {
            'id': vehiculo.id,
            'tipo': vehiculo.tipo,
            'tipo_display': vehiculo.get_tipo_display(),
            'placa': vehiculo.placa,
            'licencia_foto': licencia_url,
            'activo': vehiculo.activo,
        }


# ==========================================================
# DATOS BANCARIOS DEL REPARTIDOR
# ==========================================================

class DatosBancariosSerializer(serializers.ModelSerializer):
    """
    Serializer para consultar los datos bancarios del repartidor.
    """
    tipo_cuenta_display = serializers.CharField(
        source='get_banco_tipo_cuenta_display',
        read_only=True
    )

    class Meta:
        model = Repartidor
        fields = [
            'banco_nombre',
            'banco_tipo_cuenta',
            'tipo_cuenta_display',
            'banco_numero_cuenta',
            'banco_titular',
            'banco_cedula_titular',
            'banco_verificado',
            'banco_fecha_verificacion',
        ]
        read_only_fields = ['banco_verificado', 'banco_fecha_verificacion']


class DatosBancariosUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer para actualizar datos bancarios del repartidor.
    Los campos de verificación solo pueden ser modificados por administradores.
    """

    class Meta:
        model = Repartidor
        fields = [
            'banco_nombre',
            'banco_tipo_cuenta',
            'banco_numero_cuenta',
            'banco_titular',
            'banco_cedula_titular',
        ]

    def validate_banco_nombre(self, value):
        """Valida nombre del banco"""
        if value:
            value = value.strip()
            if len(value) < 3:
                raise serializers.ValidationError(
                    'Nombre del banco inválido. Debe tener al menos 3 caracteres'
                )
        return value

    def validate_banco_numero_cuenta(self, value):
        """Valida número de cuenta bancaria"""
        if value:
            value = value.strip()
            # Remover guiones y espacios
            value_clean = value.replace('-', '').replace(' ', '')

            if not value_clean.isdigit():
                raise serializers.ValidationError(
                    'Número de cuenta inválido. Solo debe contener números (sin letras ni caracteres especiales)'
                )

            if len(value_clean) < 8:
                raise serializers.ValidationError(
                    f'Número de cuenta muy corto. Tiene {len(value_clean)} dígitos, necesita mínimo 8 dígitos'
                )

            if len(value_clean) > 20:
                raise serializers.ValidationError(
                    f'Número de cuenta muy largo. Tiene {len(value_clean)} dígitos, máximo permitido son 20 dígitos'
                )

        return value

    def validate_banco_titular(self, value):
        """Valida nombre del titular"""
        if value:
            value = value.strip()
            if len(value) < 3:
                raise serializers.ValidationError(
                    'Nombre del titular inválido. Debe tener al menos 3 caracteres'
                )
        return value

    def validate_banco_cedula_titular(self, value):
        """Valida cédula del titular"""
        if value:
            value = value.strip()
            try:
                ValidadorCedula.validar_formato(value)
            except serializers.ValidationError as e:
                # Mejorar el mensaje de error para que sea más claro
                raise serializers.ValidationError(
                    f'Cédula del titular inválida. {str(e.detail[0]) if e.detail else "Debe tener 10 dígitos"}'
                )

        return value

    def validate(self, data):
        """
        Validación de nivel de objeto.
        Si se proporcionan datos bancarios, todos los campos deben estar completos.
        """
        campos_bancarios = [
            'banco_nombre',
            'banco_tipo_cuenta',
            'banco_numero_cuenta',
            'banco_titular',
            'banco_cedula_titular'
        ]

        # Obtener valores actuales (merge de instance + data)
        if self.instance:
            valores_actuales = {}
            for campo in campos_bancarios:
                # Priorizar data, luego instance
                if campo in data:
                    valores_actuales[campo] = data[campo]
                else:
                    valores_actuales[campo] = getattr(self.instance, campo, None)
        else:
            valores_actuales = data

        # Si al menos un campo bancario tiene valor, todos deben tener valor
        campos_con_valor = [
            campo for campo in campos_bancarios
            if valores_actuales.get(campo)
        ]

        if campos_con_valor and len(campos_con_valor) < len(campos_bancarios):
            campos_faltantes = [
                campo for campo in campos_bancarios
                if not valores_actuales.get(campo)
            ]
            # Traducir nombres de campos a español
            nombres_campos = {
                'banco_nombre': 'Nombre del banco',
                'banco_tipo_cuenta': 'Tipo de cuenta',
                'banco_numero_cuenta': 'Número de cuenta',
                'banco_titular': 'Nombre del titular',
                'banco_cedula_titular': 'Cédula del titular'
            }
            faltantes_spanish = [nombres_campos.get(c, c) for c in campos_faltantes]
            raise serializers.ValidationError({
                'datos_bancarios': f'Datos bancarios incompletos. Faltan: {", ".join(faltantes_spanish)}'
            })

        return data

    def update(self, instance, validated_data):
        """
        Al actualizar datos bancarios, marcar como no verificado
        para que un admin los revise nuevamente.
        """
        # Actualizar campos
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        # No requiere verificación manual: marcar como verificado al guardar
        instance.banco_verificado = True
        instance.banco_fecha_verificacion = timezone.now()

        instance.save()
        return instance
