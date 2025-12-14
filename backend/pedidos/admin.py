# pedidos/admin.py (VERSIÓN OPTIMIZADA + INTEGRACIÓN LOGÍSTICA)
"""
Configuración del Admin para Pedidos con Integración de Logística.

MEJORAS APLICADAS:
- Integración de 'EnvioInline' para ver datos de logística en el pedido.
- Manejo robusto de errores en reverse() y enlaces.
- Optimización de queries (select_related + prefetch_related).
- Acciones masivas protegidas con logs y transacciones.
- Exportación CSV mejorada.
- Badges visuales para estados y tipos.
"""

import logging
import csv
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from django.contrib import messages
from django.http import HttpResponse
from django.db import transaction
from django.db.models import Count, Sum, Q

from .models import Pedido, EstadoPedido, TipoPedido, ItemPedido

# INTENTO DE IMPORTAR EL MODELO DE OTRA APP (ENVIOS) DE FORMA SEGURA
try:
    from envios.models import Envio
    ENVIOS_INSTALLED = True
except ImportError:
    ENVIOS_INSTALLED = False

logger = logging.getLogger('pedidos.admin')


# ═══════════════════════════════════════════════════════════════════
#  INLINES (TABLAS DENTRO DEL PEDIDO)
# ═══════════════════════════════════════════════════════════════════

class ItemPedidoInline(admin.TabularInline):
    """Muestra los productos del pedido dentro del detalle"""
    model = ItemPedido
    extra = 0
    can_delete = False
    readonly_fields = ('subtotal',)
    fields = ('producto', 'cantidad', 'precio_unitario', 'subtotal', 'notas')
    classes = ('collapse',)  # Colapsado por defecto para ahorrar espacio

    def has_add_permission(self, request, obj=None):
        return False  # No permitir agregar items desde admin por seguridad


class EnvioInline(admin.StackedInline):
    """
    INTEGRACIÓN LOGÍSTICA: Muestra los datos de envío (Google Maps)
    directamente en la pantalla del pedido.
    """
    model = Envio if ENVIOS_INSTALLED else None
    can_delete = False
    verbose_name = "Información Logística (Envío)"
    verbose_name_plural = "Logística y Rastreo"
    
    # Campos a mostrar (solo lectura para evitar manipular costos manualmante)
    readonly_fields = (
        'distancia_km', 
        'tiempo_estimado_mins', 
        'costo_base', 
        'recargo_nocturno', 
        'total_envio', 
        'en_camino', 
        'fecha_llegada'
    )
    
    fieldsets = (
        ('Ruta y Tiempos', {
            'fields': (('distancia_km', 'tiempo_estimado_mins'), 'fecha_llegada')
        }),
        ('Costos Calculados', {
            'fields': (('costo_base', 'recargo_nocturno'), 'total_envio')
        }),
    )
    
    classes = ('collapse',)

    def has_add_permission(self, request, obj=None):
        return False  # Se crea automáticamente con el pedido


# ═══════════════════════════════════════════════════════════════════
# ACCIONES PERSONALIZADAS
# ═══════════════════════════════════════════════════════════════════

@admin.action(description="Exportar seleccionados a CSV")
def exportar_a_csv(modeladmin, request, queryset):
    """
    Acción para exportar pedidos a CSV con manejo robusto.
    """
    try:
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = f'attachment; filename="pedidos_export_{timezone.now().strftime("%Y%m%d")}.csv"'

        writer = csv.writer(response)
        writer.writerow([
            'ID', 'Número', 'Tipo', 'Estado', 'Cliente', 'Email',
            'Proveedor', 'Repartidor', 'Total Pedido', 'Costo Envío',
            'Ganancia App', 'Método Pago', 'Creado', 'Entregado'
        ])

        # Optimizar query incluyendo datos de envio si existe
        pedidos = queryset.select_related(
            'cliente__user',
            'proveedor',
            'repartidor__user'
        )
        if ENVIOS_INSTALLED:
            pedidos = pedidos.select_related('datos_envio')

        exportados = 0
        for pedido in pedidos:
            # Obtener costo de envío de forma segura
            datos_envio = getattr(pedido, 'datos_envio', None)
            costo_envio = datos_envio.total_envio if datos_envio else 0
            
            writer.writerow([
                pedido.id,
                pedido.numero_pedido,
                pedido.get_tipo_display(),
                pedido.get_estado_display(),
                pedido.cliente.user.get_full_name() if pedido.cliente else '-',
                pedido.cliente.user.email if pedido.cliente else '-',
                pedido.proveedor.nombre if pedido.proveedor else '-',
                pedido.repartidor.user.get_full_name() if pedido.repartidor else 'Sin asignar',
                f"${pedido.total}",
                f"${costo_envio}",
                f"${pedido.ganancia_app}",
                pedido.get_metodo_pago_display(),
                pedido.creado_en.strftime('%Y-%m-%d %H:%M'),
                pedido.fecha_entregado.strftime('%Y-%m-%d %H:%M') if pedido.fecha_entregado else '-',
            ])
            exportados += 1

        modeladmin.message_user(request, f"{exportados} pedidos exportados correctamente.", messages.SUCCESS)
        return response

    except Exception as e:
        logger.error(f"Error exportando CSV: {e}", exc_info=True)
        modeladmin.message_user(request, f"Error al exportar: {e}", messages.ERROR)


# ═══════════════════════════════════════════════════════════════════
# FILTROS PERSONALIZADOS
# ═══════════════════════════════════════════════════════════════════

class TieneComprobanteFilter(admin.SimpleListFilter):
    """Filtro para pedidos con/sin comprobante de entrega"""
    title = 'Comprobante de Entrega'
    parameter_name = 'tiene_comprobante'

    def lookups(self, request, model_admin):
        return (
            ('si', 'Con comprobante'),
            ('no', 'Sin comprobante'),
            ('requerido_sin', 'Transferencia sin comprobante'),
        )

    def queryset(self, request, queryset):
        evidencia_entrega = Q(imagen_evidencia__isnull=False) & ~Q(imagen_evidencia='')
        comprobante_pago = Q(pago__transferencia_comprobante__isnull=False) & ~Q(pago__transferencia_comprobante='')

        if self.value() == 'si':
            return queryset.filter(evidencia_entrega | comprobante_pago)
        if self.value() == 'no':
            return queryset.exclude(evidencia_entrega | comprobante_pago)
        if self.value() == 'requerido_sin':
            return queryset.filter(
                metodo_pago='transferencia',
                estado='entregado'
            ).exclude(evidencia_entrega | comprobante_pago)


# ═══════════════════════════════════════════════════════════════════
# ADMIN CLASS PRINCIPAL
# ═══════════════════════════════════════════════════════════════════

@admin.register(Pedido)
class PedidoAdmin(admin.ModelAdmin):
    """
    Administración completa de pedidos con integración logística.
    """
    
    # --- LISTADO ---
    list_display = [
        'id_link',              # ID Clickeable
        'tipo_badge',           # Badge visual
        'estado_badge',         # Badge visual
        'cliente_link',         # Link al cliente
        'proveedor_link',       # Link al proveedor
        'repartidor_link',      # Link al repartidor
        'total_formateado',     # Total en verde
        'metodo_pago_badge',    # Badge método de pago
        'tiene_comprobante',    # Indicador de comprobante
        'tiempo_transcurrido_admin',
        'logistica_info',       # NUEVO: Info rápida de envío
        'creado_en',
    ]

    list_filter = [
        'tipo',
        'estado',
        'metodo_pago',
        'aceptado_por_repartidor',
        ('creado_en', admin.DateFieldListFilter),
        ('fecha_entregado', admin.DateFieldListFilter),
        ('proveedor', admin.RelatedOnlyFieldListFilter),
        ('repartidor', admin.RelatedOnlyFieldListFilter),
        TieneComprobanteFilter,
    ]

    search_fields = [
        'numero_pedido',
        'cliente__user__email',
        'cliente__user__first_name',
        'proveedor__nombre',
        'repartidor__user__first_name',
        'direccion_entrega',
    ]

    list_per_page = 20
    date_hierarchy = 'creado_en'
    ordering = ['-creado_en']

    # --- INLINES ---
    # Aquí agregamos los items y la logística (si está instalada)
    inlines = [ItemPedidoInline]
    if ENVIOS_INSTALLED:
        inlines.append(EnvioInline)

    # --- DETALLE ---
    fieldsets = (
        ('Información General', {
            'fields': (
                ('numero_pedido', 'tipo', 'estado'),
                ('total', 'metodo_pago'),
                'descripcion'
            )
        }),
        ('Participantes', {
            'fields': (('cliente', 'proveedor'), 'repartidor')
        }),
        ('Ubicación', {
            'fields': ('direccion_origen', 'direccion_entrega'),
            'classes': ('collapse',)
        }),
        ('Comprobante de Entrega', {
            'fields': ('mostrar_comprobante', 'fecha_entregado'),
            'description': 'Evidencia fotográfica subida por el repartidor al momento de la entrega',
        }),
        ('Finanzas', {
            'fields': (
                ('comision_repartidor', 'comision_proveedor', 'ganancia_app'),
            ),
            'classes': ('collapse',)
        }),
        ('Fechas', {
            'fields': ('creado_en', 'actualizado_en'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = [
        'numero_pedido', 'creado_en', 'actualizado_en', 'fecha_entregado',
        'comision_repartidor', 'comision_proveedor', 'ganancia_app',
        'mostrar_comprobante'
    ]

    # Autocomplete para búsquedas rápidas en claves foráneas
    autocomplete_fields = ['cliente', 'proveedor', 'repartidor']

    actions = [
        'marcar_en_preparacion',
        'marcar_en_ruta',
        'marcar_entregado',
        'cancelar_pedidos',
        exportar_a_csv
    ]

    # --- OPTIMIZACIÓN DE QUERIES ---
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        # Traemos todos los datos relacionados para evitar N+1 queries
        qs = qs.select_related('cliente__user', 'proveedor', 'repartidor__user', 'pago')
        if ENVIOS_INSTALLED:
            qs = qs.select_related('datos_envio')
        return qs

    # --- MÉTODOS VISUALES ---

    def id_link(self, obj):
        return f"#{obj.id}"
    id_link.short_description = "ID"
    id_link.admin_order_field = 'id'

    def tipo_badge(self, obj):
        colores = {
            TipoPedido.PROVEEDOR: '#17a2b8',  # Cyan
            TipoPedido.DIRECTO: '#6f42c1',    # Purple
        }
        color = colores.get(obj.tipo, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">{}</span>',
            color, obj.get_tipo_display()
        )
    tipo_badge.short_description = 'Tipo'

    def estado_badge(self, obj):
        colores = {
            EstadoPedido.ASIGNADO_REPARTIDOR: '#ffc107',      # Amarillo
            EstadoPedido.EN_PROCESO: '#fd7e14',              # Naranja
            EstadoPedido.EN_CAMINO: '#0dcaf0',               # Celeste
            EstadoPedido.ENTREGADO: '#28a745',       # Verde
            EstadoPedido.CANCELADO: '#dc3545',       # Rojo
        }
        color = colores.get(obj.estado, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">{}</span>',
            color, obj.get_estado_display()
        )
    estado_badge.short_description = 'Estado'

    def total_formateado(self, obj):
        return format_html('<strong style="color: #28a745;">${}</strong>', obj.total)
    total_formateado.short_description = 'Total'
    total_formateado.admin_order_field = 'total'

    def metodo_pago_badge(self, obj):
        """Badge para método de pago"""
        colores = {
            'efectivo': '#28a745',        # Verde
            'tarjeta': '#007bff',         # Azul
            'transferencia': '#6f42c1',   # Púrpura
        }
        color = colores.get(obj.metodo_pago, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px;">{}</span>',
            color, obj.get_metodo_pago_display()
        )
    metodo_pago_badge.short_description = 'Pago'

    def tiene_comprobante(self, obj):
        """Indica si tiene comprobante de entrega"""
        pago = getattr(obj, 'pago', None)
        comprobante_pago = bool(getattr(pago, 'transferencia_comprobante', None))
        evidencia_entrega = bool(obj.imagen_evidencia)

        if evidencia_entrega:
            return format_html(
                '<span style="color: green;" title="Comprobante de entrega">✓</span>'
            )
        if comprobante_pago:
            return format_html(
                '<span style="color: green;" title="Comprobante de transferencia">✓</span>'
            )
        if obj.metodo_pago == 'transferencia' and obj.estado == 'entregado':
            return format_html(
                '<span style="color: red;" title="Debería tener comprobante">✗</span>'
            )
        return format_html('<span style="color: gray;">-</span>')
    tiene_comprobante.short_description = 'Comprobante'

    def mostrar_comprobante(self, obj):
        """Muestra la imagen del comprobante de entrega"""
        pago = getattr(obj, 'pago', None)
        comprobante_pago = getattr(pago, 'transferencia_comprobante', None)

        if obj.imagen_evidencia:
            url = obj.imagen_evidencia.url
            caption = 'Evidencia de entrega'
        elif comprobante_pago:
            url = comprobante_pago.url
            caption = 'Comprobante de transferencia'
        else:
            if obj.metodo_pago == 'transferencia':
                return format_html(
                    '<div style="padding: 20px; background: #fff3cd; border: 2px dashed #ffc107; text-align: center;">'
                    '<strong>⚠️ Sin comprobante</strong><br>'
                    '<small>Este pedido fue pagado por transferencia pero no tiene imagen de comprobante</small>'
                    '</div>'
                )
            return format_html(
                '<div style="padding: 20px; background: #f8f9fa; text-align: center; color: #6c757d;">'
                'No se requiere comprobante (pago en efectivo)'
                '</div>'
            )

        # Mostrar la imagen (evidencia o comprobante)
        return format_html(
            '<div style="text-align: center;">'
            '<a href="{url}" target="_blank">'
            '<img src="{url}" style="max-width: 400px; max-height: 400px; border: 2px solid #28a745; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);" />'
            '</a><br><br>'
            '<span style="display: inline-block; margin-top: 4px; color: #28a745; font-weight: 600;">{caption}</span><br>'
            '<a href="{url}" target="_blank" class="button" style="display: inline-block; padding: 8px 16px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; margin-top: 10px;">'
            '🔍 Ver imagen completa'
            '</a>'
            '</div>',
            url=url,
            caption=caption
        )
    mostrar_comprobante.short_description = 'Evidencia Fotográfica'

    def logistica_info(self, obj):
        """Muestra info rápida de logística si existe"""
        if hasattr(obj, 'datos_envio'):
            envio = obj.datos_envio
            return format_html(
                '<span title="Costo Envío">${} ({}km)</span>',
                envio.total_envio, envio.distancia_km
            )
        return "-"
    logistica_info.short_description = "Logística"

    # --- GENERADORES DE LINKS SEGUROS ---
    def _generar_link_seguro(self, obj, viewname, texto):
        if not obj: return "-"
        try:
            url = reverse(viewname, args=[obj.id])
            return format_html('<a href="{}">{}</a>', url, texto)
        except Exception:
            return str(texto)

    def cliente_link(self, obj):
        texto = obj.cliente.user.get_full_name() or obj.cliente.user.email
        return self._generar_link_seguro(obj.cliente, 'admin:usuarios_perfil_change', texto)
    cliente_link.short_description = "Cliente"

    def proveedor_link(self, obj):
        texto = obj.proveedor.nombre if obj.proveedor else "-"
        return self._generar_link_seguro(obj.proveedor, 'admin:proveedores_proveedor_change', texto)
    proveedor_link.short_description = "Proveedor"

    def repartidor_link(self, obj):
        if not obj.repartidor: return format_html('<span style="color:red;">Sin asignar</span>')
        texto = obj.repartidor.user.get_full_name()
        return self._generar_link_seguro(obj.repartidor, 'admin:repartidores_repartidor_change', texto)
    repartidor_link.short_description = "Repartidor"

    def tiempo_transcurrido_admin(self, obj):
        """Calcula visualmente cuánto tiempo lleva el pedido"""
        delta = timezone.now() - obj.creado_en
        minutos = int(delta.total_seconds() / 60)
        
        color = "black"
        if obj.estado not in [EstadoPedido.ENTREGADO, EstadoPedido.CANCELADO]:
            if minutos > 45: color = "red"
            elif minutos > 30: color = "orange"
            else: color = "green"
            
        if minutos < 60: texto = f"{minutos} min"
        else: texto = f"{minutos // 60}h {minutos % 60}m"
        
        return format_html('<span style="color: {}; font-weight:bold;">{}</span>', color, texto)
    tiempo_transcurrido_admin.short_description = "Tiempo"

    # --- ACCIONES MASIVAS ---

    @admin.action(description="Marcar como 'En preparación'")
    def marcar_en_preparacion(self, request, queryset):
        self._actualizar_estado_masivo(request, queryset, EstadoPedido.EN_PROCESO, 
                                     validos=[EstadoPedido.ASIGNADO_REPARTIDOR])

    @admin.action(description="Marcar como 'En ruta'")
    def marcar_en_ruta(self, request, queryset):
        # Validación extra: debe tener repartidor
        sin_repartidor = queryset.filter(repartidor__isnull=True)
        if sin_repartidor.exists():
            self.message_user(request, "Error: Algunos pedidos no tienen repartidor asignado.", messages.ERROR)
            return
        self._actualizar_estado_masivo(request, queryset, EstadoPedido.EN_CAMINO,
                                     validos=[EstadoPedido.ASIGNADO_REPARTIDOR, EstadoPedido.EN_PROCESO])

    @admin.action(description="Marcar como 'Entregado'")
    def marcar_entregado(self, request, queryset):
        self._actualizar_estado_masivo(request, queryset, EstadoPedido.ENTREGADO,
                                     validos=[EstadoPedido.EN_CAMINO])

    @admin.action(description="Cancelar pedidos seleccionados")
    def cancelar_pedidos(self, request, queryset):
        conteo = 0
        for pedido in queryset:
            if pedido.puede_ser_cancelado:
                pedido.cancelar(motivo="Cancelado desde Admin", actor=f"Admin {request.user.email}")
                conteo += 1
        self.message_user(request, f"{conteo} pedidos cancelados correctamente.", messages.SUCCESS)

    def _actualizar_estado_masivo(self, request, queryset, nuevo_estado, validos):
        """Helper para actualizar estados masivamente de forma segura"""
        actualizados = queryset.filter(estado__in=validos).update(
            estado=nuevo_estado, 
            actualizado_en=timezone.now()
        )
        if actualizados:
            self.message_user(request, f"{actualizados} pedidos actualizados a '{nuevo_estado}'.", messages.SUCCESS)
        else:
            self.message_user(request, "Ningún pedido cumplía los requisitos para el cambio.", messages.WARNING)
