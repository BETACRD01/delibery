# envios/urls.py
from django.urls import path

app_name = 'envios'

from .views import CotizarEnvioView, CrearPedidoCourierView

urlpatterns = [
    path('cotizar/', CotizarEnvioView.as_view(), name='cotizar_envio'),
    path('crear-courier/', CrearPedidoCourierView.as_view(), name='crear_pedido_courier'),
]
