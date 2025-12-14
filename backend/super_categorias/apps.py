# super_categorias/apps.py

from django.apps import AppConfig


class SuperCategoriasConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'super_categorias'
    verbose_name = 'Super - Categorías y Proveedores'
