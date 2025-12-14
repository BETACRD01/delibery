# backend/productos/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, F
from .models import (
    Categoria, Producto, Promocion,
    Carrito, ItemCarrito
)

# ═══════════════════════════════════════════════════════════════════════
# CATEGORÍAS
# ═══════════════════════════════════════════════════════════════════════
@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ['id', 'nombre', 'vista_previa', 'activo', 'total_productos']
    list_filter = ['activo']
    search_fields = ['nombre']

    @admin.display(description='Imagen')
    def vista_previa(self, obj):
        if obj.imagen:
            return format_html(
                '<img src="{}" style="width: 40px; height: 40px; border-radius: 50%; object-fit: cover;" />',
                obj.imagen.url
            )
        return "Sin imagen"


# ═══════════════════════════════════════════════════════════════════════
# PRODUCTOS (Edición de Precios de Oferta)
# ═══════════════════════════════════════════════════════════════════════
@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = [
        'nombre', 'proveedor', 'precio', 'precio_anterior', 
        'porcentaje_off', 'disponible', 'stock'
    ]
    list_filter = ['disponible', 'destacado', 'proveedor']
    search_fields = ['nombre', 'descripcion']
    readonly_fields = ['veces_vendido', 'rating_promedio', 'vista_imagen']
    
    @admin.display(description='% OFF')
    def porcentaje_off(self, obj):
        if obj.porcentaje_descuento > 0:
            return format_html(
                '<span style="background: #E91E63; color: white; padding: 2px 6px; border-radius: 4px;">-{}%</span>',
                obj.porcentaje_descuento
            )
        return "-"

    @admin.display(description='Imagen')
    def vista_imagen(self, obj):
        if obj.imagen_final:
            return format_html('<img src="{}" style="max-height: 150px;" />', obj.imagen_final)
        return "Sin imagen"

    fieldsets = (
        ('Información Básica', {
            'fields': ('proveedor', 'categoria', 'nombre', 'descripcion')
        }),
        ('Precios y Ofertas', {
            'fields': ('precio', 'precio_anterior'),
            'description': 'Si llenas "Precio Anterior" con un valor mayor al actual, se mostrará como oferta.'
        }),
        ('Multimedia', {
            'fields': ('imagen', 'imagen_url', 'vista_imagen')
        }),
        ('Inventario', {
            'fields': ('disponible', 'destacado', 'tiene_stock', 'stock')
        }),
    )


# ═══════════════════════════════════════════════════════════════════════
# PROMOCIONES (Configuración de Banners)
# ═══════════════════════════════════════════════════════════════════════
@admin.register(Promocion)
class PromocionAdmin(admin.ModelAdmin):
    list_display = ['titulo', 'descuento', 'activa', 'es_vigente']
    list_filter = ['activa', 'proveedor']
    
    fieldsets = (
        ('Visual', {
            'fields': ('titulo', 'descripcion', 'descuento', 'color', 'imagen', 'imagen_url')
        }),
        ('Navegación (Al hacer click)', {
            'fields': ('producto_asociado', 'categoria_asociada'),
            'description': 'Elige A DÓNDE llevará el banner cuando el usuario lo toque.'
        }),
        ('Vigencia', {
            'fields': ('activa', 'fecha_inicio', 'fecha_fin')
        }),
    )


# ═══════════════════════════════════════════════════════════════════════
# CARRITO
# ═══════════════════════════════════════════════════════════════════════
class ItemCarritoInline(admin.TabularInline):
    model = ItemCarrito
    extra = 0
    readonly_fields = ['subtotal']

@admin.register(Carrito)
class CarritoAdmin(admin.ModelAdmin):
    list_display = ['usuario', 'updated_at']
    inlines = [ItemCarritoInline]