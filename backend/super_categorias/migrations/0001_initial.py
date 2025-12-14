# Generated migration for super_categorias

from django.db import migrations, models
import django.core.validators


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='CategoriaSuper',
            fields=[
                ('id', models.CharField(help_text='Identificador único (ej: supermercados, farmacias)', max_length=50, primary_key=True, serialize=False, verbose_name='ID Categoría')),
                ('nombre', models.CharField(help_text='Nombre visible de la categoría', max_length=100, verbose_name='Nombre')),
                ('descripcion', models.TextField(help_text='Descripción breve del servicio', verbose_name='Descripción')),
                ('icono', models.IntegerField(help_text='CodePoint de Material Icons (ej: 57524 para shopping_cart)', verbose_name='Código del Icono')),
                ('color', models.CharField(help_text='Color en formato hexadecimal (ej: #4CAF50 o #FF4CAF50)', max_length=9, verbose_name='Color')),
                ('imagen', models.ImageField(blank=True, help_text='Imagen de la categoría para banners', null=True, upload_to='super/categorias/%Y/%m/', verbose_name='Imagen Principal')),
                ('logo', models.ImageField(blank=True, help_text='Logo opcional de la categoría', null=True, upload_to='super/logos/%Y/%m/', verbose_name='Logo')),
                ('imagen_url', models.URLField(blank=True, help_text='URL externa de la imagen (si no se usa archivo)', null=True, verbose_name='URL Imagen Externa')),
                ('logo_url', models.URLField(blank=True, help_text='URL externa del logo (si no se usa archivo)', null=True, verbose_name='URL Logo Externo')),
                ('activo', models.BooleanField(default=True, help_text='Si está activo se muestra en la app', verbose_name='Activo')),
                ('orden', models.IntegerField(default=0, help_text='Orden de visualización (menor primero)', validators=[django.core.validators.MinValueValidator(0)], verbose_name='Orden')),
                ('destacado', models.BooleanField(default=False, help_text='Marcar con badge "NUEVO" o destacar', verbose_name='Destacado')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Fecha de Creación')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Última Actualización')),
            ],
            options={
                'verbose_name': 'Categoría Super',
                'verbose_name_plural': 'Categorías Super',
                'db_table': 'super_categorias',
                'ordering': ['orden', 'nombre'],
            },
        ),
        migrations.CreateModel(
            name='ProveedorSuper',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nombre', models.CharField(help_text='Ej: Supermercado La Rebaja, Farmacia Cruz Azul', max_length=200, verbose_name='Nombre del Proveedor')),
                ('descripcion', models.TextField(blank=True, verbose_name='Descripción')),
                ('telefono', models.CharField(blank=True, max_length=20, verbose_name='Teléfono')),
                ('email', models.EmailField(blank=True, max_length=254, verbose_name='Email')),
                ('direccion', models.TextField(verbose_name='Dirección')),
                ('latitud', models.DecimalField(blank=True, decimal_places=8, max_digits=10, null=True, verbose_name='Latitud')),
                ('longitud', models.DecimalField(blank=True, decimal_places=8, max_digits=11, null=True, verbose_name='Longitud')),
                ('logo', models.ImageField(blank=True, null=True, upload_to='super/proveedores/logos/%Y/%m/', verbose_name='Logo')),
                ('imagen_portada', models.ImageField(blank=True, null=True, upload_to='super/proveedores/portadas/%Y/%m/', verbose_name='Imagen de Portada')),
                ('horario_apertura', models.TimeField(blank=True, null=True, verbose_name='Hora de Apertura')),
                ('horario_cierre', models.TimeField(blank=True, null=True, verbose_name='Hora de Cierre')),
                ('calificacion', models.DecimalField(decimal_places=2, default=0, max_digits=3, validators=[django.core.validators.MinValueValidator(0)], verbose_name='Calificación Promedio')),
                ('total_resenas', models.IntegerField(default=0, verbose_name='Total de Reseñas')),
                ('activo', models.BooleanField(default=True, verbose_name='Activo')),
                ('verificado', models.BooleanField(default=False, help_text='Proveedor verificado por JP Express', verbose_name='Verificado')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('categoria', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='proveedores_super', to='super_categorias.categoriasuper', verbose_name='Categoría Super')),
            ],
            options={
                'verbose_name': 'Proveedor Super',
                'verbose_name_plural': 'Proveedores Super',
                'db_table': 'super_proveedores',
                'ordering': ['-calificacion', 'nombre'],
            },
        ),
        migrations.CreateModel(
            name='ProductoSuper',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nombre', models.CharField(max_length=200, verbose_name='Nombre del Producto')),
                ('descripcion', models.TextField(blank=True, verbose_name='Descripción')),
                ('precio', models.DecimalField(decimal_places=2, max_digits=8, validators=[django.core.validators.MinValueValidator(0)], verbose_name='Precio')),
                ('precio_anterior', models.DecimalField(blank=True, decimal_places=2, help_text='Para mostrar descuentos', max_digits=8, null=True, verbose_name='Precio Anterior')),
                ('imagen', models.ImageField(blank=True, null=True, upload_to='super/productos/%Y/%m/', verbose_name='Imagen')),
                ('stock', models.IntegerField(default=0, validators=[django.core.validators.MinValueValidator(0)], verbose_name='Stock Disponible')),
                ('disponible', models.BooleanField(default=True, verbose_name='Disponible')),
                ('destacado', models.BooleanField(default=False, verbose_name='Producto Destacado')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('proveedor', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='productos', to='super_categorias.proveedorsuper', verbose_name='Proveedor')),
            ],
            options={
                'verbose_name': 'Producto Super',
                'verbose_name_plural': 'Productos Super',
                'db_table': 'super_productos',
                'ordering': ['-destacado', '-created_at'],
            },
        ),
    ]
