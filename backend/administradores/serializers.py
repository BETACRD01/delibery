# -*- coding: utf-8 -*-
# administradores/serializers.py
"""
Serializers para gestión administrativa
- Serializers de usuarios, proveedores y repartidores
- Serializers de logs y configuración del sistema
- Validaciones de permisos y seguridad
"""

from rest_framework import serializers
from django.utils import timezone
from django.db import transaction
from django.core.validators import MinValueValidator, MaxValueValidator
import logging
from usuarios.models import SolicitudCambioRol

from authentication.models import User
from usuarios.models import Perfil
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from .models import Administrador, AccionAdministrativa, ConfiguracionSistema

logger = logging.getLogger('administradores')


# ============================================
# VALIDADORES REUTILIZABLES
# ============================================

def validate_percentage(value):
    """Validador genérico para campos de porcentaje"""
    if not 0 <= value <= 100:
        raise serializers.ValidationError("El porcentaje debe estar entre 0 y 100")
    return value


def validate_positive_amount(value):
    """Validador para montos positivos"""
    if value <= 0:
        raise serializers.ValidationError("El monto debe ser positivo")
    return value


def validate_unique_celular(value, exclude_user_id=None):
    """Validador para celular único"""
    query = User.objects.filter(celular=value)
    if exclude_user_id:
        query = query.exclude(id=exclude_user_id)
    if query.exists():
        raise serializers.ValidationError("Este número de celular ya está registrado")
    return value


# ============================================
# MIXINS PARA CAMPOS COMUNES
# ============================================

class UserInfoMixin:
    """Mixin para campos comunes de información de usuario"""
    
    def get_edad(self, obj):
        """Calcula la edad del usuario de forma segura"""
        try:
            if hasattr(obj, 'get_edad'):
                return obj.get_edad()
        except Exception as e:
            logger.warning(f"Error calculando edad para usuario {obj.id}: {str(e)}")
        return None


class BaseUserSerializerMixin(serializers.Serializer):
    """Mixin base para serializers que incluyen información de usuario"""
    usuario_email = serializers.CharField(source='user.email', read_only=True)
    usuario_nombre = serializers.CharField(source='user.get_full_name', read_only=True)
    usuario_celular = serializers.CharField(source='user.celular', read_only=True)


# ============================================
# SERIALIZER: ADMINISTRADOR
# ============================================

class AdministradorSerializer(serializers.ModelSerializer):
    """
    Serializer para perfil de administrador
    Retorna información del admin y sus permisos
    """
    usuario_email = serializers.CharField(source='user.email', read_only=True)
    usuario_nombre = serializers.CharField(source='user.get_full_name', read_only=True)
    es_super_admin = serializers.BooleanField(read_only=True)
    total_acciones = serializers.IntegerField(read_only=True)
    
    # Mapeo de fechas seguro
    creado_en = serializers.DateTimeField(source='created_at', read_only=True)
    actualizado_en = serializers.DateTimeField(source='updated_at', read_only=True)

    class Meta:
        model = Administrador
        fields = [
            'id', 'usuario_email', 'usuario_nombre', 'cargo', 'departamento',
            # Permisos
            'puede_gestionar_usuarios', 'puede_gestionar_pedidos',
            'puede_gestionar_proveedores', 'puede_gestionar_repartidores',
            'puede_gestionar_rifas', 'puede_ver_reportes', 'puede_configurar_sistema',
            # Estado
            'activo', 'es_super_admin', 'total_acciones',
            'creado_en', 'actualizado_en'
        ]
        read_only_fields = [
            'id', 'usuario_email', 'usuario_nombre', 'es_super_admin',
            'total_acciones', 'creado_en', 'actualizado_en'
        ]


# ============================================
# SERIALIZER: USUARIO - LISTAR
# ============================================

class UsuarioListSerializer(UserInfoMixin, serializers.ModelSerializer):
    """
    Serializer para listar usuarios (vista simplificada)
    Usado en listados y búsquedas
    """
    # === BLINDAJE DE CAMPOS ===
    rol = serializers.CharField(read_only=True)
    verificado = serializers.BooleanField(read_only=True, default=False)
    cuenta_desactivada = serializers.BooleanField(read_only=True, default=False)
    # ==========================
    
    rol_display = serializers.CharField(source='get_rol_display', read_only=True)
    edad = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'username', 'first_name', 'last_name',
            'celular', 'rol', 'rol_display', 'edad',
            'is_active', 'cuenta_desactivada', 'verificado', 'created_at'
        ]
        read_only_fields = ['id', 'created_at', 'rol_display', 'rol', 'verificado', 'cuenta_desactivada']


# ============================================
# SERIALIZER: USUARIO - DETALLE
# ============================================

class UsuarioDetalleSerializer(UserInfoMixin, serializers.ModelSerializer):
    """
    Serializer para detalle completo de usuario
    Incluye toda la información personal y de seguridad
    """
    # === BLINDAJE DE CAMPOS ===
    rol = serializers.CharField(read_only=True)
    verificado = serializers.BooleanField(read_only=True, default=False)
    cuenta_desactivada = serializers.BooleanField(read_only=True, default=False)
    # ==========================

    rol_display = serializers.CharField(source='get_rol_display', read_only=True)
    edad = serializers.SerializerMethodField()
    perfil = serializers.SerializerMethodField()
    intentos_login_fallidos = serializers.IntegerField(read_only=True)
    cuenta_bloqueada = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'username', 'first_name', 'last_name',
            'celular', 'fecha_nacimiento', 'edad',
            'rol', 'rol_display',
            # Términos
            'terminos_aceptados', 'terminos_fecha_aceptacion',
            # Notificaciones
            'notificaciones_email', 'notificaciones_marketing', 'notificaciones_push',
            # Estado
            'is_active', 'cuenta_desactivada', 'verificado',
            'intentos_login_fallidos', 'cuenta_bloqueada',
            # Auditoría
            'created_at', 'updated_at', 'perfil'
        ]
        read_only_fields = [
            'id', 'created_at', 'updated_at', 'rol_display', 'edad',
            'intentos_login_fallidos', 'cuenta_bloqueada', 'perfil', 'rol',
            'verificado', 'cuenta_desactivada'
        ]

    def get_perfil(self, obj):
        """Información del perfil de usuario si existe"""
        try:
            # 💡 CORRECCIÓN: Usar 'perfil' que es la clave de relación correcta (related_name por defecto si no es 'perfil_usuario')
            if hasattr(obj, 'perfil'):
                perfil = obj.perfil
                return {
                    'id': perfil.id,
                    'total_pedidos': perfil.total_pedidos,
                    'calificacion_promedio': float(perfil.calificacion_promedio or 0)
                }
        except Exception:
            return None

    def get_cuenta_bloqueada(self, obj):
        """Verifica si la cuenta está bloqueada"""
        try:
            return obj.esta_bloqueado() if hasattr(obj, 'esta_bloqueado') else False
        except Exception:
            return False


# ============================================
# SERIALIZER: USUARIO - EDITAR
# ============================================
class UsuarioEditarSerializer(serializers.ModelSerializer):
    """
    Serializer para editar información de usuario por admin
    Permite cambiar datos personales y preferencias
    """
    # BLINDAJE: Definir 'verificado' explícitamente (si está en fields debe ser manejado)
    verificado = serializers.BooleanField(required=False)
    
    class Meta:
        model = User
        fields = [
            'first_name', 'last_name', 'celular', 'fecha_nacimiento',
            'notificaciones_email', 'notificaciones_marketing', 'notificaciones_push',
            'verificado' # El serializador intenta actualizar este campo
        ]

    def validate_celular(self, value):
        """Validar que el celular sea único (excepto el del usuario actual)"""
        return validate_unique_celular(value, exclude_user_id=self.instance.id if self.instance else None)

# ============================================
# SERIALIZER: CAMBIAR ROL
# ============================================

class CambiarRolSerializer(serializers.Serializer):
    """
    Serializer para cambiar el rol de un usuario
    Los roles ahora se gestionan en esta app, no en authentication
    """

    # Usar directamente User.RolChoices para mantener consistencia
    nuevo_rol = serializers.ChoiceField(
        choices=User.RolChoices.choices,
        label="Nuevo rol"
    )
    motivo = serializers.CharField(
        required=False,
        allow_blank=True,
        label="Motivo del cambio",
        max_length=500
    )

    def validate(self, data):
        """Validaciones combinadas"""
        usuario = self.context.get('usuario')
        nuevo_rol = data.get('nuevo_rol')

        if not usuario:
            raise serializers.ValidationError("Usuario no especificado")

        # No permitir cambiar a ADMINISTRADOR directamente desde aquí
        if nuevo_rol == 'admin':
            raise serializers.ValidationError(
                "No se puede cambiar directamente a ADMINISTRADOR. "
                "Usar proceso de creación de admin."
            )

        return data


# ============================================
# SERIALIZER: DESACTIVAR USUARIO
# ============================================

class DesactivarUsuarioSerializer(serializers.Serializer):
    """
    Serializer para desactivar un usuario
    """
    razon = serializers.CharField(
        max_length=500,
        label="Razón de desactivación"
    )
    permanente = serializers.BooleanField(
        default=False,
        label="¿Desactivación permanente?"
    )


# ============================================
# SERIALIZER: RESETEAR PASSWORD
# ============================================

class ResetearPasswordSerializer(serializers.Serializer):
    """
    Serializer para resetear password de usuario
    """
    nueva_password = serializers.CharField(
        min_length=8,
        max_length=128,
        write_only=True,
        style={'input_type': 'password'},
        label="Nueva contraseña"
    )
    confirmar_password = serializers.CharField(
        min_length=8,
        max_length=128,
        write_only=True,
        style={'input_type': 'password'},
        label="Confirmar contraseña"
    )

    def validate(self, data):
        """Validar que las contraseñas coincidan"""
        if data['nueva_password'] != data['confirmar_password']:
            raise serializers.ValidationError({
                'confirmar_password': 'Las contraseñas no coinciden'
            })
        return data


# ============================================
# SERIALIZER: PROVEEDOR - LISTAR
# ============================================
class ProveedorListSerializer(BaseUserSerializerMixin, serializers.ModelSerializer):
    """
    Serializer para listar proveedores (vista simplificada)
    """
    # Mapeamos 'creado_en' (nombre en API) a 'created_at' (nombre en BD)
    creado_en = serializers.DateTimeField(source='created_at', read_only=True)
    
    # Definimos los campos calculados para que DRF no los busque en BD
    calificacion_promedio = serializers.FloatField(read_only=True, default=0.0)
    total_pedidos = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Proveedor
        fields = [
            'id', 'usuario_email', 'usuario_nombre',
            'nombre', 'tipo_proveedor', 'ciudad',
            'verificado', 'activo',
            'calificacion_promedio', 'total_pedidos',
            'creado_en'
        ]
        read_only_fields = ['id', 'creado_en', 'calificacion_promedio', 'total_pedidos']
        # === CORRECCIÓN DE SWAGGER ===
        ref_name = 'AdminProveedorList' 
        # =============================


# ============================================
# SERIALIZER: PROVEEDOR - DETALLE
# ============================================

class ProveedorDetalleSerializer(BaseUserSerializerMixin, serializers.ModelSerializer):
    """
    Serializer para detalle completo de proveedor
    """
    # === CAMPOS BLINDADOS (Definidos explícitamente para evitar errores) ===
    # Documentos
    documento_identidad = serializers.CharField(read_only=True, required=False)
    numero_documento = serializers.CharField(read_only=True, required=False)
    documento_verificacion = serializers.FileField(read_only=True, required=False)
    
    # Financieros / Configuración (Se definen por si no existen en el modelo directo)
    comision_app = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True, default=0)
    cuenta_bancaria = serializers.CharField(read_only=True, required=False)
    
    # Fechas mapeadas
    creado_en = serializers.DateTimeField(source='created_at', read_only=True)
    actualizado_en = serializers.DateTimeField(source='updated_at', read_only=True)

    # Campos calculados (Stats)
    calificacion_promedio = serializers.FloatField(read_only=True, default=0.0)
    total_ventas = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True, default=0)
    total_pedidos = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Proveedor
        fields = [
            'id', 'usuario_email', 'usuario_nombre', 'usuario_celular',
            'nombre', 'descripcion', 'tipo_proveedor',
            'telefono', 'direccion', 'ciudad',
            'documento_identidad', 'numero_documento',
            'documento_verificacion',
            'verificado', 'activo',
            'calificacion_promedio', 'total_ventas', 'total_pedidos',
            'comision_app', 'cuenta_bancaria',
            'creado_en', 'actualizado_en'
        ]
        read_only_fields = [
            'id', 'creado_en', 'actualizado_en',
            'calificacion_promedio', 'total_ventas', 'total_pedidos',
            'documento_identidad', 'numero_documento', 'documento_verificacion',
            'comision_app', 'cuenta_bancaria'
        ]
        # === CORRECCIÓN DE SWAGGER ===
        ref_name = 'AdminProveedorDetalle' 
        # =============================


# ============================================
# SERIALIZER: VERIFICAR PROVEEDOR
# ============================================

class VerificarProveedorSerializer(serializers.Serializer):
    """
    Serializer para verificar o rechazar un proveedor
    """
    verificado = serializers.BooleanField(
        label="¿Verificar proveedor?"
    )
    motivo = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=500,
        label="Motivo de decisión"
    )


# ============================================
# SERIALIZER: REPARTIDOR - LISTAR
# ============================================

class RepartidorListSerializer(BaseUserSerializerMixin, serializers.ModelSerializer):
    """
    Serializer para listar repartidores (vista simplificada)
    """
    # === CAMPOS BLINDADOS ===
    # Campos calculados (se definen para que DRF no los busque en la BD)
    entregas_completadas = serializers.IntegerField(read_only=True, default=0)
    calificacion_promedio = serializers.FloatField(read_only=True, default=0.0)
    ganancias_totales = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True, default=0)
    
    # Mapeo de fecha
    creado_en = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Repartidor
        fields = [
            'id', 'usuario_email', 'usuario_nombre',
            'estado', 'verificado', 'activo',
            'entregas_completadas', 'calificacion_promedio',
            'ganancias_totales', 'creado_en'
        ]
        read_only_fields = [
            'id', 'creado_en',
            'entregas_completadas', 'calificacion_promedio', 'ganancias_totales'
        ]
        # === CORRECCIÓN DE SWAGGER ===
        ref_name = 'AdminRepartidorList' 
        # =============================


# ============================================
# SERIALIZER: REPARTIDOR - DETALLE
# ============================================

class RepartidorDetalleSerializer(BaseUserSerializerMixin, serializers.ModelSerializer):
    """
    Serializer para detalle completo de repartidor
    """
    usuario_fecha_nacimiento = serializers.CharField(
        source='user.fecha_nacimiento', 
        read_only=True
    )
    
    # === CAMPOS BLINDADOS (Definidos explícitamente) ===
    # Identificación y Vehículo
    tipo_documento = serializers.CharField(read_only=True, required=False)
    cedula = serializers.CharField(read_only=True, required=False)
    placa_vehiculo = serializers.CharField(read_only=True, required=False)
    tipo_vehiculo = serializers.CharField(read_only=True, required=False)
    
    # Archivos/Multimedia
    foto_cedula = serializers.FileField(read_only=True, required=False)
    foto_vehiculo = serializers.FileField(read_only=True, required=False)
    documento_verificacion = serializers.FileField(read_only=True, required=False)
    
    # Datos Bancarios
    numero_cuenta = serializers.CharField(read_only=True, required=False)
    titular_cuenta = serializers.CharField(read_only=True, required=False)
    banco = serializers.CharField(read_only=True, required=False)

    # Campos calculados (Stats)
    entregas_completadas = serializers.IntegerField(read_only=True, default=0)
    entregas_canceladas = serializers.IntegerField(read_only=True, default=0)
    calificacion_promedio = serializers.FloatField(read_only=True, default=0.0)
    ganancias_totales = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True, default=0)

    # Mapeo de fechas
    creado_en = serializers.DateTimeField(source='created_at', read_only=True)
    actualizado_en = serializers.DateTimeField(source='updated_at', read_only=True)

    class Meta:
        model = Repartidor
        fields = [
            'id', 'usuario_email', 'usuario_nombre', 'usuario_celular',
            'usuario_fecha_nacimiento',
            'cedula', 'tipo_documento',
            'placa_vehiculo', 'tipo_vehiculo',
            'foto_cedula', 'foto_vehiculo', 'documento_verificacion',
            'estado', 'verificado', 'activo',
            'entregas_completadas', 'entregas_canceladas',
            'calificacion_promedio', 'ganancias_totales',
            'numero_cuenta', 'titular_cuenta', 'banco',
            'creado_en', 'actualizado_en'
        ]
        read_only_fields = [
            'id', 'creado_en', 'actualizado_en',
            'entregas_completadas', 'entregas_canceladas',
            'calificacion_promedio', 'ganancias_totales',
            'tipo_documento', 'cedula', 'placa_vehiculo', 'tipo_vehiculo'
        ]
        # === CORRECCIÓN DE SWAGGER ===
        ref_name = 'AdminRepartidorDetalle' 
        # =============================


# ============================================
# SERIALIZER: VERIFICAR REPARTIDOR
# ============================================

class VerificarRepartidorSerializer(serializers.Serializer):
    """
    Serializer para verificar o rechazar un repartidor
    """
    verificado = serializers.BooleanField(
        label="¿Verificar repartidor?"
    )
    motivo = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=500,
        label="Motivo de decisión"
    )


# ============================================
# SERIALIZER: ACCIÓN ADMINISTRATIVA
# ============================================

class AccionAdministrativaSerializer(serializers.ModelSerializer):
    """
    Serializer para logs de acciones administrativas
    """
    admin_email = serializers.CharField(
        source='administrador.user.email', 
        read_only=True
    )
    admin_nombre = serializers.CharField(
        source='administrador.user.get_full_name', 
        read_only=True
    )
    tipo_accion_display = serializers.CharField(
        source='get_tipo_accion_display', 
        read_only=True
    )
    resumen = serializers.CharField(read_only=True)

    class Meta:
        model = AccionAdministrativa
        fields = [
            'id', 'admin_email', 'admin_nombre',
            'tipo_accion', 'tipo_accion_display',
            'descripcion', 'resumen',
            'modelo_afectado', 'objeto_id',
            'datos_anteriores', 'datos_nuevos',
            'ip_address', 'exitosa', 'mensaje_error',
            'fecha_accion'
        ]
        read_only_fields = [
            'id', 'admin_email', 'admin_nombre', 'tipo_accion_display',
            'resumen', 'fecha_accion'
        ]


# ============================================
# SERIALIZER: CONFIGURACIÓN DEL SISTEMA
# ============================================

class ConfiguracionSistemaSerializer(serializers.ModelSerializer):
    """
    Serializer para configuración global del sistema
    Solo accesible por super administradores
    """
    modificado_por_email = serializers.CharField(
        source='modificado_por.user.email',
        read_only=True
    )
    
    # Usar validadores directamente en los campos
    comision_app_proveedor = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    comision_app_directo = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    comision_repartidor_proveedor = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    comision_repartidor_directo = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    pedido_minimo = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    pedido_maximo = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )

    class Meta:
        model = ConfiguracionSistema
        fields = [
            # Comisiones
            'comision_app_proveedor', 'comision_app_directo',
            'comision_repartidor_proveedor', 'comision_repartidor_directo',
            # Rifas
            'pedidos_minimos_rifa',
            # Límites
            'pedido_maximo', 'pedido_minimo',
            # Tiempos
            'tiempo_maximo_entrega',
            # Contacto
            'telefono_soporte', 'email_soporte',
            # Estado
            'mantenimiento', 'mensaje_mantenimiento',
            # Auditoría
            'modificado_por_email', 'actualizado_en'
        ]
        read_only_fields = [
            'modificado_por_email', 'actualizado_en'
        ]

    def validate(self, data):
        """Validaciones combinadas"""
        # Obtener valores actuales o usar los proporcionados
        instance = self.instance
        minimo = data.get('pedido_minimo', instance.pedido_minimo if instance else 0)
        maximo = data.get('pedido_maximo', instance.pedido_maximo if instance else 1000)

        if minimo >= maximo:
            raise serializers.ValidationError({
                "pedido_minimo": "El monto mínimo debe ser menor que el máximo"
            })

        return data


# ============================================
# SERIALIZERS OPTIMIZADOS PARA QUERIES
# ============================================

class OptimizedUserListSerializer(UsuarioListSerializer):
    """
    Serializer optimizado para listar usuarios con prefetch
    """
    
    @classmethod
    def setup_eager_loading(cls, queryset):
        """Optimiza las queries con select_related y prefetch_related"""
        # 💡 CORRECCIÓN CRÍTICA: Cambiar 'perfil_usuario' por 'perfil'
        queryset = queryset.select_related('perfil') 
        return queryset


class OptimizedProveedorListSerializer(ProveedorListSerializer):
    """
    Serializer optimizado para listar proveedores con prefetch
    """
    
    @classmethod
    def setup_eager_loading(cls, queryset):
        """Optimiza las queries con select_related y prefetch_related"""
        queryset = queryset.select_related('user')
        return queryset


class OptimizedRepartidorListSerializer(RepartidorListSerializer):
    """
    Serializer optimizado para listar repartidores con prefetch
    """
    
    @classmethod
    def setup_eager_loading(cls, queryset):
        """Optimiza las queries con select_related y prefetch_related"""
        queryset = queryset.select_related('user')
        return queryset


class OptimizedAccionAdministrativaSerializer(AccionAdministrativaSerializer):
    """
    Serializer optimizado para logs con prefetch
    """
    
    @classmethod
    def setup_eager_loading(cls, queryset):
        """Optimiza las queries con select_related"""
        queryset = queryset.select_related(
            'administrador',
            'administrador__user'
        )
        return queryset


class UsuarioNormalSerializer(serializers.Serializer):
    """
    Serializer para la acción 'normales' (Solo usado para la estructura de datos básicos)
    """
    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    is_active = serializers.BooleanField()
    last_login = serializers.DateTimeField(allow_null=True)

class SolicitudCambioRolAdminSerializer(serializers.ModelSerializer):
    """
    Serializer específico para que los administradores vean las solicitudes.
    Rompe la dependencia circular con la app 'usuarios'.
    """
    usuario_email = serializers.CharField(source='user.email', read_only=True)
    usuario_nombre = serializers.CharField(source='user.get_full_name', read_only=True)
    admin_responsable_nombre = serializers.CharField(source='admin_responsable.get_full_name', read_only=True)
    
    class Meta:
        model = SolicitudCambioRol
        fields = [
            'id', 
            'usuario_email', 
            'usuario_nombre',
            'rol_solicitado', 
            'estado', 
            'motivo', 
            'admin_responsable_nombre',
            'motivo_respuesta',
            'creado_en', 
            'respondido_en'
        ]
        read_only_fields = fields 
