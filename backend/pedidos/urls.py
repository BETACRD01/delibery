# pedidos/urls.py (VERSIÓN OPTIMIZADA)
"""
Rutas URL para la gestión de pedidos.
Endpoints RESTful organizados por recurso.
"""

from django.urls import path
from . import views

app_name = "pedidos"

urlpatterns = [
    # ==========================================================
    #  CORE: GESTIÓN DE PEDIDOS (CRUD)
    # ==========================================================
    
    # GET  /api/pedidos/ -> Listar mis pedidos (con filtros)
    # POST /api/pedidos/ -> Crear nuevo pedido
    path(
        "",
        views.pedidos_view,
        name="lista_crear_pedidos"
    ),

    # GET /api/pedidos/{id}/ -> Ver detalle completo
    path(
        "<int:pedido_id>/",
        views.pedido_detalle,
        name="detalle_pedido"
    ),

    # ==========================================================
    #  FLUJO DE ESTADOS (CAMBIOS DE STATUS)
    # ==========================================================

    # PATCH /api/pedidos/{id}/aceptar-repartidor/ -> Repartidor toma el pedido
    path(
        "<int:pedido_id>/aceptar-repartidor/",
        views.aceptar_pedido_repartidor,
        name="aceptar_repartidor"
    ),

    # PATCH /api/pedidos/{id}/confirmar-proveedor/ -> Restaurante confirma preparación
    path(
        "<int:pedido_id>/confirmar-proveedor/",
        views.confirmar_pedido_proveedor,
        name="confirmar_proveedor"
    ),

    # PATCH /api/pedidos/{id}/estado/ -> Cambios manuales (En ruta, Entregado)
    path(
        "<int:pedido_id>/estado/",
        views.cambiar_estado_pedido,
        name="cambiar_estado"
    ),

    # POST /api/pedidos/{id}/cancelar/ -> Cancelación controlada
    path(
        "<int:pedido_id>/cancelar/",
        views.cancelar_pedido,
        name="cancelar_pedido"
    ),

    # ==========================================================
    #  FINANZAS Y REPORTES
    # ==========================================================

    # GET /api/pedidos/{id}/ganancias/ -> Ver desglose de comisiones
    path(
        "<int:pedido_id>/ganancias/",
        views.ver_ganancias_pedido,
        name="ver_ganancias"
    ),

]