# super_categorias/serializers.py
"""
Serializers para la API de Super Categorías
"""

from rest_framework import serializers
from .models import CategoriaSuper, ProveedorSuper, ProductoSuper


class CategoriaSuperSerializer(serializers.ModelSerializer):
    """Serializer para Categorías Super"""

    # Campos calculados
    total_proveedores = serializers.ReadOnlyField()
    tiene_imagen = serializers.ReadOnlyField()
    tiene_logo = serializers.ReadOnlyField()

    # URLs de imágenes
    imagen_url = serializers.SerializerMethodField()
    logo_url = serializers.SerializerMethodField()

    class Meta:
        model = CategoriaSuper
        fields = [
            'id',
            'nombre',
            'descripcion',
            'icono',
            'color',
            'imagen',
            'logo',
            'imagen_url',
            'logo_url',
            'activo',
            'orden',
            'destacado',
            'total_proveedores',
            'tiene_imagen',
            'tiene_logo',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_imagen_url(self, obj):
        """Retorna la URL completa de la imagen"""
        url = obj.get_imagen_url()
        if url and not url.startswith('http'):
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(url)
        return url

    def get_logo_url(self, obj):
        """Retorna la URL completa del logo"""
        url = obj.get_logo_url()
        if url and not url.startswith('http'):
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(url)
        return url


class CategoriaSuperListSerializer(serializers.ModelSerializer):
    """Serializer simplificado para listado de categorías"""

    imagen_url = serializers.SerializerMethodField()
    total_proveedores = serializers.ReadOnlyField()

    class Meta:
        model = CategoriaSuper
        fields = [
            'id',
            'nombre',
            'descripcion',
            'icono',
            'color',
            'imagen_url',
            'activo',
            'orden',
            'destacado',
            'total_proveedores',
        ]

    def get_imagen_url(self, obj):
        """Retorna la URL completa de la imagen"""
        url = obj.get_imagen_url()
        if url and not url.startswith('http'):
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(url)
        return url


class ProductoSuperSerializer(serializers.ModelSerializer):
    """Serializer para Productos Super"""

    # Campos calculados
    en_oferta = serializers.ReadOnlyField()
    porcentaje_descuento = serializers.ReadOnlyField()
    tiene_stock = serializers.ReadOnlyField()

    # URL de imagen
    imagen_url = serializers.SerializerMethodField()

    class Meta:
        model = ProductoSuper
        fields = [
            'id',
            'proveedor',
            'nombre',
            'descripcion',
            'precio',
            'precio_anterior',
            'imagen',
            'imagen_url',
            'stock',
            'disponible',
            'destacado',
            'en_oferta',
            'porcentaje_descuento',
            'tiene_stock',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_imagen_url(self, obj):
        """Retorna la URL completa de la imagen"""
        if obj.imagen:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url)
            return obj.imagen.url
        return None


class ProveedorSuperSerializer(serializers.ModelSerializer):
    """Serializer para Proveedores Super"""

    # Relación con categoría
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)

    # Campos calculados
    esta_abierto = serializers.ReadOnlyField()

    # URLs de imágenes
    logo_url = serializers.SerializerMethodField()
    imagen_portada_url = serializers.SerializerMethodField()

    # Productos (opcional, para detalle)
    productos = ProductoSuperSerializer(many=True, read_only=True)

    class Meta:
        model = ProveedorSuper
        fields = [
            'id',
            'categoria',
            'categoria_nombre',
            'nombre',
            'descripcion',
            'telefono',
            'email',
            'direccion',
            'latitud',
            'longitud',
            'logo',
            'logo_url',
            'imagen_portada',
            'imagen_portada_url',
            'horario_apertura',
            'horario_cierre',
            'calificacion',
            'total_resenas',
            'activo',
            'verificado',
            'esta_abierto',
            'productos',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at', 'calificacion', 'total_resenas']

    def get_logo_url(self, obj):
        """Retorna la URL completa del logo"""
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None

    def get_imagen_portada_url(self, obj):
        """Retorna la URL completa de la imagen de portada"""
        if obj.imagen_portada:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen_portada.url)
            return obj.imagen_portada.url
        return None


class ProveedorSuperListSerializer(serializers.ModelSerializer):
    """Serializer simplificado para listado de proveedores"""

    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    esta_abierto = serializers.ReadOnlyField()
    logo_url = serializers.SerializerMethodField()

    class Meta:
        model = ProveedorSuper
        fields = [
            'id',
            'categoria_nombre',
            'nombre',
            'descripcion',
            'logo_url',
            'calificacion',
            'total_resenas',
            'activo',
            'verificado',
            'esta_abierto',
        ]

    def get_logo_url(self, obj):
        """Retorna la URL completa del logo"""
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None
