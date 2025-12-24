# productos/urls.py
"""
URLs para el sistema de productos y carrito
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Router para ViewSets
router = DefaultRouter()
router.register(r'categorias', views.CategoriaViewSet, basename='categoria')
router.register(r'productos', views.ProductoViewSet, basename='producto')
router.register(r'promociones', views.PromocionViewSet, basename='promocion')
router.register(r'provider/products', views.ProviderProductoViewSet, basename='provider-producto')
router.register(r'provider/promociones', views.ProviderPromocionViewSet, basename='provider-promocion')

# URLs del carrito
urlpatterns_carrito = [
    path('', views.ver_carrito, name='ver-carrito'),
    path('agregar/', views.agregar_al_carrito, name='agregar-carrito'),
    path('item/<int:item_id>/cantidad/', views.actualizar_cantidad, name='actualizar-cantidad'),
    path('item/<int:item_id>/', views.remover_del_carrito, name='remover-item'),
    path('limpiar/', views.limpiar_carrito, name='limpiar-carrito'),
    path('checkout/', views.checkout, name='checkout'),
]

# URLs principales
urlpatterns = [
    # ViewSets
    path('', include(router.urls)),
    
    # Carrito
    path('carrito/', include(urlpatterns_carrito)),
]