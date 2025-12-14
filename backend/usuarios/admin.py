from django.contrib import admin, messages
from django.utils.html import format_html
from django.db import transaction
from django.utils.translation import ngettext
from .models import Perfil, DireccionFavorita, MetodoPago, SolicitudCambioRol
import logging

logger = logging.getLogger('usuarios')

# ============================================
# MIXINS Y UTILIDADES
# ============================================

class UserRelatedMixin:
    """Mixin para optimizar la carga de usuarios relacionados."""
    list_select_related = ('user',)

    @admin.display(description='Email del Usuario', ordering='user__email')
    def user_email(self, obj):
        return obj.user.email

    @admin.display(description='Teléfono')
    def telefono_usuario(self, obj):
        return getattr(obj.user, 'celular', '-')
    
    # Alias para compatibilidad con el error reportado anteriormente
    def usuario_email(self, obj):
        return obj.user.email
    usuario_email.short_description = 'Email'

# ============================================
# PERFIL ADMIN
# ============================================
@admin.register(Perfil)
class PerfilAdmin(UserRelatedMixin, admin.ModelAdmin):
    list_display = [
        'user_email',
        'telefono_usuario',
        'total_pedidos',
        'pedidos_mes_actual',
        'participa_en_sorteos',
        'calificacion_formateada',
        'es_cliente_frecuente_display',  
        'tiene_fcm_token',
        'actualizado_en'
    ]

    # Filtros: Se eliminaron propiedades computadas que causaban error
    list_filter = [
        'calificacion',
        'participa_en_sorteos',
        'actualizado_en'
    ]

    search_fields = ['user__email', 'user__first_name', 'user__last_name', 'user__celular']
    
    # ✅ CORRECCIÓN 1: Está declarado aquí, así que DEBE existir la función abajo
    readonly_fields = [
        'total_pedidos', 'pedidos_mes_actual', 'calificacion', 
        'edad', 'es_cliente_frecuente_display', 'fcm_token', 
        'creado_en', 'actualizado_en',
        'puede_recibir_notificaciones' 
    ]

    fieldsets = (
        ('Usuario', {'fields': ('user',)}),
        ('Información Personal', {'fields': ('foto_perfil', 'fecha_nacimiento', 'edad')}),
        ('Configuración FCM', {
            'fields': ('puede_recibir_notificaciones', 'fcm_token'),
            'classes': ('collapse',)
        }),
        ('Métricas', {
            'fields': ('total_pedidos', 'pedidos_mes_actual', 'es_cliente_frecuente_display'),
        }),
        ('Sorteos y Rifas', {'fields': ('participa_en_sorteos',)}),
        ('Calidad', {'fields': ('calificacion', 'total_resenas')}),
    )

    actions = [
        'resetear_contador_mensual_bulk',
        'activar_rifas_bulk',
        'desactivar_rifas_bulk',
    ]

    # --- Métodos de Visualización ---

    @admin.display(description='Calificación', ordering='calificacion')
    def calificacion_formateada(self, obj):
        val = float(obj.calificacion or 0)
        return f"{val:.1f} / 5.0"
    
    @admin.display(description='Cliente Frecuente', boolean=True)
    def es_cliente_frecuente_display(self, obj):
        """Wrapper para mostrar la propiedad como booleano en admin."""
        return obj.es_cliente_frecuente

    @admin.display(description='FCM Activo', boolean=True)
    def tiene_fcm_token(self, obj):
        return bool(obj.fcm_token)

    # ✅ CORRECCIÓN 2: AQUÍ ESTÁ LA FUNCIÓN QUE FALTABA
    # Esta función calcula el valor para el campo 'puede_recibir_notificaciones'
    @admin.display(description='Recibe Notificaciones', boolean=True)
    def puede_recibir_notificaciones(self, obj):
        """Determina si el usuario puede recibir notificaciones push"""
        tiene_token = bool(obj.fcm_token)
        # Verificamos la configuración en el modelo User (si existe) o asumimos True
        config_activa = getattr(obj.user, 'notificaciones_push', True) 
        return tiene_token and config_activa

    # --- Acciones Optimizadas ---

    @admin.action(description='Resetear contador mensual (Lote)')
    def resetear_contador_mensual_bulk(self, request, queryset):
        updated = queryset.update(pedidos_mes_actual=0)
        self.message_user(request, f'{updated} contadores reseteados.', messages.SUCCESS)

    @admin.action(description='Activar participación en rifas')
    def activar_rifas_bulk(self, request, queryset):
        updated = queryset.update(participa_en_sorteos=True)
        self.message_user(request, f'{updated} perfiles activados para rifas.', messages.SUCCESS)

    @admin.action(description='Desactivar participación en rifas')
    def desactivar_rifas_bulk(self, request, queryset):
        updated = queryset.update(participa_en_sorteos=False)
        self.message_user(request, f'{updated} perfiles desactivados de rifas.', messages.SUCCESS)


# ============================================
# DIRECCIÓN FAVORITA ADMIN
# ============================================

@admin.register(DireccionFavorita)
class DireccionFavoritaAdmin(UserRelatedMixin, admin.ModelAdmin):
    list_display = [
        'user_email',
        'tipo_display',
        'etiqueta',
        'ciudad',
        'es_predeterminada',
        'activa',
        'veces_usada'
    ]

    list_filter = ['tipo', 'es_predeterminada', 'activa', 'ciudad']
    search_fields = ['user__email', 'etiqueta', 'direccion', 'ciudad']
    
    actions = ['marcar_como_predeterminada', 'toggle_activar_bulk']

    @admin.display(description='Tipo', ordering='tipo')
    def tipo_display(self, obj):
        return obj.get_tipo_display()

    @admin.action(description='Hacer predeterminada (Solo primera selección)')
    def marcar_como_predeterminada(self, request, queryset):
        if queryset.count() != 1:
            self.message_user(request, "Por favor, selecciona solo una dirección.", messages.ERROR)
            return

        direccion = queryset.first()
        
        with transaction.atomic():
            DireccionFavorita.objects.filter(
                user=direccion.user, 
                es_predeterminada=True
            ).update(es_predeterminada=False)
            
            direccion.es_predeterminada = True
            direccion.save(update_fields=['es_predeterminada'])

        self.message_user(request, f"Dirección '{direccion.etiqueta}' establecida como predeterminada.")

    @admin.action(description='Alternar estado activo/inactivo')
    def toggle_activar_bulk(self, request, queryset):
        updated = queryset.update(activa=True)
        self.message_user(request, f"{updated} direcciones activadas.")


# ============================================
# MÉTODO DE PAGO ADMIN
# ============================================

@admin.register(MetodoPago)
class MetodoPagoAdmin(UserRelatedMixin, admin.ModelAdmin):
    list_display = [
        'user_email',
        'tipo_display',
        'alias',
        'estado_comprobante',
        'es_predeterminado',
        'activo',
        'created_at'
    ]

    # CORRECCIÓN: Eliminado 'tiene_comprobante' (propiedad)
    list_filter = ['tipo', 'es_predeterminado', 'activo']
    
    search_fields = ['user__email', 'alias']

    actions = ['validar_comprobantes_bulk']

    @admin.display(description='Tipo', ordering='tipo')
    def tipo_display(self, obj):
        return obj.get_tipo_display()

    @admin.display(description='Comprobante')
    def estado_comprobante(self, obj):
        if obj.tiene_comprobante:
            return "Cargado"
        return "Requerido" if obj.tipo == 'transferencia' else "No aplica"

    @admin.action(description='Validar comprobantes seleccionados')
    def validar_comprobantes_bulk(self, request, queryset):
        updated = queryset.filter(
            requiere_verificacion=True
        ).update(requiere_verificacion=False)
        
        self.message_user(request, f"{updated} comprobantes marcados como verificados.")


# ============================================
# SOLICITUD DE CAMBIO DE ROL
# ============================================

@admin.register(SolicitudCambioRol)
class SolicitudCambioRolAdmin(UserRelatedMixin, admin.ModelAdmin):
    # CORRECCIÓN: 'usuario_email' ahora existe gracias al Mixin
    list_display = [
        'usuario_email',
        'rol_solicitado',
        'estado_solicitud',
        'creado_en'
    ]
    
    list_filter = ['estado', 'rol_solicitado']
    search_fields = ['user__email', 'motivo']
    list_select_related = ('user', 'admin_responsable')
    
    readonly_fields = ['user', 'rol_solicitado', 'motivo', 'creado_en', 'respondido_en']
    
    actions = ['procesar_aceptacion', 'procesar_rechazo']
    
    @admin.display(description='Estado', ordering='estado')
    def estado_solicitud(self, obj):
        return obj.get_estado_display()
    
    @admin.action(description='Aceptar solicitudes pendientes')
    def procesar_aceptacion(self, request, queryset):
        procesadas = 0
        for solicitud in queryset.filter(estado='PENDIENTE'):
            try:
                solicitud.aceptar(request.user, 'Aprobado por administración')
                procesadas += 1
            except Exception as e:
                logger.error(f"Error procesando solicitud {solicitud.id}: {e}")
        
        self.message_user(request, f"{procesadas} solicitudes aceptadas correctamente.")

    @admin.action(description='Rechazar solicitudes pendientes')
    def procesar_rechazo(self, request, queryset):
        procesadas = 0
        for solicitud in queryset.filter(estado='PENDIENTE'):
            solicitud.rechazar(request.user, 'Rechazado por administración')
            procesadas += 1
        
        self.message_user(request, f"{procesadas} solicitudes rechazadas.")