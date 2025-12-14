# backend/pagos/views.py
"""
Vistas (Controllers) para el módulo de Pagos.

LÓGICA IMPLEMENTADA:
1. Flujos de Efectivo y Transferencia (Diagramas 1A, 1B, 2A, 2B).
2. Interacción Cliente -> Sube Foto -> Chofer Verifica.
3. Supervisión total del Administrador.
"""
import logging
from django.utils import timezone
from django.db.models import Q, Sum
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404

from .models import (
    MetodoPago, Pago, Transaccion, EstadisticasPago,
    EstadoPago, TipoMetodoPago
)
from .serializers import (
    # Serializers Base
    MetodoPagoSerializer, MetodoPagoListSerializer,
    PagoCreateSerializer, PagoDetailSerializer, PagoListSerializer,
    TransaccionSerializer, TransaccionListSerializer,
    EstadisticasPagoSerializer,
    # Serializers Operativos (Nuevos)
    PagoSubirComprobanteSerializer,
    DatosBancariosChoferSerializer,
    PagoUpdateEstadoSerializer,
    PagoReembolsoSerializer,
    PagoResumenSerializer
)
from .filters import PagoFilter, TransaccionFilter, MetodoPagoFilter

logger = logging.getLogger('pagos')

# ==========================================================
# VIEWSET: METODO DE PAGO
# ==========================================================

class MetodoPagoViewSet(viewsets.ModelViewSet):
    """
    Gestión de métodos de pago.
    Admin gestiona, usuarios solo leen.
    """
    queryset = MetodoPago.objects.all()
    filterset_class = MetodoPagoFilter
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'list':
            return MetodoPagoListSerializer
        return MetodoPagoSerializer

    @action(detail=False, methods=['get'])
    def disponibles(self, request):
        """Retorna solo métodos activos para el checkout del cliente"""
        metodos = self.queryset.filter(activo=True)
        serializer = MetodoPagoListSerializer(metodos, many=True)
        return Response(serializer.data)


# ==========================================================
# VIEWSET: PAGO (Lógica Principal)
# ==========================================================

class PagoViewSet(viewsets.ModelViewSet):
    """
    Gestión central de Pagos.
    Controla el flujo Cliente <-> Chofer <-> Admin.
    """
    queryset = Pago.objects.all()
    filterset_class = PagoFilter
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """
        Reglas de Visibilidad:
        1. ADMIN: Ve TODOS los pagos (para analizar).
        2. CLIENTE: Ve solo sus pagos.
        3. REPARTIDOR: Ve solo los pagos de pedidos asignados a él.
        """
        user = self.request.user
        
        # El Admin lo ve todo
        if user.is_staff or user.is_superuser:
            return Pago.objects.all().select_related('pedido', 'metodo_pago')
        
        # Usuarios ven lo suyo o lo asignado
        return Pago.objects.filter(
            Q(pedido__cliente__user=user) |  # Soy el cliente
            Q(pedido__repartidor__user=user)       # Soy el chofer
        ).distinct()

    def get_serializer_class(self):
        if self.action == 'create':
            return PagoCreateSerializer
        elif self.action == 'list':
            return PagoListSerializer
        elif self.action == 'subir_comprobante':
            return PagoSubirComprobanteSerializer
        elif self.action == 'actualizar_estado':
            return PagoUpdateEstadoSerializer
        elif self.action == 'reembolsar':
            return PagoReembolsoSerializer
        elif self.action == 'resumen':
            return PagoResumenSerializer
        return PagoDetailSerializer

    # ==========================================================
    # ACCIONES OPERATIVAS (Diagramas 1B y 2B)
    # ==========================================================

    @action(detail=True, methods=['post'])
    def subir_comprobante(self, request, pk=None):
        """
        [CLIENTE] Paso: Subir la foto de la transferencia.
        Cambia estado a: ESPERANDO_VERIFICACION.
        """
        pago = self.get_object()
        user = request.user

        # Validar que sea el cliente (o admin ayudando)
        es_cliente = pago.pedido.cliente.user == user
        es_admin = user.is_staff

        if not (es_cliente or es_admin):
            return Response({'error': 'No autorizado'}, status=status.HTTP_403_FORBIDDEN)

        # Solo si está pendiente
        if pago.estado != EstadoPago.PENDIENTE:
             return Response(
                 {'error': f'No se puede subir comprobante en estado {pago.get_estado_display()}'}, 
                 status=status.HTTP_400_BAD_REQUEST
             )

        serializer = PagoSubirComprobanteSerializer(pago, data=request.data, partial=True)
        if serializer.is_valid():
            pago = serializer.save()
            
            # AUTOMATIZACIÓN: Cambiar estado para alertar al chofer
            pago.estado = EstadoPago.ESPERANDO_VERIFICACION
            pago.save(update_fields=['estado', 'actualizado_en'])
            
            logger.info(f"Comprobante subido en Pago {pago.referencia}. Estado: Esperando Verificación.")
            
            return Response({
                'status': 'ok', 
                'mensaje': 'Comprobante enviado. Esperando validación del repartidor.',
                'estado': pago.estado
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def datos_transferencia(self, request, pk=None):
        """
        [CLIENTE] Obtener datos bancarios del Chofer asignado.
        """
        pago = self.get_object()
        
        if not pago.pedido.repartidor:
             return Response(
                 {'error': 'Aún no hay un repartidor asignado para recibir la transferencia.'}, 
                 status=status.HTTP_400_BAD_REQUEST
             )
        
        serializer = DatosBancariosChoferSerializer(pago)
        return Response(serializer.data)

    # ==========================================================
    # ACCIONES DE VERIFICACIÓN (Chofer / Admin)
    # ==========================================================

    @action(detail=True, methods=['post'])
    def confirmar_recepcion_dinero(self, request, pk=None):
        """
        [CHOFER/ADMIN] Paso final: Confirmar que el dinero llegó.
        - EFECTIVO: "Ya lo tengo en la mano".
        - TRANSFERENCIA: "Ya revisé mi banco y está ahí".
        """
        pago = self.get_object()
        user = request.user
        
        # Permisos: Chofer asignado O Admin
        es_repartidor = pago.pedido.repartidor == user
        es_admin = user.is_staff

        if not (es_repartidor or es_admin):
            return Response(
                {'error': 'Solo el repartidor asignado o el Admin pueden confirmar el cobro.'}, 
                status=status.HTTP_403_FORBIDDEN
            )

        # Validaciones de Estado según el Método
        tipo = pago.metodo_pago.tipo
        nota_auditoria = ""

        if tipo == TipoMetodoPago.EFECTIVO:
            # Efectivo puede confirmarse desde Pendiente o Procesando
            if pago.estado == EstadoPago.COMPLETADO:
                return Response({'error': 'El pago ya está completado'}, status=400)
            nota_auditoria = "Cobro en efectivo confirmado."

        elif tipo == TipoMetodoPago.TRANSFERENCIA:
            # Transferencia DEBE tener comprobante (salvo que sea Admin forzando)
            if pago.estado != EstadoPago.ESPERANDO_VERIFICACION and not es_admin:
                return Response(
                    {'error': 'El cliente debe subir el comprobante antes de verificar.'}, 
                    status=400
                )
            nota_auditoria = "Transferencia bancaria validada."

        else:
             # Tarjetas suelen ser automáticas, pero permitimos override de admin
             if not es_admin:
                 return Response({'error': 'Este método se verifica automáticamente'}, status=400)

        # EJECUTAR CONFIRMACIÓN
        # Si es Admin, queda registrado que fue él (Analizando y resolviendo)
        pago.marcar_completado(verificado_por=user)
        
        # Auditoría en notas
        autor = "ADMIN" if es_admin else "REPARTIDOR"
        pago.notas = f"{pago.notas}\n[{timezone.now().strftime('%Y-%m-%d %H:%M')}] {autor}: {nota_auditoria}".strip()
        pago.save(update_fields=['notas'])

        logger.info(f"Pago {pago.referencia} completado por {autor} ({user.email})")

        return Response({
            'status': 'ok',
            'mensaje': 'Pago confirmado exitosamente.',
            'estado': EstadoPago.COMPLETADO
        })

    @action(detail=True, methods=['post'])
    def rechazar_comprobante(self, request, pk=None):
        """
        [CHOFER/ADMIN] Si la foto es falsa o borrosa.
        Regresa el estado a PENDIENTE para que el cliente intente de nuevo.
        """
        pago = self.get_object()
        user = request.user
        
        es_repartidor = pago.pedido.repartidor == user
        es_admin = user.is_staff

        if not (es_repartidor or es_admin):
            return Response({'error': 'No autorizado'}, status=403)

        motivo = request.data.get('motivo', 'Comprobante rechazado por el verificador')
        
        # Retroceder estado
        pago.estado = EstadoPago.PENDIENTE
        pago.notas = f"{pago.notas}\n[RECHAZO] {motivo} - Por: {user.get_full_name()}".strip()
        # Limpiar evidencia previa para evitar reutilizarla
        if pago.transferencia_comprobante:
            pago.transferencia_comprobante.delete(save=False)
        pago.transferencia_comprobante = None
        pago.transferencia_banco_origen = ''
        pago.transferencia_numero_operacion = ''
        pago.save(update_fields=[
            'estado', 'notas', 'transferencia_comprobante',
            'transferencia_banco_origen', 'transferencia_numero_operacion', 'actualizado_en'
        ])

        return Response({'status': 'ok', 'mensaje': 'Comprobante rechazado. Se solicitó uno nuevo al cliente.'})

    # ==========================================================
    # ACCIONES ADMINISTRATIVAS (Reembolsos, Stats)
    # ==========================================================

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reembolsar(self, request, pk=None):
        """Admin fuerza un reembolso"""
        pago = self.get_object()
        serializer = PagoReembolsoSerializer(data=request.data, context={'pago': pago})
        if serializer.is_valid():
            serializer.save()
            return Response({'status': 'ok', 'mensaje': 'Reembolso procesado'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def transacciones(self, request, pk=None):
        """Historial de intentos del pago"""
        pago = self.get_object()
        serializer = TransaccionListSerializer(pago.transacciones.all(), many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def resumen(self, request, pk=None):
        """Resumen rápido"""
        pago = self.get_object()
        data = {
            'referencia': pago.referencia,
            'monto': pago.monto,
            'estado': pago.get_estado_display(),
            'metodo': pago.metodo_pago.nombre,
            'fecha': pago.creado_en
        }
        serializer = PagoResumenSerializer(data)
        return Response(serializer.data)


# ==========================================================
# VIEWSET: TRANSACCIONES (Read Only)
# ==========================================================

class TransaccionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Historial inmutable.
    Admin ve todo, Usuarios ven solo lo suyo.
    """
    queryset = Transaccion.objects.all()
    serializer_class = TransaccionSerializer
    filterset_class = TransaccionFilter
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Transaccion.objects.all()
        return Transaccion.objects.filter(pago__pedido__cliente__user=user)

    def get_serializer_class(self):
        if self.action == 'list':
            return TransaccionListSerializer
        return TransaccionSerializer


# ==========================================================
# VIEWSET: ESTADÍSTICAS (Admin Only)
# ==========================================================

class EstadisticasPagoViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Dashboard financiero para el Admin.
    """
    queryset = EstadisticasPago.objects.all()
    serializer_class = EstadisticasPagoSerializer
    permission_classes = [permissions.IsAdminUser]

    @action(detail=False, methods=['post'])
    def recalcular(self, request):
        """Fuerza el recálculo de un día específico"""
        fecha_str = request.data.get('fecha')
        try:
            stats = EstadisticasPago.calcular_y_guardar(fecha_str) # Fecha None = Hoy
            serializer = self.get_serializer(stats)
            return Response(serializer.data)
        except Exception as e:
            return Response({'error': str(e)}, status=500)


# ==========================================================
# WEBHOOKS (Integraciones Externas)
# ==========================================================

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def stripe_webhook(request):
    logger.warning("Webhook Stripe recibido pero no implementado/validado.")
    return Response({'error': 'Webhook Stripe no implementado'}, status=status.HTTP_501_NOT_IMPLEMENTED)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def kushki_webhook(request):
    logger.warning("Webhook Kushki recibido pero no implementado/validado.")
    return Response({'error': 'Webhook Kushki no implementado'}, status=status.HTTP_501_NOT_IMPLEMENTED)

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def paymentez_webhook(request):
    logger.warning("Webhook Paymentez recibido pero no implementado/validado.")
    return Response({'error': 'Webhook Paymentez no implementado'}, status=status.HTTP_501_NOT_IMPLEMENTED)


# ==========================================================
# COMPROBANTES DE PAGO (CLIENTE Y REPARTIDOR)
# ==========================================================

@api_view(['POST', 'PATCH'])
@permission_classes([permissions.IsAuthenticated])
def subir_comprobante_pago(request, pago_id):
    """
    Endpoint para que el CLIENTE suba el comprobante de transferencia.

    POST: Subir comprobante por primera vez
    PATCH: Actualizar comprobante existente
    """
    try:
        pago = Pago.objects.select_related(
            'pedido__cliente__user',
            'pedido__repartidor'
        ).get(pk=pago_id)
    except Pago.DoesNotExist:
        return Response(
            {'error': 'Pago no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Verificar que el usuario sea el dueño del pedido
    if not (pago.pedido.cliente.user == request.user or request.user.is_staff):
        return Response(
            {'error': 'No tienes permiso para subir comprobantes a este pago'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Verificar que el método de pago sea transferencia
    if pago.metodo_pago.tipo != TipoMetodoPago.TRANSFERENCIA:
        return Response(
            {'error': 'Solo se pueden subir comprobantes para pagos por transferencia'},
            status=status.HTTP_400_BAD_REQUEST
        )

    from .serializers import PagoSubirComprobanteSerializer

    serializer = PagoSubirComprobanteSerializer(
        pago,
        data=request.data,
        partial=True
    )

    if serializer.is_valid():
        pago_actualizado = serializer.save()

        # Asignar el repartidor del pedido al pago (si existe)
        if pago_actualizado.pedido.repartidor:
            pago_actualizado.repartidor_asignado = pago_actualizado.pedido.repartidor
            pago_actualizado.comprobante_visible_repartidor = True
            pago_actualizado.save(update_fields=[
                'repartidor_asignado',
                'comprobante_visible_repartidor'
            ])

            # 🔔 Enviar notificación push al repartidor
            try:
                from notificaciones.services import notificar_comprobante_subido
                notificar_comprobante_subido(pago_actualizado)
            except Exception as e:
                # No fallar si la notificación falla, solo loguear
                import logging
                logger = logging.getLogger('pagos')
                logger.error(f'Error enviando notificación de comprobante: {e}')

        from .serializers import PagoConComprobanteSerializer
        response_serializer = PagoConComprobanteSerializer(
            pago_actualizado,
            context={'request': request}
        )

        return Response(
            {
                'message': 'Comprobante subido correctamente',
                'pago': response_serializer.data
            },
            status=status.HTTP_200_OK
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def ver_comprobante_repartidor(request, pago_id):
    """
    Endpoint para que el REPARTIDOR vea el comprobante de transferencia.
    """
    try:
        repartidor = request.user.repartidor
    except AttributeError:
        return Response(
            {'error': 'No tienes perfil de repartidor'},
            status=status.HTTP_403_FORBIDDEN
        )

    try:
        pago = Pago.objects.select_related(
            'pedido__cliente__user',
            'repartidor_asignado'
        ).get(pk=pago_id)
    except Pago.DoesNotExist:
        return Response(
            {'error': 'Pago no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Verificar que el repartidor sea el asignado a este pago
    if pago.repartidor_asignado != repartidor and not request.user.is_staff:
        return Response(
            {'error': 'No tienes permiso para ver este comprobante'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Verificar que el comprobante esté disponible
    if not pago.comprobante_visible_repartidor:
        return Response(
            {'error': 'El comprobante aún no está disponible'},
            status=status.HTTP_400_BAD_REQUEST
        )

    from .serializers import ComprobanteVerRepartidorSerializer

    serializer = ComprobanteVerRepartidorSerializer(
        pago,
        context={'request': request}
    )

    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def marcar_comprobante_visto(request, pago_id):
    """
    Endpoint para que el REPARTIDOR marque el comprobante como visto.
    """
    try:
        repartidor = request.user.repartidor
    except AttributeError:
        return Response(
            {'error': 'No tienes perfil de repartidor'},
            status=status.HTTP_403_FORBIDDEN
        )

    try:
        pago = Pago.objects.get(pk=pago_id)
    except Pago.DoesNotExist:
        return Response(
            {'error': 'Pago no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Verificar que el repartidor sea el asignado
    if pago.repartidor_asignado != repartidor:
        return Response(
            {'error': 'No tienes permiso para marcar este comprobante'},
            status=status.HTTP_403_FORBIDDEN
        )

    from .serializers import ComprobanteMarcarVistoSerializer

    serializer = ComprobanteMarcarVistoSerializer(
        data=request.data,
        context={'pago': pago}
    )

    if serializer.is_valid():
        pago_actualizado = serializer.save()

        from .serializers import ComprobanteVerRepartidorSerializer
        response_serializer = ComprobanteVerRepartidorSerializer(
            pago_actualizado,
            context={'request': request}
        )

        return Response(
            {
                'message': 'Comprobante marcado como visto',
                'pago': response_serializer.data
            },
            status=status.HTTP_200_OK
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def obtener_datos_bancarios_para_pago(request, pago_id):
    """
    Endpoint para que el CLIENTE obtenga los datos bancarios del repartidor
    para realizar la transferencia.
    """
    try:
        pago = Pago.objects.select_related(
            'pedido__cliente__user',
            'pedido__repartidor'
        ).get(pk=pago_id)
    except Pago.DoesNotExist:
        return Response(
            {'error': 'Pago no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Verificar que el usuario sea el dueño del pedido
    if not (pago.pedido.cliente.user == request.user or request.user.is_staff):
        return Response(
            {'error': 'No tienes permiso para ver estos datos'},
            status=status.HTTP_403_FORBIDDEN
        )

    # Verificar que haya un repartidor asignado
    if not pago.pedido.repartidor:
        return Response(
            {'error': 'Este pedido aún no tiene repartidor asignado'},
            status=status.HTTP_400_BAD_REQUEST
        )

    repartidor = pago.pedido.repartidor

    # Verificar que el repartidor tenga datos bancarios completos
    if not all([
        repartidor.banco_nombre,
        repartidor.banco_tipo_cuenta,
        repartidor.banco_numero_cuenta,
        repartidor.banco_titular,
        repartidor.banco_cedula_titular
    ]):
        return Response(
            {'error': 'El repartidor aún no ha configurado sus datos bancarios'},
            status=status.HTTP_400_BAD_REQUEST
        )

    datos_bancarios = {
        'banco': repartidor.banco_nombre,
        'tipo_cuenta': repartidor.banco_tipo_cuenta,
        'tipo_cuenta_display': repartidor.get_banco_tipo_cuenta_display(),
        'numero_cuenta': repartidor.banco_numero_cuenta,
        'titular': repartidor.banco_titular,
        'cedula_titular': repartidor.banco_cedula_titular,
        'verificado': repartidor.banco_verificado,
        'monto_a_transferir': str(pago.monto),
        'referencia_pago': str(pago.referencia),
    }

    return Response(datos_bancarios, status=status.HTTP_200_OK)
