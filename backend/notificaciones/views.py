# notificaciones/views.py (VERSIÓN OPTIMIZADA)
"""
Controlador de Notificaciones.
Gestiona el listado, lectura y estadísticas de las alertas del usuario.
"""

import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.utils import timezone
from django.db.models import Count

from notificaciones.models import Notificacion
from notificaciones.serializers import (
    NotificacionSerializer,
    NotificacionListSerializer, # Versión ligera para listas
    MarcarLeidaSerializer,
    EstadisticasNotificacionesSerializer
)

logger = logging.getLogger('notificaciones.views')


class NotificacionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API para que el usuario gestione sus notificaciones.
    No permite crear ni borrar individualmente (solo lectura y acciones de estado).
    """
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Retorna solo las notificaciones del usuario actual, ordenadas por fecha.
        Optimizado con select_related para traer datos del pedido en una sola query.
        """
        # Protección para generación de esquemas (Swagger)
        if getattr(self, 'swagger_fake_view', False):
            return Notificacion.objects.none()

        user = self.request.user
        qs = Notificacion.objects.filter(usuario=user).select_related('pedido')

        # --- FILTROS OPCIONALES ---
        tipo = self.request.query_params.get('tipo')
        if tipo:
            qs = qs.filter(tipo=tipo)

        leida = self.request.query_params.get('leida')
        if leida is not None:
            es_leida = leida.lower() in ['true', '1', 'yes']
            qs = qs.filter(leida=es_leida)

        return qs.order_by('-creada_en')

    def get_serializer_class(self):
        """Usa un serializer más ligero para listar (ahorra datos)"""
        if self.action == 'list':
            return NotificacionListSerializer
        return NotificacionSerializer

    # ==========================================================
    #  ACCIONES DE LECTURA (MARCAR COMO LEÍDO)
    # ==========================================================

    def retrieve(self, request, *args, **kwargs):
        """
        Al abrir una notificación específica, se marca como leída automáticamente.
        """
        instance = self.get_object()
        if not instance.leida:
            instance.marcar_leida()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def marcar_leida(self, request, pk=None):
        """Marca una notificación específica como leída manualmente"""
        notificacion = self.get_object()
        notificacion.marcar_leida()
        return Response({'status': 'ok', 'leida': True})

    @action(detail=True, methods=['post'])
    def marcar_no_leida(self, request, pk=None):
        """Marca una notificación específica como NO leída"""
        notificacion = self.get_object()
        notificacion.leida = False
        notificacion.leida_en = None
        notificacion.save(update_fields=['leida', 'leida_en'])
        return Response({'status': 'ok', 'leida': False})

    @action(detail=False, methods=['post'])
    def marcar_todas_leidas(self, request):
        """
        Marca TODAS las notificaciones del usuario como leídas.
        Útil para el botón 'Marcar todo como leído' en la UI.
        """
        # Usamos el manager optimizado para update masivo
        count = Notificacion.objects.filter(
            usuario=request.user, 
            leida=False
        ).marcar_como_leidas()
        
        return Response({
            'status': 'ok', 
            'actualizadas': count,
            'mensaje': f'{count} notificaciones marcadas como leídas'
        })

    @action(detail=False, methods=['post'])
    def marcar_varias(self, request):
        """
        Marca una lista específica de IDs como leídas.
        Body: { "ids": ["uuid1", "uuid2"] }
        """
        serializer = MarcarLeidaSerializer(data=request.data)
        if serializer.is_valid():
            ids = serializer.validated_data['ids']
            # Filtramos por usuario para evitar que marque notificaciones ajenas
            count = Notificacion.objects.filter(
                id__in=ids, 
                usuario=request.user
            ).marcar_como_leidas()
            
            return Response({'status': 'ok', 'actualizadas': count})
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # ==========================================================
    #  UTILIDADES Y ESTADÍSTICAS
    # ==========================================================

    @action(detail=False, methods=['get'])
    def estadisticas(self, request):
        """
        Retorna conteos para los badges de la UI (Campanita).
        Ej: { "no_leidas": 5, "total": 20 }
        """
        user = request.user
        
        # Consultas optimizadas usando índices
        total = Notificacion.objects.filter(usuario=user).count()
        no_leidas = Notificacion.objects.contar_no_leidas(user)
        
        # Traer las 5 más recientes para preview rápido
        ultimas = Notificacion.objects.filter(usuario=user).select_related('pedido')[:5]
        
        data = {
            'total': total,
            'no_leidas': no_leidas,
            'leidas': total - no_leidas,
            'ultimas_5': NotificacionListSerializer(ultimas, many=True).data
        }
        return Response(data)

    @action(detail=False, methods=['delete'])
    def limpiar_historial(self, request):
        """
        Elimina notificaciones antiguas DEL USUARIO ACTUAL.
        Por defecto > 30 días.
        """
        dias = int(request.query_params.get('dias', 30))
        if dias < 1: dias = 30
        
        fecha_limite = timezone.now() - timezone.timedelta(days=dias)
        
        # Solo borramos las del usuario que lo solicita
        count, _ = Notificacion.objects.filter(
            usuario=request.user,
            creada_en__lt=fecha_limite,
            leida=True # Por seguridad, solo borramos las que ya leyó
        ).delete()
        
        return Response({
            'status': 'ok', 
            'eliminadas': count,
            'mensaje': f'Se eliminaron {count} notificaciones antiguas'
        })

    # ==========================================================
    #  HERRAMIENTAS DE DESARROLLO (ADMIN ONLY)
    # ==========================================================

    @action(detail=False, methods=['post'], permission_classes=[IsAdminUser])
    def test_push(self, request):
        """
        Solo para Admins: Envía una notificación de prueba a sí mismo
        para verificar que Firebase funciona.
        """
        from notificaciones.services import crear_y_enviar_notificacion
        
        exito = crear_y_enviar_notificacion(
            usuario=request.user,
            titulo="Test de Sistema",
            mensaje="Si lees esto, Firebase está funcionando correctamente.",
            tipo='sistema',
            datos_extra={'test': 'true'}
        )
        
        if exito:
            return Response({'status': 'ok', 'mensaje': 'Push enviado'})
        return Response(
            {'status': 'error', 'mensaje': 'Fallo al enviar (ver logs)'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )