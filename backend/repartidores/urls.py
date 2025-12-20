# repartidores/urls.py
from django.urls import path
from . import views
from .views import editar_mi_perfil, editar_mi_contacto

app_name = 'repartidores'

urlpatterns = [
    # ==========================================================
    # NUEVO: Mi Repartidor (Para Flutter - Panel Repartidor)
    # ==========================================================
    path(
        "mi_repartidor/",
        views.mi_repartidor,
        name="mi_repartidor"
    ),

    # ==========================================================
    # PERFIL DEL REPARTIDOR (propio)
    # ==========================================================
    path(
        "perfil/",
        views.obtener_mi_perfil,
        name="perfil"
    ),
    path(
        "perfil/actualizar/",
        views.actualizar_mi_perfil,
        name="actualizar_perfil"
    ),
    path(
        "perfil/estadisticas/",
        views.obtener_estadisticas,
        name="estadisticas"
    ),

    # ==========================================================
    # ESTADO LABORAL (disponible / ocupado / fuera de servicio)
    # ==========================================================
    path(
        "estado/",
        views.cambiar_estado,
        name="cambiar_estado"
    ),
    path(
        "estado/historial/",
        views.historial_estados,
        name="historial_estados"
    ),

    # ==========================================================
    # UBICACIÓN EN TIEMPO REAL
    # ==========================================================
    path(
        "ubicacion/",
        views.actualizar_ubicacion,
        name="actualizar_ubicacion"
    ),
    path(
        "ubicacion/historial/",
        views.historial_ubicaciones,
        name="historial_ubicaciones"
    ),
    path(
        "historial-entregas/",
        views.historial_entregas,
        name="historial_entregas"
    ),

    # ==========================================================
    # VEHÍCULOS
    # ==========================================================
    path(
        "vehiculos/",
        views.listar_vehiculos,
        name="listar_vehiculos"
    ),
    path(
        "vehiculos/crear/",
        views.crear_vehiculo,
        name="crear_vehiculo"
    ),
    path(
        "vehiculos/<int:vehiculo_id>/",
        views.detalle_vehiculo,
        name="detalle_vehiculo"
    ),
    path(
        "vehiculos/<int:vehiculo_id>/activar/",
        views.activar_vehiculo,
        name="activar_vehiculo"
    ),
    path(
        "vehiculo/actualizar-datos/",
        views.actualizar_datos_vehiculo,
        name="actualizar_datos_vehiculo"
    ),

    # ==========================================================
    # CALIFICACIONES
    # ==========================================================
    path(
        "calificaciones/",
        views.listar_mis_calificaciones,
        name="listar_calificaciones"
    ),
    path(
        "calificaciones/clientes/<int:pedido_id>/",
        views.calificar_cliente,
        name="calificar_cliente"
    ),

    # ==========================================================
    # PERFIL PÚBLICO (visto por el cliente)
    # ==========================================================
    path(
        "publico/<int:pedido_id>/",
        views.perfil_repartidor_por_pedido,
        name="perfil_publico_por_pedido"
    ),
    path(
        "publico/<int:repartidor_id>/info/",
        views.info_repartidor_publico,
        name="info_repartidor_publico"
    ),

    # ==========================================================
    # MAPA DE PEDIDOS
    # ==========================================================
    path(
        "pedidos-disponibles/",
        views.obtener_pedidos_disponibles_mapa,
        name="pedidos_disponibles_mapa"
    ),
    path(
        "mis-pedidos/",
        views.obtener_mis_pedidos_activos,
        name="mis_pedidos_activos"
    ),
    path(
        "mis-pedidos/actualizaciones/",
        views.obtener_actualizaciones_pedidos,
        name="actualizaciones_pedidos"
    ),
    path(
        "pedidos/<int:pedido_id>/detalle/",
        views.detalle_pedido_repartidor,
        name="detalle_pedido_repartidor"
    ),
    path(
        "pedidos/<int:pedido_id>/aceptar/",
        views.aceptar_pedido,
        name="aceptar_pedido"
    ),
    path(
        "pedidos/<int:pedido_id>/rechazar/",
        views.rechazar_pedido,
        name="rechazar_pedido"
    ),
    path(
        "pedidos/<int:pedido_id>/marcar-en-camino/",
        views.marcar_pedido_en_camino,
        name="marcar_pedido_en_camino"
    ),
    path(
        "pedidos/<int:pedido_id>/marcar-entregado/",
        views.marcar_pedido_entregado,
        name="marcar_pedido_entregado"
    ),
    path('editar_mi_perfil/', editar_mi_perfil,
         name='editar_mi_perfil'),

    path('editar_mi_contacto/', editar_mi_contacto,
         name='editar_mi_contacto'),

    # ==========================================================
    # DATOS BANCARIOS
    # ==========================================================
    path(
        "datos-bancarios/",
        views.datos_bancarios_repartidor,
        name="datos_bancarios"
    ),
]