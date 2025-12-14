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

from authentication.models import User
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
                if not re.match(r"^09\d{8}$", nuevo_celular):
                    raise DRFValidationError({"telefono": "El celular debe comenzar con 09 y tener 10 dígitos."})
                
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
    user = request.user
    nuevo_rol = request.data.get("nuevo_rol")

    if not nuevo_rol:
        return Response({"error": "Debe especificar el nuevo rol."}, status=400)

    nuevo_rol = nuevo_rol.upper()
    
    # 1. Validar si el usuario realmente tiene ese perfil
    tiene_permiso = False
    
    if nuevo_rol == "CLIENTE":
        tiene_permiso = True
    elif nuevo_rol == "PROVEEDOR":
        # Verificamos si existe la relación en la BD
        if hasattr(user, 'proveedor') and user.proveedor.activo:
            tiene_permiso = True
    elif nuevo_rol == "REPARTIDOR":
        # Verificamos si existe la relación en la BD
        if hasattr(user, 'repartidor') and user.repartidor.activo:
            tiene_permiso = True
            
    # Admin (Opcional)
    elif nuevo_rol == "ADMINISTRADOR" and user.is_staff:
        tiene_permiso = True

    if not tiene_permiso:
        return Response(
            {"error": f"No tienes el perfil de {nuevo_rol} activo o verificado."}, 
            status=403
        )

    try:
        # 2. Actualizar el campo rol en User (si existe)
        if hasattr(user, 'rol'):
            user.rol = nuevo_rol
            user.save(update_fields=['rol'])
        
        # 3. Actualizar rol_activo si existe
        if hasattr(user, 'rol_activo'):
            user.rol_activo = nuevo_rol.lower()
            user.save(update_fields=['rol_activo'])
        
        # 4. Generar nuevos tokens
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(user)
        refresh['rol'] = nuevo_rol
        
        return Response({
            "mensaje": f"Rol cambiado a {nuevo_rol}",
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "rol": nuevo_rol
            }
        }, status=200)

    except Exception as e:
        logger.error(f"Error cambio rol: {e}")
        return Response({"error": "Error interno."}, status=500)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def mis_roles(request):
    """
    Devuelve los roles que tiene el usuario basados en sus perfiles activos
    y el estado de sus solicitudes.
    """
    user = request.user
    roles_data = []

    # 1. ROL CLIENTE (Siempre activo por defecto)
    roles_data.append({
        "nombre": "CLIENTE",
        "estado": "ACEPTADO",
        "activo": True
    })

    # 2. ROL PROVEEDOR (Verificar perfil real)
    if hasattr(user, 'proveedor') and user.proveedor.activo:
        roles_data.append({
            "nombre": "PROVEEDOR",
            "estado": "ACEPTADO", 
            "activo": True
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
                "activo": False
            })

    # 3. ROL REPARTIDOR (Verificar perfil real)
    if hasattr(user, 'repartidor') and user.repartidor.activo:
        roles_data.append({
            "nombre": "REPARTIDOR",
            "estado": "ACEPTADO",
            "activo": True
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
                "activo": False
            })

    return Response({"roles": roles_data}, status=status.HTTP_200_OK)


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
