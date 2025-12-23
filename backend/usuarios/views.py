# usuarios/views.py

import os
import logging
import re
from io import BytesIO
from PIL import Image
from django.apps import apps
from django.conf import settings
from django.core.files.uploadedfile import InMemoryUploadedFile
from django.db import transaction, IntegrityError
from django.shortcuts import get_object_or_404

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.exceptions import ValidationError as DRFValidationError
from django.core.exceptions import ValidationError as DjangoValidationError

from authentication.models import User, validar_celular
from .models import Perfil, DireccionFavorita, MetodoPago, UbicacionUsuario, SolicitudCambioRol
from .serializers import (
    PerfilSerializer,
    PerfilPublicoSerializer,
    ActualizarPerfilSerializer,
    DireccionFavoritaSerializer,
    CrearDireccionSerializer,
    ActualizarDireccionSerializer,
    MetodoPagoSerializer,
    CrearMetodoPagoSerializer,
    ActualizarMetodoPagoSerializer,
    EstadisticasUsuarioSerializer,
    FCMTokenSerializer,
    EstadoNotificacionesSerializer,
    UbicacionUsuarioSerializer,
    ActualizarUbicacionSerializer,
    SolicitudCambioRolListSerializer,
    SolicitudCambioRolDetalleSerializer,
    CrearSolicitudProveedorSerializer,
    CrearSolicitudRepartidorSerializer,
)
from utils.throttles import (
    PerfilThrottle,
    UploadThrottle,
    FCMThrottle,
    UbicacionThrottle,
)

logger = logging.getLogger("usuarios")

# ============================================
# PAGINACIÓN
# ============================================

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


# ============================================
# UTILIDADES
# ============================================

def procesar_imagen_perfil(imagen):
    """
    Redimensiona y optimiza la imagen de perfil en memoria.
    Retorna un InMemoryUploadedFile listo para guardar.
    """
    img = Image.open(imagen)
    
    # Convertir a RGB si es necesario (PNG/WEBP con transparencia)
    if img.mode in ("RGBA", "P", "LA"):
        img = img.convert("RGB")
    
    # Redimensionar manteniendo ratio
    img.thumbnail((800, 800), Image.Resampling.LANCZOS)
    
    output = BytesIO()
    img.save(output, format="JPEG", quality=85, optimize=True)
    output.seek(0)
    
    return InMemoryUploadedFile(
        output,
        "ImageField",
        f"{os.path.splitext(imagen.name)[0]}.jpg",
        "image/jpeg",
        output.getbuffer().nbytes,
        None
    )


# ============================================
# VISTAS DE PERFIL
# ============================================

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def obtener_perfil(request):
    """Obtiene el perfil del usuario autenticado con optimización SQL."""
    perfil = get_object_or_404(Perfil.objects.select_related("user"), user=request.user)
    serializer = PerfilSerializer(perfil, context={"request": request})
    return Response({"perfil": serializer.data})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def obtener_perfil_publico(request, user_id):
    """Obtiene perfil público de otro usuario."""
    perfil = get_object_or_404(Perfil.objects.select_related("user"), user_id=user_id)
    serializer = PerfilPublicoSerializer(perfil, context={"request": request})
    return Response({"perfil": serializer.data})


@api_view(["PUT", "PATCH"])
@permission_classes([IsAuthenticated])
@throttle_classes([PerfilThrottle])
def actualizar_perfil(request):
    """Actualiza perfil y datos del usuario (celular) atómicamente."""
    user = request.user
    perfil = get_object_or_404(Perfil.objects.select_related("user"), user=user)
    
    data = request.data.copy()
    nuevo_celular = data.pop("telefono", None)

    try:
        with transaction.atomic():
            # 1. Actualización de Celular (Modelo User)
            if nuevo_celular:
                nuevo_celular = str(nuevo_celular).strip()
                if re.match(r'^09\d{8}$', nuevo_celular):
                    nuevo_celular = '+593' + nuevo_celular[1:]
                try:
                    validar_celular(nuevo_celular)
                except DjangoValidationError as exc:
                    mensaje = exc.message if hasattr(exc, "message") and exc.message else None
                    if not mensaje and exc.messages:
                        mensaje = exc.messages[0]
                    raise DRFValidationError({"telefono": mensaje or "El celular tiene un formato inválido."})
                
                if User.objects.filter(celular=nuevo_celular).exclude(id=user.id).exists():
                    raise DRFValidationError({"telefono": "Este número ya está registrado."})
                
                user.celular = nuevo_celular
                user.save(update_fields=["celular"])

            # 2. Actualización de Perfil (Modelo Perfil)
            # Limpieza de campo foto si viene vacío
            if "foto_perfil" in data and data["foto_perfil"] in [None, "", "null"]:
                data["foto_perfil"] = None

            serializer = ActualizarPerfilSerializer(perfil, data=data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()

        # Respuesta exitosa
        perfil.refresh_from_db()
        return Response({
            "mensaje": "Perfil actualizado correctamente.",
            "perfil": PerfilSerializer(perfil, context={"request": request}).data
        })

    except DRFValidationError as e:
        return Response({"error": "Error de validación", "detalles": e.detail}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error(f"Error actualizando perfil {user.email}: {e}", exc_info=True)
        return Response({"error": "Error interno del servidor."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST", "DELETE"])
@permission_classes([IsAuthenticated])
@throttle_classes([UploadThrottle])
def subir_foto_perfil(request):
    """Gestiona la subida y eliminación de foto de perfil."""
    perfil = get_object_or_404(Perfil, user=request.user)

    try:
        if request.method == "POST":
            if "foto_perfil" not in request.FILES:
                return Response({"error": "No se proporcionó archivo 'foto_perfil'."}, status=status.HTTP_400_BAD_REQUEST)

            archivo = request.FILES["foto_perfil"]
            
            # Validación básica antes de procesar
            if archivo.size > 5 * 1024 * 1024:
                return Response({"error": "La imagen excede los 5MB."}, status=status.HTTP_400_BAD_REQUEST)

            # Procesamiento de imagen
            try:
                imagen_procesada = procesar_imagen_perfil(archivo)
            except Exception as e:
                logger.warning(f"Error procesando imagen para {request.user.email}: {e}")
                return Response({"error": "Archivo de imagen inválido o corrupto."}, status=status.HTTP_400_BAD_REQUEST)

            # Guardado
            perfil.foto_perfil = imagen_procesada
            perfil.save(update_fields=["foto_perfil", "actualizado_en"])
            
            logger.info(f"Foto de perfil actualizada: {request.user.email}")
            return Response({
                "mensaje": "Foto actualizada correctamente.",
                "perfil": PerfilSerializer(perfil, context={"request": request}).data
            })

        elif request.method == "DELETE":
            if perfil.foto_perfil:
                perfil.foto_perfil.delete(save=False)
                perfil.foto_perfil = None
                perfil.save(update_fields=["foto_perfil", "actualizado_en"])
            
            return Response({
                "mensaje": "Foto eliminada correctamente.",
                "perfil": PerfilSerializer(perfil, context={"request": request}).data
            })

    except Exception as e:
        logger.error(f"Error en foto perfil {request.user.email}: {e}", exc_info=True)
        return Response({"error": "Error procesando la solicitud."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def estadisticas_usuario(request):
    """Retorna estadísticas agregadas del usuario."""
    user = request.user
    perfil, _ = Perfil.objects.get_or_create(user=user)
    total_direcciones_count = DireccionFavorita.objects.filter(user=user, activa=True).count()
    total_metodos_pago_count = MetodoPago.objects.filter(user=user, activo=True).count()

    data = {
        "total_pedidos": perfil.total_pedidos,
        "pedidos_mes_actual": perfil.pedidos_mes_actual,
        "calificacion": perfil.calificacion,
        "total_resenas": perfil.total_resenas,
        "es_cliente_frecuente": perfil.es_cliente_frecuente,
        "puede_participar_rifa": perfil.puede_participar_rifa,
        "total_direcciones": total_direcciones_count, 
        "total_metodos_pago": total_metodos_pago_count,
    }
    
    serializer = EstadisticasUsuarioSerializer(data)
    return Response({"estadisticas": serializer.data})


# ============================================
# NOTIFICACIONES (FCM)
# ============================================

@api_view(["POST"])
@permission_classes([IsAuthenticated])
@throttle_classes([FCMThrottle])
def registrar_fcm_token(request):
    serializer = FCMTokenSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    perfil = get_object_or_404(Perfil, user=request.user)
    success = perfil.actualizar_fcm_token(serializer.validated_data["fcm_token"])

    if success:
        return Response({
            "mensaje": "Token registrado.",
            "configuracion": {
                "push_activo": perfil.notificaciones_pedido or perfil.notificaciones_promociones,
                "pedidos": perfil.notificaciones_pedido,
                "promociones": perfil.notificaciones_promociones
            }
        })
    return Response({"error": "No se pudo actualizar el token."}, status=status.HTTP_400_BAD_REQUEST)


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def eliminar_fcm_token(request):
    perfil = get_object_or_404(Perfil, user=request.user)
    perfil.eliminar_fcm_token()
    return Response({"mensaje": "Token eliminado (sesión cerrada para notificaciones)."})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def estado_notificaciones(request):
    perfil = get_object_or_404(Perfil, user=request.user)
    data = {
        "puede_recibir_notificaciones": perfil.puede_recibir_notificaciones,
        "notificaciones_pedido": perfil.notificaciones_pedido,
        "notificaciones_promociones": perfil.notificaciones_promociones,
        "token_actualizado": perfil.fcm_token_actualizado,
    }
    return Response(EstadoNotificacionesSerializer(data).data)


# ============================================
# DIRECCIONES FAVORITAS
# ============================================

@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def direcciones_favoritas(request):
    user = request.user

    if request.method == "GET":
        queryset = user.direcciones_favoritas.filter(activa=True).order_by(
            "-es_predeterminada", "-ultimo_uso", "-created_at"
        )
        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(queryset, request)
        
        if page is not None:
            serializer = DireccionFavoritaSerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)
        
        serializer = DireccionFavoritaSerializer(queryset, many=True)
        return Response({"direcciones": serializer.data, "total": queryset.count()})

    elif request.method == "POST":
        serializer = CrearDireccionSerializer(data=request.data, context={"request": request})
        try:
            serializer.is_valid(raise_exception=True)
            direccion = serializer.save()
            return Response({
                "mensaje": "Dirección creada.",
                "direccion": DireccionFavoritaSerializer(direccion).data
            }, status=status.HTTP_201_CREATED)
        except IntegrityError:
            return Response({"error": "Error de integridad. Verifique duplicados."}, status=status.HTTP_400_BAD_REQUEST)
        except DRFValidationError as e:
            return Response(e.detail, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def detalle_direccion(request, direccion_id):
    user = request.user
    direccion = get_object_or_404(DireccionFavorita, id=direccion_id, user=user, activa=True)

    if request.method == "GET":
        return Response(DireccionFavoritaSerializer(direccion).data)

    elif request.method in ["PUT", "PATCH"]:
        serializer = ActualizarDireccionSerializer(direccion, data=request.data, partial=True, context={"request": request})
        serializer.is_valid(raise_exception=True)
        
        with transaction.atomic():
            if request.data.get("es_predeterminada"):
                user.direcciones_favoritas.select_for_update().filter(activa=True).exclude(id=direccion_id).update(es_predeterminada=False)
            serializer.save()

        return Response({
            "mensaje": "Dirección actualizada.",
            "direccion": DireccionFavoritaSerializer(direccion).data
        })

    elif request.method == "DELETE":
        with transaction.atomic():
            direccion.activa = False
            direccion.es_predeterminada = False
            direccion.save(update_fields=["activa", "es_predeterminada"])
        return Response({"mensaje": "Dirección eliminada."})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def direccion_predeterminada(request):
    direccion = request.user.direcciones_favoritas.filter(es_predeterminada=True, activa=True).first()
    if not direccion:
        return Response({"mensaje": "Sin dirección predeterminada."}, status=status.HTTP_404_NOT_FOUND)
    return Response({"direccion": DireccionFavoritaSerializer(direccion).data})


# ============================================
# MÉTODOS DE PAGO
# ============================================

@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def metodos_pago(request):
    user = request.user

    if request.method == "GET":
        queryset = user.metodos_pago.filter(activo=True).order_by("-es_predeterminado", "-created_at")
        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(queryset, request)
        
        if page is not None:
            serializer = MetodoPagoSerializer(page, many=True, context={"request": request})
            return paginator.get_paginated_response(serializer.data)
            
        serializer = MetodoPagoSerializer(queryset, many=True, context={"request": request})
        return Response({"metodos_pago": serializer.data, "total": queryset.count()})

    elif request.method == "POST":
        serializer = CrearMetodoPagoSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        metodo = serializer.save()
        
        return Response({
            "mensaje": "Método de pago guardado.",
            "metodo_pago": MetodoPagoSerializer(metodo, context={"request": request}).data
        }, status=status.HTTP_201_CREATED)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def detalle_metodo_pago(request, metodo_id):
    metodo = get_object_or_404(MetodoPago, id=metodo_id, user=request.user, activo=True)

    if request.method == "GET":
        return Response(MetodoPagoSerializer(metodo, context={"request": request}).data)

    elif request.method in ["PUT", "PATCH"]:
        serializer = ActualizarMetodoPagoSerializer(metodo, data=request.data, partial=True, context={"request": request})
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            if request.data.get("es_predeterminado"):
                request.user.metodos_pago.select_for_update().filter(activo=True).exclude(id=metodo_id).update(es_predeterminado=False)
            serializer.save()

        return Response({
            "mensaje": "Método actualizado.",
            "metodo_pago": MetodoPagoSerializer(metodo, context={"request": request}).data
        })

    elif request.method == "DELETE":
        metodo.activo = False
        metodo.es_predeterminado = False
        metodo.save(update_fields=["activo", "es_predeterminado"])
        return Response({"mensaje": "Método eliminado."})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def metodo_pago_predeterminado(request):
    metodo = request.user.metodos_pago.filter(activo=True, es_predeterminado=True).first()
    if not metodo:
        metodo = request.user.metodos_pago.filter(activo=True).first()
        
    if not metodo:
        return Response({"mensaje": "No hay métodos de pago."}, status=status.HTTP_404_NOT_FOUND)
        
    return Response({"metodo_pago": MetodoPagoSerializer(metodo, context={"request": request}).data})


# ============================================
# UBICACIÓN (REST)
# ============================================

@api_view(["POST"])
@permission_classes([IsAuthenticated])
@throttle_classes([UbicacionThrottle])
def actualizar_ubicacion(request):
    serializer = ActualizarUbicacionSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    
    data = serializer.validated_data
    ubic, _ = UbicacionUsuario.objects.update_or_create(
        user=request.user,
        defaults={"latitud": data["latitud"], "longitud": data["longitud"]}
    )
    
    return Response({
        "mensaje": "Ubicación actualizada.",
        "ubicacion": UbicacionUsuarioSerializer(ubic).data
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def mi_ubicacion(request):
    ubic = UbicacionUsuario.objects.filter(user=request.user).first()
    if not ubic:
        return Response({"mensaje": "Sin ubicación."}, status=status.HTTP_404_NOT_FOUND)
    return Response(UbicacionUsuarioSerializer(ubic).data)


# ============================================
# SOLICITUDES DE ROL
# ============================================

@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def mis_solicitudes_cambio_rol(request):
    user = request.user

    if request.method == "GET":
        queryset = user.solicitudes_cambio_rol.all().order_by("-creado_en")
        paginator = StandardResultsSetPagination()
        page = paginator.paginate_queryset(queryset, request)

        stats = {
            "total": queryset.count(),
            "pendientes": queryset.filter(estado="PENDIENTE").count(),
            "aceptadas": queryset.filter(estado="ACEPTADA").count(),
            "rechazadas": queryset.filter(estado="RECHAZADA").count(),
        }

        if page is not None:
            response = paginator.get_paginated_response(SolicitudCambioRolListSerializer(page, many=True).data)
            response.data.update(stats)
            return response
            
        return Response({
            "solicitudes": SolicitudCambioRolListSerializer(queryset, many=True).data,
            **stats
        })

    elif request.method == "POST":
        rol_solicitado = request.data.get("rol_solicitado")
        
        if rol_solicitado == "PROVEEDOR":
            serializer_cls = CrearSolicitudProveedorSerializer
        elif rol_solicitado == "REPARTIDOR":
            serializer_cls = CrearSolicitudRepartidorSerializer
        else:
            return Response({"error": "Rol inválido o no especificado."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = serializer_cls(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        solicitud = serializer.save()

        logger.info(f"Solicitud rol creada: {user.email} -> {rol_solicitado}")
        return Response({
            "mensaje": "Solicitud creada.",
            "solicitud": SolicitudCambioRolDetalleSerializer(solicitud).data
        }, status=status.HTTP_201_CREATED)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def detalle_solicitud_cambio_rol(request, solicitud_id):
    solicitud = get_object_or_404(SolicitudCambioRol, id=solicitud_id, user=request.user)
    return Response(SolicitudCambioRolDetalleSerializer(solicitud).data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cambiar_rol_activo(request):
    """
    Cambia el rol activo del usuario.

    OPTIMIZADO:
    - Valida que el rol esté aprobado antes de cambiar
    - Previene activación de roles pendientes o rechazados
    - Devuelve tokens en formato compatible con Flutter (access/refresh directos)
    - Agrega cache control para invalidar caché del cliente
    """
    user = request.user
    nuevo_rol = request.data.get("nuevo_rol")

    if not nuevo_rol:
        return Response({"error": "Debe especificar el nuevo rol."}, status=400)

    rol_claim = nuevo_rol.upper()
    rol_model = rol_claim.lower()

    # 1. Validar si el usuario realmente tiene ese perfil ACTIVO y APROBADO
    tiene_permiso = False
    motivo_rechazo = ""

    if rol_claim in {"CLIENTE", "USUARIO"}:
        # Solo validamos que el Perfil existe y el usuario está activo
        tiene_permiso = hasattr(user, "perfil") and user.is_active
        motivo_rechazo = "No tienes un perfil de cliente activo"
    elif rol_claim == "PROVEEDOR":
        # Verificamos si existe la relación en la BD Y está activo
        if hasattr(user, 'proveedor') and user.proveedor.activo:
            # Verificar si está verificado (si aplica)
            if hasattr(user.proveedor, 'verificado'):
                if user.proveedor.verificado:
                    tiene_permiso = True
                    motivo_rechazo = ""
                else:
                    motivo_rechazo = "Tu perfil de proveedor aún no está verificado. Espera la aprobación del administrador."
            else:
                tiene_permiso = True
        else:
            # Verificar si hay solicitud pendiente
            solicitud = SolicitudCambioRol.objects.filter(
                user=user, rol_solicitado="PROVEEDOR"
            ).order_by("-creado_en").first()

            if solicitud:
                if solicitud.estado == "PENDIENTE":
                    motivo_rechazo = "Tu solicitud de proveedor está en revisión. Te notificaremos cuando sea aprobada."
                elif solicitud.estado == "RECHAZADO":
                    razon = solicitud.razon_rechazo or "Contacta con soporte para más información"
                    motivo_rechazo = f"Tu solicitud de proveedor fue rechazada: {razon}"
                else:
                    motivo_rechazo = "No tienes perfil de proveedor activo"
            else:
                motivo_rechazo = "No tienes perfil de proveedor. Solicita el rol desde la app."

    elif rol_claim == "REPARTIDOR":
        # Verificamos si existe la relación en la BD Y está activo
        if hasattr(user, 'repartidor') and user.repartidor.activo:
            tiene_permiso = True
        else:
            # Verificar solicitud
            solicitud = SolicitudCambioRol.objects.filter(
                user=user, rol_solicitado="REPARTIDOR"
            ).order_by("-creado_en").first()

            if solicitud:
                if solicitud.estado == "PENDIENTE":
                    motivo_rechazo = "Tu solicitud de repartidor está en revisión. Te notificaremos cuando sea aprobada."
                elif solicitud.estado == "RECHAZADO":
                    razon = solicitud.razon_rechazo or "Contacta con soporte para más información"
                    motivo_rechazo = f"Tu solicitud de repartidor fue rechazada: {razon}"
                else:
                    motivo_rechazo = "No tienes perfil de repartidor activo"
            else:
                motivo_rechazo = "No tienes perfil de repartidor. Solicita el rol desde la app."

    # Admin (Opcional)
    elif rol_claim == "ADMINISTRADOR" and user.is_staff:
        tiene_permiso = True

    if not tiene_permiso:
        return Response(
            {"error": motivo_rechazo or f"No tienes el perfil de {rol_claim} activo o verificado."},
            status=403
        )

    try:
        # 2. Asegurar que el rol esté en roles_aprobados
        if hasattr(user, "roles_aprobados"):
            roles = [r.lower() for r in (user.roles_aprobados or [])]
            if rol_model not in roles:
                roles.append(rol_model)
            user.roles_aprobados = roles

        # 3. Actualizar el tipo_usuario (campo real del modelo)
        user.tipo_usuario = rol_model

        # 4. Actualizar rol_activo (minúsculas para modelo)
        user.rol_activo = rol_model

        user.save(update_fields=['roles_aprobados', 'tipo_usuario', 'rol_activo', 'updated_at'])
        user.refresh_from_db(fields=['roles_aprobados', 'tipo_usuario', 'rol_activo'])

        # 5. Generar nuevos tokens
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(user)
        refresh['rol'] = rol_claim

        # 6. Preparar respuesta optimizada para Flutter
        response_data = {
            "mensaje": f"Rol cambiado a {rol_claim}",
            "rol_activo": rol_claim,
            # Tokens en formato directo (compatible con Flutter ApiClient.saveTokens)
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "rol": rol_claim
        }

        response = Response(response_data, status=200)

        # 7. Agregar headers de cache control
        response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response['Pragma'] = 'no-cache'
        response['Expires'] = '0'

        return response

    except Exception as e:
        logger.error(f"Error cambio rol: {e}", exc_info=True)
        return Response({"error": "Error interno al cambiar de rol."}, status=500)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def mis_roles(request):
    """
    Devuelve los roles que tiene el usuario basados en sus perfiles activos
    y el estado de sus solicitudes.

    OPTIMIZADO:
    - Incluye estados detallados (ACEPTADO, PENDIENTE, RECHAZADO)
    - Incluye razón de rechazo cuando aplica
    - Agrega cache-control para sincronización
    - Compatible con RoleManager de Flutter
    """
    user = request.user
    user.refresh_from_db(fields=['roles_aprobados', 'rol_activo', 'tipo_usuario'])
    roles_data = []

    # 1. ROL CLIENTE (Siempre activo por defecto)
    roles_data.append({
        "nombre": "CLIENTE",
        "estado": "ACEPTADO",
        "activo": True,
        "razon_rechazo": None
    })

    # 2. ROL PROVEEDOR (Verificar perfil real)
    if hasattr(user, 'proveedor') and user.proveedor.activo:
        # Verificar si está verificado
        if hasattr(user.proveedor, 'verificado'):
            if user.proveedor.verificado:
                roles_data.append({
                    "nombre": "PROVEEDOR",
                    "estado": "ACEPTADO",
                    "activo": True,
                    "razon_rechazo": None
                })
            else:
                roles_data.append({
                    "nombre": "PROVEEDOR",
                    "estado": "PENDIENTE",
                    "activo": False,
                    "razon_rechazo": "Perfil en proceso de verificación"
                })
        else:
            roles_data.append({
                "nombre": "PROVEEDOR",
                "estado": "ACEPTADO",
                "activo": True,
                "razon_rechazo": None
            })
    else:
        # Si no tiene perfil, buscar si tiene solicitud pendiente/rechazada
        solicitud = SolicitudCambioRol.objects.filter(
            user=user, rol_solicitado="PROVEEDOR"
        ).order_by("-creado_en").first()

        if solicitud:
            roles_data.append({
                "nombre": "PROVEEDOR",
                "estado": solicitud.estado,
                "activo": False,
                "razon_rechazo": solicitud.razon_rechazo if solicitud.estado == "RECHAZADO" else None
            })

    # 3. ROL REPARTIDOR (Verificar perfil real)
    if hasattr(user, 'repartidor') and user.repartidor.activo:
        roles_data.append({
            "nombre": "REPARTIDOR",
            "estado": "ACEPTADO",
            "activo": True,
            "razon_rechazo": None
        })
    else:
        # Buscar solicitud
        solicitud = SolicitudCambioRol.objects.filter(
            user=user, rol_solicitado="REPARTIDOR"
        ).order_by("-creado_en").first()

        if solicitud:
            roles_data.append({
                "nombre": "REPARTIDOR",
                "estado": solicitud.estado,
                "activo": False,
                "razon_rechazo": solicitud.razon_rechazo if solicitud.estado == "RECHAZADO" else None
            })

    # Determinar rol activo
    rol_token = None
    try:
        token_obj = getattr(request, "auth", None)
        if isinstance(token_obj, dict):
            rol_token = token_obj.get("rol")
        elif hasattr(token_obj, "get"):
            rol_token = token_obj.get("rol", None)
    except Exception:
        rol_token = None

    rol_activo_db = (
        getattr(user, "rol_activo", None)
        or getattr(user, "tipo_usuario", None)
        or getattr(user, "rol", "cliente")
    )

    rol_activo = rol_token or rol_activo_db or "cliente"
    rol_activo = rol_activo.upper() if isinstance(rol_activo, str) else "CLIENTE"

    response_data = {
        "roles": roles_data,
        "rol_activo": rol_activo,
        "roles_disponibles": [
            r["nombre"] for r in roles_data if r.get("estado") == "ACEPTADO"
        ]
    }

    response = Response(response_data, status=status.HTTP_200_OK)

    # Agregar cache control - permitir caché por 5 minutos
    response['Cache-Control'] = 'private, max-age=300'  # 5 minutos
    response['Vary'] = 'Authorization'  # Varía según usuario

    return response


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def verificar_roles_usuario(request):
    """
    Endpoint para verificar roles del usuario.
    CORREGIDO: Usa getattr para campos que pueden no existir.
    """
    user = request.user
    
    # Verificación optimizada (fail-safe)
    es_proveedor = False
    es_repartidor = False
    es_verificado = False
    
    try:
        from proveedores.models import Proveedor
        from repartidores.models import Repartidor
        es_proveedor = Proveedor.objects.filter(user=user, activo=True, verificado=True).exists()
        es_repartidor = Repartidor.objects.filter(user=user, activo=True, verificado=True).exists()
    except ImportError:
        pass  # Modelos no disponibles en este contexto

    # CORRECCIÓN CRÍTICA: Usar getattr para 'verificado' ya que puede no existir en User
    es_verificado = getattr(user, 'verificado', True)  # Default True si no existe
    cuenta_desactivada = getattr(user, 'cuenta_desactivada', False)
    
    puede_solicitar = es_verificado and user.is_active and not cuenta_desactivada

    return Response({
        "usuario_id": user.id,
        "email": user.email,
        "rol_principal": getattr(user, 'rol', 'CLIENTE'),
        "rol_activo": getattr(user, "rol_activo", getattr(user, 'rol', 'cliente')),
        "es_proveedor": es_proveedor,
        "es_repartidor": es_repartidor,
        "es_verificado": es_verificado,
        "roles_disponibles": user.obtener_todos_los_roles() if hasattr(user, 'obtener_todos_los_roles') else ['CLIENTE'],
        "puede_solicitar": puede_solicitar,
        "tiene_perfil_completo": bool(getattr(user, 'celular', None) and user.email),
    })
