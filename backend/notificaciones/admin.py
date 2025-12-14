# notificaciones/admin.py (VERSIÓN OPTIMIZADA)
"""
Panel administrativo avanzado para Notificaciones.
Incluye formateo de JSON, acciones de reenvío y badges visuales.
"""

import json
import logging
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import Notificacion, TipoNotificacion

logger = logging.getLogger('notificaciones.admin')


@admin.register(Notificacion)
class NotificacionAdmin(admin.ModelAdmin):
    """
    Gestión de alertas enviadas a los usuarios.
    Optimizado para depuración de Firebase.
    """
    
    # LISTADO PRINCIPAL
    list_display = [
        'titulo_corto',
        'usuario_link',
        'tipo_badge',
        'pedido_link',
        'estado_push',   # Icono de envío push
        'estado_lectura',# Leída / No leída
        'creada_en',
    ]

    list_filter = [
        'tipo',
        'enviada_push',
        'leida',
        ('creada_en', admin.DateFieldListFilter),
        'error_envio',   # Filtra las que fallaron
    ]

    search_fields = [
        'usuario__email',
        'usuario__first_name',
        'titulo',
        'mensaje',
        'pedido__numero_pedido',
        'id'
    ]

    # DETALLE (READ ONLY)
    # Hacemos casi todo solo lectura para mantener la integridad del historial
    readonly_fields = [
        'id', 
        'creada_en', 
        'leida_en', 
        'json_datos_extra', # Campo calculado bonito
        'pedido_link_detail',
        'error_envio'
    ]

    fieldsets = (
        ('Destinatario', {
            'fields': ('usuario', 'pedido_link_detail')
        }),
        ('Contenido', {
            'fields': ('tipo', 'titulo', 'mensaje', 'json_datos_extra')
        }),
        ('Estado del Envío (Firebase)', {
            'fields': ('enviada_push', 'error_envio'),
            'classes': ('collapse',),
        }),
        ('Auditoría de Lectura', {
            'fields': ('leida', 'leida_en', 'creada_en', 'id'),
            'classes': ('collapse',),
        }),
    )

    actions = ['marcar_como_leida', 'reenviar_push_seleccionadas']

    # ==========================================================
    #  OPTIMIZACIÓN DE CONSULTAS
    # ==========================================================
    
    def get_queryset(self, request):
        """Evita el problema N+1 cargando relaciones clave"""
        return super().get_queryset(request).select_related('usuario', 'pedido')

    # ==========================================================
    #  BADGES Y CAMPOS CALCULADOS
    # ==========================================================

    def titulo_corto(self, obj):
        return (obj.titulo[:30] + '...') if len(obj.titulo) > 30 else obj.titulo
    titulo_corto.short_description = "Título"

    def usuario_link(self, obj):
        """Link directo al perfil del usuario"""
        url = reverse("admin:authentication_user_change", args=[obj.usuario.id])
        return format_html('<a href="{}">{}</a>', url, obj.usuario.email)
    usuario_link.short_description = "Usuario"
    usuario_link.admin_order_field = 'usuario__email'

    def pedido_link(self, obj):
        """Link corto al pedido en la lista"""
        if not obj.pedido:
            return "-"
        url = reverse("admin:pedidos_pedido_change", args=[obj.pedido.id])
        return format_html('<a href="{}" style="font-weight:bold;">#{}</a>', url, obj.pedido.numero_pedido or obj.pedido.id)
    pedido_link.short_description = "Pedido"

    def pedido_link_detail(self, obj):
        """Link completo al pedido en el detalle"""
        return self.pedido_link(obj)
    pedido_link_detail.short_description = "Pedido Relacionado"

    def tipo_badge(self, obj):
        colores = {
            TipoNotificacion.PEDIDO: 'blue',
            TipoNotificacion.SISTEMA: 'gray',
            TipoNotificacion.PROMOCION: 'green',
            TipoNotificacion.REPARTIDOR: 'orange',
            TipoNotificacion.PAGO: 'purple',
        }
        color = colores.get(obj.tipo, 'black')
        return format_html(
            '<span style="color:{}; font-weight:bold;">{}</span>', 
            color, obj.get_tipo_display()
        )
    tipo_badge.short_description = "Tipo"

    def estado_push(self, obj):
        if obj.enviada_push:
            return format_html('<span style="color:green;">✔ Enviado</span>')
        if obj.error_envio:
            return format_html('<span style="color:red; font-weight:bold;" title="{}">✘ Error</span>', obj.error_envio)
        return format_html('<span style="color:gray;">Solo App</span>')
    estado_push.short_description = "Push"

    def estado_lectura(self, obj):
        if obj.leida:
            return format_html('<span style="color:green;">Leída</span>')
        return format_html('<span style="color:#ccc;">No leída</span>')
    estado_lectura.short_description = "Estado"

    def json_datos_extra(self, obj):
        """Formatea el JSON para que sea legible en el admin"""
        if not obj.datos_extra:
            return "-"
        try:
            # Convertimos a string bonito con indentación
            json_str = json.dumps(obj.datos_extra, indent=4, ensure_ascii=False)
            # Usamos <pre> para mantener el formato
            return mark_safe(f'<pre>{json_str}</pre>')
        except Exception:
            return str(obj.datos_extra)
    json_datos_extra.short_description = "Datos Extra (JSON)"

    # ==========================================================
    #  ACCIONES PERSONALIZADAS
    # ==========================================================

    @admin.action(description="Reenviar notificación PUSH (Intento manual)")
    def reenviar_push_seleccionadas(self, request, queryset):
        """
        Intenta reenviar la notificación a Firebase.
        Útil si el usuario dice que no le llegó.
        """
        from notificaciones.services import enviar_notificacion_push
        
        enviadas = 0
        fallidas = 0
        
        for notif in queryset:
            # Reusamos el servicio core, pero le decimos que NO guarde una copia nueva en BD
            exito, error = enviar_notificacion_push(
                usuario=notif.usuario,
                titulo=notif.titulo,
                mensaje=notif.mensaje,
                datos_extra=notif.datos_extra,
                guardar_en_bd=False, # ¡Importante! No duplicar historial
                tipo=notif.tipo,
                pedido=notif.pedido
            )
            
            if exito:
                notif.enviada_push = True
                notif.error_envio = None # Limpiamos error previo
                enviadas += 1
            else:
                notif.enviada_push = False
                notif.error_envio = f"Reenvío fallido: {error}"
                fallidas += 1
            
            notif.save(update_fields=['enviada_push', 'error_envio'])

        self.message_user(
            request, 
            f"Proceso finalizado: {enviadas} enviadas correctamente, {fallidas} fallaron.",
            level='SUCCESS' if fallidas == 0 else 'WARNING'
        )

    @admin.action(description="Marcar como LEÍDAS")
    def marcar_como_leida(self, request, queryset):
        rows = queryset.update(leida=True)
        self.message_user(request, f"{rows} notificaciones marcadas como leídas.")