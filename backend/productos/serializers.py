# productos/serializers.py
from rest_framework import serializers
from .models import (
    Categoria, Producto, Promocion,
    Carrito, ItemCarrito
)
from .visual_services import CategoriaVisualizer


def _build_media_url(file_field, request=None):
    """Construye URL absoluta para un ImageField/FileField si existe."""
    if not file_field:
        return None
    try:
        url = file_field.url
    except Exception:
        return None
    if not url:
        return None
    if url.startswith('http://') or url.startswith('https://'):
        return url
    if request is not None:
        return request.build_absolute_uri(url)
    return url


# ... (CategoriaSerializer se mantiene igual) ...
class CategoriaSerializer(serializers.ModelSerializer):
    total_productos = serializers.ReadOnlyField()
    ui_data = serializers.SerializerMethodField()

    class Meta:
        model = Categoria
        fields = ['id', 'nombre', 'ui_data', 'activo', 'total_productos']

    def get_ui_data(self, obj):
        request = self.context.get('request')
        return CategoriaVisualizer.procesar_visualizacion(obj, request)

# ═══════════════════════════════════════════════════════════════════════
# PRODUCTOS (Actualizado con Lógica de Ofertas)
# ═══════════════════════════════════════════════════════════════════════

class ProductoListSerializer(serializers.ModelSerializer):
    """Serializer optimizado para listas de productos (Home, Catálogo)"""
    
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    proveedor_nombre = serializers.CharField(source='proveedor.nombre', read_only=True)
    proveedor_logo_url = serializers.SerializerMethodField()
    imagen_url = serializers.SerializerMethodField()
    
    # Nuevos campos para UI de Ofertas
    en_oferta = serializers.BooleanField(read_only=True)
    precio_anterior = serializers.DecimalField(max_digits=8, decimal_places=2, read_only=True)
    porcentaje_descuento = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Producto
        fields = [
            'id', 'nombre', 'descripcion', 
            'precio', 'precio_anterior', 'en_oferta', 'porcentaje_descuento',
            'imagen_url', 'disponible', 'destacado',
            'rating_promedio', 'total_resenas',
            'categoria_id', 'categoria_nombre',
            'proveedor_id', 'proveedor_nombre', 'proveedor_logo_url',
        ]

    def get_imagen_url(self, obj):
        # Prioriza imagen de archivo, devuelve URL absoluta si hay request
        if obj.imagen:
            request = self.context.get('request')
            return _build_media_url(obj.imagen, request)
        return obj.imagen_url

    def get_proveedor_logo_url(self, obj):
        prov = getattr(obj, 'proveedor', None)
        if not prov:
            return None
        request = self.context.get('request')
        # 1) Logo directo del proveedor
        logo = _build_media_url(getattr(prov, 'logo', None), request)
        if logo:
            return logo
        # 2) Fallback: foto de perfil del usuario proveedor
        user = getattr(prov, 'user', None)
        perfil = getattr(user, 'perfil', None) if user else None
        foto = _build_media_url(getattr(perfil, 'foto_perfil', None), request)
        if foto:
            return foto
        # 3) Último recurso: avatar generado por nombre
        nombre = getattr(prov, 'nombre', '') or 'Proveedor'
        from urllib.parse import quote
        return f'https://ui-avatars.com/api/?name={quote(nombre)}&background=0D8ABC&color=fff'

class ProductoDetalleSerializer(serializers.ModelSerializer):
    """Serializer completo para la pantalla de detalle"""
    
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    proveedor_nombre = serializers.CharField(source='proveedor.nombre', read_only=True)
    proveedor_logo_url = serializers.SerializerMethodField()
    imagen_url = serializers.SerializerMethodField()
    
    en_oferta = serializers.BooleanField(read_only=True)
    porcentaje_descuento = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Producto
        fields = [
            'id', 'nombre', 'descripcion', 
            'precio', 'precio_anterior', 'en_oferta', 'porcentaje_descuento',
            'imagen_url', 'disponible', 'destacado',
            'tiene_stock', 'stock', 'veces_vendido',
            'rating_promedio', 'total_resenas',
            'categoria_id', 'categoria_nombre',
            'proveedor_id', 'proveedor_nombre', 'proveedor_logo_url',
            'created_at', 'updated_at'
        ]

    def get_imagen_url(self, obj):
        if obj.imagen:
            request = self.context.get('request')
            return _build_media_url(obj.imagen, request)
        return obj.imagen_url

    def get_proveedor_logo_url(self, obj):
        prov = getattr(obj, 'proveedor', None)
        if not prov:
            return None
        request = self.context.get('request')
        logo = _build_media_url(getattr(prov, 'logo', None), request)
        if logo:
            return logo
        user = getattr(prov, 'user', None)
        perfil = getattr(user, 'perfil', None) if user else None
        foto = _build_media_url(getattr(perfil, 'foto_perfil', None), request)
        if foto:
            return foto
        from urllib.parse import quote
        nombre = getattr(prov, 'nombre', '') or 'Proveedor'
        return f'https://ui-avatars.com/api/?name={quote(nombre)}&background=0D8ABC&color=fff'

class ProductoCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Producto
        fields = [
            'nombre', 'descripcion', 'precio', 'precio_anterior', # Agregado para edición
            'categoria', 'imagen', 'imagen_url', 
            'disponible', 'destacado',
            'tiene_stock', 'stock'
        ]
    
    def validate(self, data):
        # Validación lógica de precios
        precio = data.get('precio')
        precio_ant = data.get('precio_anterior')
        
        if precio and precio <= 0:
            raise serializers.ValidationError({"precio": "El precio debe ser mayor a 0"})
            
        if precio_ant and precio and precio_ant <= precio:
             raise serializers.ValidationError({
                 "precio_anterior": "El precio anterior (tachado) debe ser mayor al precio actual para que sea una oferta válida."
             })
             
        if data.get('tiene_stock') and data.get('stock', 0) < 0:
            raise serializers.ValidationError({'stock': 'El stock no puede ser negativo.'})
            
        return data


# ═══════════════════════════════════════════════════════════════════════
# PROMOCIONES (Banners con Navegación)
# ═══════════════════════════════════════════════════════════════════════

class PromocionSerializer(serializers.ModelSerializer):
    proveedor_nombre = serializers.CharField(source='proveedor.nombre', read_only=True)
    
    # Campo calculado para la URL de la imagen
    imagen_url = serializers.SerializerMethodField()
    
    es_vigente = serializers.ReadOnlyField()
    dias_restantes = serializers.ReadOnlyField()
    
    class Meta:
        model = Promocion
        fields = [
            'id', 'titulo', 'descripcion', 'descuento',
            'color', 'imagen_url', 
            'proveedor_id', 'proveedor_nombre',
            
            # Campos de navegación
            'producto_asociado', 'categoria_asociada',
            
            'fecha_inicio', 'fecha_fin', 'activa',
            'es_vigente', 'dias_restantes'
        ]
    
    def get_imagen_url(self, obj):
        # 1. Si hay un archivo subido (Prioridad)
        if obj.imagen:
            request = self.context.get('request')
            if request:
                # 🔥 CORRECCIÓN CRÍTICA: Devuelve la URL absoluta (http://ip:8000/media/...)
                return request.build_absolute_uri(obj.imagen.url)
            return obj.imagen.url
            
        # 2. Si no hay archivo, usa la URL externa (si existe)
        return obj.imagen_url

# ... (El resto de serializers de Carrito se mantienen igual) ...
class ItemCarritoSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    producto_imagen = serializers.CharField(source='producto.imagen_final', read_only=True)
    producto_disponible = serializers.BooleanField(source='producto.disponible', read_only=True)
    proveedor_latitud = serializers.SerializerMethodField()
    proveedor_longitud = serializers.SerializerMethodField()
    subtotal = serializers.ReadOnlyField()
    
    class Meta:
        model = ItemCarrito
        fields = [
            'id', 'producto_id', 'producto_nombre', 'producto_imagen', 'producto_disponible',
            'cantidad', 'precio_unitario', 'subtotal', 'proveedor_latitud', 'proveedor_longitud'
        ]

    def get_proveedor_latitud(self, obj):
        return getattr(obj.producto.proveedor, 'latitud', None)

    def get_proveedor_longitud(self, obj):
        return getattr(obj.producto.proveedor, 'longitud', None)

class CarritoSerializer(serializers.ModelSerializer):
    items = ItemCarritoSerializer(many=True, read_only=True)
    total = serializers.ReadOnlyField()
    cantidad_total = serializers.ReadOnlyField()
    
    class Meta:
        model = Carrito
        fields = ['id', 'usuario_id', 'items', 'total', 'cantidad_total']

class AgregarAlCarritoSerializer(serializers.Serializer):
    producto_id = serializers.IntegerField()
    cantidad = serializers.IntegerField(min_value=1, default=1)
    
    def validate_producto_id(self, value):
        try:
            producto = Producto.objects.get(id=value)
            if not producto.disponible:
                raise serializers.ValidationError("Este producto no está disponible")
            self.instance = producto 
            return value
        except Producto.DoesNotExist:
            raise serializers.ValidationError("Producto no encontrado")

    def validate(self, data):
        producto = self.instance 
        cantidad = data.get('cantidad')
        if producto.tiene_stock:
            carrito = self.context.get('carrito_instance')
            en_carrito = 0
            if carrito:
                 try:
                     item = ItemCarrito.objects.get(carrito=carrito, producto_id=producto.id)
                     en_carrito = item.cantidad
                 except ItemCarrito.DoesNotExist: pass
            
            if producto.stock < (cantidad + en_carrito):
                raise serializers.ValidationError({'cantidad': f"Stock insuficiente."})
        return data

class ActualizarCantidadSerializer(serializers.Serializer):
    cantidad = serializers.IntegerField(min_value=1)
