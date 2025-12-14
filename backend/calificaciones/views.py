# calificaciones/views.py

import logging
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404

from .models import Calificacion, ResumenCalificacion, TipoCalificacion
from .serializers import (
    CalificacionListSerializer,
    CalificacionDetailSerializer,
    CrearCalificacionSerializer,
    ActualizarCalificacionSerializer,
    ResumenCalificacionSerializer,
    CalificacionPendienteSerializer,
    EstadisticasCalificacionSerializer,
    CalificacionRapidaSerializer,
)
from .services import CalificacionService

logger = logging.getLogger('calificaciones')


class CalificacionViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestión de calificaciones.
    
    Endpoints:
    - GET    /calificaciones/              → Lista mis calificaciones recibidas
    - POST   /calificaciones/              → Crear nueva calificación
    - GET    /calificaciones/{id}/         → Detalle de calificación
    - PATCH  /calificaciones/{id}/         → Actualizar calificación
    - DELETE /calificaciones/{id}/         → Eliminar calificación
    
    - GET    /calificaciones/dadas/        → Calificaciones que he dado
    - GET    /calificaciones/recibidas/    → Calificaciones que he recibido
    - GET    /calificaciones/pendientes/   → Calificaciones pendientes por dar
    - GET    /calificaciones/estadisticas/ → Mis estadísticas
    - POST   /calificaciones/rapida/       → Calificación rápida (solo estrellas)
    - GET    /calificaciones/pedido/{id}/  → Calificaciones de un pedido
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Retorna calificaciones según el contexto"""
        user = self.request.user
        
        # Por defecto, mostrar calificaciones recibidas
        return Calificacion.objects.filter(
            calificado=user
        ).select_related(
            'pedido', 'calificador', 'calificado'
        ).order_by('-created_at')

    def get_serializer_class(self):
        """Selecciona el serializer según la acción"""
        if self.action == 'create':
            return CrearCalificacionSerializer
        elif self.action in ['update', 'partial_update']:
            return ActualizarCalificacionSerializer
        elif self.action == 'retrieve':
            return CalificacionDetailSerializer
        elif self.action == 'rapida':
            return CalificacionRapidaSerializer
        return CalificacionListSerializer

    # ============================================
    # ACCIONES CRUD BÁSICAS
    # ============================================

    def list(self, request, *args, **kwargs):
        """Lista calificaciones recibidas por el usuario autenticado"""
        queryset = self.get_queryset()
        
        # Filtros opcionales
        tipo = request.query_params.get('tipo')
        estrellas = request.query_params.get('estrellas')
        
        if tipo:
            queryset = queryset.filter(tipo=tipo)
        if estrellas:
            queryset = queryset.filter(estrellas=estrellas)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    def create(self, request, *args, **kwargs):
        """Crea una nueva calificación"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        calificacion = serializer.save()
        
        # Retornar el detalle de la calificación creada
        detail_serializer = CalificacionDetailSerializer(calificacion)
        
        return Response({
            'message': '¡Gracias por tu calificación!',
            'calificacion': detail_serializer.data
        }, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        """Actualiza una calificación existente"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Verificar que el usuario sea el calificador
        if instance.calificador_id != request.user.id:
            return Response({
                'error': 'Solo puedes editar tus propias calificaciones.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response({
            'message': 'Calificación actualizada correctamente.',
            'calificacion': CalificacionDetailSerializer(instance).data
        })

    def destroy(self, request, *args, **kwargs):
        """Elimina una calificación (solo el calificador puede eliminar)"""
        instance = self.get_object()
        
        if instance.calificador_id != request.user.id:
            return Response({
                'error': 'Solo puedes eliminar tus propias calificaciones.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        instance.delete()
        
        # Recalcular promedio del calificado
        CalificacionService.actualizar_promedio_usuario(instance.calificado)
        
        return Response({
            'message': 'Calificación eliminada correctamente.'
        }, status=status.HTTP_200_OK)

    # ============================================
    # ACCIONES PERSONALIZADAS
    # ============================================

    @action(detail=False, methods=['get'])
    def dadas(self, request):
        """Lista calificaciones dadas por el usuario"""
        calificaciones = Calificacion.objects.filter(
            calificador=request.user
        ).select_related(
            'pedido', 'calificado'
        ).order_by('-created_at')
        
        # Filtros
        tipo = request.query_params.get('tipo')
        if tipo:
            calificaciones = calificaciones.filter(tipo=tipo)
        
        page = self.paginate_queryset(calificaciones)
        if page is not None:
            serializer = CalificacionListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = CalificacionListSerializer(calificaciones, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def recibidas(self, request):
        """Lista calificaciones recibidas por el usuario"""
        calificaciones = Calificacion.objects.filter(
            calificado=request.user
        ).select_related(
            'pedido', 'calificador'
        ).order_by('-created_at')
        
        # Filtros
        tipo = request.query_params.get('tipo')
        estrellas_min = request.query_params.get('estrellas_min')
        
        if tipo:
            calificaciones = calificaciones.filter(tipo=tipo)
        if estrellas_min:
            calificaciones = calificaciones.filter(estrellas__gte=estrellas_min)
        
        page = self.paginate_queryset(calificaciones)
        if page is not None:
            serializer = CalificacionListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = CalificacionListSerializer(calificaciones, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='pendientes/(?P<pedido_id>[^/.]+)')
    def pendientes(self, request, pedido_id=None):
        """
        Retorna las calificaciones pendientes por dar para un pedido específico.
        
        Útil para mostrar en la app después de la entrega.
        """
        from pedidos.models import Pedido
        
        pedido = get_object_or_404(Pedido, id=pedido_id)
        
        pendientes = CalificacionService.obtener_calificaciones_pendientes(
            pedido=pedido,
            user=request.user
        )
        
        return Response({
            'pedido_id': pedido.id,
            'numero_pedido': pedido.numero_pedido,
            'calificaciones_pendientes': pendientes,
            'total_pendientes': len(pendientes)
        })

    @action(detail=False, methods=['get'])
    def estadisticas(self, request):
        """Retorna estadísticas completas de calificaciones del usuario"""
        stats = CalificacionService.obtener_estadisticas_usuario(request.user)
        serializer = EstadisticasCalificacionSerializer(stats)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def mi_resumen(self, request):
        """Retorna el resumen de calificaciones del usuario autenticado"""
        resumen, _ = ResumenCalificacion.objects.get_or_create(user=request.user)
        serializer = ResumenCalificacionSerializer(resumen)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def rapida(self, request):
        """
        Calificación rápida (solo estrellas, sin comentario).
        
        Útil para el flujo rápido en la app móvil.
        """
        serializer = CalificacionRapidaSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        calificacion = serializer.save()
        
        return Response({
            'message': '¡Gracias por tu calificación!',
            'calificacion': {
                'id': calificacion.id,
                'estrellas': calificacion.estrellas,
                'tipo': calificacion.tipo,
            }
        }, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], url_path='pedido/(?P<pedido_id>[^/.]+)')
    def por_pedido(self, request, pedido_id=None):
        """
        Lista todas las calificaciones de un pedido específico.
        
        Solo pueden ver las calificaciones los participantes del pedido.
        """
        from pedidos.models import Pedido
        
        pedido = get_object_or_404(Pedido, id=pedido_id)
        
        # Verificar que el usuario sea participante del pedido
        es_participante = (
            (pedido.cliente and pedido.cliente.user_id == request.user.id) or
            (pedido.repartidor and pedido.repartidor.user_id == request.user.id) or
            (pedido.proveedor and pedido.proveedor.user_id == request.user.id) or
            request.user.is_staff
        )
        
        if not es_participante:
            return Response({
                'error': 'No tienes permiso para ver las calificaciones de este pedido.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        calificaciones = Calificacion.objects.filter(pedido=pedido)
        serializer = CalificacionListSerializer(calificaciones, many=True)
        
        # Obtener pendientes del usuario actual
        pendientes = CalificacionService.obtener_calificaciones_pendientes(
            pedido=pedido,
            user=request.user
        )
        
        return Response({
            'pedido_id': pedido.id,
            'numero_pedido': pedido.numero_pedido,
            'estado': pedido.estado,
            'calificaciones': serializer.data,
            'total_calificaciones': len(serializer.data),
            'mis_pendientes': pendientes,
        })

    @action(detail=False, methods=['get'], url_path='usuario/(?P<user_id>[^/.]+)')
    def de_usuario(self, request, user_id=None):
        """
        Lista calificaciones recibidas por un usuario específico.
        
        Útil para ver el historial de un repartidor/proveedor.
        """
        from django.contrib.auth import get_user_model
        User = get_user_model()
        
        usuario = get_object_or_404(User, id=user_id)
        
        calificaciones = Calificacion.objects.filter(
            calificado=usuario
        ).order_by('-created_at')[:20]  # Últimas 20
        
        # Obtener resumen
        resumen, _ = ResumenCalificacion.objects.get_or_create(user=usuario)
        
        return Response({
            'usuario': {
                'id': usuario.id,
                'nombre': usuario.get_full_name(),
            },
            'resumen': ResumenCalificacionSerializer(resumen).data,
            'ultimas_calificaciones': CalificacionListSerializer(calificaciones, many=True).data,
        })


# ============================================
# VISTA PARA TIPOS DE CALIFICACIÓN
# ============================================

class TipoCalificacionView(viewsets.ViewSet):
    """Vista para obtener tipos de calificación disponibles"""
    
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        """Lista todos los tipos de calificación"""
        tipos = [
            {'value': choice[0], 'label': choice[1]}
            for choice in TipoCalificacion.choices
        ]
        return Response(tipos)