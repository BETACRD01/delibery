# envios/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import Envio

@admin.register(Envio)
class EnvioAdmin(admin.ModelAdmin):
    """
    Administración de la logística y envíos.
    """
    list_display = [
        'id',
        'pedido_link',          # Enlace al pedido
        'distancia_km',
        'tiempo_estimado_mins',
        'total_envio_format',   # Costo formateado
        'estado_envio_badge',   # Badge visual (En camino / Pendiente)
        'es_nocturno_icon',     # Icono si es tarifa nocturna
    ]

    list_filter = [
        'en_camino',
        'fecha_salida',
        'fecha_llegada',
    ]

    search_fields = [
        'pedido__numero_pedido', # Buscar por número de pedido (ej: JP-2024-...)
        'pedido__cliente__user__email',
    ]

    readonly_fields = [
        'pedido_link_detail',
        'distancia_km',
        'tiempo_estimado_mins',
        'costo_base',
        'costo_km_adicional',
        'recargo_nocturno',
        'total_envio',
        'lat_origen_calc',
        'lng_origen_calc',
        'lat_destino_calc',
        'lng_destino_calc',
    ]

    fieldsets = (
        ('Resumen', {
            'fields': ('pedido_link_detail', 'total_envio', 'en_camino')
        }),
        ('Datos Logísticos (Google Maps)', {
            'fields': (
                ('distancia_km', 'tiempo_estimado_mins'),
                ('fecha_salida', 'fecha_llegada')
            )
        }),
        ('Desglose de Costos', {
            'fields': (
                'costo_base', 
                'costo_km_adicional', 
                'recargo_nocturno'
            )
        }),
        ('Auditoría de Coordenadas', {
            'classes': ('collapse',),
            'fields': (
                ('lat_origen_calc', 'lng_origen_calc'),
                ('lat_destino_calc', 'lng_destino_calc')
            )
        }),
    )

    # --- MÉTODOS DE VISUALIZACIÓN ---

    def pedido_link(self, obj):
        """Genera un link clickable al pedido asociado en la lista"""
        if not obj.pedido:
            return "-"
        url = reverse('admin:pedidos_pedido_change', args=[obj.pedido.id])
        return format_html('<a href="{}">{}</a>', url, obj.pedido.numero_pedido)
    pedido_link.short_description = 'Pedido Asociado'

    def pedido_link_detail(self, obj):
        """Genera un link para el detalle (vista de edición)"""
        return self.pedido_link(obj)
    pedido_link_detail.short_description = 'Ir al Pedido'

    def total_envio_format(self, obj):
        return f"${obj.total_envio}"
    total_envio_format.short_description = 'Costo Total'

    def estado_envio_badge(self, obj):
        """Badge de color para saber si está en camino"""
        if obj.fecha_llegada:
            return format_html('<span style="color:green; font-weight:bold;">Entregado</span>')
        elif obj.en_camino:
            return format_html('<span style="background-color:#17a2b8; color:white; padding:3px 8px; border-radius:10px;">En Ruta 🛵</span>')
        return format_html('<span style="color:gray;">Pendiente</span>')
    estado_envio_badge.short_description = 'Estado'

    def es_nocturno_icon(self, obj):
        """Muestra una luna si se cobró recargo nocturno"""
        if obj.recargo_nocturno > 0:
            return format_html('<span title="Tarifa Nocturna aplicada">🌙 Sí</span>')
        return "-"
    es_nocturno_icon.short_description = 'Nocturno'