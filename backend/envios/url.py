# envios/urls.py
from django.urls import path

app_name = 'envios'

from .views import CotizarEnvioView

urlpatterns = [
    path('cotizar/', CotizarEnvioView.as_view(), name='cotizar_envio'),
]
