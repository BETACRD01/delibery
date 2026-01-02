# productos/views.py
from rest_framework import viewsets, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from django.db.models import Q, F
from django.db import transaction 
from rest_framework import serializers
from decimal import Decimal

from .models import (
    Categoria, Producto, Promocion,
    Carrito, ItemCarrito
)
from .serializers import (
    CategoriaSerializer,
    ProductoListSerializer, ProductoDetalleSerializer,
    PromocionSerializer,
    CarritoSerializer, ItemCarritoSerializer,
    AgregarAlCarritoSerializer, ActualizarCantidadSerializer
)
from .serializers import ProviderProductoDetailSerializer, ProviderProductoSerializer
from pedidos.serializers import PedidoCreateSerializer, PedidoDetailSerializer
from pedidos.models import TipoPedido
from pagos.models import Pago, MetodoPago, TipoMetodoPago, EstadoPago as EstadoPagoPago
import logging

logger = logging.getLogger('productos')

logger = logging.getLogger('productos')

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class CategoriaViewSet(viewsets.ModelViewSet):
    queryset = Categoria.objects.filter(activo=True)
    serializer_class = CategoriaSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        serializer.save(activo=True)

class ProductoViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [AllowAny]
    pagination_class = StandardResultsSetPagination  
    
    def get_queryset(self):
        queryset = Producto.objects.filter(disponible=True)
        
        categoria_id = self.request.query_params.get('categoria_id')
        if categoria_id:
            queryset = queryset.filter(categoria_id=categoria_id)
        
        proveedor_id = self.request.query_params.get('proveedor_id')
        if proveedor_id:
            queryset = queryset.filter(proveedor_id=proveedor_id)
        
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(nombre__icontains=search) |
                Q(descripcion__icontains=search)
            )
        
        # Filtro rápido de ofertas: /api/productos/?solo_ofertas=true
        if self.request.query_params.get('solo_ofertas') == 'true':
            queryset = queryset.filter(precio_anterior__gt=F('precio'))

        return queryset.exclude(tiene_stock=True, stock__lte=0).select_related('categoria', 'proveedor')
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductoDetalleSerializer
        return ProductoListSerializer
    
    @action(detail=False, methods=['get'])
    def destacados(self, request):
        productos = self.get_queryset().filter(destacado=True)[:10]
        serializer = self.get_serializer(productos, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def ofertas(self, request):
        """Endpoint dedicado a ofertas: /api/productos/ofertas/"""
        # Filtramos donde el precio anterior existe Y es mayor al precio actual
        productos = self.get_queryset().filter(
            precio_anterior__isnull=False,
            precio_anterior__gt=F('precio')
        )

        # Si se solicita orden aleatorio
        if request.query_params.get('random') == 'true':
            productos = productos.order_by('?')[:20]

        serializer = self.get_serializer(productos, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def novedades(self, request):
        """
        Endpoint de novedades: /api/productos/novedades/
        Retorna productos recién agregados (ordenados por fecha de creación)
        """
        # Si se solicita orden aleatorio (rotación de productos)
        if request.query_params.get('random') == 'true':
            productos = self.get_queryset().order_by('?')[:20]
        else:
            productos = self.get_queryset().order_by('-created_at')[:20]

        serializer = self.get_serializer(productos, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='mas-populares')
    def mas_populares(self, request):
        """
        Endpoint de más populares: /api/productos/mas-populares/
        Retorna productos más vendidos y mejor calificados
        """
        # Si se solicita orden aleatorio (rotación de productos)
        if request.query_params.get('random') == 'true':
            # Filtra productos populares (con ventas > 0) y los mezcla aleatoriamente
            productos = self.get_queryset().filter(veces_vendido__gt=0).order_by('?')[:20]
        else:
            # Ordenamos por veces_vendido (descendente) y rating_promedio (descendente)
            productos = self.get_queryset().order_by('-veces_vendido', '-rating_promedio')[:20]

        serializer = self.get_serializer(productos, many=True)
        return Response(serializer.data)

class PromocionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PromocionSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        return Promocion.objects.filter(activa=True)


class ProviderPromocionViewSet(viewsets.ModelViewSet):
    """
    ViewSet para que los proveedores gestionen sus promociones.
    Permite crear, editar y eliminar promociones.
    """
    serializer_class = PromocionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Filtra promociones del proveedor autenticado
        return Promocion.objects.filter(
            proveedor__user=self.request.user
        ).order_by('-created_at')

    def perform_create(self, serializer):
        from proveedores.models import Proveedor
        try:
            proveedor = Proveedor.objects.get(user=self.request.user)
            serializer.save(proveedor=proveedor)
        except Proveedor.DoesNotExist:
            raise serializers.ValidationError("Usuario no es proveedor")

    def perform_update(self, serializer):
        serializer.save()

    def perform_destroy(self, instance):
        instance.delete()

class ProviderProductoViewSet(viewsets.ModelViewSet):
    """
    ViewSet exclusivo para que los proveedores gestionen sus productos.
    """
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Filtra productos donde el proveedor es el usuario actual
        # Se asume que Proveedor.user es el usuario logueado
        return Producto.objects.filter(
            proveedor__user=self.request.user
        ).select_related('categoria', 'proveedor').order_by('-created_at')
    
    def get_serializer_class(self):
        if self.action in ['retrieve', 'update', 'partial_update']:
            return ProviderProductoDetailSerializer
        if self.action == 'create':
            return ProviderProductoSerializer
        return ProductoListSerializer 

    def perform_create(self, serializer):
        from proveedores.models import Proveedor
        try:
            proveedor = Proveedor.objects.get(user=self.request.user)
            serializer.save(proveedor=proveedor)
        except Proveedor.DoesNotExist:
            raise serializers.ValidationError("Usuario no es proveedor")

    @action(detail=True, methods=['get'])
    def reviews(self, request, pk=None):
        """
        Las calificaciones de productos individuales fueron eliminadas.
        Ahora solo se califican proveedores.
        Retorna lista vacía por compatibilidad con versiones anteriores.
        """
        # Retornar respuesta paginada vacía
        return Response({'results': [], 'count': 0, 'next': None, 'previous': None})
            
    @action(detail=True, methods=['get'])
    def ratings(self, request, pk=None):
        """
        Las calificaciones de productos individuales fueron eliminadas.
        Ahora solo se califican proveedores.
        Retorna lista vacía por compatibilidad con versiones anteriores.
        """
        # Retornar respuesta paginada vacía
        return Response({'results': [], 'count': 0, 'next': None, 'previous': None})

    @action(detail=False, methods=['get'])
    def estadisticas(self, request):
        """
        Endpoint para obtener estadísticas de ventas del proveedor.
        GET /api/productos/provider/products/estadisticas/
        """
        from django.db.models import Sum, Count, Avg
        from django.utils import timezone
        from datetime import timedelta
        from pedidos.models import ItemPedido, Pedido, EstadoPedido

        # Obtener productos del proveedor
        productos = self.get_queryset()

        # Calcular ventas totales y productos top
        top_productos = []
        for producto in productos[:10]:  # Top 10 productos
            items = ItemPedido.objects.filter(
                producto=producto,
                pedido__estado__in=[EstadoPedido.ENTREGADO, EstadoPedido.EN_CAMINO]
            )
            total_vendido = items.aggregate(total=Sum('cantidad'))['total'] or 0
            ingresos = items.aggregate(
                ingresos=Sum(F('cantidad') * F('precio_unitario'))
            )['ingresos'] or Decimal('0')

            top_productos.append({
                'producto_id': producto.id,
                'nombre': producto.nombre,
                'cantidad_vendida': total_vendido,
                'ingresos': float(ingresos),
                'imagen_url': _build_media_url(producto.imagen, request) if producto.imagen else producto.imagen_url,
            })

        # Ordenar por ingresos
        top_productos.sort(key=lambda x: x['ingresos'], reverse=True)

        # Ventas por día (últimos 30 días)
        hoy = timezone.now().date()
        hace_30_dias = hoy - timedelta(days=30)

        ventas_por_dia = []
        for i in range(30):
            fecha = hace_30_dias + timedelta(days=i)
            items = ItemPedido.objects.filter(
                producto__proveedor__user=request.user,
                pedido__estado__in=[EstadoPedido.ENTREGADO, EstadoPedido.EN_CAMINO],
                pedido__created_at__date=fecha
            )
            ingresos = items.aggregate(
                total=Sum(F('cantidad') * F('precio_unitario'))
            )['total'] or Decimal('0')

            ventas_por_dia.append({
                'fecha': fecha.isoformat(),
                'ingresos': float(ingresos),
            })

        # Totales generales
        total_items = ItemPedido.objects.filter(
            producto__proveedor__user=request.user,
            pedido__estado__in=[EstadoPedido.ENTREGADO, EstadoPedido.EN_CAMINO]
        )

        resumen = {
            'total_productos_vendidos': total_items.aggregate(total=Sum('cantidad'))['total'] or 0,
            'ingresos_totales': float(
                total_items.aggregate(total=Sum(F('cantidad') * F('precio_unitario')))['total'] or Decimal('0')
            ),
            'pedidos_completados': Pedido.objects.filter(
                items__producto__proveedor__user=request.user,
                estado=EstadoPedido.ENTREGADO
            ).distinct().count(),
        }

        return Response({
            'resumen': resumen,
            'top_productos': top_productos[:5],
            'ventas_por_dia': ventas_por_dia,
        })

# ... (El resto de vistas del Carrito se mantiene igual, no necesita cambios) ...
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def ver_carrito(request):
    try:
        carrito = Carrito.objects.prefetch_related('items__producto').get(usuario=request.user)
    except Carrito.DoesNotExist:
        carrito = Carrito.objects.create(usuario=request.user)
    return Response(CarritoSerializer(carrito).data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def agregar_al_carrito(request):
    carrito, _ = Carrito.objects.get_or_create(usuario=request.user)
    serializer = AgregarAlCarritoSerializer(data=request.data, context={'carrito_instance': carrito})
    serializer.is_valid(raise_exception=True)
    
    producto = serializer.instance 
    cantidad = serializer.validated_data['cantidad']
    
    item, created = ItemCarrito.objects.get_or_create(
        carrito=carrito, producto=producto,
        defaults={'cantidad': cantidad, 'precio_unitario': producto.precio}
    )
    if not created:
        item.cantidad += cantidad
        item.save()
    
    return Response(CarritoSerializer(carrito).data)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def actualizar_cantidad(request, item_id):
    serializer = ActualizarCantidadSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    try:
        item = ItemCarrito.objects.get(id=item_id, carrito__usuario=request.user)
    except ItemCarrito.DoesNotExist:
        return Response({'error': 'Item no encontrado'}, status=404)
    
    nueva = serializer.validated_data['cantidad']
    if item.producto.tiene_stock and item.producto.stock < nueva:
        return Response({'error': 'Stock insuficiente'}, status=400)
    
    item.cantidad = nueva
    item.save()
    return Response(CarritoSerializer(item.carrito).data)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remover_del_carrito(request, item_id):
    try:
        item = ItemCarrito.objects.get(id=item_id, carrito__usuario=request.user)
        carrito = item.carrito
        item.delete()
        return Response(CarritoSerializer(carrito).data)
    except ItemCarrito.DoesNotExist:
        return Response({'error': 'Item no encontrado'}, status=404)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def limpiar_carrito(request):
    try:
        carrito = Carrito.objects.get(usuario=request.user)
        carrito.limpiar()
        return Response(CarritoSerializer(carrito).data)
    except Carrito.DoesNotExist:
        return Response({'message': 'Carrito vacío'}, status=404)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@transaction.atomic
def checkout(request):
    """
    Crea UN SOLO pedido global que contiene todos los productos del carrito,
    independientemente del proveedor. El desglose interno se maneja en los items.
    """
    try:
        carrito = Carrito.objects.prefetch_related('items__producto__proveedor').get(usuario=request.user)
    except Carrito.DoesNotExist:
        return Response({'error': 'No tienes un carrito'}, status=404)

    if not carrito.items.exists():
        return Response({'error': 'Carrito vacío'}, status=400)

    # Validar perfil del cliente
    if not hasattr(request.user, 'perfil'):
        return Response({'error': 'Perfil de cliente no encontrado'}, status=400)

    direccion = request.data.get('direccion_entrega')
    if not direccion:
        return Response({'error': 'Falta dirección'}, status=400)

    # Validar que todos los productos tengan proveedor asignado
    for item in carrito.items.all():
        if item.producto.proveedor_id is None:
            return Response({'error': f'El producto {item.producto.nombre} no tiene proveedor asignado'}, status=400)

    # Extraer datos de logística (opcionales)
    datos_envio = request.data.get('datos_envio')
    total_envio = Decimal(str(datos_envio.get('total_envio'))) if isinstance(datos_envio, dict) and datos_envio.get('total_envio') is not None else Decimal('0')

    # Preparar payload para UN SOLO pedido
    items_payload = []
    subtotal_items = Decimal('0.00')
    proveedores_involucrados = set()

    for item in carrito.items.all():
        precio_unit = Decimal(str(item.precio_unitario or item.producto.precio))
        subtotal_items += precio_unit * item.cantidad
        proveedores_involucrados.add(item.producto.proveedor_id)

        items_payload.append({
            'producto': item.producto_id,
            'cantidad': item.cantidad,
            'precio_unitario': str(precio_unit),
        })

    # El pedido NO tiene un proveedor específico asignado inicialmente
    # Los proveedores se determinan desde los items
    payload = {
        'tipo': TipoPedido.PROVEEDOR,
        'proveedor': None,  # Ningún proveedor específico - es multi-proveedor
        'direccion_entrega': direccion,
        'metodo_pago': request.data.get('metodo_pago', 'efectivo'),
        'items': items_payload,
        'total': str(subtotal_items + total_envio),
        'cargo_extra': '0',
    }

    # Agregar instrucciones de entrega si existen
    instrucciones = request.data.get('instrucciones_entrega')
    if instrucciones:
        payload['instrucciones_entrega'] = instrucciones

    # Agregar latitud y longitud si existen
    lat_destino = request.data.get('latitud_destino')
    lng_destino = request.data.get('longitud_destino')
    if lat_destino is not None:
        payload['latitud_destino'] = lat_destino
    if lng_destino is not None:
        payload['longitud_destino'] = lng_destino

    # Agregar datos de envío si existen
    if isinstance(datos_envio, dict):
        payload['datos_envio'] = datos_envio

    serializer = PedidoCreateSerializer(
        data=payload,
        context={'request': request}
    )
    serializer.is_valid(raise_exception=True)
    pedido = serializer.save()

    # Crear el registro de Pago si aún no existe (necesario para transferencias)
    try:
        metodo_raw = (payload.get('metodo_pago') or '').strip().lower() or TipoMetodoPago.EFECTIVO
        metodo_normalizado = metodo_raw if metodo_raw in dict(TipoMetodoPago.choices) else TipoMetodoPago.EFECTIVO

        metodo_pago_obj, _ = MetodoPago.objects.get_or_create(
            tipo=metodo_normalizado,
            defaults={
                'nombre': metodo_normalizado.replace('_', ' ').title(),
                'descripcion': 'Generado automáticamente desde checkout',
                'requiere_verificacion': metodo_normalizado == TipoMetodoPago.TRANSFERENCIA,
                'activo': True,
            }
        )

        if not hasattr(pedido, 'pago'):
            Pago.objects.create(
                pedido=pedido,
                metodo_pago=metodo_pago_obj,
                monto=pedido.total,
                estado=EstadoPagoPago.PENDIENTE
            )
    except Exception as e:
        logger.warning(f"No se pudo crear el registro de pago para el pedido #{pedido.id}: {e}")

    # Limpiar carrito después de crear el pedido
    carrito.limpiar()

    return Response(
        {
            'message': 'Pedido creado exitosamente',
            'pedido': PedidoDetailSerializer(pedido, context={'request': request}).data,
            'total_proveedores': len(proveedores_involucrados),
            'proveedores_involucrados': list(proveedores_involucrados),
        },
        status=201
    )
