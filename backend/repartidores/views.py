# -*- coding: utf-8 -*-
# repartidores/views.py

from django.db import transaction
from django.shortcuts import get_object_or_404
from django.apps import apps
from django.core.exceptions import ValidationError
from django.db.models import Count, Avg, Q
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.throttling import UserRateThrottle
from decimal import Decimal
from math import radians, cos, sin, sqrt, atan2
import logging
from pagos.models import Pago

from utils.throttles import (
    PerfilThrottle,
    EstadoThrottle,
    UbicacionThrottle,
    VehiculoThrottle,
    CalificacionThrottle,
)
from .models import (
    Repartidor,
    RepartidorVehiculo,
    HistorialUbicacion,
    RepartidorEstadoLog,
    CalificacionRepartidor,
    CalificacionCliente,
)
from .serializers import (
    RepartidorPerfilSerializer,
    RepartidorUpdateSerializer,
    RepartidorEstadoSerializer,
    RepartidorUbicacionSerializer,
    RepartidorPublicoSerializer,
    RepartidorVehiculoSerializer,
    HistorialUbicacionSerializer,
    RepartidorEstadoLogSerializer,
    CalificacionRepartidorSerializer,
    CalificacionClienteCreateSerializer,
    RepartidorEditarPerfilSerializer,
    RepartidorEditarContactoSerializer,
    RepartidorPerfilCompletoSerializer,
)
from .permissions import IsRepartidor

logger = logging.getLogger("repartidores")

# ==========================================================
# PAGINACIÓN
# ==========================================================
class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


# ==========================================================
# HELPERS
# ==========================================================

def construir_url_media_view(file_field, request):
    """
    Construye URL completa para archivos media desde vistas.
    """
    if not file_field:
        return None
    
    try:
        return request.build_absolute_uri(file_field.url)
    except Exception as e:
        logger.error(f"Error construyendo URL: {e}")
        return None


def construir_perfil_response(repartidor, request):
    """
    HELPER: Construye respuesta de perfil con URLs completas.
    """
    return {
        'id': repartidor.id,
        'nombre_completo': repartidor.user.get_full_name(),
        'email': repartidor.user.email,
        'foto_perfil': construir_url_media_view(repartidor.foto_perfil, request),
        'cedula': repartidor.cedula,
        'telefono': repartidor.telefono,
        'vehiculo': repartidor.vehiculo,
        'estado': repartidor.estado,
        'verificado': repartidor.verificado,
        'activo': repartidor.activo,
        'calificacion_promedio': float(repartidor.calificacion_promedio),
        'entregas_completadas': repartidor.entregas_completadas,
    }


def construir_vehiculo_response(vehiculo, request):
    """
    HELPER: Construye respuesta de vehículo con URLs completas.
    """
    return {
        'id': vehiculo.id,
        'tipo': vehiculo.tipo,
        'tipo_display': vehiculo.get_tipo_display(),
        'placa': vehiculo.placa,
        'licencia_foto': construir_url_media_view(vehiculo.licencia_foto, request),
        'activo': vehiculo.activo,
    }


# ==========================================================
# NOTA: La función mi_repartidor está definida más abajo (línea ~1476)
# para evitar duplicación de código
# ==========================================================


# ==========================================================
# PERFIL DEL REPARTIDOR
# ==========================================================

@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([PerfilThrottle])
def obtener_mi_perfil(request):
    """
    Devuelve el perfil completo del repartidor autenticado.
    Con URLs completas de imágenes.
    """
    try:
        repartidor = request.user.repartidor
        serializer = RepartidorPerfilSerializer(repartidor, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
    except (AttributeError, Exception) as e:
        # Capturamos Exception genérica por si es RelatedObjectDoesNotExist que no hereda de AttributeError en todas las versiones
        logger.warning(f"Usuario {request.user.email} no tiene perfil de repartidor (Error: {e}). Restableciendo a Cliente.")
        
        # Auto-corregir
        request.user.rol_activo = 'cliente'
        request.user.save(update_fields=['rol_activo'])

        return Response(
            {"error": "No tienes perfil de repartidor asociado. Rol restablecido a Cliente.", "action": "ROLE_RESET"},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(["PATCH"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([PerfilThrottle])
def actualizar_mi_perfil(request):
    """
    Permite actualizar teléfono, foto de perfil y datos del repartidor.
    Soporta multipart/form-data para subir archivos.
    """
    try:
        repartidor = request.user.repartidor

        # Manejar eliminación de foto
        eliminar_foto = request.data.get('eliminar_foto_perfil', 'false')
        if eliminar_foto in ['true', True, '1', 1]:
            if repartidor.foto_perfil:
                try:
                    repartidor.foto_perfil.delete(save=False)
                except Exception as e:
                    logger.warning(f"Error eliminando archivo de foto: {e}")
                
                repartidor.foto_perfil = None
                repartidor.save()
                
                logger.info(f"Foto eliminada: {repartidor.user.email}")
                
                return Response({
                    "mensaje": "Foto de perfil eliminada correctamente",
                    "perfil": construir_perfil_response(repartidor, request)
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    "mensaje": "No hay foto de perfil para eliminar",
                    "perfil": construir_perfil_response(repartidor, request)
                }, status=status.HTTP_200_OK)

        # Manejar foto de perfil (archivo)
        foto_perfil = request.FILES.get('foto_perfil')
        if foto_perfil:
            if foto_perfil.size > 5 * 1024 * 1024:
                return Response({
                    'error': 'La imagen no puede superar 5MB'
                }, status=status.HTTP_400_BAD_REQUEST)

            valid_extensions = ['jpg', 'jpeg', 'png', 'webp']
            ext = foto_perfil.name.split('.')[-1].lower()
            if ext not in valid_extensions:
                return Response({
                    'error': f'Formato no válido. Usa: {", ".join(valid_extensions)}'
                }, status=status.HTTP_400_BAD_REQUEST)

            repartidor.foto_perfil = foto_perfil

        # Actualizar teléfono si viene
        telefono = request.data.get('telefono')
        if telefono:
            import re
            if not re.match(r'^\+?[0-9]{7,15}$', telefono):
                return Response({
                    'error': 'Número de teléfono inválido. Formato: +593987654321 o 0987654321'
                }, status=status.HTTP_400_BAD_REQUEST)

            repartidor.telefono = telefono

        repartidor.save()

        logger.info(f"Perfil actualizado: {repartidor.user.email}")

        return Response({
            "mensaje": "Perfil actualizado correctamente",
            "perfil": construir_perfil_response(repartidor, request)
        }, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except ValidationError as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(f"Error al actualizar perfil: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al actualizar perfil."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["PATCH"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([VehiculoThrottle])
def actualizar_datos_vehiculo(request):
    """
    Permite actualizar tipo, placa y subir foto de licencia del vehículo activo.
    """
    try:
        repartidor = request.user.repartidor

        vehiculo_activo = repartidor.vehiculos.filter(activo=True).first()

        if not vehiculo_activo:
            return Response({
                'error': 'No tienes un vehículo activo registrado'
            }, status=status.HTTP_404_NOT_FOUND)

        tipo_vehiculo = request.data.get('tipo')
        if tipo_vehiculo:
            from repartidores.models import TipoVehiculo
            if tipo_vehiculo not in dict(TipoVehiculo.choices):
                return Response({
                    'error': f'Tipo de vehículo inválido. Opciones: {", ".join(dict(TipoVehiculo.choices).keys())}'
                }, status=status.HTTP_400_BAD_REQUEST)

            vehiculo_activo.tipo = tipo_vehiculo

        placa = request.data.get('placa')
        if placa:
            vehiculo_activo.placa = placa.strip().upper()

        licencia_foto = request.FILES.get('licencia_foto')
        if licencia_foto:
            if licencia_foto.size > 5 * 1024 * 1024:
                return Response({
                    'error': 'La imagen no puede superar 5MB'
                }, status=status.HTTP_400_BAD_REQUEST)

            valid_extensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf']
            ext = licencia_foto.name.split('.')[-1].lower()
            if ext not in valid_extensions:
                return Response({
                    'error': f'Formato no válido. Usa: {", ".join(valid_extensions)}'
                }, status=status.HTTP_400_BAD_REQUEST)

            vehiculo_activo.licencia_foto = licencia_foto

        vehiculo_activo.save()

        logger.info(f"Vehículo actualizado: {vehiculo_activo.tipo} para {repartidor.user.email}")

        return Response({
            "mensaje": "Datos del vehículo actualizados correctamente",
            "vehiculo": construir_vehiculo_response(vehiculo_activo, request)
        }, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al actualizar vehículo: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al actualizar vehículo."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([PerfilThrottle])
def obtener_estadisticas(request):
    """
    Devuelve estadísticas detalladas del repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor

        calificaciones_stats = repartidor.calificaciones.aggregate(
            total=Count('id'),
            promedio=Avg('puntuacion'),
            cinco_estrellas=Count('id', filter=Q(puntuacion=5)),
            cuatro_estrellas=Count('id', filter=Q(puntuacion=4)),
            tres_estrellas=Count('id', filter=Q(puntuacion=3)),
            dos_estrellas=Count('id', filter=Q(puntuacion=2)),
            una_estrella=Count('id', filter=Q(puntuacion=1)),
        )

        total_calificaciones = calificaciones_stats['total'] or 0
        entregas = repartidor.entregas_completadas

        estadisticas = {
            "entregas_completadas": entregas,
            "calificacion_promedio": float(repartidor.calificacion_promedio),
            "total_calificaciones": total_calificaciones,
            "desglose_calificaciones": {
                "5_estrellas": calificaciones_stats['cinco_estrellas'] or 0,
                "4_estrellas": calificaciones_stats['cuatro_estrellas'] or 0,
                "3_estrellas": calificaciones_stats['tres_estrellas'] or 0,
                "2_estrellas": calificaciones_stats['dos_estrellas'] or 0,
                "1_estrella": calificaciones_stats['una_estrella'] or 0,
            },
            "porcentaje_5_estrellas": round(
                (calificaciones_stats['cinco_estrellas'] or 0) / total_calificaciones * 100, 2
            ) if total_calificaciones > 0 else 0,
            "estado_actual": repartidor.estado,
            "verificado": repartidor.verificado,
            "activo": repartidor.activo,
        }

        logger.info(f"Estadísticas consultadas: {repartidor.user.email}")

        return Response(estadisticas, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al obtener estadísticas: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener estadísticas."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# CAMBIO DE ESTADO
# ==========================================================
@api_view(["PATCH"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([EstadoThrottle])
def cambiar_estado(request):
    """
    Cambia el estado del repartidor (disponible / ocupado / fuera_servicio).
    """
    try:
        repartidor = request.user.repartidor
        serializer = RepartidorEstadoSerializer(
            data=request.data,
            context={"repartidor": repartidor}
        )

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        nuevo_estado = serializer.validated_data["estado"]
        anterior = repartidor.estado

        with transaction.atomic():
            if nuevo_estado == "disponible":
                repartidor.marcar_disponible()
            elif nuevo_estado == "ocupado":
                repartidor.marcar_ocupado()
            else:
                repartidor.marcar_fuera_servicio()

        logger.info(f"Estado cambiado: {anterior} → {nuevo_estado} ({repartidor.user.email})")

        return Response({
            "mensaje": "Estado actualizado correctamente",
            "estado_anterior": anterior,
            "estado_nuevo": repartidor.estado
        }, status=status.HTTP_200_OK)

    except ValidationError as e:
        logger.warning(f"Validación fallida al cambiar estado: {e}")
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    except ValueError as e:
        logger.warning(f"Valor inválido al cambiar estado: {e}")
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al cambiar estado: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al actualizar estado."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([EstadoThrottle])
def historial_estados(request):
    """
    Devuelve el historial de cambios de estado del repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor

        logs = RepartidorEstadoLog.objects.filter(
            repartidor=repartidor
        ).order_by('-timestamp')

        paginator = StandardResultsSetPagination()
        paginated_logs = paginator.paginate_queryset(logs, request)

        serializer = RepartidorEstadoLogSerializer(paginated_logs, many=True)

        return paginator.get_paginated_response(serializer.data)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al obtener historial de estados: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener historial."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# ACTUALIZAR UBICACIÓN EN TIEMPO REAL
# ==========================================================
@api_view(["PATCH"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([UbicacionThrottle])
def actualizar_ubicacion(request):
    """
    Actualiza la ubicación (latitud, longitud) del repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor
        serializer = RepartidorUbicacionSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        lat = serializer.validated_data["latitud"]
        lon = serializer.validated_data["longitud"]

        with transaction.atomic():
            actualizado = repartidor.actualizar_ubicacion(
                lat, lon, save_historial=True
            )

        logger.debug(f"Ubicación actualizada: {repartidor.user.email} → ({lat}, {lon})")

        return Response({
            "mensaje": "Ubicación actualizada correctamente" if actualizado else "Ubicación sin cambios",
            "actualizada": actualizado,
            "latitud": lat,
            "longitud": lon,
            "timestamp": repartidor.ultima_localizacion
        }, status=status.HTTP_200_OK)

    except ValidationError as e:
        logger.warning(f"Validación fallida al actualizar ubicación: {e}")
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al actualizar ubicación: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al actualizar ubicación."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([UbicacionThrottle])
def historial_ubicaciones(request):
    """
    Devuelve el historial de ubicaciones del repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor

        ubicaciones = HistorialUbicacion.objects.filter(
            repartidor=repartidor
        ).order_by('-timestamp')

        fecha_inicio = request.query_params.get('fecha_inicio')
        fecha_fin = request.query_params.get('fecha_fin')

        if fecha_inicio:
            ubicaciones = ubicaciones.filter(timestamp__gte=fecha_inicio)

        if fecha_fin:
            ubicaciones = ubicaciones.filter(timestamp__lte=fecha_fin)

        paginator = StandardResultsSetPagination()
        paginated_ubicaciones = paginator.paginate_queryset(ubicaciones, request)

        serializer = HistorialUbicacionSerializer(paginated_ubicaciones, many=True)

        return paginator.get_paginated_response(serializer.data)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al obtener historial de ubicaciones: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener historial."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
def historial_entregas(request):
    """
    Devuelve el historial de entregas completadas del repartidor autenticado.
    Incluye información detallada de cada entrega: fecha, comprobante, comisión, etc.
    """
    try:
        # Verificar que el usuario tenga perfil de repartidor
        if not hasattr(request.user, 'repartidor'):
            return Response(
                {"error": "No tienes perfil de repartidor asociado."},
                status=status.HTTP_403_FORBIDDEN
            )

        repartidor = request.user.repartidor
        Pedido = apps.get_model('pedidos', 'Pedido')

        # Obtener pedidos entregados por este repartidor
        entregas = Pedido.objects.filter(
            repartidor=repartidor,
            estado='entregado'
        ).select_related(
            'cliente__user',
            'proveedor__user',
            'pago'
        ).order_by('-fecha_entregado')

        # Filtros opcionales
        fecha_inicio = request.query_params.get('fecha_inicio')
        fecha_fin = request.query_params.get('fecha_fin')

        if fecha_inicio:
            entregas = entregas.filter(fecha_entregado__gte=fecha_inicio)

        if fecha_fin:
            entregas = entregas.filter(fecha_entregado__lte=fecha_fin)

        # Paginación
        paginator = StandardResultsSetPagination()
        paginated_entregas = paginator.paginate_queryset(entregas, request)

        # Serializar datos
        entregas_data = []
        for pedido in paginated_entregas:
            # Obtener nombre del cliente de forma segura
            cliente_nombre = 'N/A'
            if pedido.cliente and pedido.cliente.user:
                nombre_completo = pedido.cliente.user.get_full_name()
                if nombre_completo and nombre_completo.strip():
                    cliente_nombre = nombre_completo
                elif pedido.cliente.user.username:
                    cliente_nombre = pedido.cliente.user.username

            # Obtener teléfono del cliente de forma segura
            cliente_telefono = None
            if pedido.cliente and pedido.cliente.user:
                # El teléfono puede estar en User o en otro modelo
                cliente_telefono = getattr(pedido.cliente.user, 'telefono', None) or getattr(pedido.cliente.user, 'phone', None)

            comprobante = pedido.imagen_evidencia
            if not comprobante:
                comprobante = getattr(getattr(pedido, 'pago', None), 'transferencia_comprobante', None)

            entrega_data = {
                'id': pedido.id,
                'tipo': pedido.tipo,
                'numero_pedido': pedido.numero_pedido,
                'fecha_entregado': pedido.fecha_entregado.isoformat() if pedido.fecha_entregado else None,
                'monto_total': float(pedido.total) if pedido.total else 0.0,
                'metodo_pago': pedido.metodo_pago or 'efectivo',
                'comision_repartidor': float(pedido.comision_repartidor) if pedido.comision_repartidor else 0.0,
                'cliente_nombre': cliente_nombre,
                'cliente_telefono': cliente_telefono,
                'cliente_direccion': pedido.direccion_entrega or 'Dirección no disponible',
                'proveedor_nombre': pedido.proveedor.nombre if pedido.proveedor else 'N/A',
                'tiene_comprobante': bool(comprobante),
                'url_comprobante': request.build_absolute_uri(comprobante.url) if comprobante else None,
            }
            entregas_data.append(entrega_data)

        # Estadísticas adicionales (del queryset completo, no paginado)
        total_entregas = entregas.count()
        total_comisiones = sum(float(p.comision_repartidor) for p in entregas if p.comision_repartidor)

        # Construir respuesta paginada manualmente
        response_data = paginator.get_paginated_response(entregas_data)

        # Agregar estadísticas a la respuesta
        response_data.data['total_entregas'] = total_entregas
        response_data.data['total_comisiones'] = total_comisiones

        return response_data

    except AttributeError as e:
        logger.error(f"AttributeError en historial_entregas: {e}", exc_info=True)
        return Response(
            {"error": "No tienes perfil de repartidor asociado.", "detalle": str(e)},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al obtener historial de entregas: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener historial de entregas.", "detalle": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# VEHÍCULOS
# ==========================================================
@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([VehiculoThrottle])
def listar_vehiculos(request):
    """
    Lista todos los vehículos del repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor
        vehiculos = repartidor.vehiculos.all().order_by('-activo', '-creado_en')

        serializer = RepartidorVehiculoSerializer(vehiculos, many=True)

        return Response({
            "total": vehiculos.count(),
            "vehiculos": serializer.data
        }, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al listar vehículos: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al listar vehículos."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([VehiculoThrottle])
def crear_vehiculo(request):
    """
    Crea un nuevo vehículo para el repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor
        serializer = RepartidorVehiculoSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            vehiculo = serializer.save(repartidor=repartidor)

        logger.info(f"Vehículo creado: {vehiculo.tipo} para {repartidor.user.email}")

        return Response({
            "mensaje": "Vehículo creado correctamente",
            "vehiculo": RepartidorVehiculoSerializer(vehiculo).data
        }, status=status.HTTP_201_CREATED)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al crear vehículo: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al crear vehículo."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([VehiculoThrottle])
def detalle_vehiculo(request, vehiculo_id):
    """
    Obtiene, actualiza o elimina un vehículo específico.
    """
    try:
        repartidor = request.user.repartidor
        vehiculo = get_object_or_404(
            RepartidorVehiculo,
            id=vehiculo_id,
            repartidor=repartidor
        )

        if request.method == "GET":
            serializer = RepartidorVehiculoSerializer(vehiculo)
            return Response(serializer.data, status=status.HTTP_200_OK)

        elif request.method == "PATCH":
            serializer = RepartidorVehiculoSerializer(
                vehiculo,
                data=request.data,
                partial=True
            )

            if not serializer.is_valid():
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

            serializer.save()
            logger.info(f"Vehículo actualizado: {vehiculo.id}")

            return Response({
                "mensaje": "Vehículo actualizado correctamente",
                "vehiculo": serializer.data
            }, status=status.HTTP_200_OK)

        elif request.method == "DELETE":
            if vehiculo.activo and repartidor.vehiculos.filter(activo=True).count() == 1:
                return Response(
                    {"error": "No puedes eliminar tu único vehículo activo."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            vehiculo.delete()
            logger.info(f"Vehículo eliminado: {vehiculo_id}")

            return Response(
                {"mensaje": "Vehículo eliminado correctamente"},
                status=status.HTTP_204_NO_CONTENT
            )

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error en detalle_vehiculo: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al procesar solicitud."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["PATCH"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([VehiculoThrottle])
def activar_vehiculo(request, vehiculo_id):
    """
    Activa un vehículo específico y desactiva los demás automáticamente.
    """
    try:
        repartidor = request.user.repartidor
        vehiculo = get_object_or_404(
            RepartidorVehiculo,
            id=vehiculo_id,
            repartidor=repartidor
        )

        with transaction.atomic():
            RepartidorVehiculo.objects.filter(
                repartidor=repartidor
            ).exclude(id=vehiculo_id).update(activo=False)

            vehiculo.activo = True
            vehiculo.save()

        logger.info(f"Vehículo activado: {vehiculo.tipo} ({vehiculo_id})")

        return Response({
            "mensaje": "Vehículo activado correctamente",
            "vehiculo": RepartidorVehiculoSerializer(vehiculo).data
        }, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al activar vehículo: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al activar vehículo."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# CALIFICACIONES
# ==========================================================
@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([CalificacionThrottle])
def listar_mis_calificaciones(request):
    """
    Lista todas las calificaciones recibidas por el repartidor autenticado.
    """
    try:
        repartidor = request.user.repartidor

        calificaciones = CalificacionRepartidor.objects.filter(
            repartidor=repartidor
        ).select_related('cliente').order_by('-creado_en')

        puntuacion = request.query_params.get('puntuacion')
        if puntuacion:
            calificaciones = calificaciones.filter(puntuacion=puntuacion)

        paginator = StandardResultsSetPagination()
        paginated_calificaciones = paginator.paginate_queryset(calificaciones, request)

        serializer = CalificacionRepartidorSerializer(paginated_calificaciones, many=True)

        return paginator.get_paginated_response(serializer.data)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al listar calificaciones: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al listar calificaciones."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRepartidor])
@throttle_classes([CalificacionThrottle])
def calificar_cliente(request, pedido_id):
    """
    Permite al repartidor calificar a un cliente después de completar un pedido.
    """
    try:
        repartidor = request.user.repartidor

        Pedido = apps.get_model('pedidos', 'Pedido')

        pedido = get_object_or_404(
            Pedido.objects.select_related('cliente', 'repartidor'),
            pk=pedido_id,
            repartidor=repartidor
        )

        if CalificacionCliente.objects.filter(
            cliente=pedido.cliente,
            repartidor=repartidor,
            pedido_id=pedido_id
        ).exists():
            return Response(
                {"error": "Ya has calificado a este cliente por este pedido."},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = CalificacionClienteCreateSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            calificacion = serializer.save(
                cliente=pedido.cliente,
                repartidor=repartidor,
                pedido_id=str(pedido_id)
            )

        logger.info(
            f"Repartidor {repartidor.id} calificó cliente "
            f"{pedido.cliente.id if pedido.cliente else 'N/A'} "
            f"con {calificacion.puntuacion} estrellas (pedido {pedido_id})"
        )

        return Response({
            "mensaje": "Calificación enviada correctamente",
            "calificacion": {
                "puntuacion": float(calificacion.puntuacion),
                "comentario": calificacion.comentario,
                "pedido_id": calificacion.pedido_id,
            }
        }, status=status.HTTP_201_CREATED)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except ValidationError as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    except LookupError:
        logger.error("Modelo 'Pedido' no encontrado en la app 'pedidos'")
        return Response(
            {"error": "Configuración del sistema incorrecta."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logger.error(f"Error al calificar cliente: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al enviar calificación."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# PERFIL PÚBLICO
# ==========================================================
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def perfil_repartidor_por_pedido(request, pedido_id):
    """
    Devuelve el perfil público del repartidor asignado a un pedido.
    """
    try:
        Pedido = apps.get_model('pedidos', 'Pedido')

        pedido = get_object_or_404(
            Pedido.objects.select_related("repartidor__user", "cliente"),
            pk=pedido_id
        )

        if pedido.cliente != request.user:
            logger.warning(
                f"Acceso no autorizado: usuario {request.user.email} "
                f"intentó acceder al pedido {pedido_id} del cliente {pedido.cliente.email}"
            )
            return Response(
                {"error": "No tienes autorización para ver este pedido."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not pedido.repartidor:
            return Response(
                {"mensaje": "Este pedido aún no tiene repartidor asignado."},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = RepartidorPublicoSerializer(pedido.repartidor)

        return Response({
            "pedido_id": pedido.id,
            "repartidor": serializer.data
        }, status=status.HTTP_200_OK)

    except LookupError:
        logger.error("Modelo 'Pedido' no encontrado en la app 'pedidos'")
        return Response(
            {"error": "Configuración del sistema incorrecta."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logger.error(f"Error al obtener perfil público de repartidor: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener información del repartidor."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def info_repartidor_publico(request, repartidor_id):
    """
    Devuelve información pública básica de un repartidor por su ID.
    """
    try:
        repartidor = get_object_or_404(
            Repartidor.objects.select_related('user').prefetch_related('vehiculos'),
            pk=repartidor_id,
            activo=True,
            verificado=True
        )

        serializer = RepartidorPublicoSerializer(repartidor)

        return Response(serializer.data, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error al obtener info pública de repartidor: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener información del repartidor."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# ENDPOINTS PARA MAPA DE PEDIDOS DISPONIBLES
# ==========================================================

def calcular_distancia_haversine(lat1, lon1, lat2, lon2):
    """
    Calcula la distancia en kilómetros entre dos puntos usando Haversine.
    """
    if not all([lat1, lon1, lat2, lon2]):
        return None

    try:
        R = 6371.0
        lat1, lon1, lat2, lon2 = map(float, [lat1, lon1, lat2, lon2])

        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)

        a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return round(R * c, 2)
    except (ValueError, TypeError):
        return None


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
def obtener_pedidos_disponibles_mapa(request):
    """
    Devuelve pedidos disponibles cercanos al repartidor con sus ubicaciones.
    """
    try:
        logger.info(f"[DEBUG] Usuario autenticado: {request.user.email} (ID: {request.user.id})")
        logger.info(f"[DEBUG] hasattr repartidor: {hasattr(request.user, 'repartidor')}")

        repartidor = request.user.repartidor
        logger.info(f"[DEBUG] Repartidor obtenido: {repartidor.id}")

        lat_param = request.query_params.get('latitud')
        lon_param = request.query_params.get('longitud')

        if lat_param and lon_param:
            try:
                latitud_repartidor = float(lat_param)
                longitud_repartidor = float(lon_param)

                if not (-90.0 <= latitud_repartidor <= 90.0):
                    return Response({
                        "error": "Latitud fuera de rango válido (-90 a 90).",
                        "pedidos": []
                    }, status=status.HTTP_400_BAD_REQUEST)

                if not (-180.0 <= longitud_repartidor <= 180.0):
                    return Response({
                        "error": "Longitud fuera de rango válido (-180 a 180).",
                        "pedidos": []
                    }, status=status.HTTP_400_BAD_REQUEST)

                logger.debug(
                    f"Usando coordenadas del request: ({latitud_repartidor}, {longitud_repartidor})"
                )
            except ValueError:
                return Response({
                    "error": "Coordenadas inválidas en los parámetros.",
                    "pedidos": []
                }, status=status.HTTP_400_BAD_REQUEST)

        elif repartidor.latitud and repartidor.longitud:
            latitud_repartidor = float(repartidor.latitud)
            longitud_repartidor = float(repartidor.longitud)
            logger.debug(
                f"Usando coordenadas de BD: ({latitud_repartidor}, {longitud_repartidor})"
            )

        else:
            return Response({
                "error": "Debes activar tu ubicación para ver pedidos cercanos.",
                "pedidos": []
            }, status=status.HTTP_400_BAD_REQUEST)

        radio_km = float(request.query_params.get('radio', 15.0))

        Pedido = apps.get_model('pedidos', 'Pedido')
        from pedidos.serializers import PedidoRepartidorResumidoSerializer

        # Filtrar pedidos PENDIENTES (sin repartidor asignado)
        estados_disponibles = [
            'pendiente_repartidor',
            'asignado_repartidor',
            'aceptado_repartidor',  # por si un pedido quedó en este estado sin repartidor
        ]
        pedidos_query = Pedido.objects.filter(
            repartidor__isnull=True,
            estado__in=estados_disponibles
        ).select_related('cliente__user', 'proveedor')

        def _filtrar_por_radio(radio, pedidos):
            resultados = []
            for pedido in pedidos:
                lat_destino = getattr(pedido, 'latitud_destino', None)
                lon_destino = getattr(pedido, 'longitud_destino', None)

                # Si no hay coords, incluir igual (sin distancia)
                if lat_destino is None or lon_destino is None:
                    pedido_data = PedidoRepartidorResumidoSerializer(pedido).data
                    pedido_data['distancia_km'] = None
                    pedido_data['tiempo_estimado_min'] = None
                    resultados.append(pedido_data)
                    continue

                distancia = calcular_distancia_haversine(
                    latitud_repartidor,
                    longitud_repartidor,
                    lat_destino,
                    lon_destino
                )

                if distancia is None:
                    # Coordenadas inválidas: incluir sin distancia
                    pedido_data = PedidoRepartidorResumidoSerializer(pedido).data
                    pedido_data['distancia_km'] = None
                    pedido_data['tiempo_estimado_min'] = None
                    resultados.append(pedido_data)
                    continue

                # Incluir si está dentro del radio
                if distancia <= radio:
                    pedido_data = PedidoRepartidorResumidoSerializer(pedido).data
                    pedido_data['distancia_km'] = round(distancia, 2)
                    pedido_data['tiempo_estimado_min'] = max(int(distancia / 0.5), 5)
                    resultados.append(pedido_data)
            return resultados

        pedidos_cercanos = _filtrar_por_radio(radio_km, pedidos_query)

        # Si no hay nada en el radio solicitado, probar con un radio extendido (200 km)
        radio_usado = radio_km
        if not pedidos_cercanos and radio_km < 200:
            radio_usado = 200.0
            pedidos_cercanos = _filtrar_por_radio(radio_usado, pedidos_query)

        pedidos_cercanos.sort(key=lambda x: x['distancia_km'] if x.get('distancia_km') is not None else 999999)

        logger.info(
            f"Repartidor {repartidor.id} consultó mapa: "
            f"{len(pedidos_cercanos)} pedidos en radio de {radio_usado}km "
            f"desde ({latitud_repartidor}, {longitud_repartidor})"
        )

        return Response({
            'repartidor_ubicacion': {
                'latitud': latitud_repartidor,
                'longitud': longitud_repartidor,
            },
            'radio_km': radio_usado,
            'total_pedidos': len(pedidos_cercanos),
            'pedidos': pedidos_cercanos,
        }, status=status.HTTP_200_OK)

    except Repartidor.DoesNotExist:
        logger.error(f"Usuario {request.user.email} no tiene perfil de repartidor asociado")
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except AttributeError as e:
        logger.error(f"AttributeError al obtener pedidos disponibles: {e}", exc_info=True)
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except LookupError:
        logger.error("Modelo 'Pedido' no encontrado en la app 'pedidos'")
        return Response(
            {"error": "Configuración del sistema incorrecta."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logger.error(f"Error al obtener pedidos disponibles: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener pedidos."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
def obtener_mis_pedidos_activos(request):
    """
    Obtiene los pedidos ASIGNADOS al repartidor (en curso).
    Incluye datos completos ya que el repartidor ya aceptó estos pedidos.
    """
    try:
        repartidor = request.user.repartidor
        Pedido = apps.get_model('pedidos', 'Pedido')
        from pedidos.serializers import PedidoRepartidorDetalladoSerializer

        # Obtener pedidos asignados que no están entregados
        pedidos_activos = Pedido.objects.filter(
            repartidor=repartidor
        ).exclude(
            estado__in=['entregado', 'cancelado']
        ).select_related(
            'cliente__user',
            'proveedor'
        ).prefetch_related(
            'items__producto'
        ).order_by('-creado_en')

        # Serializar con datos completos
        pedidos_data = []
        for pedido in pedidos_activos:
            try:
                pedidos_data.append(PedidoRepartidorDetalladoSerializer(pedido, context={'request': request}).data)
            except Exception as e:
                logger.error(f"Error serializando pedido {pedido.id}: {e}", exc_info=True)
                continue

        logger.info(
            f"Repartidor {repartidor.id} consultó {len(pedidos_data)} pedidos activos"
        )

        return Response({
            'total': len(pedidos_data),
            'pedidos': pedidos_data
        }, status=status.HTTP_200_OK)

    except Repartidor.DoesNotExist:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error al obtener pedidos activos: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener pedidos activos."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
def obtener_actualizaciones_pedidos(request):
    """
    Endpoint incremental optimizado para smart polling.

    Solo devuelve pedidos modificados después del timestamp especificado.
    Reduce significativamente el ancho de banda y carga del servidor.

    Query params:
    - desde: ISO timestamp (opcional) - solo devuelve pedidos modificados después de esta fecha

    Optimizaciones:
    - Cache-Control headers para permitir caché del cliente
    - Respuesta compacta con solo datos necesarios
    - Índices de DB optimizados con updated_at
    """
    try:
        from datetime import datetime
        from django.utils import timezone

        repartidor = request.user.repartidor
        Pedido = apps.get_model('pedidos', 'Pedido')
        from pedidos.serializers import PedidoRepartidorDetalladoSerializer

        # Obtener timestamp desde parámetro
        desde_param = request.query_params.get('desde')
        desde = None

        if desde_param:
            try:
                # Parsear ISO timestamp
                desde = datetime.fromisoformat(desde_param.replace('Z', '+00:00'))
                # Asegurar que tenga timezone
                if timezone.is_naive(desde):
                    desde = timezone.make_aware(desde)
            except (ValueError, TypeError) as e:
                logger.warning(f"Timestamp inválido recibido: {desde_param}, error: {e}")
                desde = None

        # Query base - pedidos activos del repartidor
        queryset = Pedido.objects.filter(
            repartidor=repartidor
        ).exclude(
            estado__in=['entregado', 'cancelado']
        ).select_related(
            'cliente__user',
            'proveedor'
        ).prefetch_related(
            'items__producto'
        )

        # Aplicar filtro incremental si hay timestamp
        if desde:
            queryset = queryset.filter(updated_at__gt=desde)

        queryset = queryset.order_by('-updated_at')

        # Serializar pedidos
        pedidos_data = []
        for pedido in queryset:
            try:
                pedidos_data.append(
                    PedidoRepartidorDetalladoSerializer(
                        pedido,
                        context={'request': request}
                    ).data
                )
            except Exception as e:
                logger.error(f"Error serializando pedido {pedido.id}: {e}")
                continue

        # Timestamp actual para próxima sincronización
        ahora = timezone.now()

        logger.info(
            f"Actualización incremental - Repartidor {repartidor.id}: "
            f"{len(pedidos_data)} pedidos desde {desde_param or 'inicio'}"
        )

        response_data = {
            'pedidos': pedidos_data,
            'timestamp': ahora.isoformat(),
            'total': len(pedidos_data),
            'es_incremental': desde is not None
        }

        response = Response(response_data, status=status.HTTP_200_OK)

        # Headers de cache - permitir caché por 30 segundos
        response['Cache-Control'] = 'private, max-age=30'
        response['Vary'] = 'Authorization'

        return response

    except Repartidor.DoesNotExist:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error en actualizaciones incrementales: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener actualizaciones."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated, IsRepartidor])
def detalle_pedido_repartidor(request, pedido_id):
    """
    Obtiene el detalle COMPLETO de un pedido (con datos sensibles).

    SEGURIDAD:
    - Si el pedido está PENDIENTE: Retorna error 403 (datos protegidos)
    - Si el pedido está ASIGNADO a OTRO repartidor: Retorna error 403
    - Si el pedido está ASIGNADO al repartidor autenticado: Retorna detalle completo
    """
    try:
        repartidor = request.user.repartidor
        Pedido = apps.get_model('pedidos', 'Pedido')
        from pedidos.serializers import PedidoRepartidorDetalladoSerializer

        pedido = get_object_or_404(Pedido, pk=pedido_id)

        # VALIDACIÓN DE SEGURIDAD: Solo el repartidor asignado puede ver datos sensibles
        if pedido.repartidor is None:
            logger.warning(
                f"Repartidor {repartidor.id} intentó acceder a pedido {pedido_id} "
                f"que está PENDIENTE (sin asignar)"
            )
            return Response(
                {
                    "error": "Acceso denegado",
                    "detalle": "No puedes ver los datos completos de un pedido que no has aceptado."
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # Verificar que el pedido esté asignado a este repartidor (con null check adicional)
        if pedido.repartidor is not None and pedido.repartidor.id != repartidor.id:
            logger.warning(
                f"Repartidor {repartidor.id} intentó acceder a pedido {pedido_id} "
                f"asignado a repartidor {pedido.repartidor.id}"
            )
            return Response(
                {
                    "error": "Acceso denegado",
                    "detalle": "Este pedido está asignado a otro repartidor."
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # OK: El pedido está asignado al repartidor autenticado
        serializer = PedidoRepartidorDetalladoSerializer(pedido, context={'request': request})

        logger.info(
            f"Repartidor {repartidor.id} accedió al detalle completo del pedido {pedido_id}"
        )

        return Response(serializer.data, status=status.HTTP_200_OK)

    except Repartidor.DoesNotExist:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except LookupError:
        logger.error("Modelo 'Pedido' no encontrado")
        return Response(
            {"error": "Configuración del sistema incorrecta."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logger.error(f"Error al obtener detalle del pedido: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al obtener detalle del pedido."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRepartidor])
def aceptar_pedido(request, pedido_id):
    """
    Permite al repartidor aceptar un pedido disponible.
    """
    try:
        repartidor = request.user.repartidor

        # Si no está disponible, intentar ponerlo disponible automáticamente
        if repartidor.estado != 'disponible':
            try:
                repartidor.marcar_disponible()
            except ValidationError as e:
                return Response(
                    {"error": str(e)},
                    status=status.HTTP_400_BAD_REQUEST
                )

        Pedido = apps.get_model('pedidos', 'Pedido')

        with transaction.atomic():
            # Usar _base_manager para evitar joins del manager custom y poder bloquear la fila
            pedido = get_object_or_404(
                Pedido._base_manager.select_for_update(),
                pk=pedido_id
            )

            if pedido.repartidor is not None:
                return Response(
                    {"error": "Este pedido ya fue asignado a otro repartidor."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            pedido.aceptar_por_repartidor(repartidor)
            repartidor.marcar_ocupado()

        logger.info(f"Repartidor {repartidor.id} aceptó pedido {pedido_id}")

        # Notificar a repartidores y al cliente (no debe fallar el flujo)
        from .models import Repartidor
        from notificaciones.services import enviar_notificacion_push

        # 1. Notificar a otros repartidores que el pedido ya no está disponible
        try:
            otros_repartidores = Repartidor.objects.filter(
                estado='disponible'
            ).exclude(id=repartidor.id)

            for rep in otros_repartidores:
                enviar_notificacion_push(
                    usuario=rep.user,
                    titulo='Pedido tomado por otro repartidor',
                    mensaje=f"El pedido #{pedido.numero_pedido or pedido.id} ya fue aceptado.",
                    datos_extra={
                        'tipo_evento': 'pedido_aceptado',
                        'accion': 'remover_pedido_disponible',
                        'pedido_id': str(pedido.id),
                        'numero_pedido': pedido.numero_pedido or '',
                    },
                    guardar_en_bd=False,  # Notificaciones internas para repartidores
                    tipo='repartidor'
                )
        except Exception as e:
            logger.warning(f"Error enviando notificación a repartidores disponibles: {e}")

        # 2. Notificar al CLIENTE que su pedido fue aceptado
        try:
            if pedido.cliente and pedido.cliente.user:
                datos_extra = {
                    'tipo_evento': 'pedido_actualizado',
                    'accion': 'actualizar_estado_pedido',
                    'pedido_id': str(pedido.id),
                    'numero_pedido': pedido.numero_pedido or '',
                    'nuevo_estado': 'asignado_repartidor',
                    'estado_display': 'Asignado a repartidor',
                    'repartidor_nombre': repartidor.user.get_full_name() if repartidor.user else 'Repartidor',
                }
                titulo = '¡Pedido aceptado! 🎉'
                cuerpo = f'Un repartidor aceptó tu pedido #{pedido.numero_pedido}.'

                if pedido.metodo_pago == 'transferencia':
                    datos_extra['accion'] = 'subir_comprobante'
                    datos_extra['monto'] = str(pedido.total)
                    titulo = 'Pedido aceptado: transfiere y sube el comprobante'
                    cuerpo = f'Transfiere ${pedido.total} y sube el comprobante para el pedido #{pedido.numero_pedido}.'

                enviar_notificacion_push(
                    usuario=pedido.cliente.user,
                    titulo=titulo,
                    mensaje=cuerpo,
                    datos_extra=datos_extra,
                    tipo='pedido',
                    pedido=pedido
                )
                logger.info(f"Notificación enviada al cliente {pedido.cliente.id}")
        except Exception as e:
            logger.warning(f"Error enviando notificación al cliente: {e}")

        # Serializar el pedido con detalle completo para devolverlo al repartidor
        from pedidos.serializers import PedidoRepartidorDetalladoSerializer
        serializer = PedidoRepartidorDetalladoSerializer(pedido, context={'request': request})

        return Response({
            "mensaje": "Pedido aceptado correctamente",
            "pedido": serializer.data,
            "estado_repartidor": repartidor.estado,
        }, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except ValidationError as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    except LookupError:
        logger.error("Modelo 'Pedido' no encontrado")
        return Response(
            {"error": "Configuración del sistema incorrecta."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logger.error(f"Error al aceptar pedido: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al aceptar pedido."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRepartidor])
def rechazar_pedido(request, pedido_id):
    """
    Permite al repartidor rechazar un pedido (opcional).
    """
    try:
        repartidor = request.user.repartidor

        Pedido = apps.get_model('pedidos', 'Pedido')

        pedido = get_object_or_404(Pedido, pk=pedido_id)

        # Validar que el pedido NO esté ya asignado a este repartidor
        if pedido.repartidor == repartidor:
            return Response(
                {"error": "No puedes rechazar un pedido que ya aceptaste."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validar que el pedido esté disponible (sin asignar a nadie)
        if pedido.repartidor is not None:
            return Response(
                {"error": "Este pedido ya fue asignado a otro repartidor."},
                status=status.HTTP_400_BAD_REQUEST
            )

        logger.info(f"Repartidor {repartidor.id} rechazó pedido {pedido_id}")

        return Response({
            "mensaje": "Pedido rechazado",
            "pedido_id": pedido.id,
        }, status=status.HTTP_200_OK)

    except AttributeError:
        return Response(
            {"error": "No tienes perfil de repartidor asociado."},
            status=status.HTTP_404_NOT_FOUND
        )
    except LookupError:
        logger.error("Modelo 'Pedido' no encontrado")
        return Response(
            {"error": "Configuración del sistema incorrecta."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        logger.error(f"Error al rechazar pedido: {e}", exc_info=True)
        return Response(
            {"error": "Error interno al rechazar pedido."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# ==========================================================
# EDITAR MI PERFIL (Datos del Repartidor)
# ==========================================================

# Definir throttle para editar perfil
class EditarPerfilThrottle(UserRateThrottle):
    rate = "30/hour"

@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
@throttle_classes([EditarPerfilThrottle])
def editar_mi_perfil(request):

    user = request.user
    
    # Verificar rol de repartidor
    if hasattr(user, 'rol_activo') and user.rol_activo != 'repartidor':
        logger.warning(
            f"Usuario {user.email} intentó editar perfil repartidor "
            f"con rol_activo={user.rol_activo}"
        )
        return Response(
            {
                'error': 'No tienes rol de repartidor activo',
                'rol_actual': user.rol_activo,
                'mensaje': 'Cambia tu rol activo a repartidor para editar'
            },
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Buscar repartidor vinculado
    try:
        repartidor = Repartidor.objects.select_related('user').get(user=user)
    except Repartidor.DoesNotExist:
        return Response(
            {'error': 'No tienes un repartidor vinculado a tu cuenta'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Campos permitidos para edición
    campos_permitidos = ['cedula', 'telefono', 'foto_perfil', 'vehiculo']
    
    # Manejar eliminación de foto
    eliminar_foto = request.data.get('eliminar_foto_perfil', 'false')
    if eliminar_foto in ['true', True, '1', 1]:
        if repartidor.foto_perfil:
            try:
                repartidor.foto_perfil.delete(save=False)
            except Exception as e:
                logger.warning(f"Error eliminando archivo de foto: {e}")
            
            repartidor.foto_perfil = None
            repartidor.save(update_fields=['foto_perfil', 'actualizado_en'])
            
            logger.info(f"Foto eliminada para repartidor {repartidor.id}")
            
            return Response({
                'message': 'Foto de perfil eliminada correctamente',
                'repartidor': RepartidorPerfilCompletoSerializer(
                    repartidor, 
                    context={'request': request}
                ).data
            })
    
    # Filtrar datos recibidos
    datos_filtrados = {}
    
    # Datos de formulario (texto)
    for campo in ['cedula', 'telefono', 'vehiculo']:
        if campo in request.data:
            valor = request.data.get(campo)
            if valor is not None and str(valor).strip():
                datos_filtrados[campo] = str(valor).strip()
    
    # Archivo de foto
    if 'foto_perfil' in request.FILES:
        datos_filtrados['foto_perfil'] = request.FILES['foto_perfil']
    
    if not datos_filtrados:
        return Response(
            {
                'error': 'No se proporcionaron datos válidos para actualizar',
                'campos_permitidos': campos_permitidos
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Validar con serializer
    serializer = RepartidorEditarPerfilSerializer(
        repartidor,
        data=datos_filtrados,
        partial=True
    )
    
    if not serializer.is_valid():
        return Response(
            {
                'error': 'Datos inválidos',
                'detalles': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Guardar cambios
    serializer.save()
    
    # Refrescar para obtener datos actualizados
    repartidor.refresh_from_db()
    
    logger.info(
        f"Repartidor {repartidor.id} actualizó perfil: "
        f"{list(datos_filtrados.keys())}"
    )
    
    return Response({
        'message': 'Perfil actualizado exitosamente',
        'campos_actualizados': list(datos_filtrados.keys()),
        'repartidor': RepartidorPerfilCompletoSerializer(
            repartidor,
            context={'request': request}
        ).data
    })


# ==========================================================
# EDITAR MI CONTACTO (Datos del User)
# ==========================================================

@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
@throttle_classes([EditarPerfilThrottle])
def editar_mi_contacto(request):
    
    user = request.user
    
    # Verificar rol de repartidor
    if hasattr(user, 'rol_activo') and user.rol_activo != 'repartidor':
        return Response(
            {'error': 'No tienes rol de repartidor activo'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Buscar repartidor vinculado
    try:
        repartidor = Repartidor.objects.select_related('user').get(user=user)
    except Repartidor.DoesNotExist:
        return Response(
            {'error': 'No tienes un repartidor vinculado a tu cuenta'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Validar datos con el serializer
    serializer = RepartidorEditarContactoSerializer(
        data=request.data,
        context={'usuario': user}
    )
    
    if not serializer.is_valid():
        return Response(
            {
                'error': 'Datos inválidos',
                'detalles': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Actualizar usuario
    email = serializer.validated_data.get('email')
    first_name = serializer.validated_data.get('first_name')
    last_name = serializer.validated_data.get('last_name')
    
    campos_actualizados = []
    
    if email:
        user.email = email
        campos_actualizados.append('email')
    
    if first_name:
        user.first_name = first_name
        campos_actualizados.append('first_name')
    
    if last_name:
        user.last_name = last_name
        campos_actualizados.append('last_name')
    
    if campos_actualizados:
        user.save(update_fields=campos_actualizados + ['updated_at'])
    
    logger.info(
        f"Repartidor {repartidor.id} actualizó contacto: "
        f"{', '.join(campos_actualizados)}"
    )
    
    # Refrescar repartidor para obtener datos actualizados
    repartidor.refresh_from_db()
    
    return Response({
        'message': 'Datos de contacto actualizados exitosamente',
        'campos_actualizados': campos_actualizados,
        'repartidor': RepartidorPerfilCompletoSerializer(
            repartidor,
            context={'request': request}
        ).data
    })


# ==========================================================
# MI REPARTIDOR (Obtener perfil completo)
# ==========================================================

@api_view(["GET"])
@permission_classes([IsAuthenticated])
@throttle_classes([PerfilThrottle])
def mi_repartidor(request):
   
    user = request.user
    
    # Verificar rol de repartidor
    if hasattr(user, 'rol_activo') and user.rol_activo != 'repartidor':
        logger.warning(
            f"Usuario {user.email} intentó acceder a mi_repartidor "
            f"con rol_activo={user.rol_activo}"
        )
        return Response(
            {
                'error': 'No tienes rol de repartidor activo',
                'rol_actual': user.rol_activo,
                'mensaje': 'Cambia tu rol activo a repartidor para acceder'
            },
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Buscar repartidor vinculado
    try:
        repartidor = Repartidor.objects.select_related('user').prefetch_related(
            'vehiculos'
        ).get(user=user)
    except Repartidor.DoesNotExist:
        logger.warning(
            f"Usuario {user.email} con rol repartidor no tiene "
            f"Repartidor vinculado en la base de datos. Restableciendo a Cliente."
        )
        # Auto-corregir inconsistencia
        user.rol_activo = 'cliente'
        user.save(update_fields=['rol_activo'])

        return Response(
            {
                'error': 'No se encontró tu perfil de repartidor. Se ha restablecido tu cuenta a modo Cliente.',
                'action': 'ROLE_RESET'
            },
            status=status.HTTP_404_NOT_FOUND
        )
    
    logger.info(f"Repartidor {repartidor.id} consultado por {user.email}")

    serializer = RepartidorPerfilCompletoSerializer(
        repartidor,
        context={'request': request}
    )

    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRepartidor])
def marcar_pedido_en_camino(request, pedido_id):
    """
    Marca un pedido como 'en_camino'.
    El repartidor ya recogió el pedido y está en camino hacia el cliente.

    Validaciones:
    - El pedido debe estar asignado al repartidor autenticado
    - El pedido debe estar en estado 'pendiente_repartidor' o 'asignado_repartidor'

    Al marcar como en camino:
    - Actualiza estado del pedido a 'en_camino'
    - Envía notificación push al cliente
    """
    try:
        repartidor = request.user.repartidor
        Pedido = apps.get_model('pedidos', 'Pedido')

        # Obtener el pedido
        pedido = get_object_or_404(Pedido, pk=pedido_id)

        logger.info(
            f"[EN_CAMINO] Repartidor {repartidor.id} ({repartidor.user.email}) "
            f"intentando marcar pedido {pedido_id} como en camino. Estado actual: {pedido.estado}"
        )

        # Verificar que el pedido esté asignado a este repartidor
        if pedido.repartidor != repartidor:
            logger.warning(
                f"[EN_CAMINO] Repartidor {repartidor.id} intentó marcar pedido {pedido_id} "
                f"que está asignado a repartidor {pedido.repartidor.id if pedido.repartidor else 'ninguno'}"
            )
            return Response(
                {
                    "error": "Acceso denegado",
                    "mensaje": "Este pedido no está asignado a ti."
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # Verificar estado del pedido - solo se puede marcar en camino si está pendiente o asignado
        estados_validos = ['pendiente_repartidor', 'asignado_repartidor']
        if pedido.estado not in estados_validos:
            return Response(
                {
                    "error": "Estado inválido",
                    "mensaje": f"El pedido debe estar 'pendiente_repartidor' o 'asignado_repartidor' para marcarlo como en camino. Estado actual: {pedido.estado}"
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Actualizar estado del pedido
        with transaction.atomic():
            estado_anterior = pedido.estado
            pedido.estado = 'en_camino'
            pedido.save()

            logger.info(
                f"[EN_CAMINO] ✅ Pedido {pedido_id} marcado como en camino. "
                f"Estado: {estado_anterior} -> {pedido.estado}"
            )

        # Enviar notificación push al cliente
        try:
            from firebase_admin import messaging

            if pedido.cliente and hasattr(pedido.cliente.user, 'fcm_token') and pedido.cliente.user.fcm_token:
                try:
                    mensaje_cliente = messaging.Message(
                        notification=messaging.Notification(
                            title='Tu pedido está en camino 🚚',
                            body=f'El repartidor va en camino con tu pedido #{pedido.numero_pedido}'
                        ),
                        data={
                            'tipo_evento': 'pedido_actualizado',
                            'accion': 'actualizar_estado_pedido',
                            'pedido_id': str(pedido.id),
                            'numero_pedido': pedido.numero_pedido or '',
                            'nuevo_estado': 'en_camino',
                            'estado_display': 'En Camino',
                            'repartidor_nombre': repartidor.user.get_full_name() if repartidor.user else 'Repartidor',
                        },
                        token=pedido.cliente.user.fcm_token
                    )
                    messaging.send(mensaje_cliente)
                    logger.info(f"[EN_CAMINO] Notificación enviada al cliente {pedido.cliente.id}")
                except Exception as e:
                    logger.warning(f"[EN_CAMINO] Error al enviar notificación al cliente: {e}")

        except Exception as e:
            logger.warning(f"[EN_CAMINO] Error general en sistema de notificaciones: {e}")

        return Response({
            "success": True,
            "mensaje": "Pedido marcado como en camino correctamente",
            "pedido": {
                "id": pedido.id,
                "numero_pedido": pedido.numero_pedido,
                "estado": pedido.estado,
            },
        }, status=status.HTTP_200_OK)

    except AttributeError as e:
        logger.error(f"[EN_CAMINO] Usuario sin perfil de repartidor: {request.user.email}", exc_info=True)
        return Response(
            {
                "error": "Perfil no encontrado",
                "mensaje": "No tienes perfil de repartidor asociado."
            },
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(
            f"[EN_CAMINO] Error inesperado al marcar pedido {pedido_id} como en camino: {type(e).__name__}: {e}",
            exc_info=True
        )
        return Response(
            {
                "error": "Error interno del servidor",
                "mensaje": "Ocurrió un error inesperado al procesar la solicitud.",
                "tipo_error": type(e).__name__
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated, IsRepartidor])
def marcar_pedido_entregado(request, pedido_id):
    """
    Marca un pedido como entregado por el repartidor.

    Validaciones:
    - El pedido debe estar asignado al repartidor autenticado
    - El pedido debe estar en estado 'en_camino'
    - Para método de pago TRANSFERENCIA, se requiere imagen del comprobante
    - La imagen debe ser válida (formato y tamaño)

    Al marcar como entregado:
    - Actualiza estado del pedido a 'entregado'
    - Registra fecha/hora de entrega
    - Distribuye ganancias entre proveedor, repartidor y app
    - Cambia estado del repartidor a 'disponible'
    - Envía notificaciones push a cliente y proveedor
    """
    try:
        repartidor = request.user.repartidor
        Pedido = apps.get_model('pedidos', 'Pedido')

        # Obtener el pedido
        pedido = get_object_or_404(Pedido, pk=pedido_id)

        logger.info(
            f"[ENTREGA] Repartidor {repartidor.id} ({repartidor.user.email}) "
            f"intentando marcar pedido {pedido_id} como entregado. Estado actual: {pedido.estado}"
        )

        # Verificar que el pedido esté asignado a este repartidor
        if pedido.repartidor != repartidor:
            logger.warning(
                f"[ENTREGA] Repartidor {repartidor.id} intentó marcar pedido {pedido_id} "
                f"que está asignado a repartidor {pedido.repartidor.id if pedido.repartidor else 'ninguno'}"
            )
            return Response(
                {
                    "error": "Acceso denegado",
                    "mensaje": "Este pedido no está asignado a ti."
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # Verificar estado del pedido - solo se puede entregar si está 'en_camino'
        if pedido.estado == 'entregado':
            return Response(
                {
                    "error": "Pedido ya entregado",
                    "mensaje": "Este pedido ya fue marcado como entregado anteriormente.",
                    "fecha_entregado": pedido.fecha_entregado.isoformat() if pedido.fecha_entregado else None
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if pedido.estado == 'cancelado':
            return Response(
                {
                    "error": "Pedido cancelado",
                    "mensaje": "No se puede entregar un pedido cancelado.",
                    "motivo_cancelacion": pedido.motivo_cancelacion
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if pedido.estado != 'en_camino':
            return Response(
                {
                    "error": "Estado inválido",
                    "mensaje": f"El pedido debe estar 'en_camino' para poder entregarlo. Estado actual: {pedido.estado}"
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        imagen_evidencia = request.FILES.get('imagen_evidencia')

        # Validación de comprobante de transferencia (cliente)
        if pedido.metodo_pago == 'transferencia':
            pago = getattr(pedido, 'pago', None)
            if not pago or not pago.transferencia_comprobante:
                logger.warning(
                    f"[ENTREGA] Intento de entregar pedido {pedido_id} por transferencia sin comprobante del cliente"
                )
                return Response(
                    {
                        "error": "Comprobante requerido",
                        "mensaje": "El cliente debe subir el comprobante de transferencia antes de marcar como entregado.",
                        "metodo_pago": pedido.metodo_pago
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

        # Marcar como entregado dentro de transacción atómica
        with transaction.atomic():
            # Guardar datos antes de la actualización para logging
            estado_anterior = pedido.estado

            # Actualizar pedido
            pedido.marcar_entregado(imagen_evidencia=imagen_evidencia)

            # Cambiar estado del repartidor a disponible
            repartidor.marcar_disponible()

            logger.info(
                f"[ENTREGA] ✅ Pedido {pedido_id} entregado exitosamente. "
                f"Estado: {estado_anterior} -> {pedido.estado}. "
                f"Método pago: {pedido.metodo_pago}. "
                f"Comprobante: {'Sí' if imagen_evidencia else 'No'}. "
                f"Total: ${pedido.total}. "
                f"Comisión repartidor: ${pedido.comision_repartidor}. "
                f"Comisión proveedor: ${pedido.comision_proveedor}"
            )

        # Enviar notificaciones push
        notificaciones_enviadas = {
            'cliente': False,
            'proveedor': False
        }

        try:
            from firebase_admin import messaging

            # Notificación al cliente
            if pedido.cliente and hasattr(pedido.cliente.user, 'fcm_token') and pedido.cliente.user.fcm_token:
                try:
                    mensaje_cliente = messaging.Message(
                        notification=messaging.Notification(
                            title='¡Pedido entregado! ✅',
                            body=f'Tu pedido #{pedido.numero_pedido} ha sido entregado. ¡Buen provecho!'
                        ),
                        data={
                            'tipo_evento': 'pedido_actualizado',
                            'accion': 'actualizar_estado_pedido',
                            'pedido_id': str(pedido.id),
                            'numero_pedido': pedido.numero_pedido or '',
                            'nuevo_estado': 'entregado',
                            'estado_display': 'Entregado',
                            'repartidor_nombre': repartidor.user.get_full_name() if repartidor.user else 'Repartidor',
                            'fecha_entrega': pedido.fecha_entregado.isoformat() if pedido.fecha_entregado else '',
                        },
                        token=pedido.cliente.user.fcm_token
                    )
                    messaging.send(mensaje_cliente)
                    notificaciones_enviadas['cliente'] = True
                    logger.info(f"[ENTREGA] Notificación enviada al cliente {pedido.cliente.id}")
                except Exception as e:
                    logger.warning(f"[ENTREGA] Error al enviar notificación al cliente: {e}")

            # Notificación al proveedor
            if pedido.proveedor and hasattr(pedido.proveedor.user, 'fcm_token') and pedido.proveedor.user.fcm_token:
                try:
                    mensaje_proveedor = messaging.Message(
                        notification=messaging.Notification(
                            title='Pedido entregado ✅',
                            body=f'El pedido #{pedido.numero_pedido} fue entregado al cliente'
                        ),
                        data={
                            'tipo_evento': 'pedido_actualizado',
                            'accion': 'actualizar_estado_pedido',
                            'pedido_id': str(pedido.id),
                            'numero_pedido': pedido.numero_pedido or '',
                            'nuevo_estado': 'entregado',
                            'estado_display': 'Entregado',
                            'total': str(pedido.total),
                            'comision_proveedor': str(pedido.comision_proveedor),
                        },
                        token=pedido.proveedor.user.fcm_token
                    )
                    messaging.send(mensaje_proveedor)
                    notificaciones_enviadas['proveedor'] = True
                    logger.info(f"[ENTREGA] Notificación enviada al proveedor {pedido.proveedor.id}")
                except Exception as e:
                    logger.warning(f"[ENTREGA] Error al enviar notificación al proveedor: {e}")

        except Exception as e:
            # No fallar la operación si falla el sistema de notificaciones
            logger.warning(f"[ENTREGA] Error general en sistema de notificaciones: {e}")

        return Response({
            "success": True,
            "mensaje": "Pedido marcado como entregado correctamente",
            "pedido": {
                "id": pedido.id,
                "numero_pedido": pedido.numero_pedido,
                "estado": pedido.estado,
                "estado_pago": pedido.estado_pago,
                "fecha_entregado": pedido.fecha_entregado.isoformat() if pedido.fecha_entregado else None,
                "total": str(pedido.total),
                "metodo_pago": pedido.metodo_pago,
                "tiene_comprobante": bool(pedido.imagen_evidencia),
            },
            "comisiones": {
                "repartidor": str(pedido.comision_repartidor),
                "proveedor": str(pedido.comision_proveedor),
                "app": str(pedido.ganancia_app),
            },
            "repartidor": {
                "estado": repartidor.estado,
                "pedidos_activos": repartidor.pedidos_activos.count() if hasattr(repartidor, 'pedidos_activos') else 0,
            },
            "notificaciones_enviadas": notificaciones_enviadas,
        }, status=status.HTTP_200_OK)

    except AttributeError as e:
        logger.error(f"[ENTREGA] Usuario sin perfil de repartidor: {request.user.email}", exc_info=True)
        return Response(
            {
                "error": "Perfil no encontrado",
                "mensaje": "No tienes perfil de repartidor asociado. Contacta al administrador."
            },
            status=status.HTTP_404_NOT_FOUND
        )
    except LookupError as e:
        logger.error(f"[ENTREGA] Modelo Pedido no encontrado en el sistema", exc_info=True)
        return Response(
            {
                "error": "Configuración del sistema incorrecta",
                "mensaje": "Error en la configuración del servidor. Contacta al administrador."
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except ValidationError as e:
        logger.warning(f"[ENTREGA] Error de validación al marcar pedido {pedido_id}: {e}")
        return Response(
            {
                "error": "Error de validación",
                "mensaje": str(e),
                "detalles": e.message_dict if hasattr(e, 'message_dict') else None
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        logger.error(
            f"[ENTREGA] Error inesperado al marcar pedido {pedido_id} como entregado: {type(e).__name__}: {e}",
            exc_info=True,
            extra={
                'pedido_id': pedido_id,
                'repartidor_id': request.user.repartidor.id if hasattr(request.user, 'repartidor') else None,
                'usuario': request.user.email
            }
        )
        return Response(
            {
                "error": "Error interno del servidor",
                "mensaje": "Ocurrió un error inesperado al procesar la entrega. El equipo técnico ha sido notificado.",
                "tipo_error": type(e).__name__
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================
# DATOS BANCARIOS DEL REPARTIDOR
# ==========================================================

@api_view(['GET', 'PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def datos_bancarios_repartidor(request):
    """
    Endpoint para gestionar los datos bancarios del repartidor autenticado.

    GET: Obtiene los datos bancarios actuales
    PUT/PATCH: Actualiza los datos bancarios
    """
    try:
        repartidor = request.user.repartidor
    except AttributeError:
        return Response(
            {'error': 'No tienes perfil de repartidor'},
            status=status.HTTP_403_FORBIDDEN
        )

    if request.method == 'GET':
        from .serializers import DatosBancariosSerializer
        serializer = DatosBancariosSerializer(repartidor)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method in ['PUT', 'PATCH']:
        from .serializers import DatosBancariosUpdateSerializer
        import logging

        logger = logging.getLogger('repartidores')

        partial = request.method == 'PATCH'
        serializer = DatosBancariosUpdateSerializer(
            repartidor,
            data=request.data,
            partial=partial
        )

        if serializer.is_valid():
            try:
                serializer.save()

                # Retornar datos actualizados
                from .serializers import DatosBancariosSerializer
                response_serializer = DatosBancariosSerializer(repartidor)

                return Response(
                    {
                        'message': 'Datos bancarios actualizados correctamente',
                        'datos_bancarios': response_serializer.data
                    },
                    status=status.HTTP_200_OK
                )
            except Exception as e:
                logger.error(
                    f'Error al guardar datos bancarios del repartidor {repartidor.id}: {str(e)}',
                    exc_info=True
                )
                return Response(
                    {
                        'error': 'Error al guardar los datos bancarios',
                        'detail': str(e)
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
