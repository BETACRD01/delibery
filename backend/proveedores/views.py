# -*- coding: utf-8 -*-
# Proveedores/views.py - VIEWSETS PARA PROVEEDORES Y REPARTIDORES
"""
ViewSets actualizados para permitir edición completa de Proveedores y Repartidores

CAMBIOS EN ESTA VERSIÓN:
- NUEVO: Acción editar_mi_perfil() para editar datos del negocio (nombre, dirección, horarios, etc.)
- editar_mi_contacto() para editar datos de contacto del usuario
- mi_proveedor() para obtener el proveedor del usuario autenticado
"""

from rest_framework import viewsets, status, filters, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import serializers 
import logging
from django.db.models import Q
from productos.models import Producto

from authentication.models import User
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from .models import AccionAdministrativa
from .serializers import (
    # Proveedores
    ProveedorListSerializer,
    ProveedorDetalleSerializer,
    ProveedorEditarSerializer,
    ProveedorEditarContactoSerializer,
    VerificarProveedorSerializer,
    # Repartidores
    RepartidorListSerializer,
    RepartidorDetalleSerializer,
    RepartidorEditarSerializer,
    RepartidorEditarContactoSerializer,
    VerificarRepartidorSerializer,
    ProductoProveedorSerializer
)
from .permissions import (
    EsAdministrador,
    PuedeGestionarProveedores,
    PuedeGestionarRepartidores,
    AdministradorActivo,
    obtener_perfil_admin,
)
from productos.models import Promocion 
from .serializers import PromocionProveedorSerializer 

logger = logging.getLogger('administradores')


# ════════════════════════════════════════════════════════════════════════════
# BLOQUE 0: VIEWSET PÚBLICO PARA CONSULTAR PROVEEDORES
# ════════════════════════════════════════════════════════════════════════════

class ProveedorViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet PÚBLICO para consultar proveedores
    Incluye acciones para usuarios autenticados con rol proveedor:
    - mi_proveedor: obtener datos del proveedor
    - editar_mi_perfil: editar datos del negocio
    - editar_mi_contacto: editar datos de contacto
    """
    
    permission_classes = [permissions.AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['tipo_proveedor', 'ciudad', 'verificado']
    search_fields = ['nombre', 'descripcion', 'ciudad']
    ordering_fields = ['nombre', 'created_at']
    ordering = ['nombre']
    
    def get_queryset(self):
        """Retorna solo proveedores activos y verificados (público)"""
        if getattr(self, 'swagger_fake_view', False):
            return Proveedor.objects.none()

        return Proveedor.objects.filter(
            activo=True,
            verificado=True,
            deleted_at__isnull=True
        ).select_related('user')
    
    def get_serializer_class(self):
        """Selecciona serializer según acción"""
        if self.action == 'list':
            return ProveedorListSerializer
        if self.action == 'editar_mi_perfil':
            return ProveedorEditarSerializer
        return ProveedorDetalleSerializer
    
    def list(self, request, *args, **kwargs):
        """GET /api/proveedores/ - Listar proveedores"""
        return super().list(request, *args, **kwargs)
    
    def retrieve(self, request, *args, **kwargs):
        """GET /api/proveedores/{id}/ - Detalle de proveedor"""
        return super().retrieve(request, *args, **kwargs)
    
    # ════════════════════════════════════════════════════════════════════════
    # ACCIÓN: MI PROVEEDOR (Usuario autenticado)
    # ════════════════════════════════════════════════════════════════════════
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def mi_proveedor(self, request):
        """
        GET /api/proveedores/mi_proveedor/
        Obtiene el proveedor vinculado al usuario autenticado
        
        Requiere:
        - Usuario autenticado
        - rol_activo = 'proveedor'
        - Tener un Proveedor vinculado
        
        Returns:
        - 200: Datos del proveedor (ProveedorDetalleSerializer)
        - 403: Si el usuario no tiene rol de proveedor activo
        - 404: Si no tiene proveedor vinculado
        """
        user = request.user
        
        if user.rol_activo != 'proveedor':
            logger.warning(
                f"Usuario {user.email} intentó acceder a mi_proveedor "
                f"con rol_activo={user.rol_activo}"
            )
            return Response(
                {
                    'error': 'No tienes rol de proveedor activo',
                    'rol_actual': user.rol_activo,
                    'mensaje': 'Cambia tu rol activo a proveedor para acceder'
                },
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            proveedor = Proveedor.objects.select_related('user').get(
                user=user,
                deleted_at__isnull=True
            )
        except Proveedor.DoesNotExist:
            logger.warning(
                f"Usuario {user.email} con rol proveedor no tiene "
                f"Proveedor vinculado en la base de datos. Restableciendo a Cliente."
            )
            # Auto-corregir inconsistencia
            user.rol_activo = 'cliente'
            user.save(update_fields=['rol_activo'])

            return Response(
                {
                    'error': 'No se encontró tu perfil de proveedor. Se ha restablecido tu cuenta a modo Cliente.',
                    'action': 'ROLE_RESET'
                },
                status=status.HTTP_404_NOT_FOUND
            )
        
        logger.info(f"Proveedor {proveedor.nombre} consultado por {user.email}")
        serializer = ProveedorDetalleSerializer(proveedor)
        return Response(serializer.data)
    
    # ════════════════════════════════════════════════════════════════════════
    # ACCIÓN: EDITAR MI PERFIL (Datos del negocio)
    # ════════════════════════════════════════════════════════════════════════
    
    @action(detail=False, methods=['patch'], permission_classes=[IsAuthenticated])
    def editar_mi_perfil(self, request):
        """
        PATCH /api/proveedores/editar_mi_perfil/
        Edita los datos del negocio del proveedor autenticado
        
        Body (todos opcionales):
        - nombre: Nombre del negocio
        - ruc: RUC del negocio
        - tipo_proveedor: restaurante, farmacia, supermercado, tienda, otro
        - descripcion: Descripción del negocio
        - direccion: Dirección física
        - ciudad: Ciudad
        - horario_apertura: HH:MM:SS
        - horario_cierre: HH:MM:SS
        
        Returns:
        - 200: Proveedor actualizado
        - 400: Datos inválidos
        - 403: Sin rol de proveedor
        - 404: Sin proveedor vinculado
        """
        user = request.user
        
        # Verificar rol
        if user.rol_activo != 'proveedor':
            logger.warning(
                f"Usuario {user.email} intentó editar perfil "
                f"con rol_activo={user.rol_activo}"
            )
            return Response(
                {
                    'error': 'No tienes rol de proveedor activo',
                    'rol_actual': user.rol_activo,
                    'mensaje': 'Cambia tu rol activo a proveedor para editar'
                },
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Buscar proveedor
        try:
            proveedor = Proveedor.objects.select_related('user').get(
                user=user,
                deleted_at__isnull=True
            )
        except Proveedor.DoesNotExist:
            return Response(
                {'error': 'No tienes un proveedor vinculado'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Campos permitidos para edición
        campos_permitidos = [
            'nombre', 'ruc', 'tipo_proveedor', 'descripcion',
            'direccion', 'ciudad', 'horario_apertura', 'horario_cierre',
            'latitud', 'longitud', 'telefono','logo',
        ]
        
        # Filtrar solo campos permitidos
        datos_filtrados = {
            k: v for k, v in request.data.items() 
            if k in campos_permitidos
        }
        
        if not datos_filtrados:
            return Response(
                {
                    'error': 'No se proporcionaron datos válidos para actualizar',
                    'campos_permitidos': campos_permitidos
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validar con serializer
        serializer = ProveedorEditarSerializer(
            proveedor,
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
        proveedor.refresh_from_db()
        
        logger.info(
            f"Proveedor {proveedor.nombre} actualizó perfil: "
            f"{list(datos_filtrados.keys())}"
        )
        
        return Response({
            'message': 'Perfil del negocio actualizado exitosamente',
            'campos_actualizados': list(datos_filtrados.keys()),
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        })
    
    # ════════════════════════════════════════════════════════════════════════
    # ACCIÓN: EDITAR MI CONTACTO (Datos del usuario)
    # ════════════════════════════════════════════════════════════════════════
    
    @action(detail=False, methods=['patch'], permission_classes=[IsAuthenticated])
    def editar_mi_contacto(self, request):
        """
        PATCH /api/proveedores/editar_mi_contacto/
        Edita los datos de contacto del usuario vinculado al proveedor
        
        Body (todos opcionales, al menos uno requerido):
        - email: Nuevo email
        - first_name: Nuevo nombre
        - last_name: Nuevo apellido
        
        Returns:
        - 200: Proveedor actualizado
        - 400: Datos inválidos
        - 403: Sin rol de proveedor
        - 404: Sin proveedor vinculado
        """
        user = request.user
        
        # Verificar rol
        if user.rol_activo != 'proveedor':
            return Response(
                {'error': 'No tienes rol de proveedor activo'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Buscar proveedor
        try:
            proveedor = Proveedor.objects.select_related('user').get(
                user=user,
                deleted_at__isnull=True
            )
        except Proveedor.DoesNotExist:
            return Response(
                {'error': 'No tienes un proveedor vinculado'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Validar datos con el serializer
        serializer = ProveedorEditarContactoSerializer(
            data=request.data,
            context={'usuario': user}
        )
        serializer.is_valid(raise_exception=True)
        
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
            f"Proveedor {proveedor.nombre} actualizó contacto: "
            f"{', '.join(campos_actualizados)}"
        )
        
        # Refrescar proveedor para obtener datos actualizados
        proveedor.refresh_from_db()
        
        return Response({
            'message': 'Datos de contacto actualizados exitosamente',
            'campos_actualizados': campos_actualizados,
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        })
    
    # ════════════════════════════════════════════════════════════════════════
    # ACCIONES PÚBLICAS EXISTENTES
    # ════════════════════════════════════════════════════════════════════════
    
    @action(detail=False, methods=['get'])
    def activos(self, request):
        """GET /api/proveedores/activos/ - Solo proveedores activos"""
        proveedores = self.get_queryset()
        serializer = self.get_serializer(proveedores, many=True)
        
        return Response({
            'total': proveedores.count(),
            'proveedores': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def abiertos(self, request):
        """GET /api/proveedores/abiertos/ - Proveedores abiertos ahora"""
        proveedores = self.get_queryset()
        abiertos = []
        
        for proveedor in proveedores:
            if hasattr(proveedor, 'esta_abierto') and proveedor.esta_abierto():
                abiertos.append(proveedor)
        
        serializer = self.get_serializer(abiertos, many=True)
        
        return Response({
            'total': len(abiertos),
            'proveedores': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def por_tipo(self, request):
        """GET /api/proveedores/por_tipo/?tipo=restaurante"""
        tipo = request.query_params.get('tipo')
        
        if not tipo:
            return Response({
                'error': 'Debes proporcionar el parámetro tipo',
                'tipos_validos': ['restaurante', 'farmacia', 'supermercado', 'tienda', 'otro']
            }, status=status.HTTP_400_BAD_REQUEST)
        
        proveedores = self.get_queryset().filter(tipo_proveedor=tipo)
        serializer = self.get_serializer(proveedores, many=True)
        
        return Response({
            'total': proveedores.count(),
            'tipo': tipo,
            'proveedores': serializer.data
        })


# ════════════════════════════════════════════════════════════════════════════
# BLOQUE 1: HELPER - REGISTRAR ACCIONES
# ════════════════════════════════════════════════════════════════════════════

def registrar_accion_admin(request, tipo_accion, descripcion, **kwargs):
    """Helper para registrar acciones administrativas"""
    try:
        if not request.user.is_authenticated:
            return None
            
        admin = obtener_perfil_admin(request.user)
        if not admin:
            return None

        ip_address = request.META.get('REMOTE_ADDR')
        user_agent = request.META.get('HTTP_USER_AGENT', '')

        return AccionAdministrativa.registrar_accion(
            administrador=admin,
            tipo_accion=tipo_accion,
            descripcion=descripcion,
            ip_address=ip_address,
            user_agent=user_agent,
            **kwargs
        )
    except Exception as e:
        logger.error(f"Error registrando acción: {e}")
        return None


# ════════════════════════════════════════════════════════════════════════════
# BLOQUE 2: VIEWSET GESTIÓN DE PROVEEDORES (ADMIN)
# ════════════════════════════════════════════════════════════════════════════

class GestionProveedoresViewSet(viewsets.ModelViewSet):
    """
    ViewSet para GESTIÓN COMPLETA de Proveedores (Admin)
    """
    
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeGestionarProveedores
    ]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['verificado', 'tipo_proveedor', 'activo']
    search_fields = ['nombre', 'user__email', 'telefono']
    ordering_fields = ['created_at', 'nombre']
    ordering = ['-created_at']

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return Proveedor.objects.none()

        return Proveedor.objects.select_related('user').filter(
            deleted_at__isnull=True
        )

    def get_serializer_class(self):
        if self.action == 'list':
            return ProveedorListSerializer
        elif self.action in ['update', 'partial_update']:
            return ProveedorEditarSerializer
        elif self.action == 'editar_contacto':
            return ProveedorEditarContactoSerializer
        return ProveedorDetalleSerializer

    # -------- MÉTODOS ESTÁNDAR --------

    def retrieve(self, request, *args, **kwargs):
        proveedor = self.get_object()
        serializer = self.get_serializer(proveedor)
        return Response(serializer.data)

    def update(self, request, *args, **kwargs):
        partial = False
        proveedor = self.get_object()

        serializer = self.get_serializer(
            proveedor,
            data=request.data,
            partial=partial
        )
        serializer.is_valid(raise_exception=True)

        self.perform_update(serializer)

        registrar_accion_admin(
            request,
            'editar_proveedor',
            f"Proveedor editado: {proveedor.nombre}",
            modelo_afectado='Proveedor',
            objeto_id=str(proveedor.id),
            datos_nuevos=serializer.data
        )

        return Response({
            'message': 'Proveedor editado exitosamente',
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        }, status=status.HTTP_200_OK)

    def partial_update(self, request, *args, **kwargs):
        partial = True
        proveedor = self.get_object()

        serializer = self.get_serializer(
            proveedor,
            data=request.data,
            partial=partial
        )
        serializer.is_valid(raise_exception=True)

        self.perform_update(serializer)

        registrar_accion_admin(
            request,
            'editar_proveedor',
            f"Información actualizada: {proveedor.nombre}",
            modelo_afectado='Proveedor',
            objeto_id=str(proveedor.id),
            datos_nuevos=serializer.data
        )

        return Response({
            'message': 'Proveedor actualizado exitosamente',
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        }, status=status.HTTP_200_OK)

    # -------- ACCIONES CUSTOM --------

    @action(detail=True, methods=['patch'])
    def editar_contacto(self, request, pk=None):
        proveedor = self.get_object()
        usuario = proveedor.user

        serializer = self.get_serializer(
            data=request.data,
            context={'usuario': usuario}
        )
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data.get('email')
        first_name = serializer.validated_data.get('first_name')
        last_name = serializer.validated_data.get('last_name')

        if email: usuario.email = email
        if first_name: usuario.first_name = first_name
        if last_name: usuario.last_name = last_name
        usuario.save()

        registrar_accion_admin(
            request,
            'editar_proveedor_contacto',
            f"Contacto editado: {proveedor.nombre}",
            modelo_afectado='User',
            objeto_id=str(usuario.id),
            datos_nuevos={'email': usuario.email}
        )

        return Response({
            'message': 'Contacto editado exitosamente',
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def verificar(self, request, pk=None):
        proveedor = self.get_object()
        serializer = VerificarProveedorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verificado = serializer.validated_data['verificado']
        motivo = serializer.validated_data.get('motivo', '')

        proveedor.verificado = verificado
        proveedor.save(update_fields=['verificado', 'updated_at'])

        if not verificado and hasattr(proveedor, 'activo'):
            proveedor.activo = False
            proveedor.save(update_fields=['activo'])

        accion = 'verificar_proveedor' if verificado else 'rechazar_proveedor'
        registrar_accion_admin(
            request,
            accion,
            f"Proveedor {'verificado' if verificado else 'rechazado'}: {proveedor.nombre}",
            modelo_afectado='Proveedor',
            objeto_id=str(proveedor.id)
        )

        return Response({
            'message': f"Proveedor {'verificado' if verificado else 'rechazado'} exitosamente",
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        })

    @action(detail=True, methods=['post'])
    def desactivar(self, request, pk=None):
        proveedor = self.get_object()
        
        if not proveedor.activo:
            return Response(
                {'error': 'El proveedor ya está desactivado'},
                status=status.HTTP_400_BAD_REQUEST
            )

        proveedor.activo = False
        proveedor.save(update_fields=['activo', 'updated_at'])

        registrar_accion_admin(
            request,
            'desactivar_proveedor',
            f"Proveedor desactivado: {proveedor.nombre}",
            modelo_afectado='Proveedor',
            objeto_id=str(proveedor.id)
        )

        return Response({
            'message': 'Proveedor desactivado exitosamente',
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        })

    @action(detail=True, methods=['post'])
    def activar(self, request, pk=None):
        proveedor = self.get_object()

        if proveedor.activo:
            return Response(
                {'error': 'El proveedor ya está activo'},
                status=status.HTTP_400_BAD_REQUEST
            )

        proveedor.activo = True
        proveedor.save(update_fields=['activo', 'updated_at'])

        registrar_accion_admin(
            request,
            'activar_proveedor',
            f"Proveedor activado: {proveedor.nombre}",
            modelo_afectado='Proveedor',
            objeto_id=str(proveedor.id)
        )

        return Response({
            'message': 'Proveedor activado exitosamente',
            'proveedor': ProveedorDetalleSerializer(proveedor).data
        })

    @action(detail=False, methods=["get"], url_path="pendientes")
    def pendientes(self, request):
        """Lista proveedores con estado 'verificado=False'."""
        queryset = self.get_queryset()
        queryset = queryset.filter(verificado=False)
        queryset = self.filter_queryset(queryset)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'total': queryset.count(),
            'proveedores': serializer.data
        })


# ════════════════════════════════════════════════════════════════════════════
# BLOQUE 3: VIEWSET GESTIÓN DE REPARTIDORES (ADMIN)
# ════════════════════════════════════════════════════════════════════════════

class GestionRepartidoresViewSet(viewsets.ModelViewSet):
    """
    ViewSet para GESTIÓN COMPLETA de Repartidores
    """
    
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeGestionarRepartidores
    ]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['verificado', 'estado', 'activo']
    search_fields = ['user__email', 'user__first_name', 'user__last_name', 'cedula', 'telefono']
    ordering_fields = ['created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        if getattr(self, 'swagger_fake_view', False):
            return Repartidor.objects.none()

        return Repartidor.objects.select_related('user').filter(
            deleted_at__isnull=True
        )

    def get_serializer_class(self):
        if self.action == 'list':
            return RepartidorListSerializer
        elif self.action in ['update', 'partial_update']:
            return RepartidorEditarSerializer
        elif self.action == 'editar_contacto':
            return RepartidorEditarContactoSerializer
        return RepartidorDetalleSerializer

    # -------- MÉTODOS ESTÁNDAR --------

    def retrieve(self, request, *args, **kwargs):
        repartidor = self.get_object()
        serializer = self.get_serializer(repartidor)
        return Response(serializer.data)

    def update(self, request, *args, **kwargs):
        partial = False
        repartidor = self.get_object()

        serializer = self.get_serializer(
            repartidor,
            data=request.data,
            partial=partial
        )
        serializer.is_valid(raise_exception=True)

        self.perform_update(serializer)

        registrar_accion_admin(
            request,
            'editar_repartidor',
            f"Repartidor editado: {repartidor.user.get_full_name()}",
            modelo_afectado='Repartidor',
            objeto_id=str(repartidor.id),
            datos_nuevos=serializer.data
        )

        return Response({
            'message': 'Repartidor editado exitosamente',
            'repartidor': RepartidorDetalleSerializer(repartidor).data
        }, status=status.HTTP_200_OK)

    def partial_update(self, request, *args, **kwargs):
        partial = True
        repartidor = self.get_object()

        serializer = self.get_serializer(
            repartidor,
            data=request.data,
            partial=partial
        )
        serializer.is_valid(raise_exception=True)

        self.perform_update(serializer)

        registrar_accion_admin(
            request,
            'editar_repartidor',
            f"Información actualizada: {repartidor.user.get_full_name()}",
            modelo_afectado='Repartidor',
            objeto_id=str(repartidor.id),
            datos_nuevos=serializer.data
        )

        return Response({
            'message': 'Repartidor actualizado exitosamente',
            'repartidor': RepartidorDetalleSerializer(repartidor).data
        }, status=status.HTTP_200_OK)

    # -------- ACCIONES CUSTOM --------

    @action(detail=True, methods=['patch'])
    def editar_contacto(self, request, pk=None):
        repartidor = self.get_object()
        usuario = repartidor.user

        serializer = self.get_serializer(
            data=request.data,
            context={'usuario': usuario}
        )
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data.get('email')
        first_name = serializer.validated_data.get('first_name')
        last_name = serializer.validated_data.get('last_name')

        if email: usuario.email = email
        if first_name: usuario.first_name = first_name
        if last_name: usuario.last_name = last_name
        usuario.save()

        registrar_accion_admin(
            request,
            'editar_repartidor_contacto',
            f"Contacto editado: {repartidor.user.get_full_name()}",
            modelo_afectado='User',
            objeto_id=str(usuario.id),
            datos_nuevos={'email': usuario.email}
        )

        return Response({
            'message': 'Contacto editado exitosamente',
            'repartidor': RepartidorDetalleSerializer(repartidor).data
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def verificar(self, request, pk=None):
        repartidor = self.get_object()
        serializer = VerificarRepartidorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verificado = serializer.validated_data['verificado']
        motivo = serializer.validated_data.get('motivo', '')

        repartidor.verificado = verificado
        repartidor.save(update_fields=['verificado', 'updated_at'])

        if not verificado and hasattr(repartidor, 'activo'):
            repartidor.activo = False
            repartidor.save(update_fields=['activo'])

        accion = 'verificar_repartidor' if verificado else 'rechazar_repartidor'
        registrar_accion_admin(
            request,
            accion,
            f"Repartidor {'verificado' if verificado else 'rechazado'}: {repartidor.user.get_full_name()}",
            modelo_afectado='Repartidor',
            objeto_id=str(repartidor.id)
        )

        return Response({
            'message': f"Repartidor {'verificado' if verificado else 'rechazado'} exitosamente",
            'repartidor': RepartidorDetalleSerializer(repartidor).data
        })

    @action(detail=True, methods=['post'])
    def desactivar(self, request, pk=None):
        repartidor = self.get_object()
        
        if not repartidor.activo:
            return Response(
                {'error': 'El repartidor ya está desactivado'},
                status=status.HTTP_400_BAD_REQUEST
            )

        repartidor.activo = False
        repartidor.save(update_fields=['activo', 'updated_at'])

        registrar_accion_admin(
            request,
            'desactivar_repartidor',
            f"Repartidor desactivado: {repartidor.user.get_full_name()}",
            modelo_afectado='Repartidor',
            objeto_id=str(repartidor.id)
        )

        return Response({
            'message': 'Repartidor desactivado exitosamente',
            'repartidor': RepartidorDetalleSerializer(repartidor).data
        })

    @action(detail=True, methods=['post'])
    def activar(self, request, pk=None):
        repartidor = self.get_object()

        if repartidor.activo:
            return Response(
                {'error': 'El repartidor ya está activo'},
                status=status.HTTP_400_BAD_REQUEST
            )

        repartidor.activo = True
        repartidor.save(update_fields=['activo', 'updated_at'])

        registrar_accion_admin(
            request,
            'activar_repartidor',
            f"Repartidor activado: {repartidor.user.get_full_name()}",
            modelo_afectado='Repartidor',
            objeto_id=str(repartidor.id)
        )

        return Response({
            'message': 'Repartidor activado exitosamente',
            'repartidor': RepartidorDetalleSerializer(repartidor).data
        })

    @action(detail=False, methods=['get'])
    def pendientes(self, request):
        """Lista repartidores pendientes de verificación."""
        if getattr(self, 'swagger_fake_view', False):
            return Repartidor.objects.none()
            
        queryset = self.get_queryset()
        queryset = queryset.filter(verificado=False)
        queryset = self.filter_queryset(queryset)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'total': queryset.count(),
            'repartidores': serializer.data
        })
        
# ============================================================================
# BLOQUE NUEVO: GESTIÓN DE INVENTARIO DEL PROVEEDOR
# ============================================================================
class MisProductosViewSet(viewsets.ModelViewSet):
    """
    ViewSet para que el PROVEEDOR gestione SU inventario.
    Endpoint: /api/proveedores/mis-productos/
    
    Seguridad:
    1. Filtra automáticamente por el proveedor logueado.
    2. Al crear, asigna el proveedor automáticamente.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = ProductoProveedorSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['categoria', 'disponible', 'tiene_stock']
    search_fields = ['nombre', 'descripcion']
    ordering_fields = ['nombre', 'precio', 'stock', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Retorna SOLO los productos que pertenecen al proveedor autenticado.
        """
        user = self.request.user
        
        # 1. Validar que el usuario tenga rol proveedor
        if getattr(user, 'rol_activo', '') != 'proveedor':
            return Producto.objects.none()
            
        try:
            # 2. Buscar el perfil de proveedor vinculado
            proveedor = Proveedor.objects.get(user=user)
            return Producto.objects.filter(proveedor=proveedor).select_related('categoria')
        except Proveedor.DoesNotExist:
            return Producto.objects.none()

    def perform_create(self, serializer):
        """
        Al crear un producto, asignamos automáticamente el proveedor dueño.
        """
        user = self.request.user
        
        if getattr(user, 'rol_activo', '') != 'proveedor':
            raise serializers.ValidationError("Debes estar en modo Proveedor para crear productos.")
            
        try:
            proveedor = Proveedor.objects.get(user=user)
            serializer.save(proveedor=proveedor)
            
            logger.info(f"Producto creado por {proveedor.nombre}: {serializer.validated_data.get('nombre')}")
            
        except Proveedor.DoesNotExist:
            raise serializers.ValidationError("No tienes un perfil de proveedor vinculado. Contacta a soporte.")

    @action(detail=True, methods=['patch'])
    def toggle_disponible(self, request, pk=None):
        """
        Acción rápida: Activar/Desactivar producto (ej. se acabó el ingrediente)
        """
        producto = self.get_object()
        producto.disponible = not producto.disponible
        producto.save(update_fields=['disponible'])
        
        estado = "disponible" if producto.disponible else "no disponible"
        return Response({
            'status': 'success', 
            'message': f'Producto marcado como {estado}', 
            'disponible': producto.disponible
        })

    @action(detail=True, methods=['patch'])
    def actualizar_stock(self, request, pk=None):
        """
        Acción rápida: Actualizar inventario numérico
        """
        producto = self.get_object()
        
        nuevo_stock = request.data.get('stock')
        if new_stock is None:
            return Response({'error': 'Campo stock requerido'}, status=400)
            
        try:
            stock_int = int(nuevo_stock)
            if stock_int < 0: raise ValueError
        except ValueError:
            return Response({'error': 'Stock debe ser un número entero positivo'}, status=400)
            
        producto.stock = stock_int
        producto.tiene_stock = True # Forzamos el control de stock activado
        producto.save(update_fields=['stock', 'tiene_stock'])
        
        return Response({
            'status': 'success', 
            'message': 'Inventario actualizado', 
            'stock': producto.stock
        })
        
# ============================================================================
# BLOQUE NUEVO: GESTIÓN DE PROMOCIONES (BANNERS) DEL PROVEEDOR
# ============================================================================
class MisPromocionesViewSet(viewsets.ModelViewSet):
    """
    ViewSet para que el PROVEEDOR gestione sus Banners publicitarios.
    Endpoint: /api/proveedores/mis-promociones/
    """
    permission_classes = [IsAuthenticated]
    serializer_class = PromocionProveedorSerializer
    
    def get_queryset(self):
        """Retorna SOLO las promociones del proveedor logueado"""
        user = self.request.user
        if getattr(user, 'rol_activo', '') != 'proveedor':
            return Promocion.objects.none()
            
        try:
            proveedor = Proveedor.objects.get(user=user)
            return Promocion.objects.filter(proveedor=proveedor)
        except Proveedor.DoesNotExist:
            return Promocion.objects.none()

    def perform_create(self, serializer):
        """Asigna automáticamente el proveedor al crear el banner"""
        user = self.request.user
        if getattr(user, 'rol_activo', '') != 'proveedor':
            raise serializers.ValidationError("Debes estar en modo Proveedor.")
            
        try:
            proveedor = Proveedor.objects.get(user=user)
            serializer.save(proveedor=proveedor)
            logger.info(f"Promoción creada por {proveedor.nombre}: {serializer.validated_data.get('titulo')}")
        except Proveedor.DoesNotExist:
            raise serializers.ValidationError("No tienes perfil de proveedor.")