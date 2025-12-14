# backend/pagos/urls.py
"""
Configuración de URLs para el módulo de Pagos.

CARACTERÍSTICAS:
- Rutas REST automáticas con DefaultRouter.
- Endpoints operativos (Cliente -> Chofer).
- Webhooks para pasarelas externas.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    MetodoPagoViewSet,
    PagoViewSet,
    TransaccionViewSet,
    EstadisticasPagoViewSet,
    # Webhooks (Funciones)
    stripe_webhook,
    kushki_webhook,
    paymentez_webhook,
    # Comprobantes (Funciones)
    subir_comprobante_pago,
    ver_comprobante_repartidor,
    marcar_comprobante_visto,
    obtener_datos_bancarios_para_pago,
)

app_name = 'pagos'

# ==========================================================
# 🔗 ROUTER DE DRF
# ==========================================================

router = DefaultRouter()

# 1. Métodos de Pago (Catálogo)
router.register(r'metodos', MetodoPagoViewSet, basename='metodo-pago')

# 2. Pagos (Gestión Central)
# Incluye acciones: subir_comprobante, confirmar_recepcion_dinero, etc.
router.register(r'pagos', PagoViewSet, basename='pago')

# 3. Transacciones (Historial)
router.register(r'transacciones', TransaccionViewSet, basename='transaccion')

# 4. Estadísticas (Admin)
router.register(r'estadisticas-diarias', EstadisticasPagoViewSet, basename='estadistica-pago')

# ==========================================================
# 📍 URLS PRINCIPALES
# ==========================================================

urlpatterns = [
    # API REST (Incluye todas las rutas del router)
    path('', include(router.urls)),

    # Webhooks Externos (Stripe, Kushki, Paymentez)
    path('webhook/stripe/', stripe_webhook, name='webhook-stripe'),
    path('webhook/kushki/', kushki_webhook, name='webhook-kushki'),
    path('webhook/paymentez/', paymentez_webhook, name='webhook-paymentez'),

    # ==========================================================
    # COMPROBANTES DE PAGO
    # ==========================================================
    # Cliente sube comprobante
    path('pagos/<int:pago_id>/subir-comprobante/', subir_comprobante_pago, name='subir-comprobante'),

    # Cliente obtiene datos bancarios para transferir
    path('pagos/<int:pago_id>/datos-bancarios/', obtener_datos_bancarios_para_pago, name='datos-bancarios-pago'),

    # Repartidor ve comprobante
    path('pagos/<int:pago_id>/ver-comprobante/', ver_comprobante_repartidor, name='ver-comprobante'),

    # Repartidor marca comprobante como visto
    path('pagos/<int:pago_id>/marcar-visto/', marcar_comprobante_visto, name='marcar-comprobante-visto'),
]

# ==========================================================
#  DOCUMENTACIÓN DE ENDPOINTS (REFERENCIA RÁPIDA)
# ==========================================================
"""
RUTAS CLAVE GENERADAS AUTOMÁTICAMENTE:

╔══════════════════════════════════════════════════════════════════════╗
║                    FLUJO OPERATIVO (APP)                           ║
╚══════════════════════════════════════════════════════════════════════╝

1. [CLIENTE] Ver a dónde transferir (Datos del Chofer):
   GET /api/pagos/pagos/{id}/datos_transferencia/

2. [CLIENTE] Subir la foto del comprobante:
   POST /api/pagos/pagos/{id}/subir_comprobante/
   Body (Multipart): { "transferencia_comprobante": <archivo> }

3. [CHOFER/ADMIN] Confirmar que tienen el dinero:
   POST /api/pagos/pagos/{id}/confirmar_recepcion_dinero/

4. [CHOFER/ADMIN] Rechazar comprobante falso:
   POST /api/pagos/pagos/{id}/rechazar_comprobante/
   Body: { "motivo": "Foto borrosa" }

╔══════════════════════════════════════════════════════════════════════╗
║                     GESTIÓN GENERAL                                ║
╚══════════════════════════════════════════════════════════════════════╝

- Listar mis pagos:
  GET /api/pagos/pagos/
  
- Crear un pago nuevo:
  POST /api/pagos/pagos/

- Ver métodos disponibles:
  GET /api/pagos/metodos/disponibles/

- Ver historial de un pago:
  GET /api/pagos/pagos/{id}/transacciones/
"""