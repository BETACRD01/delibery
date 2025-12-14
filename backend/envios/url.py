# envios/urls.py
from django.urls import path
from .views import CotizarEnvioView

app_name = 'envios'

urlpatterns = [
    path('cotizar/', CotizarEnvioView.as_view(), name='cotizar_envio'),
]