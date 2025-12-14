# super_categorias/views.py
"""
Vistas de la API para Super Categorías
"""

from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.db import models

from .models import CategoriaSuper, ProveedorSuper, ProductoSuper
from .serializers import (
    CategoriaSuperSerializer,
    CategoriaSuperListSerializer,
    ProveedorSuperSerializer,
    ProveedorSuperListSerializer,
    ProductoSuperSerializer
)


class CategoriaSuperViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar Categorías Super

    list: Retorna todas las categorías activas
    retrieve: Retorna una categoría específica
    create: Crea una nueva categoría (Admin)
    update: Actualiza una categoría (Admin)
    delete: Elimina una categoría (Admin)
    """

    queryset = CategoriaSuper.objects.all()
    serializer_class = CategoriaSuperSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter, filters.SearchFilter]
    filterset_fields = ['activo', 'destacado']
    search_fields = ['nombre', 'descripcion']
    ordering_fields = ['orden', 'nombre', 'created_at']
    ordering = ['orden', 'nombre']

    def get_permissions(self):
        """
        Permisos:
        - list, retrieve: Todos (AllowAny)
        - create, update, destroy: Solo Admin
        """
        if self.action in ['list', 'retrieve', 'activas']:
            return [AllowAny()]
        return [IsAdminUser()]

    def get_serializer_class(self):
        """Usa serializer simplificado para listado"""
        if self.action == 'list':
            return CategoriaSuperListSerializer
        return CategoriaSuperSerializer

    def get_queryset(self):
        """
        Para usuarios normales, solo muestra categorías activas
        Para admin, muestra todas
        """
        queryset = super().get_queryset()

        # Si no es admin, filtrar solo activas
        if not (self.request.user and self.request.user.is_staff):
            queryset = queryset.filter(activo=True)

        return queryset

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def activas(self, request):
        """
        Endpoint: GET /super/categorias/activas/
        Retorna solo categorías activas ordenadas por orden
        """
        categorias = self.get_queryset().filter(activo=True)
        serializer = CategoriaSuperListSerializer(
            categorias,
            many=True,
            context={'request': request}
        )
        return Response(serializer.data)

    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def proveedores(self, request, pk=None):
        """
        Endpoint: GET /super/categorias/{id}/proveedores/
        Retorna proveedores de una categoría específica
        """
        categoria = self.get_object()
        proveedores = categoria.proveedores_super.filter(activo=True)

        serializer = ProveedorSuperListSerializer(
            proveedores,
            many=True,
            context={'request': request}
        )
        return Response(serializer.data)


class ProveedorSuperViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar Proveedores Super

    list: Retorna todos los proveedores activos
    retrieve: Retorna un proveedor específico con sus productos
    create: Crea un nuevo proveedor (Admin)
    update: Actualiza un proveedor (Admin)
    delete: Elimina un proveedor (Admin)
    """

    queryset = ProveedorSuper.objects.select_related('categoria').all()
    serializer_class = ProveedorSuperSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter, filters.SearchFilter]
    filterset_fields = ['categoria', 'activo', 'verificado']
    search_fields = ['nombre', 'descripcion', 'direccion']
    ordering_fields = ['calificacion', 'nombre', 'created_at']
    ordering = ['-calificacion', 'nombre']

    def get_permissions(self):
        """
        Permisos:
        - list, retrieve: Todos
        - create, update, destroy: Solo Admin
        """
        if self.action in ['list', 'retrieve', 'por_categoria', 'abiertos']:
            return [AllowAny()]
        return [IsAdminUser()]

    def get_serializer_class(self):
        """Usa serializer simplificado para listado"""
        if self.action == 'list':
            return ProveedorSuperListSerializer
        return ProveedorSuperSerializer

    def get_queryset(self):
        """Para usuarios normales, solo muestra proveedores activos"""
        queryset = super().get_queryset()

        if not (self.request.user and self.request.user.is_staff):
            queryset = queryset.filter(activo=True)

        return queryset

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def por_categoria(self, request):
        """
        Endpoint: GET /super/proveedores/por_categoria/?categoria={id}
        Retorna proveedores de una categoría específica
        """
        categoria_id = request.query_params.get('categoria')

        if not categoria_id:
            return Response(
                {'error': 'El parámetro "categoria" es requerido'},
                status=status.HTTP_400_BAD_REQUEST
            )

        proveedores = self.get_queryset().filter(
            categoria_id=categoria_id,
            activo=True
        )

        serializer = ProveedorSuperListSerializer(
            proveedores,
            many=True,
            context={'request': request}
        )
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def abiertos(self, request):
        """
        Endpoint: GET /super/proveedores/abiertos/
        Retorna proveedores que están abiertos actualmente
        """
        proveedores = self.get_queryset().filter(activo=True)
        proveedores_abiertos = [p for p in proveedores if p.esta_abierto]

        serializer = ProveedorSuperListSerializer(
            proveedores_abiertos,
            many=True,
            context={'request': request}
        )
        return Response(serializer.data)

    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def productos(self, request, pk=None):
        """
        Endpoint: GET /super/proveedores/{id}/productos/
        Retorna productos de un proveedor específico
        """
        proveedor = self.get_object()
        productos = proveedor.productos.filter(disponible=True)

        serializer = ProductoSuperSerializer(
            productos,
            many=True,
            context={'request': request}
        )
        return Response(serializer.data)


class ProductoSuperViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar Productos Super

    list: Retorna todos los productos disponibles
    retrieve: Retorna un producto específico
    create: Crea un nuevo producto (Admin)
    update: Actualiza un producto (Admin)
    delete: Elimina un producto (Admin)
    """

    queryset = ProductoSuper.objects.select_related('proveedor', 'proveedor__categoria').all()
    serializer_class = ProductoSuperSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter, filters.SearchFilter]
    filterset_fields = ['proveedor', 'disponible', 'destacado']
    search_fields = ['nombre', 'descripcion']
    ordering_fields = ['precio', 'nombre', 'created_at']
    ordering = ['-destacado', '-created_at']

    def get_permissions(self):
        """
        Permisos:
        - list, retrieve: Todos
        - create, update, destroy: Solo Admin
        """
        if self.action in ['list', 'retrieve', 'ofertas', 'destacados']:
            return [AllowAny()]
        return [IsAdminUser()]

    def get_queryset(self):
        """Para usuarios normales, solo muestra productos disponibles"""
        queryset = super().get_queryset()

        if not (self.request.user and self.request.user.is_staff):
            queryset = queryset.filter(disponible=True, stock__gt=0)

        return queryset

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def ofertas(self, request):
        """
        Endpoint: GET /super/productos/ofertas/
        Retorna productos en oferta
        """
        productos = self.get_queryset().filter(
            disponible=True,
            stock__gt=0,
            precio_anterior__isnull=False
        ).exclude(precio_anterior__lte=models.F('precio'))

        serializer = self.get_serializer(productos, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def destacados(self, request):
        """
        Endpoint: GET /super/productos/destacados/
        Retorna productos destacados
        """
        productos = self.get_queryset().filter(
            disponible=True,
            destacado=True,
            stock__gt=0
        )

        serializer = self.get_serializer(productos, many=True)
        return Response(serializer.data)
