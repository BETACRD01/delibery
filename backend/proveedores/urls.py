# proveedores/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ProveedorViewSet, 
    GestionProveedoresViewSet, 
    GestionRepartidoresViewSet,
    MisProductosViewSet,
    MisPromocionesViewSet
)

router = DefaultRouter()
router.register(r'gestion-admin', GestionProveedoresViewSet, basename='admin-proveedores')
router.register(r'gestion-repartidores', GestionRepartidoresViewSet, basename='admin-repartidores')
router.register(r'mis-productos', MisProductosViewSet, basename='mis-productos')
router.register(r'', ProveedorViewSet, basename='proveedor')

app_name = 'proveedores'

urlpatterns = [
    path('', include(router.urls)),
]