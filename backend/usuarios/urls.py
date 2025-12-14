# -*- coding: utf-8 -*-
# usuarios/urls.py

from django.urls import path
from . import views

app_name = "usuarios"

urlpatterns = [
    # ==========================================
    # GESTIÓN DE PERFIL
    # ==========================================
    path("perfil/", views.obtener_perfil, name="obtener_perfil"),
    path("perfil/actualizar/", views.actualizar_perfil, name="actualizar_perfil"),
    path("perfil/foto/", views.subir_foto_perfil, name="subir_foto_perfil"),
    path("perfil/estadisticas/", views.estadisticas_usuario, name="estadisticas_usuario"),
    path("perfil/publico/<int:user_id>/", views.obtener_perfil_publico, name="perfil_publico"),

    # ==========================================
    # ROLES Y VERIFICACIÓN
    # ==========================================
    path("verificar-roles/", views.verificar_roles_usuario, name="verificar_roles"),
    path("mis-roles/", views.mis_roles, name="mis_roles"),
    path("cambiar-rol-activo/", views.cambiar_rol_activo, name="cambiar_rol_activo"),

    # ==========================================
    # SOLICITUDES DE CAMBIO DE ROL
    # ==========================================
    path("solicitudes-cambio-rol/", views.mis_solicitudes_cambio_rol, name="mis_solicitudes"),
    path("solicitudes-cambio-rol/<uuid:solicitud_id>/", views.detalle_solicitud_cambio_rol, name="detalle_solicitud"),

    # ==========================================
    # NOTIFICACIONES PUSH (FCM)
    # ==========================================
    path("fcm-token/", views.registrar_fcm_token, name="registrar_fcm_token"),
    path("fcm-token/eliminar/", views.eliminar_fcm_token, name="eliminar_fcm_token"),
    path("notificaciones/", views.estado_notificaciones, name="estado_notificaciones"),

    # ==========================================
    # UBICACIÓN (TIEMPO REAL / REST)
    # ==========================================
    path("ubicacion/actualizar/", views.actualizar_ubicacion, name="actualizar_ubicacion"),
    path("ubicacion/mia/", views.mi_ubicacion, name="mi_ubicacion"),

    # ==========================================
    # DIRECCIONES
    # ==========================================
    # Nota: Rutas estáticas antes de las dinámicas (<uuid>)
    path("direcciones/", views.direcciones_favoritas, name="direcciones_favoritas"),
    path("direcciones/predeterminada/", views.direccion_predeterminada, name="direccion_predeterminada"),
    path("direcciones/<uuid:direccion_id>/", views.detalle_direccion, name="detalle_direccion"),

    # ==========================================
    # MÉTODOS DE PAGO
    # ==========================================
    # Nota: Rutas estáticas antes de las dinámicas (<uuid>)
    path("metodos-pago/", views.metodos_pago, name="metodos_pago"),
    path("metodos-pago/predeterminado/", views.metodo_pago_predeterminado, name="metodo_pago_predeterminado"),
    path("metodos-pago/<uuid:metodo_id>/", views.detalle_metodo_pago, name="detalle_metodo_pago"),
]