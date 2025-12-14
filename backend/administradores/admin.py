# -*- coding: utf-8 -*-
# administradores/admin.py
"""
Configuración del Django Admin para el módulo de administradores
Interfaz completa para gestionar administradores
Logs de acciones con filtros avanzados
Configuración del sistema
Gestión de permisos para solicitudes
"""

import json
from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from .models import Administrador, AccionAdministrativa, ConfiguracionSistema

# ============================================
# CONFIGURACIÓN DE ESTILOS Y CONSTANTES
# ============================================

ADMIN_STYLES = {
    "success": "#28a745",
    "danger": "#dc3545",
    "warning": "#ffc107",
    "info": "#17a2b8",
    "primary": "#007bff",
    "secondary": "#6c757d",
    "purple": "#6f42c1",
    "inactive": "#999999",
}

def _render_badge(text, color_code, bold=False):
    """Helper para renderizar badges HTML de forma consistente"""
    font_weight = "bold" if bold else "normal"
    return format_html(
        '<span style="background-color: {}; color: white; padding: 3px 10px; '
        'border-radius: 3px; font-weight: {}; font-size: 12px;">{}</span>',
        color_code,
        font_weight,
        text,
    )

def _render_status_text(text, color_code, bold=True):
    """Helper para texto coloreado sin fondo"""
    font_weight = "bold" if bold else "normal"
    return format_html(
        '<span style="color: {}; font-weight: {};">{}</span>',
        color_code,
        font_weight,
        text
    )

# ============================================
# ADMIN: ADMINISTRADOR
# ============================================

@admin.register(Administrador)
class AdministradorAdmin(admin.ModelAdmin):
    """
    Administración de perfiles de administradores
    """
    list_display = [
        "id",
        "usuario_info",
        "cargo",
        "departamento",
        "permisos_resumen",
        "total_acciones",
        "activo_badge",
        "creado_en",
    ]

    list_filter = [
        "activo",
        "creado_en",
        # Agrupamos permisos para limpiar la UI lateral si es necesario
        "puede_gestionar_usuarios",
        "puede_gestionar_pedidos",
        "puede_configurar_sistema",
    ]

    search_fields = [
        "user__email",
        "user__first_name",
        "user__last_name",
        "cargo",
        "departamento",
    ]

    readonly_fields = [
        "user",
        "total_acciones",
        "es_super_admin",
        "creado_en",
        "actualizado_en",
    ]

    fieldsets = (
        ("Información del Usuario", {"fields": ("user", "cargo", "departamento")}),
        (
            "Permisos de Gestión",
            {
                "fields": (
                    "puede_gestionar_usuarios",
                    "puede_gestionar_pedidos",
                    "puede_gestionar_proveedores",
                    "puede_gestionar_repartidores",
                    "puede_gestionar_rifas",
                    "puede_ver_reportes",
                    "puede_configurar_sistema",
                    "puede_gestionar_solicitudes",
                ),
                "description": "Configura los permisos específicos del administrador",
            },
        ),
        ("Estado", {"fields": ("activo",)}),
        (
            "Métricas y Auditoría",
            {
                "fields": (
                    "total_acciones",
                    "es_super_admin",
                    "creado_en",
                    "actualizado_en",
                ),
                "classes": ("collapse",),
            },
        ),
    )

    ordering = ["-creado_en"]
    date_hierarchy = "creado_en"

    def usuario_info(self, obj):
        """Muestra información del usuario"""
        return format_html(
            "<strong>{}</strong><br><small>{}</small>",
            obj.user.get_full_name() or obj.user.username,
            obj.user.email,
        )
    usuario_info.short_description = "Usuario"

    def permisos_resumen(self, obj):
        """Muestra resumen de permisos iterando sobre un mapa"""
        permission_map = [
            (obj.puede_gestionar_usuarios, "Usuarios"),
            (obj.puede_gestionar_pedidos, "Pedidos"),
            (obj.puede_gestionar_proveedores, "Proveedores"),
            (obj.puede_gestionar_repartidores, "Repartidores"),
            (obj.puede_gestionar_rifas, "Rifas"),
            (obj.puede_ver_reportes, "Reportes"),
            (obj.puede_gestionar_solicitudes, "Solicitudes"),
            (obj.puede_configurar_sistema, "Sistema"),
        ]

        active_perms = [label for has_perm, label in permission_map if has_perm]

        if not active_perms:
            return format_html('<span style="color: {};">Sin permisos</span>', ADMIN_STYLES['inactive'])

        return format_html("<br>".join(active_perms))
    permisos_resumen.short_description = "Permisos Asignados"

    def activo_badge(self, obj):
        """Badge de estado activo"""
        if obj.activo:
            return _render_badge("Activo", ADMIN_STYLES["success"])
        return _render_badge("Inactivo", ADMIN_STYLES["danger"])
    activo_badge.short_description = "Estado"

    def has_delete_permission(self, request, obj=None):
        return False


# ============================================
# ADMIN: ACCIÓN ADMINISTRATIVA
# ============================================

@admin.register(AccionAdministrativa)
class AccionAdministrativaAdmin(admin.ModelAdmin):
    """
    Administración de logs de acciones administrativas
    """
    list_display = [
        "id",
        "fecha_accion",
        "administrador_info",
        "tipo_accion_badge",
        "descripcion_corta",
        "modelo_afectado",
        "exitosa_badge",
    ]

    list_filter = [
        "tipo_accion",
        "exitosa",
        "fecha_accion",
        "modelo_afectado",
    ]

    search_fields = [
        "descripcion",
        "administrador__user__email",
        "objeto_id",
        "ip_address",
    ]

    readonly_fields = [f.name for f in AccionAdministrativa._meta.fields] + [
        "datos_anteriores_formatted", "datos_nuevos_formatted"
    ]

    fieldsets = (
        ("Resumen", {
            "fields": ("administrador", "tipo_accion", "exitosa", "fecha_accion")
        }),
        ("Detalle de la Acción", {
            "fields": ("descripcion", "modelo_afectado", "objeto_id", "mensaje_error")
        }),
        ("Datos Técnicos (JSON)", {
            "fields": ("datos_anteriores_formatted", "datos_nuevos_formatted"),
            "classes": ("collapse",),
        }),
        ("Metadatos de Conexión", {
            "fields": ("ip_address", "user_agent"),
            "classes": ("collapse",),
        }),
    )

    ordering = ["-fecha_accion"]
    date_hierarchy = "fecha_accion"

    def administrador_info(self, obj):
        if obj.administrador:
            return format_html(
                "<strong>{}</strong><br><small>{}</small>",
                obj.administrador.user.get_full_name(),
                obj.administrador.user.email,
            )
        return format_html('<span style="color: {};">Admin eliminado</span>', ADMIN_STYLES["inactive"])
    administrador_info.short_description = "Administrador"

    def tipo_accion_badge(self, obj):
        """Badge dinámico basado en el tipo de acción"""
        # Mapa de colores según palabras clave en el tipo de acción
        action_type = obj.tipo_accion.lower()
        color = ADMIN_STYLES["secondary"]

        if "crear" in action_type or "activar" in action_type or "aceptar" in action_type or "verificar" in action_type:
            color = ADMIN_STYLES["success"]
        elif "editar" in action_type or "cambiar" in action_type:
            color = ADMIN_STYLES["primary"]
        elif "desactivar" in action_type or "rechazar" in action_type or "cancelar" in action_type:
            color = ADMIN_STYLES["danger"]
        elif "configurar" in action_type:
            color = ADMIN_STYLES["purple"]
        
        return _render_badge(obj.get_tipo_accion_display(), color)
    tipo_accion_badge.short_description = "Tipo"

    def exitosa_badge(self, obj):
        if obj.exitosa:
            return _render_status_text("Exitosa", ADMIN_STYLES["success"])
        return _render_status_text("Fallida", ADMIN_STYLES["danger"])
    exitosa_badge.short_description = "Resultado"

    def _format_json_field(self, data):
        """Formatea diccionario a JSON legible"""
        if not data:
            return "-"
        formatted = json.dumps(data, indent=2, ensure_ascii=False)
        return format_html("<pre style='font-size: 11px; line-height: 1.2;'>{}</pre>", formatted)

    def datos_anteriores_formatted(self, obj):
        return self._format_json_field(obj.datos_anteriores)
    datos_anteriores_formatted.short_description = "Datos Anteriores"

    def datos_nuevos_formatted(self, obj):
        return self._format_json_field(obj.datos_nuevos)
    datos_nuevos_formatted.short_description = "Datos Nuevos"

    def descripcion_corta(self, obj):
        return (obj.descripcion[:90] + "...") if len(obj.descripcion) > 90 else obj.descripcion
    descripcion_corta.short_description = "Descripción"

    # Desactivar modificaciones para mantener integridad de logs
    def has_add_permission(self, request): return False
    def has_change_permission(self, request, obj=None): return False
    def has_delete_permission(self, request, obj=None): return False


# ============================================
# ADMIN: CONFIGURACIÓN DEL SISTEMA
# ============================================

@admin.register(ConfiguracionSistema)
class ConfiguracionSistemaAdmin(admin.ModelAdmin):
    """
    Administración de la configuración del sistema (Singleton)
    """
    list_display = [
        "id",
        "estado_comisiones",
        "pedidos_minimos_rifa",
        "mantenimiento_badge",
        "modificado_por_info",
        "actualizado_en",
    ]

    readonly_fields = ["modificado_por", "actualizado_en"]

    fieldsets = (
        ("Comisiones", {
            "fields": (
                ("comision_app_proveedor", "comision_repartidor_proveedor"),
                ("comision_app_directo", "comision_repartidor_directo"),
            ),
            "description": "Definición de porcentajes de ganancia"
        }),
        ("Límites Operativos", {
            "fields": (
                ("pedido_minimo", "pedido_maximo"),
                "tiempo_maximo_entrega",
                "pedidos_minimos_rifa"
            )
        }),
        ("Soporte y Contacto", {
            "fields": ("telefono_soporte", "email_soporte")
        }),
        ("Estado del Sistema", {
            "fields": ("mantenimiento", "mensaje_mantenimiento"),
            "classes": ("collapse", "wide"),
            "description": "Control de acceso global a la aplicación"
        }),
        ("Auditoría", {
            "fields": ("modificado_por", "actualizado_en"),
            "classes": ("collapse",)
        }),
    )

    def estado_comisiones(self, obj):
        """Resumen visual de comisiones"""
        return format_html(
            "Prov: <b>{}%</b> / Dir: <b>{}%</b>",
            obj.comision_app_proveedor,
            obj.comision_app_directo
        )
    estado_comisiones.short_description = "Comisiones App"

    def modificado_por_info(self, obj):
        if obj.modificado_por:
            return format_html(
                "{} ({})",
                obj.modificado_por.user.get_full_name(),
                obj.modificado_por.user.email
            )
        return "-"
    modificado_por_info.short_description = "Última Modificación"

    def mantenimiento_badge(self, obj):
        if obj.mantenimiento:
            return _render_badge("MANTENIMIENTO", ADMIN_STYLES["danger"], bold=True)
        return _render_badge("Operativo", ADMIN_STYLES["success"])
    mantenimiento_badge.short_description = "Estado"

    def save_model(self, request, obj, form, change):
        """Asigna automáticamente el administrador que realiza el cambio"""
        admin_profile = getattr(request.user, 'perfil_admin', None)
        if admin_profile:
            obj.modificado_por = admin_profile
        super().save_model(request, obj, form, change)

    def has_add_permission(self, request):
        """Solo permitir una instancia"""
        return not ConfiguracionSistema.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False

    # Personalización del título de la sección
    def changelist_view(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context['title'] = 'Configuración Global del Sistema'
        return super().changelist_view(request, extra_context=extra_context)

# ============================================
# PERSONALIZACIÓN HEADER
# ============================================

admin.site.site_header = "JP Express - Panel de Administración"
admin.site.site_title = "JP Express Admin"
admin.site.index_title = "Gestión del Sistema"