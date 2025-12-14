# backend/pagos/admin.py
"""
Panel Administrativo de Pagos.

DISEÑADO PARA SUPERVISIÓN (Diagramas 1 y 2):
- Permite al Admin ver las fotos de transferencias (Comprobantes).
- Permite intervenir si el Chofer no verifica.
- Muestra claramente quién tiene el dinero (Chofer o Caja).
"""
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from django.contrib import messages
from django.db.models import Sum, Count, Q

from .models import (
    MetodoPago, Pago, Transaccion, EstadisticasPago,
    EstadoPago, TipoMetodoPago
)

# ==========================================================
# INLINES (Historial dentro del Pago)
# ==========================================================

class TransaccionInline(admin.TabularInline):
    """Muestra el historial de intentos dentro del pago"""
    model = Transaccion
    extra = 0
    can_delete = False
    readonly_fields = ('creado_en', 'tipo', 'monto', 'exitosa_display', 'descripcion')
    ordering = ('-creado_en',)

    def exitosa_display(self, obj):
        if obj.exitosa:
            return format_html('<span style="color:green;">✔ Exitosa</span>')
        elif obj.exitosa is False:
            return format_html('<span style="color:red;">✘ Fallida</span>')
        return format_html('<span style="color:orange;">⏳ En proceso</span>')
    exitosa_display.short_description = "Estado"

    def has_add_permission(self, request, obj=None):
        return False


# ==========================================================
# ADMIN: PAGO (El Centro de Control)
# ==========================================================

@admin.register(Pago)
class PagoAdmin(admin.ModelAdmin):
    list_display = (
        'referencia_corta',
        'pedido_link',
        'metodo_tipo_visual',
        'monto_display',
        'estado_visual',
        'comprobante_preview_small', # <--- ¡LA FOTO AQUÍ!
        'verificado_por_display',    # <--- ¿QUIÉN LO REVISÓ?
        'creado_en'
    )

    list_filter = (
        'estado',
        ('metodo_pago__tipo', admin.ChoicesFieldListFilter),
        'creado_en',
        ('verificado_por', admin.RelatedOnlyFieldListFilter), # Filtrar por verificador
    )

    search_fields = (
        'referencia',
        'pedido__id',
        'pedido__cliente__user__email',
        'pedido__repartidor__email', # Buscar pagos de un chofer específico
        'transferencia_numero_operacion'
    )

    readonly_fields = (
        'referencia', 'pedido_info', 'monto_pendiente_reembolso',
        'creado_en', 'actualizado_en', 'fecha_completado', 'fecha_verificacion',
        'comprobante_preview_large' # Foto grande en detalle
    )

    inlines = [TransaccionInline]
    
    date_hierarchy = 'creado_en'

    fieldsets = (
        ('Estado y Auditoría', {
            'fields': (
                'referencia', 
                'estado', 
                'verificado_por', # Admin puede ver quién fue
                'fecha_verificacion'
            )
        }),
        ('Detalles Financieros', {
            'fields': (
                'pedido_info', 
                'metodo_pago', 
                'monto'
            )
        }),
        ('Evidencia de Transferencia (Flujo 1B/2B)', {
            'fields': (
                'comprobante_preview_large', # Ver la foto grande
                'transferencia_comprobante',
                'transferencia_banco_origen',
                'transferencia_numero_operacion'
            ),
            'description': 'Aquí se valida si el cliente realmente transfirió al chofer.'
        }),
        ('Reembolsos', {
            'fields': ('monto_reembolsado', 'fecha_reembolso'),
            'classes': ('collapse',),
        }),
        ('Notas del Sistema', {
            'fields': ('notas', 'metadata'),
            'classes': ('collapse',),
        })
    )

    # --- ACCIONES MASIVAS PARA EL ADMIN ---

    actions = ['validar_transferencia_admin', 'rechazar_comprobante_admin']

    def validar_transferencia_admin(self, request, queryset):
        """El Admin fuerza la validación (Override)"""
        count = 0
        for pago in queryset:
            if pago.estado in [EstadoPago.ESPERANDO_VERIFICACION, EstadoPago.PENDIENTE]:
                pago.marcar_completado(verificado_por=request.user)
                pago.notas += f"\n[ADMIN] Validado forzosamente desde panel."
                pago.save()
                count += 1
        self.message_user(request, f"✅ {count} pagos validados manualmente por Admin.", messages.SUCCESS)
    validar_transferencia_admin.short_description = "🛡️ Validar Transferencia (Override)"

    def rechazar_comprobante_admin(self, request, queryset):
        """El Admin rechaza comprobantes falsos/borrosos"""
        count = 0
        for pago in queryset:
            if pago.estado == EstadoPago.ESPERANDO_VERIFICACION:
                pago.estado = EstadoPago.PENDIENTE
                pago.notas += f"\n[ADMIN] Comprobante rechazado desde panel."
                pago.save()
                count += 1
        self.message_user(request, f"🚫 {count} comprobantes rechazados. Estado devuelto a Pendiente.", messages.WARNING)
    rechazar_comprobante_admin.short_description = "🚫 Rechazar Comprobante (Devolver a Pendiente)"


    # --- VISUALIZADORES PERSONALIZADOS ---

    def referencia_corta(self, obj):
        return str(obj.referencia)[:8] + "..."
    referencia_corta.short_description = "Ref"

    def pedido_link(self, obj):
        url = reverse("admin:pedidos_pedido_change", args=[obj.pedido.id])
        return format_html('<a href="{}">Pedido #{}</a>', url, obj.pedido.id)
    pedido_link.short_description = "Pedido"

    def pedido_info(self, obj):
        """Muestra info clave del pedido en modo lectura"""
        cliente = obj.pedido.cliente.user.get_full_name()
        chofer = obj.pedido.repartidor.get_full_name() if obj.pedido.repartidor else "Sin asignar"
        return f"Cliente: {cliente} | Chofer: {chofer}"
    pedido_info.short_description = "Información del Pedido"

    def monto_display(self, obj):
        return f"${obj.monto}"
    monto_display.short_description = "Monto"

    def metodo_tipo_visual(self, obj):
        if obj.metodo_pago.tipo == TipoMetodoPago.TRANSFERENCIA:
            return format_html('🏦 Transf.')
        elif obj.metodo_pago.tipo == TipoMetodoPago.EFECTIVO:
            return format_html('💵 Efectivo')
        return obj.metodo_pago.tipo
    metodo_tipo_visual.short_description = "Método"

    def estado_visual(self, obj):
        colors = {
            EstadoPago.COMPLETADO: 'green',
            EstadoPago.PENDIENTE: 'orange',
            EstadoPago.ESPERANDO_VERIFICACION: 'blue', # ¡OJO AQUÍ ADMIN!
            EstadoPago.FALLIDO: 'red',
        }
        color = colors.get(obj.estado, 'black')
        texto = obj.get_estado_display()
        
        # Si espera verificación, lo resaltamos fuerte
        estilo = "font-weight:bold;" if obj.estado == EstadoPago.ESPERANDO_VERIFICACION else ""
        
        return format_html(
            '<span style="color: {}; {}">{}</span>', 
            color, estilo, texto
        )
    estado_visual.short_description = "Estado"

    def verificado_por_display(self, obj):
        """Muestra ícono según si fue Chofer o Admin"""
        if not obj.verificado_por:
            return "-"
        
        if obj.verificado_por.is_staff:
            return format_html('🛡️ {} (Admin)', obj.verificado_por.first_name)
        else:
            return format_html('👤 {} (Chofer)', obj.verificado_por.first_name)
    verificado_por_display.short_description = "Verificado Por"

    def comprobante_preview_small(self, obj):
        """Miniatura para la lista"""
        if obj.transferencia_comprobante:
            return format_html(
                '<a href="{}" target="_blank"><img src="{}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 4px; border: 1px solid #ccc;" /></a>',
                obj.transferencia_comprobante.url,
                obj.transferencia_comprobante.url
            )
        return "-"
    comprobante_preview_small.short_description = "📷 Evidencia"

    def comprobante_preview_large(self, obj):
        """Imagen grande para el detalle"""
        if obj.transferencia_comprobante:
            return format_html(
                '<a href="{}" target="_blank"><img src="{}" style="max-width: 400px; max-height: 400px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.2);" /></a><br><small>Clic para ver original</small>',
                obj.transferencia_comprobante.url,
                obj.transferencia_comprobante.url
            )
        return "No hay comprobante subido"
    comprobante_preview_large.short_description = "Vista Previa del Comprobante"


# ==========================================================
# ADMIN: MÉTODO DE PAGO
# ==========================================================

@admin.register(MetodoPago)
class MetodoPagoAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'tipo', 'activo', 'requiere_verificacion', 'total_pagos_hoy')
    list_filter = ('activo', 'tipo')
    search_fields = ('nombre',)
    
    def total_pagos_hoy(self, obj):
        hoy = timezone.now().date()
        return obj.pagos.filter(creado_en__date=hoy).count()
    total_pagos_hoy.short_description = "Pagos Hoy"


# ==========================================================
# ADMIN: TRANSACCIONES (Solo lectura)
# ==========================================================

@admin.register(Transaccion)
class TransaccionAdmin(admin.ModelAdmin):
    list_display = ('pago_link', 'tipo', 'monto', 'exitosa', 'creado_en')
    list_filter = ('tipo', 'exitosa', 'creado_en')
    search_fields = ('pago__referencia', 'descripcion')
    
    def pago_link(self, obj):
        url = reverse("admin:pagos_pago_change", args=[obj.pago.id])
        return format_html('<a href="{}">{}...</a>', url, str(obj.pago.referencia)[:8])
    pago_link.short_description = "Pago Ref"

    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False


# ==========================================================
# ADMIN: ESTADÍSTICAS
# ==========================================================

@admin.register(EstadisticasPago)
class EstadisticasPagoAdmin(admin.ModelAdmin):
    list_display = ('fecha', 'total_pagos', 'pagos_completados', 'monto_total_visual', 'tasa_exito_visual')
    date_hierarchy = 'fecha'
    readonly_fields = ('fecha', 'actualizado_en')

    def monto_total_visual(self, obj):
        return f"${obj.monto_total}"
    monto_total_visual.short_description = "Total ($)"

    def tasa_exito_visual(self, obj):
        color = "green" if obj.tasa_exito > 90 else "orange"
        return format_html('<span style="color:{}; font-weight:bold;">{}%</span>', color, obj.tasa_exito)
    tasa_exito_visual.short_description = "Tasa Éxito"

    def has_add_permission(self, request):
        return False