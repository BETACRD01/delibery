# super_categorias/models.py
"""
Sistema de Categorías Super para JP Express
Gestiona: Supermercados, Farmacias, Bebidas, Mensajería, Tiendas
"""

from django.db import models
from django.core.validators import MinValueValidator
from django.utils import timezone


class CategoriaSuper(models.Model):
    """
    Modelo para las categorías del servicio Super
    Ejemplos: Supermercados, Farmacias, Bebidas, Mensajería, Tiendas
    """

    # Identificador único para cada categoría
    id = models.CharField(
        max_length=50,
        primary_key=True,
        verbose_name='ID Categoría',
        help_text='Identificador único (ej: supermercados, farmacias)'
    )

    # Información básica
    nombre = models.CharField(
        max_length=100,
        verbose_name='Nombre',
        help_text='Nombre visible de la categoría'
    )

    descripcion = models.TextField(
        verbose_name='Descripción',
        help_text='Descripción breve del servicio'
    )

    # Visualización
    icono = models.IntegerField(
        verbose_name='Código del Icono',
        help_text='CodePoint de Material Icons (ej: 57524 para shopping_cart)'
    )

    color = models.CharField(
        max_length=9,
        verbose_name='Color',
        help_text='Color en formato hexadecimal (ej: #4CAF50 o #FF4CAF50)'
    )

    # Imágenes
    imagen = models.ImageField(
        upload_to='super/categorias/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='Imagen Principal',
        help_text='Imagen de la categoría para banners'
    )

    logo = models.ImageField(
        upload_to='super/logos/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='Logo',
        help_text='Logo opcional de la categoría'
    )

    # URLs alternativas para imágenes externas
    imagen_url = models.URLField(
        blank=True,
        null=True,
        verbose_name='URL Imagen Externa',
        help_text='URL externa de la imagen (si no se usa archivo)'
    )

    logo_url = models.URLField(
        blank=True,
        null=True,
        verbose_name='URL Logo Externo',
        help_text='URL externa del logo (si no se usa archivo)'
    )

    # Control
    activo = models.BooleanField(
        default=True,
        verbose_name='Activo',
        help_text='Si está activo se muestra en la app'
    )

    orden = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        verbose_name='Orden',
        help_text='Orden de visualización (menor primero)'
    )

    # Metadata
    destacado = models.BooleanField(
        default=False,
        verbose_name='Destacado',
        help_text='Marcar con badge "NUEVO" o destacar'
    )

    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Fecha de Creación'
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Última Actualización'
    )

    class Meta:
        db_table = 'super_categorias'
        verbose_name = 'Categoría Super'
        verbose_name_plural = 'Categorías Super'
        ordering = ['orden', 'nombre']

    def __str__(self):
        return f"{self.nombre} ({self.id})"

    @property
    def total_proveedores(self):
        """Total de proveedores activos en esta categoría"""
        return self.proveedores_super.filter(activo=True).count()

    @property
    def tiene_imagen(self):
        """Verifica si tiene imagen (archivo o URL)"""
        return bool(self.imagen or self.imagen_url)

    @property
    def tiene_logo(self):
        """Verifica si tiene logo (archivo o URL)"""
        return bool(self.logo or self.logo_url)

    def get_imagen_url(self):
        """Retorna la URL de la imagen (archivo o externa)"""
        if self.imagen:
            return self.imagen.url
        return self.imagen_url

    def get_logo_url(self):
        """Retorna la URL del logo (archivo o externo)"""
        if self.logo:
            return self.logo.url
        return self.logo_url


class ProveedorSuper(models.Model):
    """
    Proveedores asociados a categorías Super
    Ej: Un supermercado específico, una farmacia, etc.
    """

    categoria = models.ForeignKey(
        CategoriaSuper,
        on_delete=models.CASCADE,
        related_name='proveedores_super',
        verbose_name='Categoría Super'
    )

    nombre = models.CharField(
        max_length=200,
        verbose_name='Nombre del Proveedor',
        help_text='Ej: Supermercado La Rebaja, Farmacia Cruz Azul'
    )

    descripcion = models.TextField(
        blank=True,
        verbose_name='Descripción'
    )

    # Información de contacto
    telefono = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='Teléfono'
    )

    email = models.EmailField(
        blank=True,
        verbose_name='Email'
    )

    # Ubicación
    direccion = models.TextField(
        verbose_name='Dirección'
    )

    latitud = models.DecimalField(
        max_digits=10,
        decimal_places=8,
        blank=True,
        null=True,
        verbose_name='Latitud'
    )

    longitud = models.DecimalField(
        max_digits=11,
        decimal_places=8,
        blank=True,
        null=True,
        verbose_name='Longitud'
    )

    # Imágenes
    logo = models.ImageField(
        upload_to='super/proveedores/logos/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='Logo'
    )

    imagen_portada = models.ImageField(
        upload_to='super/proveedores/portadas/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='Imagen de Portada'
    )

    # Horarios
    horario_apertura = models.TimeField(
        blank=True,
        null=True,
        verbose_name='Hora de Apertura'
    )

    horario_cierre = models.TimeField(
        blank=True,
        null=True,
        verbose_name='Hora de Cierre'
    )

    # Calificación
    calificacion = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
        verbose_name='Calificación Promedio'
    )

    total_resenas = models.IntegerField(
        default=0,
        verbose_name='Total de Reseñas'
    )

    # Control
    activo = models.BooleanField(
        default=True,
        verbose_name='Activo'
    )

    verificado = models.BooleanField(
        default=False,
        verbose_name='Verificado',
        help_text='Proveedor verificado por JP Express'
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'super_proveedores'
        verbose_name = 'Proveedor Super'
        verbose_name_plural = 'Proveedores Super'
        ordering = ['-calificacion', 'nombre']

    def __str__(self):
        return f"{self.nombre} - {self.categoria.nombre}"

    @property
    def esta_abierto(self):
        """Verifica si el proveedor está abierto actualmente"""
        if not (self.horario_apertura and self.horario_cierre):
            return True  # Si no tiene horarios, asumimos que está abierto

        ahora = timezone.now().time()
        return self.horario_apertura <= ahora <= self.horario_cierre


class ProductoSuper(models.Model):
    """
    Productos ofrecidos por proveedores Super
    """

    proveedor = models.ForeignKey(
        ProveedorSuper,
        on_delete=models.CASCADE,
        related_name='productos',
        verbose_name='Proveedor'
    )

    nombre = models.CharField(
        max_length=200,
        verbose_name='Nombre del Producto'
    )

    descripcion = models.TextField(
        blank=True,
        verbose_name='Descripción'
    )

    # Precios
    precio = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        verbose_name='Precio'
    )

    precio_anterior = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        blank=True,
        null=True,
        verbose_name='Precio Anterior',
        help_text='Para mostrar descuentos'
    )

    # Imagen
    imagen = models.ImageField(
        upload_to='super/productos/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='Imagen'
    )

    # Stock
    stock = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        verbose_name='Stock Disponible'
    )

    # Control
    disponible = models.BooleanField(
        default=True,
        verbose_name='Disponible'
    )

    destacado = models.BooleanField(
        default=False,
        verbose_name='Producto Destacado'
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'super_productos'
        verbose_name = 'Producto Super'
        verbose_name_plural = 'Productos Super'
        ordering = ['-destacado', '-created_at']

    def __str__(self):
        return f"{self.nombre} - {self.proveedor.nombre}"

    @property
    def en_oferta(self):
        """Verifica si el producto está en oferta"""
        return self.precio_anterior and self.precio_anterior > self.precio

    @property
    def porcentaje_descuento(self):
        """Calcula el porcentaje de descuento"""
        if not self.en_oferta:
            return 0
        return int(((self.precio_anterior - self.precio) / self.precio_anterior) * 100)

    @property
    def tiene_stock(self):
        """Verifica si hay stock disponible"""
        return self.stock > 0
