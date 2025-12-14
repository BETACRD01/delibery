# super_categorias/admin.py
"""
Configuración del panel de administración para Super Categorías
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import CategoriaSuper, ProveedorSuper, ProductoSuper


@admin.register(CategoriaSuper)
class CategoriaSuperAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'nombre',
        'preview_imagen',
        'color_display',
        'activo',
        'orden',
        'destacado',
        'total_proveedores',
        'created_at'
    ]

    list_filter = ['activo', 'destacado', 'created_at']
    search_fields = ['id', 'nombre', 'descripcion']
    list_editable = ['activo', 'orden', 'destacado']
    ordering = ['orden', 'nombre']

    fieldsets = (
        ('Información Básica', {
            'fields': ('id', 'nombre', 'descripcion')
        }),
        ('Visualización', {
            'fields': ('icono', 'color', 'orden', 'destacado')
        }),
        ('Imágenes (Archivos)', {
            'fields': ('imagen', 'logo'),
            'description': 'Sube archivos de imagen directamente'
        }),
        ('Imágenes (URLs Externas)', {
            'fields': ('imagen_url', 'logo_url'),
            'description': 'O usa URLs externas si prefieres'
        }),
        ('Control', {
            'fields': ('activo',)
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def preview_imagen(self, obj):
        """Muestra preview de la imagen en el listado"""
        url = obj.get_imagen_url()
        if url:
            return format_html(
                '<img src="{}" width="50" height="50" style="border-radius: 8px;" />',
                url
            )
        return '-'
    preview_imagen.short_description = 'Vista Previa'

    def color_display(self, obj):
        """Muestra el color como badge"""
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 5px;">{}</span>',
            obj.color,
            obj.color
        )
    color_display.short_description = 'Color'


@admin.register(ProveedorSuper)
class ProveedorSuperAdmin(admin.ModelAdmin):
    list_display = [
        'nombre',
        'categoria',
        'preview_logo',
        'calificacion',
        'total_resenas',
        'activo',
        'verificado',
        'esta_abierto_display',
        'created_at'
    ]

    list_filter = ['categoria', 'activo', 'verificado', 'created_at']
    search_fields = ['nombre', 'descripcion', 'direccion', 'telefono', 'email']
    list_editable = ['activo', 'verificado']
    ordering = ['-calificacion', 'nombre']

    fieldsets = (
        ('Información Básica', {
            'fields': ('categoria', 'nombre', 'descripcion')
        }),
        ('Contacto', {
            'fields': ('telefono', 'email', 'direccion')
        }),
        ('Ubicación (GPS)', {
            'fields': ('latitud', 'longitud'),
            'description': 'Coordenadas GPS para mapas'
        }),
        ('Imágenes', {
            'fields': ('logo', 'imagen_portada')
        }),
        ('Horarios', {
            'fields': ('horario_apertura', 'horario_cierre')
        }),
        ('Calificación', {
            'fields': ('calificacion', 'total_resenas'),
            'description': 'Se calcula automáticamente con las reseñas'
        }),
        ('Control', {
            'fields': ('activo', 'verificado')
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def preview_logo(self, obj):
        """Muestra preview del logo"""
        if obj.logo:
            return format_html(
                '<img src="{}" width="40" height="40" style="border-radius: 8px;" />',
                obj.logo.url
            )
        return '-'
    preview_logo.short_description = 'Logo'

    def esta_abierto_display(self, obj):
        """Muestra si está abierto con colores"""
        if obj.esta_abierto:
            return format_html(
                '<span style="color: green; font-weight: bold;">● Abierto</span>'
            )
        return format_html(
            '<span style="color: red; font-weight: bold;">● Cerrado</span>'
        )
    esta_abierto_display.short_description = 'Estado'


@admin.register(ProductoSuper)
class ProductoSuperAdmin(admin.ModelAdmin):
    list_display = [
        'nombre',
        'proveedor',
        'preview_imagen',
        'precio',
        'precio_anterior',
        'descuento_display',
        'stock',
        'disponible',
        'destacado',
        'created_at'
    ]

    list_filter = ['proveedor__categoria', 'proveedor', 'disponible', 'destacado', 'created_at']
    search_fields = ['nombre', 'descripcion', 'proveedor__nombre']
    list_editable = ['disponible', 'destacado', 'stock']
    ordering = ['-destacado', '-created_at']

    fieldsets = (
        ('Información Básica', {
            'fields': ('proveedor', 'nombre', 'descripcion')
        }),
        ('Precios', {
            'fields': ('precio', 'precio_anterior'),
            'description': 'El precio_anterior genera descuentos automáticos'
        }),
        ('Imagen', {
            'fields': ('imagen',)
        }),
        ('Stock', {
            'fields': ('stock',)
        }),
        ('Control', {
            'fields': ('disponible', 'destacado')
        }),
    )

    readonly_fields = ['created_at', 'updated_at']

    def preview_imagen(self, obj):
        """Muestra preview de la imagen"""
        if obj.imagen:
            return format_html(
                '<img src="{}" width="40" height="40" style="border-radius: 8px;" />',
                obj.imagen.url
            )
        return '-'
    preview_imagen.short_description = 'Imagen'

    def descuento_display(self, obj):
        """Muestra el descuento si existe"""
        if obj.en_oferta:
            return format_html(
                '<span style="background-color: #f44336; color: white; padding: 3px 8px; border-radius: 5px; font-weight: bold;">-{}%</span>',
                obj.porcentaje_descuento
            )
        return '-'
    descuento_display.short_description = 'Descuento'
