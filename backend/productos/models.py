# productos/models.py
"""
Sistema de Productos y Catálogo para Deliber/JP Express
Actualizado: Integración de Ofertas y Promociones Avanzadas + Fix Carrito
"""

from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.db.models import Sum, F
from decimal import Decimal

from proveedores.models import Proveedor


# ═══════════════════════════════════════════════════════════════════════
# CATEGORÍAS
# ═══════════════════════════════════════════════════════════════════════
class Categoria(models.Model):
    nombre = models.CharField(
        max_length=100,
        unique=True,
        verbose_name='Nombre',
        help_text='Nombre de la categoría (Ej: Pizza, Bebidas)'
    )
    
    imagen = models.ImageField(
        upload_to='categorias/',
        blank=True, 
        null=True,
        verbose_name='Imagen'
    )

    imagen_url = models.URLField(
        blank=True,
        null=True,
        verbose_name='URL Imagen',
        help_text='URL externa si no se sube archivo'
    )
    
    activo = models.BooleanField(default=True, verbose_name='Activo')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'categorias'
        verbose_name = 'Categoría'
        verbose_name_plural = 'Categorías'
        ordering = ['nombre']
    
    def __str__(self):
        return self.nombre
    
    @property
    def total_productos(self):
        return self.productos.filter(disponible=True).count()

    @property
    def imagen_final(self):
        """Retorna la URL de imagen, ya sea archivo o URL externa."""
        if self.imagen:
            return self.imagen.url
        return self.imagen_url


# ═══════════════════════════════════════════════════════════════════════
# PRODUCTOS (Con lógica de Ofertas)
# ═══════════════════════════════════════════════════════════════════════
class Producto(models.Model):
    proveedor = models.ForeignKey(
        Proveedor,
        on_delete=models.CASCADE,
        related_name='productos',
        verbose_name='Proveedor'
    )
    
    categoria = models.ForeignKey(
        Categoria,
        on_delete=models.SET_NULL,
        null=True,
        related_name='productos',
        verbose_name='Categoría'
    )
    
    nombre = models.CharField(max_length=200, verbose_name='Nombre del Producto')
    descripcion = models.TextField(verbose_name='Descripción')
    
    # --- SISTEMA DE PRECIOS Y OFERTAS ---
    precio = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Precio Actual (Final)'
    )

    precio_anterior = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        blank=True, null=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        verbose_name='Precio Anterior (Tachado)',
        help_text='Si se llena, el sistema calculará y mostrará el % de descuento.'
    )
    
    imagen = models.ImageField(
        upload_to='productos/%Y/%m/',
        blank=True, null=True,
        verbose_name='Imagen (Archivo)'
    )
    
    imagen_url = models.URLField(
        blank=True, null=True,
        verbose_name='URL Imagen'
    )
    
    # Estado
    disponible = models.BooleanField(default=True, verbose_name='Disponible')
    destacado = models.BooleanField(default=False, verbose_name='Destacado')
    
    # Inventario
    tiene_stock = models.BooleanField(default=False, verbose_name='Controlar Stock')
    stock = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    
    # Stats
    veces_vendido = models.IntegerField(default=0)
    rating_promedio = models.DecimalField(
        max_digits=3, decimal_places=2, default=0,
        validators=[MinValueValidator(0), MaxValueValidator(5)]
    )
    total_resenas = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'productos'
        verbose_name = 'Producto'
        verbose_name_plural = 'Productos'
        ordering = ['-destacado', '-created_at']
        indexes = [
            models.Index(fields=['proveedor', 'disponible']),
            models.Index(fields=['categoria', 'disponible']),
        ]
    
    def __str__(self):
        return f"{self.nombre} ({self.proveedor.nombre})"
    
    @property
    def imagen_final(self):
        if self.imagen: return self.imagen.url
        return self.imagen_url

    @property
    def en_oferta(self):
        """Retorna True si tiene un precio anterior mayor al actual"""
        return self.precio_anterior and self.precio_anterior > self.precio

    @property
    def porcentaje_descuento(self):
        """Calcula el % de ahorro para mostrar el sticker '38% OFF'"""
        if self.en_oferta:
            descuento = ((self.precio_anterior - self.precio) / self.precio_anterior) * 100
            return int(round(descuento))
        return 0
    
    def decrementar_stock(self, cantidad=1):
        if not self.tiene_stock: return True
        updated = Producto.objects.filter(pk=self.pk, stock__gte=cantidad).update(stock=F('stock') - cantidad)
        return updated > 0
    
    def incrementar_vendidos(self):
        Producto.objects.filter(pk=self.pk).update(veces_vendido=F('veces_vendido') + 1)


# ═══════════════════════════════════════════════════════════════════════
# PROMOCIONES (Banners Principales)
# ═══════════════════════════════════════════════════════════════════════
class Promocion(models.Model):
    proveedor = models.ForeignKey(
        Proveedor,
        on_delete=models.CASCADE,
        related_name='promociones',
        null=True, blank=True
    )
    
    titulo = models.CharField(max_length=200, help_text="Ej: Combos $4.99")
    descripcion = models.TextField(help_text="Ej: Pide tus combos favoritos...")
    
    # Datos visuales para el Widget de Flutter
    descuento = models.CharField(max_length=50, verbose_name='Texto Sticker', help_text="Ej: '20% OFF' o 'Exclusivo'")
    color = models.CharField(max_length=7, default='#E91E63', help_text="Color Hex del fondo (Ej: #E91E63)")
    
    imagen = models.ImageField(upload_to='promociones/', blank=True, null=True)
    imagen_url = models.URLField(blank=True, null=True)
    
    # LOGICA DE NAVEGACIÓN
    producto_asociado = models.ForeignKey(
        Producto, on_delete=models.SET_NULL, null=True, blank=True,
        help_text="Si se selecciona, al hacer click llevará a este producto."
    )
    categoria_asociada = models.ForeignKey(
        Categoria, on_delete=models.SET_NULL, null=True, blank=True,
        help_text="Si se selecciona, al hacer click llevará a esta categoría."
    )

    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_fin = models.DateTimeField(null=True, blank=True)
    activa = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'promociones'
        verbose_name = 'Banner Promocional'
        verbose_name_plural = 'Banners Promocionales'
        ordering = ['-created_at']
    
    def __str__(self):
        return self.titulo
    
    @property
    def es_vigente(self):
        if not self.activa: return False
        ahora = timezone.now()
        if self.fecha_inicio and ahora < self.fecha_inicio: return False
        if self.fecha_fin and ahora > self.fecha_fin: return False
        return True
    
    @property
    def dias_restantes(self):
        if not self.fecha_fin: return None
        delta = self.fecha_fin - timezone.now()
        return max(0, delta.days)


# ═══════════════════════════════════════════════════════════════════════
# CARRITO DE COMPRAS
# ═══════════════════════════════════════════════════════════════════════
class Carrito(models.Model):
    usuario = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='carrito'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'carritos'
    
    @property
    def total(self):
        data = self.items.aggregate(t=Sum(F('precio_unitario') * F('cantidad')))
        return data['t'] or Decimal('0.00')
    
    @property
    def cantidad_total(self):
        data = self.items.aggregate(c=Sum('cantidad'))
        return data['c'] or 0
    
    def limpiar(self):
        self.items.all().delete()

class ItemCarrito(models.Model):
    carrito = models.ForeignKey(Carrito, on_delete=models.CASCADE, related_name='items')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    cantidad = models.IntegerField(default=1, validators=[MinValueValidator(1)])
    precio_unitario = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'items_carrito'
        unique_together = ['carrito', 'producto']
    
    @property
    def subtotal(self):
        # 🛡️ FIX: Validación de seguridad por si precio_unitario es None
        precio = self.precio_unitario or Decimal('0.00')
        cantidad = self.cantidad or 0
        return precio * cantidad
    
    def save(self, *args, **kwargs):
        if not self.precio_unitario and self.producto:
            self.precio_unitario = self.producto.precio
        super().save(*args, **kwargs)
