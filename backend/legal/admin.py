from django.contrib import admin
from django.utils.html import format_html
from django.db import models
from django.forms import Textarea
from .models import DocumentoLegal


@admin.register(DocumentoLegal)
class DocumentoLegalAdmin(admin.ModelAdmin):
    """
    Administración de documentos legales en el panel de Django Admin
    """
    list_display = [
        'tipo_badge',
        'version_badge',
        'activo_badge',
        'fecha_modificacion',
        'modificado_por',
        'preview_button'
    ]
    list_filter = ['tipo', 'activo', 'fecha_modificacion']
    search_fields = ['contenido', 'version']
    readonly_fields = [
        'fecha_creacion',
        'fecha_modificacion',
        'vista_previa_html'
    ]

    fieldsets = (
        ('📋 Información General', {
            'fields': ('tipo', 'version', 'activo')
        }),
        ('✍️ Contenido', {
            'fields': ('contenido',),
            'description': '✨ Usa HTML para dar formato al contenido. '
                          'Puedes usar: <h1>, <h2>, <h3>, <p>, <ul>, <li>, <strong>, <br>, etc.'
        }),
        ('👁️ Vista Previa', {
            'fields': ('vista_previa_html',),
            'classes': ('wide',),
            'description': 'Vista previa de cómo se verá el documento renderizado'
        }),
        ('🕐 Metadata', {
            'fields': ('modificado_por', 'fecha_creacion', 'fecha_modificacion'),
            'classes': ('collapse',)
        }),
    )

    # Widget personalizado para el campo de contenido
    formfield_overrides = {
        models.TextField: {
            'widget': Textarea(attrs={
                'rows': 25,
                'cols': 100,
                'style': 'font-family: monospace; font-size: 13px;'
            })
        },
    }

    class Media:
        css = {
            'all': ('admin/css/legal_admin.css',)
        }

    def tipo_badge(self, obj):
        """Muestra el tipo como badge colorido"""
        colors = {
            'TERMINOS': '#4CAF50',
            'PRIVACIDAD': '#2196F3',
        }
        color = colors.get(obj.tipo, '#9E9E9E')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 4px 12px; '
            'border-radius: 12px; font-size: 11px; font-weight: bold; '
            'display: inline-block;">{}</span>',
            color,
            obj.get_tipo_display()
        )
    tipo_badge.short_description = 'Tipo'

    def version_badge(self, obj):
        """Muestra la versión como badge"""
        return format_html(
            '<span style="background-color: #FF9800; color: white; padding: 4px 10px; '
            'border-radius: 8px; font-size: 11px; font-weight: bold;">{}</span>',
            obj.version
        )
    version_badge.short_description = 'Versión'

    def activo_badge(self, obj):
        """Muestra el estado activo con emoji"""
        if obj.activo:
            return format_html(
                '<span style="color: #4CAF50; font-size: 20px;" title="Activo">✅</span>'
            )
        return format_html(
            '<span style="color: #F44336; font-size: 20px;" title="Inactivo">❌</span>'
        )
    activo_badge.short_description = 'Estado'

    def preview_button(self, obj):
        """Botón para ver vista previa"""
        return format_html(
            '<a href="#vista_previa_html" style="background-color: #673AB7; color: white; '
            'padding: 6px 12px; border-radius: 6px; text-decoration: none; '
            'font-size: 11px; font-weight: bold;">👁️ Ver Preview</a>'
        )
    preview_button.short_description = 'Acciones'

    def vista_previa_html(self, obj):
        """Muestra una vista previa renderizada del HTML"""
        if not obj.contenido:
            return format_html('<p style="color: #999;">No hay contenido para mostrar</p>')

        return format_html(
            '<div style="background-color: #f5f5f5; padding: 30px; border-radius: 8px; '
            'border: 2px solid #e0e0e0; max-height: 600px; overflow-y: auto;">'
            '<div style="background-color: white; padding: 40px; border-radius: 8px; '
            'box-shadow: 0 2px 8px rgba(0,0,0,0.1); font-family: -apple-system, '
            'BlinkMacSystemFont, \'Segoe UI\', Roboto, sans-serif; line-height: 1.6; '
            'color: #333;">'
            '{}'
            '</div>'
            '</div>',
            obj.contenido
        )
    vista_previa_html.short_description = '👁️ Vista Previa del Documento'

    def save_model(self, request, obj, form, change):
        """
        Guardar el usuario que modificó el documento
        """
        if change:
            obj.modificado_por = request.user.username
        super().save_model(request, obj, form, change)
