# pedidos/views.py (VERSIÓN FINAL OPTIMIZADA + LOGÍSTICA)

import logging
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Prefetch

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination

# Importación de utilidades
from utils.throttles import PedidoThrottle

# Importación de modelos y serializers
from .models import Pedido, EstadoPedido, TipoPedido, ItemPedido
from pagos.models import Pago, MetodoPago, TipoMetodoPago, EstadoPago as EstadoPagoPago
from .serializers import (
    PedidoCreateSerializer,
    PedidoListSerializer,
    PedidoDetailSerializer,
    PedidoAceptarRepartidorSerializer,
    PedidoConfirmarProveedorSerializer,
    PedidoCancelacionSerializer,
    PedidoEstadoUpdateSerializer,
    PedidoGananciasSerializer,
)

logger = logging.getLogger("pedidos.views")

# Firebase Cloud Messaging para notificaciones
try:
    from firebase_admin import messaging
    FCM_AVAILABLE = True
except ImportError:
    FCM_AVAILABLE = False
    logger.warning("Firebase Admin SDK no disponible - notificaciones push deshabilitadas")

# 🟢 DETECCIÓN SEGURA DE LA APP ENVIOS
try:
    from envios.models import Envio
    ENVIOS_INSTALLED = True
except ImportError:
    ENVIOS_INSTALLED = False


# ==========================================================
#  PAGINACIÓN ESTÁNDAR
# ==========================================================
class StandardPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50


# ==========================================================
#  HELPERS DE PERMISOS (Robustos)
# ==========================================================

def get_rol_seguro(user):
    """Obtiene el rol del usuario con fallback a CLIENTE"""
    return getattr(user, 'rol', 'CLIENTE').upper() if getattr(user, 'rol', None) else 'CLIENTE'

def verificar_permiso_cliente(user):
    return get_rol_seguro(user) == 'CLIENTE'

def verificar_permiso_proveedor(user, pedido=None):
    if get_rol_seguro(user) != 'PROVEEDOR': return False
    if not hasattr(user, 'proveedor'): return False
    # Si hay pedido, validar propiedad
    if pedido and pedido.proveedor_id != user.proveedor.id: return False
    return True

def verificar_permiso_repartidor(user, pedido=None):
    if get_rol_seguro(user) != 'REPARTIDOR': return False
    # Acceso seguro al perfil y repartidor
    try:
        repartidor = user.perfil.repartidor
    except AttributeError:
        return False
    
    if pedido and pedido.repartidor_id and pedido.repartidor_id != repartidor.id:
        return False
    return True

def verificar_permiso_admin(user):
    return user.is_staff or user.is_superuser


# ==========================================================
#  OPTIMIZADOR DE CONSULTAS (DRY)
# ==========================================================
def get_pedidos_queryset():
    """
    Retorna un queryset ultra-optimizado para evitar N+1 queries.
    Carga Cliente, Proveedor, Repartidor, Items y Logística en un solo golpe.
    """
    qs = Pedido.objects.select_related(
        'cliente__user',
        'proveedor',
        'repartidor__user'
    ).prefetch_related(
        'items', 
        'items__producto' # Para ver nombres de productos sin consultar de nuevo
    )
    
    # Si tenemos logística, la cargamos también
    if ENVIOS_INSTALLED:
        qs = qs.select_related('datos_envio')
        
    return qs


# ==========================================================
#  ENDPOINT: LISTAR Y CREAR PEDIDOS
# ==========================================================
@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
@throttle_classes([PedidoThrottle])
def pedidos_view(request):
    user = request.user
    rol = get_rol_seguro(user)

    # ------------------------------------------------------
    # 1. CREAR PEDIDO (POST)
    # ------------------------------------------------------
    if request.method == "POST":
        if rol != 'CLIENTE' and not verificar_permiso_admin(user):
            return Response({"error": "Solo clientes crean pedidos."}, status=status.HTTP_403_FORBIDDEN)

        try:
            # El serializer ya maneja la creación de Items y Envío (Logística)
            serializer = PedidoCreateSerializer(
                data=request.data,
                context={'request': request}
            )

            if not serializer.is_valid():
                logger.warning(f"Error creando pedido: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

            # Guardado atómico (Todo o nada)
            with transaction.atomic():
                pedido = serializer.save()

            logger.info(f"Pedido #{pedido.numero_pedido} creado por {user.email}")

            # Usamos el serializer de detalle para la respuesta (más completo)
            return Response({
                "mensaje": "Pedido creado exitosamente",
                "pedido": PedidoDetailSerializer(pedido).data
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            logger.error(f"Excepción creando pedido: {e}", exc_info=True)
            return Response({"error": "Error interno del servidor"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # ------------------------------------------------------
    # 2. LISTAR PEDIDOS (GET)
    # ------------------------------------------------------
    try:
        # Usamos el queryset optimizado
        queryset = get_pedidos_queryset()

        # --- FILTRADO POR ROL ---
        if verificar_permiso_admin(user):
            pass # Ve todo

        elif rol == 'CLIENTE':
            if not hasattr(user, 'perfil'):
                return Response({"error": "Perfil de cliente no encontrado"}, status=status.HTTP_400_BAD_REQUEST)
            queryset = queryset.filter(cliente=user.perfil)

        elif rol == 'PROVEEDOR':
            if not hasattr(user, 'proveedor'):
                return Response({"error": "Cuenta proveedor incompleta"}, status=status.HTTP_400_BAD_REQUEST)
            queryset = queryset.filter(proveedor=user.proveedor)

        elif rol == 'REPARTIDOR':
            try:
                repartidor = user.perfil.repartidor
            except AttributeError:
                return Response({"error": "Cuenta repartidor incompleta"}, status=status.HTTP_400_BAD_REQUEST)
            
            # Ve sus asignados O los disponibles (confirmados sin asignar)
            queryset = queryset.filter(
                repartidor=repartidor
            ) | queryset.filter(
                repartidor__isnull=True,
                estado=EstadoPedido.ASIGNADO_REPARTIDOR
            )
        else:
            return Response({"error": f"Rol desconocido: {rol}"}, status=status.HTTP_403_FORBIDDEN)

        # --- FILTROS ADICIONALES (Query Params) ---
        estado = request.query_params.get('estado')
        if estado:
            queryset = queryset.filter(estado=estado)

        fecha = request.query_params.get('fecha')
        if fecha:
            queryset = queryset.filter(creado_en__date=fecha)

        # --- PAGINACIÓN ---
        paginator = StandardPagination()
        page = paginator.paginate_queryset(queryset.order_by('-creado_en'), request)
        serializer = PedidoListSerializer(page, many=True)
        
        return paginator.get_paginated_response(serializer.data)

    except Exception as e:
        logger.error(f"Error listando pedidos: {e}", exc_info=True)
        return Response({"error": "Error obteniendo la lista"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==========================================================
#  ENDPOINT: DETALLE PEDIDO
# ==========================================================
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def pedido_detalle(request, pedido_id):
    """Obtiene el detalle completo incluyendo items y logística"""
    try:
        # Usamos select_related y prefetch para que sea una sola consulta rápida
        queryset = get_pedidos_queryset()
        pedido = get_object_or_404(queryset, id=pedido_id)
        user = request.user

        # --- VALIDACIÓN DE PERMISOS ---
        tiene_acceso = False
        
        if verificar_permiso_admin(user):
            tiene_acceso = True
        elif hasattr(user, 'perfil') and pedido.cliente == user.perfil:
            tiene_acceso = True
        elif verificar_permiso_proveedor(user, pedido):
            tiene_acceso = True
        elif verificar_permiso_repartidor(user, pedido):
            tiene_acceso = True

        if not tiene_acceso:
            return Response({"error": "No tienes permiso para ver este pedido"}, status=status.HTTP_403_FORBIDDEN)

        # Garantizar que exista un pago cuando el método es transferencia (evita fallos al subir comprobante)
        if pedido.metodo_pago == 'transferencia' and not hasattr(pedido, 'pago'):
            try:
                metodo_pago_obj, _ = MetodoPago.objects.get_or_create(
                    tipo=TipoMetodoPago.TRANSFERENCIA,
                    defaults={
                        'nombre': 'Transferencia',
                        'descripcion': 'Generado automáticamente',
                        'requiere_verificacion': True,
                        'activo': True,
                    }
                )
                Pago.objects.create(
                    pedido=pedido,
                    metodo_pago=metodo_pago_obj,
                    monto=pedido.total,
                    estado=EstadoPagoPago.PENDIENTE
                )
            except Exception as e:
                logger.warning(f"No se pudo autogenerar el pago para el pedido {pedido.id}: {e}")

        serializer = PedidoDetailSerializer(pedido, context={'request': request})
        return Response(serializer.data)

    except Exception as e:
        logger.error(f"Error detalle pedido {pedido_id}: {e}", exc_info=True)
        return Response({"error": "Error interno"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==========================================================
#  ACCIONES DE FLUJO (CAMBIO DE ESTADO)
# ==========================================================

@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
def aceptar_pedido_repartidor(request, pedido_id):
    """Repartidor toma un pedido"""
    try:
        if not verificar_permiso_repartidor(request.user):
            return Response({"error": "Acceso denegado"}, status=status.HTTP_403_FORBIDDEN)

        pedido = get_object_or_404(Pedido, id=pedido_id)
        
        # Serializer maneja la validación de estado y asignación
        repartidor = request.user.perfil.repartidor
        serializer = PedidoAceptarRepartidorSerializer(
            data={'repartidor_id': repartidor.id},
            context={'pedido': pedido}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                serializer.save()

                # Vincular el repartidor al pago (si existe) para habilitar transferencia
                try:
                    from pagos.models import Pago
                    pago = Pago.objects.select_for_update().get(pedido=pedido)
                    pago.repartidor_asignado = repartidor
                    pago.comprobante_visible_repartidor = False
                    pago.save(update_fields=['repartidor_asignado', 'comprobante_visible_repartidor', 'actualizado_en'])
                except Exception as e:
                    logger.warning(f"No se pudo vincular el pago al repartidor: {e}")

                # Notificar al cliente que debe transferir y subir comprobante
                try:
                    if pedido.cliente and pedido.cliente.user:
                        from notificaciones.services import crear_y_enviar_notificacion
                        crear_y_enviar_notificacion(
                            usuario=pedido.cliente.user,
                            titulo="Repartidor aceptó tu pedido",
                            mensaje=f"Debes transferir ${pedido.total} y subir el comprobante para el pedido #{pedido.numero_pedido}.",
                            tipo='pedido',
                            pedido=pedido,
                            datos_extra={
                                'accion': 'subir_comprobante',
                                'monto': str(pedido.total),
                                'pedido_id': str(pedido.id),
                                'pedido_numero': pedido.numero_pedido or '',
                            },
                        )
                except Exception as e:
                    logger.warning(f"No se pudo enviar notificación de transferencia: {e}")

            return Response({"mensaje": "Pedido aceptado"}, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error aceptando pedido: {e}")
        return Response({"error": "Error interno"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
def confirmar_pedido_proveedor(request, pedido_id):
    """Proveedor confirma preparación"""
    try:
        pedido = get_object_or_404(Pedido, id=pedido_id)
        
        if not verificar_permiso_proveedor(request.user, pedido):
            return Response({"error": "Acceso denegado"}, status=status.HTTP_403_FORBIDDEN)

        serializer = PedidoConfirmarProveedorSerializer(
            data={'proveedor_id': request.user.proveedor.id},
            context={'pedido': pedido}
        )

        if serializer.is_valid():
            serializer.save()
            return Response({"mensaje": "Pedido confirmado"}, status=status.HTTP_200_OK)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error confirmando pedido: {e}")
        return Response({"error": "Error interno"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
def cambiar_estado_pedido(request, pedido_id):
    """Cambio manual de estado (En Ruta, Entregado)"""
    try:
        pedido = get_object_or_404(Pedido, id=pedido_id)
        user = request.user

        # Validar permisos
        es_autorizado = (
            verificar_permiso_admin(user) or
            verificar_permiso_proveedor(user, pedido) or
            verificar_permiso_repartidor(user, pedido)
        )

        if not es_autorizado:
            return Response({"error": "Sin permisos"}, status=status.HTTP_403_FORBIDDEN)

        serializer = PedidoEstadoUpdateSerializer(
            data=request.data,
            context={'pedido': pedido}
        )

        if serializer.is_valid():
            # Guardar el estado anterior para comparación
            estado_anterior = pedido.estado

            # Actualizar el estado
            serializer.update(pedido, serializer.validated_data)
            nuevo_estado = pedido.estado

            # Enviar notificación push al cliente si el estado cambió
            if FCM_AVAILABLE and estado_anterior != nuevo_estado:
                _enviar_notificacion_cambio_estado_cliente(pedido, nuevo_estado)

            return Response({"mensaje": "Estado actualizado"}, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error cambiando estado: {e}")
        return Response({"error": "Error interno"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _enviar_notificacion_cambio_estado_cliente(pedido, nuevo_estado):
    """
    Envía una notificación push al cliente cuando el estado del pedido cambia.
    """
    if not pedido.cliente:
        return

    if not hasattr(pedido.cliente.user, 'fcm_token') or not pedido.cliente.user.fcm_token:
        logger.debug(f"Cliente {pedido.cliente.id} no tiene FCM token registrado")
        return

    # Mapear estados a mensajes amigables
    mensajes_estados = {
        'pendiente': {
            'titulo': 'Pedido recibido',
            'body': f'Tu pedido #{pedido.numero_pedido} ha sido recibido y está pendiente de asignación.',
            'estado_display': 'Pendiente',
        },
        'asignado': {
            'titulo': '¡Pedido aceptado! 🎉',
            'body': f'Un repartidor aceptó tu pedido #{pedido.numero_pedido}. Pronto estará en camino.',
            'estado_display': 'Asignado',
        },
        'confirmado': {
            'titulo': 'Pedido confirmado',
            'body': f'El restaurante confirmó tu pedido #{pedido.numero_pedido}.',
            'estado_display': 'Confirmado',
        },
        'en_preparacion': {
            'titulo': 'Preparando tu pedido 👨‍🍳',
            'body': f'Tu pedido #{pedido.numero_pedido} está siendo preparado.',
            'estado_display': 'En preparación',
        },
        'listo_recoger': {
            'titulo': 'Listo para recoger',
            'body': f'Tu pedido #{pedido.numero_pedido} está listo para ser recogido.',
            'estado_display': 'Listo para recoger',
        },
        'en_camino': {
            'titulo': '¡En camino! 🚚',
            'body': f'Tu pedido #{pedido.numero_pedido} está en camino hacia ti.',
            'estado_display': 'En camino',
        },
        'entregado': {
            'titulo': '¡Pedido entregado! ✅',
            'body': f'Tu pedido #{pedido.numero_pedido} ha sido entregado. ¡Buen provecho!',
            'estado_display': 'Entregado',
        },
        'finalizado': {
            'titulo': 'Pedido completado',
            'body': f'Tu pedido #{pedido.numero_pedido} ha sido completado.',
            'estado_display': 'Finalizado',
        },
        'cancelado': {
            'titulo': 'Pedido cancelado',
            'body': f'Tu pedido #{pedido.numero_pedido} ha sido cancelado.',
            'estado_display': 'Cancelado',
        },
    }

    mensaje_info = mensajes_estados.get(nuevo_estado.lower(), {
        'titulo': 'Actualización de pedido',
        'body': f'El estado de tu pedido #{pedido.numero_pedido} ha cambiado.',
        'estado_display': nuevo_estado.replace('_', ' ').title(),
    })

    # Obtener nombre del repartidor si existe
    repartidor_nombre = 'Repartidor'
    if pedido.repartidor:
        repartidor_nombre = pedido.repartidor.user.get_full_name() if pedido.repartidor.user else 'Repartidor'

    try:
        mensaje_cliente = messaging.Message(
            notification=messaging.Notification(
                title=mensaje_info['titulo'],
                body=mensaje_info['body']
            ),
            data={
                'tipo_evento': 'pedido_actualizado',
                'accion': 'actualizar_estado_pedido',
                'pedido_id': str(pedido.id),
                'numero_pedido': pedido.numero_pedido or '',
                'nuevo_estado': nuevo_estado.lower(),
                'estado_display': mensaje_info['estado_display'],
                'repartidor_nombre': repartidor_nombre,
            },
            token=pedido.cliente.user.fcm_token
        )

        messaging.send(mensaje_cliente)
        logger.info(f"Notificación de cambio de estado enviada al cliente {pedido.cliente.id} - Estado: {nuevo_estado}")

    except Exception as e:
        logger.error(f"Error enviando notificación de estado al cliente: {e}", exc_info=True)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cancelar_pedido(request, pedido_id):
    """Cancelación controlada"""
    try:
        pedido = get_object_or_404(Pedido, id=pedido_id)
        user = request.user

        # Permisos de cancelación (Similar al detalle)
        es_autorizado = (
            verificar_permiso_admin(user) or
            (hasattr(user, 'perfil') and pedido.cliente == user.perfil) or
            verificar_permiso_proveedor(user, pedido) or
            verificar_permiso_repartidor(user, pedido)
        )

        if not es_autorizado:
            return Response({"error": "No puedes cancelar este pedido"}, status=status.HTTP_403_FORBIDDEN)

        serializer = PedidoCancelacionSerializer(
            data=request.data,
            context={'pedido': pedido, 'request': request}
        )

        if serializer.is_valid():
            serializer.save()
            # Recargar el pedido con las relaciones para el serializer de detalle
            pedido.refresh_from_db()
            pedido_serializado = PedidoDetailSerializer(pedido).data
            return Response({
                "mensaje": "Pedido cancelado",
                "pedido": pedido_serializado
            }, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error cancelando: {e}")
        return Response({"error": "Error interno"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def ver_ganancias_pedido(request, pedido_id):
    try:
        pedido = get_object_or_404(Pedido, id=pedido_id)
        # Solo participantes directos ven el dinero
        if not (verificar_permiso_admin(request.user) or
                verificar_permiso_proveedor(request.user, pedido) or
                verificar_permiso_repartidor(request.user, pedido)):
            return Response({"error": "Prohibido"}, status=status.HTTP_403_FORBIDDEN)

        serializer = PedidoGananciasSerializer(pedido)
        return Response(serializer.data)
    except Exception:
        return Response({"error": "Error"}, status=500)


