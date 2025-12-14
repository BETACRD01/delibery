# -*- coding: utf-8 -*-
# administradores/views.py
"""
ViewSets para gestión de usuarios por administradores
- Gestión completa de usuarios regulares
- Gestión de proveedores (verificar, desactivar)
- Gestión de repartidores (verificar, desactivar)
- Logs de acciones administrativas
- Configuración del sistema
- Gestión de solicitudes de cambio de rol
- Dashboard con filtros de soft delete
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Count, Sum, Prefetch
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django_filters.rest_framework import DjangoFilterBackend
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.conf import settings
from functools import wraps
import logging
from typing import Dict, Any, Optional

# Modelos
from authentication.models import User
from usuarios.models import Perfil, SolicitudCambioRol
from usuarios.solicitudes import GestorSolicitudCambioRol
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from pedidos.models import Pedido, EstadoPedido
from .models import Administrador, AccionAdministrativa, ConfiguracionSistema

# Serializers optimizados
from .serializers import (
    AdministradorSerializer,
    OptimizedUserListSerializer as UsuarioListSerializer,
    UsuarioDetalleSerializer,
    UsuarioEditarSerializer,
    CambiarRolSerializer,
    DesactivarUsuarioSerializer,
    ResetearPasswordSerializer,
    OptimizedProveedorListSerializer as ProveedorListSerializer,
    ProveedorDetalleSerializer,
    VerificarProveedorSerializer,
    OptimizedRepartidorListSerializer as RepartidorListSerializer,
    RepartidorDetalleSerializer,
    VerificarRepartidorSerializer,
    OptimizedAccionAdministrativaSerializer as AccionAdministrativaSerializer,
    ConfiguracionSistemaSerializer,
)

# Permissions
from .permissions import (
    EsAdministrador,
    PuedeGestionarUsuarios,
    PuedeGestionarProveedores,
    PuedeGestionarRepartidores,
    PuedeConfigurarSistema,
    AdministradorActivo,
    PuedeGestionarSolicitudes,
    validar_no_es_superusuario,
    validar_no_auto_modificacion_critica,
    obtener_perfil_admin,
)

from .serializers import (
    SolicitudCambioRolAdminSerializer,
)

logger = logging.getLogger("administradores")

# ============================================
# DECORADORES Y HELPERS OPTIMIZADOS
# ============================================

def log_action(action_type: str):
    """Decorador para logging automático de acciones"""
    def decorator(func):
        @wraps(func)
        def wrapper(self, request, *args, **kwargs):
            user_email = request.user.email
            logger.info(f"[{action_type}] Iniciado por: {user_email}")
            try:
                response = func(self, request, *args, **kwargs)
                logger.info(f"[{action_type}] Completado exitosamente por: {user_email}")
                return response
            except Exception as e:
                logger.error(f"[{action_type}] Error por {user_email}: {str(e)}", exc_info=True)
                raise
        return wrapper
    return decorator


def registrar_accion_admin(
    request, 
    tipo_accion: str, 
    descripcion: str, 
    **kwargs: Any
) -> Optional[AccionAdministrativa]:
    """Helper optimizado para registrar acciones administrativas"""
    try:
        admin = obtener_perfil_admin(request.user)

        # Si no tiene perfil admin, no escalamos automáticamente
        if not admin:
            logger.warning(
                f"Usuario {request.user.email} no tiene perfil admin; no se registra acción."
            )
            return None

        ip_address = request.META.get("REMOTE_ADDR")
        user_agent = request.META.get("HTTP_USER_AGENT", "")

        return AccionAdministrativa.registrar_accion(
            administrador=admin,
            tipo_accion=tipo_accion,
            descripcion=descripcion,
            ip_address=ip_address,
            user_agent=user_agent,
            **kwargs,
        )

    except Exception as e:
        logger.error(f"Error registrando acción: {e}", exc_info=True)
        return None


# ============================================
# MIXIN BASE PARA VIEWSETS
# ============================================

class BaseAdminViewSetMixin:
    """Mixin base con funcionalidad común para ViewSets administrativos"""
    
    def get_client_ip(self, request) -> str:
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')
    
    def handle_error(self, error: Exception, message: str = "Error en operación") -> Response:
        logger.error(f"{message}: {str(error)}", exc_info=True)
        
        if isinstance(error, ValidationError):
            return Response(
                {"error": "Error de validación", "detalles": str(error)},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response(
            {
                "error": message,
                "detalle": str(error) if settings.DEBUG else "Intenta nuevamente"
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ============================================
# VIEWSET: GESTIÓN DE USUARIOS
# ============================================

class GestionUsuariosViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """ViewSet optimizado para gestión completa de usuarios"""

    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeGestionarUsuarios,
    ]

    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]

    filterset_fields = ["is_active", "cuenta_desactivada"]

    search_fields = ["email", "first_name", "last_name", "celular", "username"]
    ordering_fields = ["created_at", "email", "first_name"]
    ordering = ["-created_at"]

    def get_queryset(self):
        """
        Por defecto listamos solo usuarios sin perfiles especiales.
        Para acciones detail (incluyendo resetear/cambiar password) usamos
        el queryset completo para que un admin pueda operar sobre proveedores
        o repartidores.
        """

        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return User.objects.none()

        # Acciones detail: permitir cualquier usuario
        if self.action in {
            "retrieve",
            "update",
            "partial_update",
            "destroy",
            "cambiar_password",
            "resetear_password",
        }:
            return (
                User.objects
                .select_related("perfil", "perfil_admin", "proveedor", "repartidor")
                .prefetch_related("solicitudes_cambio_rol")
            )

        # Listados: solo usuarios sin roles especiales
        # Si viene search, devolvemos todo el universo para que el admin pueda encontrar
        # proveedores/repartidores/usuarios por email o nombre.
        if self.action in ['list', 'normales'] and self.request.query_params.get("search"):
            queryset = (
                User.objects
                .select_related("perfil", "perfil_admin", "proveedor", "repartidor")
                .prefetch_related("solicitudes_cambio_rol")
            )
        else:
            queryset = (
                User.objects
                .filter(
                    perfil_admin__isnull=True,
                    proveedor__isnull=True,
                    repartidor__isnull=True,
                )
                .select_related("perfil")
                .prefetch_related("solicitudes_cambio_rol")
            )

        if self.action in ['list', 'normales']:  # Incluir 'normales' para listado
            queryset = UsuarioListSerializer.setup_eager_loading(queryset)

        return queryset

 
    @action(detail=True, methods=["patch"], url_path="cambiar-password")
    def cambiar_password(self, request, pk=None):
        user = self.get_object()

        nueva = request.data.get("nueva_password")
        confirmar = request.data.get("confirmar_password")

        if not nueva or not confirmar:
            return Response({"error": "Faltan campos."}, status=400)

        if nueva != confirmar:
            return Response({"error": "Las contraseñas no coinciden."}, status=400)

        if len(nueva) < 8:
            return Response({"error": "La contraseña debe tener mínimo 8 caracteres."}, status=400)

        user.set_password(nueva)
        user.save()

        return Response({"mensaje": "Contraseña actualizada correctamente."}, status=200)

    def get_serializer_class(self):
        serializer_map = {
            'list': UsuarioListSerializer,
            'update': UsuarioEditarSerializer,
            'partial_update': UsuarioEditarSerializer,
            'cambiar_rol': CambiarRolSerializer,
            'desactivar': DesactivarUsuarioSerializer,
            'resetear_password': ResetearPasswordSerializer,
            'normales': UsuarioListSerializer, # Para la nueva acción de lista
        }
        return serializer_map.get(self.action, UsuarioDetalleSerializer)


    @log_action("RETRIEVE_USER")
    def retrieve(self, request, *args, **kwargs):
        usuario = self.get_object()
        serializer = self.get_serializer(usuario)
        return Response(serializer.data)

    @log_action("UPDATE_USER")
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        usuario = self.get_object()

        validar_no_es_superusuario(usuario)

        serializer = self.get_serializer(usuario, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        registrar_accion_admin(
            request,
            "editar_usuario",
            f"Usuario editado: {usuario.email}",
            modelo_afectado="User",
            objeto_id=str(usuario.id),
            datos_nuevos=serializer.data,
        )

        return Response(serializer.data)

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("RESET_PASSWORD")
    def resetear_password(self, request, pk=None):
        """
        Permite al admin asignar una nueva contraseña a cualquier usuario
        (cliente, proveedor o repartidor).
        """
        usuario = self.get_object()
        validar_no_es_superusuario(usuario)
        validar_no_auto_modificacion_critica(request.user, usuario, "resetear")

        serializer = ResetearPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        nueva = serializer.validated_data["nueva_password"]
        usuario.set_password(nueva)
        usuario.save(update_fields=["password", "updated_at"])

        registrar_accion_admin(
            request,
            "resetear_password",
            f"Password reseteada por admin para: {usuario.email}",
            modelo_afectado="User",
            objeto_id=str(usuario.id),
            datos_nuevos={"admin": request.user.email},
        )

        return Response({"mensaje": "Contraseña actualizada correctamente."}, status=status.HTTP_200_OK)

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("CHANGE_ROLE")
    def cambiar_rol(self, request, pk=None):
        usuario = self.get_object()
        validar_no_es_superusuario(usuario)
        validar_no_auto_modificacion_critica(request.user, usuario, "cambiar_rol")

        serializer = CambiarRolSerializer(
            data=request.data, 
            context={"usuario": usuario}
        )
        serializer.is_valid(raise_exception=True)

        rol_anterior = usuario.rol_activo
        nuevo_rol = serializer.validated_data["nuevo_rol"]
        motivo = serializer.validated_data.get("motivo", "Sin motivo especificado")

        # Aseguramos que el rol esté aprobado y lo activamos
        if nuevo_rol not in usuario.roles_aprobados:
            usuario.roles_aprobados = usuario.roles_aprobados + [nuevo_rol]
        usuario.rol_activo = nuevo_rol
        usuario.save(update_fields=["rol_activo", "roles_aprobados", "updated_at"])

        self._crear_perfil_por_rol(usuario, nuevo_rol)

        registrar_accion_admin(
            request,
            "cambiar_rol",
            f"Cambio de rol: {usuario.email} de {rol_anterior} a {nuevo_rol}",
            modelo_afectado="User",
            objeto_id=str(usuario.id),
            datos_anteriores={"rol_activo": rol_anterior},
            datos_nuevos={"rol_activo": nuevo_rol, "motivo": motivo},
        )

        return Response(
            {
                "mensaje": "Rol cambiado exitosamente",
                "usuario": usuario.email,
                "rol_anterior": rol_anterior,
                "nuevo_rol": nuevo_rol,
                "motivo": motivo,
            },
            status=status.HTTP_200_OK,
        )

    def _crear_perfil_por_rol(self, usuario: User, rol: str):
        if rol == "PROVEEDOR" and not hasattr(usuario, "proveedor"):
            Proveedor.objects.create(
                user=usuario,
                nombre=f"Proveedor {usuario.get_full_name()}",
                descripcion="Pendiente de actualización",
            )
            
        elif rol == "REPARTIDOR" and not hasattr(usuario, "repartidor"):
            Repartidor.objects.create(
                user=usuario,
                cedula="PENDIENTE",
            )

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("DEACTIVATE_USER")
    def desactivar(self, request, pk=None):
        usuario = self.get_object()
        validar_no_es_superusuario(usuario)
        validar_no_auto_modificacion_critica(request.user, usuario, "desactivar")

        serializer = DesactivarUsuarioSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        razon = serializer.validated_data["razon"]
        permanente = serializer.validated_data["permanente"]

        usuario.is_active = False
        usuario.cuenta_desactivada = True
        usuario.save(update_fields=["is_active", "cuenta_desactivada", "updated_at"])

        self._desactivar_perfiles_relacionados(usuario)

        registrar_accion_admin(
            request,
            "desactivar_usuario",
            f"Usuario desactivado: {usuario.email}. Razón: {razon}",
            modelo_afectado="User",
            objeto_id=str(usuario.id),
            datos_nuevos={"activo": False, "razon": razon, "permanente": permanente},
        )

        return Response(
            {
                "mensaje": "Usuario desactivado exitosamente",
                "usuario": usuario.email,
                "razon": razon,
                "permanente": permanente,
            },
            status=status.HTTP_200_OK,
        )

    def _desactivar_perfiles_relacionados(self, usuario: User):
        if hasattr(usuario, "proveedor"):
            usuario.proveedor.activo = False
            usuario.proveedor.save(update_fields=["activo"])
            
        if hasattr(usuario, "repartidor"):
            usuario.repartidor.activo = False
            usuario.repartidor.save(update_fields=["activo"])

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("REACTIVATE_USER")
    def reactivar(self, request, pk=None):
        usuario = self.get_object()
        validar_no_es_superusuario(usuario)

        usuario.is_active = True
        usuario.cuenta_desactivada = False
        usuario.intentos_login_fallidos = 0
        usuario.save(
            update_fields=["is_active", "cuenta_desactivada", "intentos_login_fallidos", "updated_at"]
        )

        self._reactivar_perfiles_relacionados(usuario)

        registrar_accion_admin(
            request,
            "reactivar_usuario",
            f"Usuario reactivado: {usuario.email}",
            modelo_afectado="User",
            objeto_id=str(usuario.id),
            datos_nuevos={"activo": True},
        )

        return Response(
            {"mensaje": "Usuario reactivado exitosamente", "usuario": usuario.email},
            status=status.HTTP_200_OK,
        )

    def _reactivar_perfiles_relacionados(self, usuario: User):
        if hasattr(usuario, "proveedor"):
            usuario.proveedor.activo = True
            usuario.proveedor.save(update_fields=["activo"])
            
        if hasattr(usuario, "repartidor"):
            usuario.repartidor.activo = True
            usuario.repartidor.estado = "DISPONIBLE"
            usuario.repartidor.save(update_fields=["activo", "estado"])

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("RESET_PASSWORD")
    def resetear_password(self, request, pk=None):
        usuario = self.get_object()
        validar_no_es_superusuario(usuario)
        validar_no_auto_modificacion_critica(request.user, usuario, "resetear_password")

        serializer = ResetearPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        nueva_password = serializer.validated_data["nueva_password"]
        usuario.set_password(nueva_password)
        usuario.intentos_login_fallidos = 0
        usuario.save(update_fields=["password", "intentos_login_fallidos", "updated_at"])

        registrar_accion_admin(
            request,
            "resetear_password",
            f"Contraseña reseteada para: {usuario.email}",
            modelo_afectado="User",
            objeto_id=str(usuario.id),
        )

        return Response(
            {"mensaje": "Contraseña reseteada exitosamente", "usuario": usuario.email},
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["get"])
    @log_action("USERS_STATISTICS")
    def estadisticas(self, request):

     qs = User.objects.all()

     estadisticas = {
        # Contamos cuántos usuarios tienen perfil de Admin, Proveedor o Repartidor
        "administradores": qs.filter(perfil_admin__isnull=False).count(),
        "proveedores": qs.filter(proveedor__isnull=False).count(),
        "repartidores": qs.filter(repartidor__isnull=False).count(),
        # Usuarios normales: Los que NO tienen ninguno de los perfiles anteriores
        "usuarios_normales": qs.filter(
            perfil_admin__isnull=True,
            proveedor__isnull=True,
            repartidor__isnull=True
        ).count(),
    }

     total = qs.count()
     nuevos_hoy = qs.filter(created_at__date=timezone.now().date()).count()

     return Response(
        {
            "total_usuarios": total,
            "nuevos_hoy": nuevos_hoy,
            "roles": estadisticas,
        }
    )

    @action(detail=False, methods=["get"])
    @log_action("LIST_NORMAL_USERS")
    def normales(self, request):
        """
        [CORREGIDO] Lista SOLO usuarios normales (sin perfiles especiales).
        Ruta generada: /admin/usuarios/normales/
        """
        try:
            # Reutilizar el queryset base que ya filtra por usuarios normales
            queryset = self.get_queryset()
            
            # Aplicar filtros de búsqueda y ordenamiento
            queryset = self.filter_queryset(queryset)
            
            # Aplicar paginación
            page = self.paginate_queryset(queryset)
            if page is not None:
                # Usar el serializador de listado (UsuarioListSerializer)
                serializer = self.get_serializer(page, many=True)
                return self.get_paginated_response(serializer.data)
            
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)

        except Exception as e:
            return self.handle_error(e, "Error al listar usuarios normales")


# ============================================
# VIEWSET: GESTIÓN DE PROVEEDORES
# ============================================

class GestionProveedoresViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """ViewSet optimizado para gestión de proveedores"""

    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeGestionarProveedores,
    ]
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = ["verificado", "activo", "tipo_proveedor", "ciudad"]
    search_fields = ["nombre", "user__email", "ciudad", "ruc"]
    
    # CORRECCIÓN: Quitar 'total_ventas' que no existe en el modelo Proveedor
    ordering_fields = ["nombre", "created_at", "verificado", "activo"]
    ordering = ["-created_at"]  # Ordenar por fecha de creación descendente

    def get_queryset(self):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return Proveedor.objects.none()

        queryset = Proveedor.objects.select_related('user').prefetch_related(
            'productos',
            'pedidos'
        )
        
        if self.action == 'list':
            queryset = ProveedorListSerializer.setup_eager_loading(queryset)
            
        return queryset

    def get_serializer_class(self):
        if self.action == "list":
            return ProveedorListSerializer
        elif self.action == "verificar":
            return VerificarProveedorSerializer
        return ProveedorDetalleSerializer

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("VERIFY_PROVIDER")
    def verificar(self, request, pk=None):
        proveedor = self.get_object()
        
        serializer = VerificarProveedorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verificado = serializer.validated_data["verificado"]
        motivo = serializer.validated_data.get("motivo", "")

        proveedor.verificado = verificado
        proveedor.save(update_fields=["verificado", "actualizado_en"])

        if verificado and proveedor.user:
            proveedor.user.verificado = True
            proveedor.user.save(update_fields=["verificado"])

        registrar_accion_admin(
            request,
            "verificar_proveedor",
            f"Proveedor {'verificado' if verificado else 'rechazado'}: {proveedor.nombre}",
            modelo_afectado="Proveedor",
            objeto_id=str(proveedor.id),
            datos_nuevos={"verificado": verificado, "motivo": motivo},
        )

        return Response(
            {
                "mensaje": f"Proveedor {'verificado' if verificado else 'rechazado'} exitosamente",
                "proveedor": proveedor.nombre,
                "verificado": verificado,
                "motivo": motivo,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("TOGGLE_PROVIDER_STATUS")
    def toggle_activo(self, request, pk=None):
        proveedor = self.get_object()
        
        proveedor.activo = not proveedor.activo
        proveedor.save(update_fields=["activo", "actualizado_en"])

        registrar_accion_admin(
            request,
            "toggle_proveedor",
            f"Proveedor {'activado' if proveedor.activo else 'desactivado'}: {proveedor.nombre}",
            modelo_afectado="Proveedor",
            objeto_id=str(proveedor.id),
            datos_nuevos={"activo": proveedor.activo},
        )

        return Response(
            {
                "mensaje": f"Proveedor {'activado' if proveedor.activo else 'desactivado'}",
                "proveedor": proveedor.nombre,
                "activo": proveedor.activo,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["get"])
    @log_action("PROVIDERS_STATISTICS")
    def estadisticas(self, request):
        stats = Proveedor.objects.aggregate(
            total=Count("id"),
            verificados=Count("id", filter=Q(verificado=True)),
            activos=Count("id", filter=Q(activo=True)),
            pendientes=Count("id", filter=Q(verificado=False)),
            total_ventas=Sum("total_ventas"),
            promedio_calificacion=models.Avg("calificacion_promedio"),
        )

        por_tipo = (
            Proveedor.objects.values("tipo_proveedor")
            .annotate(
                total=Count("id"),
                verificados=Count("id", filter=Q(verificado=True)),
                ventas=Sum("total_ventas"),
            )
        )

        return Response(
            {
                "estadisticas": stats,
                "por_tipo": list(por_tipo),
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["get"], url_path="pendientes")
    @log_action("PROVIDERS_PENDING")
    def pendientes(self, request):
        """
        [CORREGIDO] Lista proveedores con estado 'verificado=False'.
        Aplica filtros, búsqueda y ordenamiento (CORREGIDO).
        Ruta generada: /admin/proveedores/pendientes/
        """
        # 1. Obtener QuerySet base
        queryset = self.get_queryset()
        
        # 2. Aplicar filtro específico
        queryset = queryset.filter(verificado=False)
        
        # 3. Aplicar filtros de DRF (SearchFilter, OrderingFilter) - ¡CLAVE!
        # Esto resuelve el AttributeError: 'NoneType' object has no attribute '_meta'
        queryset = self.filter_queryset(queryset)
        
        # 4. Paginación y serialización
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


# ============================================
# VIEWSET: GESTIÓN DE REPARTIDORES
# ============================================

# En administradores/views.py

class GestionRepartidoresViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """ViewSet optimizado para gestión de repartidores"""

    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeGestionarRepartidores,
    ]
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    # CORRECCIÓN: Quitamos 'tipo_vehiculo' y 'activo' si dan problemas
    filterset_fields = ["verificado", "estado"] 
    
    search_fields = ["user__email", "cedula", "placa_vehiculo"]
    ordering_fields = ["creado_en", "entregas_completadas", "ganancias_totales"]
    ordering = ["-creado_en"]

    def get_queryset(self):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return Repartidor.objects.none()

        # Eliminamos prefetch de 'entregas' porque el related_name no existe en el modelo
        queryset = Repartidor.objects.select_related('user')
        
        if self.action == 'list':
            queryset = RepartidorListSerializer.setup_eager_loading(queryset)
            
        return queryset

    def get_serializer_class(self):
        if self.action == "list":
            return RepartidorListSerializer
        elif self.action == "verificar":
            return VerificarRepartidorSerializer
        return RepartidorDetalleSerializer

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("VERIFY_DELIVERY")
    def verificar(self, request, pk=None):
        repartidor = self.get_object()
        
        serializer = VerificarRepartidorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verificado = serializer.validated_data["verificado"]
        motivo = serializer.validated_data.get("motivo", "")

        repartidor.verificado = verificado
        if verificado:
            repartidor.estado = "DISPONIBLE"
        repartidor.save(update_fields=["verificado", "estado", "actualizado_en"])

        if verificado and repartidor.user:
            repartidor.user.verificado = True
            repartidor.user.save(update_fields=["verificado"])

        registrar_accion_admin(
            request,
            "verificar_repartidor",
            f"Repartidor {'verificado' if verificado else 'rechazado'}: {repartidor.user.email}",
            modelo_afectado="Repartidor",
            objeto_id=str(repartidor.id),
            datos_nuevos={"verificado": verificado, "motivo": motivo},
        )

        return Response(
            {
                "mensaje": f"Repartidor {'verificado' if verificado else 'rechazado'}",
                "repartidor": repartidor.user.email,
                "verificado": verificado,
                "motivo": motivo,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("TOGGLE_DELIVERY_STATUS")
    def toggle_activo(self, request, pk=None):
        repartidor = self.get_object()
        
        repartidor.activo = not repartidor.activo
        if not repartidor.activo:
            repartidor.estado = "NO_DISPONIBLE"
        else:
            repartidor.estado = "DISPONIBLE"
            
        repartidor.save(update_fields=["activo", "estado", "actualizado_en"])

        registrar_accion_admin(
            request,
            "toggle_repartidor",
            f"Repartidor {'activado' if repartidor.activo else 'desactivado'}: {repartidor.user.email}",
            modelo_afectado="Repartidor",
            objeto_id=str(repartidor.id),
            datos_nuevos={"activo": repartidor.activo},
        )

        return Response(
            {
                "mensaje": f"Repartidor {'activado' if repartidor.activo else 'desactivado'}",
                "repartidor": repartidor.user.email,
                "activo": repartidor.activo,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["get"])
    @log_action("DELIVERY_STATISTICS")
    def estadisticas(self, request):
        stats = Repartidor.objects.aggregate(
            total=Count("id"),
            verificados=Count("id", filter=Q(verificado=True)),
            activos=Count("id", filter=Q(activo=True)),
            disponibles=Count("id", filter=Q(estado="DISPONIBLE")),
            en_entrega=Count("id", filter=Q(estado="EN_ENTREGA")),
            total_entregas=Sum("entregas_completadas"),
            ganancias_totales=Sum("ganancias_totales"),
        )

        por_vehiculo = (
            Repartidor.objects.values("tipo_vehiculo")
            .annotate(
                total=Count("id"),
                activos=Count("id", filter=Q(activo=True)),
                entregas=Sum("entregas_completadas"),
            )
        )

        return Response(
            {
                "estadisticas": stats,
                "por_vehiculo": list(por_vehiculo),
            },
            status=status.HTTP_200_OK,
        )


# ============================================
# VIEWSET: LOGS DE ACCIONES
# ============================================

class AccionesAdministrativasViewSet(BaseAdminViewSetMixin, viewsets.ReadOnlyModelViewSet):
    """ViewSet optimizado para logs de acciones administrativas (solo lectura)"""

    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
    ]
    serializer_class = AccionAdministrativaSerializer
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = [
        "tipo_accion",
        "exitosa",
        "modelo_afectado",
        "administrador__user__email",
    ]
    search_fields = ["descripcion", "administrador__user__email", "ip_address"]
    ordering_fields = ["fecha_accion"]
    ordering = ["-fecha_accion"]

    def get_queryset(self):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return AccionAdministrativa.objects.none()

        queryset = AccionAdministrativa.objects.all()
        queryset = AccionAdministrativaSerializer.setup_eager_loading(queryset)
        
        fecha_desde = self.request.query_params.get("fecha_desde")
        fecha_hasta = self.request.query_params.get("fecha_hasta")
        # Por defecto, mostrar solo la actividad de los últimos 7 días
        if not fecha_desde:
            fecha_desde = timezone.now() - timezone.timedelta(days=7)
        
        if fecha_desde:
            queryset = queryset.filter(fecha_accion__gte=fecha_desde)
        if fecha_hasta:
            queryset = queryset.filter(fecha_accion__lte=fecha_hasta)
            
        return queryset

    @action(detail=False, methods=["get"])
    @log_action("LOGS_STATISTICS")
    def estadisticas(self, request):
        hoy = timezone.now().date()
        
        stats = self.get_queryset().aggregate(
            total=Count("id"),
            exitosas=Count("id", filter=Q(exitosa=True)),
            fallidas=Count("id", filter=Q(exitosa=False)),
            hoy=Count("id", filter=Q(fecha_accion__date=hoy)),
        )

        por_tipo = (
            self.get_queryset()
            .values("tipo_accion")
            .annotate(
                total=Count("id"),
                exitosas=Count("id", filter=Q(exitosa=True)),
            )
            .order_by("-total")[:10]
        )

        por_admin = (
            self.get_queryset()
            .values("administrador__user__email")
            .annotate(total=Count("id"))
            .order_by("-total")[:5]
        )

        return Response(
            {
                "estadisticas": stats,
                "por_tipo_accion": list(por_tipo),
                "por_administrador": list(por_admin),
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["post"])
    @log_action("LOGS_CLEANUP")
    def limpiar_antiguas(self, request):
        """
        Elimina acciones con más de 7 días de antigüedad.
        """
        limite = timezone.now() - timezone.timedelta(days=7)
        borradas, _ = AccionAdministrativa.objects.filter(fecha_accion__lt=limite).delete()
        return Response(
          {"mensaje": "Acciones antiguas eliminadas", "eliminadas": borradas},
          status=status.HTTP_200_OK,
        )


# ============================================
# VIEWSET: CONFIGURACIÓN DEL SISTEMA
# ============================================

class ConfiguracionSistemaViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """ViewSet para configuración del sistema"""

    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeConfigurarSistema,
    ]
    serializer_class = ConfiguracionSistemaSerializer
    
    def get_queryset(self):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return ConfiguracionSistema.objects.none()

        return ConfiguracionSistema.objects.all()

    def get_object(self):
        config, created = ConfiguracionSistema.objects.get_or_create(
            pk=1,
            defaults={
                "comision_app_proveedor": 10.00,
                "comision_app_directo": 15.00,
                "comision_repartidor_proveedor": 15.00,
                "comision_repartidor_directo": 20.00,
                "pedidos_minimos_rifa": 5,
                "pedido_maximo": 500.00,
                "pedido_minimo": 5.00,
                "tiempo_maximo_entrega": 60,
            }
        )
        return config

    @log_action("UPDATE_CONFIG")
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        
        datos_anteriores = ConfiguracionSistemaSerializer(instance).data
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        
        serializer.save(modificado_por=obtener_perfil_admin(request.user))
        
        registrar_accion_admin(
            request,
            "actualizar_configuracion",
            "Configuración del sistema actualizada",
            modelo_afectado="ConfiguracionSistema",
            objeto_id="1",
            datos_anteriores=datos_anteriores,
            datos_nuevos=serializer.data,
        )

        return Response(serializer.data)

    @action(detail=False, methods=["post"])
    @transaction.atomic
    @log_action("TOGGLE_MAINTENANCE")
    def toggle_mantenimiento(self, request):
        config = self.get_object()
        mensaje = request.data.get("mensaje", "Sistema en mantenimiento")
        
        config.mantenimiento = not config.mantenimiento
        config.mensaje_mantenimiento = mensaje if config.mantenimiento else ""
        config.modificado_por = obtener_perfil_admin(request.user)
        config.save()

        registrar_accion_admin(
            request,
            "toggle_mantenimiento",
            f"Modo mantenimiento {'activado' if config.mantenimiento else 'desactivado'}",
            modelo_afectado="ConfiguracionSistema",
            objeto_id="1",
            datos_nuevos={
                "mantenimiento": config.mantenimiento,
                "mensaje": config.mensaje_mantenimiento
            },
        )

        return Response(
            {
                "mantenimiento": config.mantenimiento,
                "mensaje": config.mensaje_mantenimiento,
            },
            status=status.HTTP_200_OK,
        )


# ============================================
# VIEWSET: DASHBOARD ADMINISTRATIVO
# ============================================

class DashboardAdminViewSet(BaseAdminViewSetMixin, viewsets.ViewSet):
    """ViewSet para dashboard administrativo con estadísticas generales"""
    
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
    ]

    @log_action("DASHBOARD_VIEW")
    def list(self, request):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return Response({})

        hoy = timezone.now().date()
        hace_7_dias = hoy - timezone.timedelta(days=7)
        hace_30_dias = hoy - timezone.timedelta(days=30)

        # 💡 CORRECCIÓN CRÍTICA: La llamada ahora usa la lógica de exclusión corregida
        usuarios_stats = self._get_usuarios_stats(hoy) 
        proveedores_stats = self._get_proveedores_stats()
        repartidores_stats = self._get_repartidores_stats()
        pedidos_stats = self._get_pedidos_stats(hoy, hace_7_dias, hace_30_dias)
        solicitudes_stats = self._get_solicitudes_stats()

        return Response({
            "usuarios": usuarios_stats,
            "proveedores": proveedores_stats,
            "repartidores": repartidores_stats,
            "pedidos": pedidos_stats,
            "solicitudes_cambio_rol": solicitudes_stats,
            "sistema": self._get_sistema_info(),
        })

    def _get_usuarios_stats(self, hoy):
        return User.objects.filter(
            perfil_admin__isnull=True,
            proveedor__isnull=True,
            repartidor__isnull=True,
        ).aggregate(
            total=Count("id"),
            activos=Count("id", filter=Q(is_active=True, cuenta_desactivada=False)),
            nuevos_hoy=Count("id", filter=Q(created_at__date=hoy)),
            bloqueados=Count("id", filter=Q(cuenta_desactivada=True)),
        )
        
    def _get_proveedores_stats(self):
        return Proveedor.objects.aggregate(
            total=Count("id"),
            activos=Count("id", filter=Q(activo=True)),
            verificados=Count("id", filter=Q(verificado=True)),
            pendientes=Count("id", filter=Q(verificado=False)),
        )

    def _get_repartidores_stats(self):
        return Repartidor.objects.aggregate(
            total=Count("id"),
            activos=Count("id", filter=Q(activo=True)),
            verificados=Count("id", filter=Q(verificado=True)),
            disponibles=Count("id", filter=Q(estado="DISPONIBLE")),
            en_entrega=Count("id", filter=Q(estado="EN_ENTREGA")),
        )

    def _get_pedidos_stats(self, hoy, hace_7_dias, hace_30_dias):
        return {
            "hoy": Pedido.objects.filter(creado_en__date=hoy).count(),
            "semana": Pedido.objects.filter(creado_en__date__gte=hace_7_dias).count(),
            "mes": Pedido.objects.filter(creado_en__date__gte=hace_30_dias).count(),
            "por_estado": dict(
                Pedido.objects.values_list("estado").annotate(Count("id"))
            ),
        }

    def _get_solicitudes_stats(self):
        return SolicitudCambioRol.objects.aggregate(
            pendientes=Count("id", filter=Q(estado="PENDIENTE")),
            total=Count("id"),
        )

    def _get_sistema_info(self):
        try:
            config = ConfiguracionSistema.objects.first()
            return {
                "mantenimiento": config.mantenimiento if config else False,
                "mensaje": config.mensaje_mantenimiento if config else "",
            }
        except Exception:
            return {"mantenimiento": False, "mensaje": ""}


# ============================================
# VIEWSET: GESTIÓN DE SOLICITUDES DE CAMBIO DE ROL
# ============================================

class GestionSolicitudesCambioRolViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """
    ViewSet optimizado para gestión de solicitudes de cambio de rol
    """
    
    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
        PuedeGestionarSolicitudes,
    ]
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = ["estado", "rol_solicitado", "rol_anterior"]
    search_fields = ["user__email", "user__first_name", "user__last_name", "motivo"]
    ordering_fields = ["creado_en", "respondido_en"]
    ordering = ["-creado_en"]
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_queryset(self):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return SolicitudCambioRol.objects.none()

        return SolicitudCambioRol.objects.select_related(
            'user',
            'user__perfil',  
            'admin_responsable'
        )

    def get_serializer_class(self):
    
        return SolicitudCambioRolAdminSerializer
    
    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("ACCEPT_ROLE_REQUEST")
    def aceptar(self, request, pk=None):
        try:
            solicitud = self.get_object()
            motivo_admin = request.data.get("motivo_revision", "Solicitud aprobada")

            # ✅ CORRECCIÓN: Usar 'aceptar_solicitud' en lugar de 'procesar_solicitud'
            resultado = GestorSolicitudCambioRol.aceptar_solicitud(
                solicitud=solicitud,
                admin=request.user,
                motivo_respuesta=motivo_admin,
            )
            
            log_data = {
                "usuario": solicitud.user.email,
                "nuevo_rol": solicitud.rol_solicitado,
                "motivo": motivo_admin
            }

            registrar_accion_admin(
                request,
                "aceptar_cambio_rol",
                f"Solicitud aceptada: {solicitud.user.email} cambió a {solicitud.rol_solicitado}",
                modelo_afectado="SolicitudCambioRol",
                objeto_id=str(solicitud.id),
                datos_nuevos=log_data,
            )

            return Response(resultado, status=status.HTTP_200_OK)

        except ValidationError as e:
            return self.handle_error(e, "Error de validación")
        except Exception as e:
            return self.handle_error(e, "Error al procesar solicitud")

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("REJECT_ROLE_REQUEST")
    def rechazar(self, request, pk=None):
        try:
            solicitud = self.get_object()
        
            raw_motivo = request.data.get("motivo_rechazo", "")
            motivo_rechazo = str(raw_motivo).strip()
            if not motivo_rechazo:
                motivo_rechazo = "Rechazado por decisión administrativa."
            
            # 3. Validación de longitud (reducida a 5 para facilitar pruebas)
            elif len(motivo_rechazo) < 5:
                return Response(
                    {"error": "El motivo de rechazo es muy corto (mínimo 5 caracteres)."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            resultado = GestorSolicitudCambioRol.rechazar_solicitud(
                solicitud=solicitud,
                admin=request.user,
                motivo_respuesta=motivo_rechazo,
            )
            
            log_data = {
                "usuario": solicitud.user.email,
                "rol_rechazado": solicitud.rol_solicitado,
                "motivo": motivo_rechazo,
                "resultado_backend": resultado
            }
            
            registrar_accion_admin(
                request,
                "rechazar_cambio_rol",
                f"Solicitud rechazada: {solicitud.user.email} - {motivo_rechazo}",
                modelo_afectado="SolicitudCambioRol",
                objeto_id=str(solicitud.id),
                datos_nuevos=log_data, 
            )

            return Response(resultado, status=status.HTTP_200_OK)

        except ValidationError as e:
            return self.handle_error(e, "Error de validación")
        except Exception as e:
            return self.handle_error(e, "Error al procesar solicitud")

    @action(detail=False, methods=["get"])
    @log_action("REQUESTS_STATISTICS")
    def estadisticas(self, request):
        stats = self.get_queryset().aggregate(
            total=Count("id"),
            pendientes=Count("id", filter=Q(estado="PENDIENTE")),
            aceptadas=Count("id", filter=Q(estado="ACEPTADA")),
            rechazadas=Count("id", filter=Q(estado="RECHAZADA")),
        )

        por_rol = (
            self.get_queryset()
            .values("rol_solicitado")
            .annotate(
                total=Count("id"),
                pendientes=Count("id", filter=Q(estado="PENDIENTE")),
                aceptadas=Count("id", filter=Q(estado="ACEPTADA")),
                rechazadas=Count("id", filter=Q(estado="RECHAZADA")),
            )
        )

        return Response(
            {
                "totales": stats,
                "por_rol": list(por_rol),
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=True, methods=["delete"])
    @transaction.atomic
    @log_action("DELETE_ROLE_REQUEST")
    def eliminar(self, request, pk=None):
        try:
            solicitud = self.get_object()

            if solicitud.estado == "ACEPTADA":
                logger.warning(
                    f"ATENCION: Eliminando solicitud ACEPTADA. "
                    f"El usuario {solicitud.user.email} MANTIENE el rol {solicitud.rol_solicitado}"
                )

            registrar_accion_admin(
                request,
                "eliminar_solicitud_rol",
                f"Solicitud {solicitud.get_estado_display()} eliminada: "
                f"{solicitud.user.email} -> {solicitud.rol_solicitado}",
                modelo_afectado="SolicitudCambioRol",
                objeto_id=str(solicitud.id),
                datos_anteriores={
                    "estado": solicitud.estado,
                    "usuario": solicitud.user.email,
                    "rol": solicitud.rol_solicitado,
                },
            )

            usuario_email = solicitud.user.email
            rol_solicitado = solicitud.rol_solicitado
            estado = solicitud.get_estado_display()

            solicitud.delete()

            return Response(
                {
                    "mensaje": f"Solicitud {estado} eliminada exitosamente",
                    "usuario": usuario_email,
                    "rol": rol_solicitado,
                    "estado_eliminado": estado,
                    "advertencia": (
                        "El usuario mantiene su rol actual"
                        if estado == "ACEPTADA"
                        else None
                    ),
                },
                status=status.HTTP_200_OK,
            )

        except SolicitudCambioRol.DoesNotExist:
            return Response(
                {"error": "Solicitud no encontrada"}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return self.handle_error(e, "Error al eliminar solicitud")

    @action(detail=True, methods=["post"])
    @transaction.atomic
    @log_action("REVERT_ROLE_CHANGE")
    def revertir(self, request, pk=None):
        try:
            solicitud = self.get_object()
            
            motivo = request.data.get("motivo_reversion", "").strip()
            if not motivo:
                motivo = "Reversión de cambio de rol por decisión administrativa"

            if len(motivo) < 10:
                return Response(
                    {"error": "El motivo debe tener al menos 10 caracteres"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            resultado = GestorSolicitudCambioRol.revertir_solicitud(
                solicitud=solicitud,
                admin=request.user,
                motivo_reversion=motivo,
            )

            registrar_accion_admin(
                request,
                "revertir_cambio_rol",
                f"Cambio de rol revertido: {resultado['usuario']} "
                f"{resultado['rol_anterior']} -> {resultado['rol_actual']}. "
                f"Motivo: {motivo}",
                modelo_afectado="SolicitudCambioRol",
                objeto_id=str(solicitud.id),
                datos_anteriores={
                    "estado": "ACEPTADA",
                    "rol_usuario": resultado["rol_anterior"],
                },
                datos_nuevos={
                    "estado": "REVERTIDA",
                    "rol_usuario": resultado["rol_actual"],
                    "motivo_reversion": motivo,
                },
            )

            solicitud.refresh_from_db()

            return Response(
                {
                    "mensaje": resultado["mensaje"],
                    "usuario": resultado["usuario"],
                    "rol_anterior": resultado["rol_anterior"],
                    "rol_actual": resultado["rol_actual"],
                    "solicitud": self.get_serializer(solicitud).data,
                },
                status=status.HTTP_200_OK,
            )

        except ValidationError as e:
            return self.handle_error(e, "Error de validación al revertir")
        except Exception as e:
            return self.handle_error(e, "Error al revertir solicitud")

# ============================================
# VIEWSET: GESTIÓN DE PROPIOS ADMINISTRADORES
# ============================================
# ============================================
# VIEWSET: GESTIÓN DE PROPIOS ADMINISTRADORES
# ============================================
class AdministradoresViewSet(BaseAdminViewSetMixin, viewsets.ModelViewSet):
    """ViewSet para que los Super Admins gestionen a otros Administradores."""
    
    permission_classes = [
        IsAuthenticated, 
        EsAdministrador, 
        AdministradorActivo, 
        PuedeConfigurarSistema 
    ]
    serializer_class = AdministradorSerializer
    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter, 
        filters.OrderingFilter
    ]
    search_fields = ['user__email', 'user__first_name', 'user__last_name', 'cargo']
    ordering_fields = ['creado_en', 'total_acciones']
    ordering = ['-creado_en']

    def get_queryset(self):
        # Protección para Swagger
        if getattr(self, 'swagger_fake_view', False):
            return Administrador.objects.none()

        return Administrador.objects.select_related('user').all()

    @log_action("CREATE_ADMIN_PROFILE")
    def create(self, request, *args, **kwargs):
        return super().create(request, *args, **kwargs)

    @log_action("UPDATE_ADMIN_PROFILE")
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        
        registrar_accion_admin(
            request,
            "editar_admin",
            f"Modificación de permisos para admin: {instance.user.email}",
            modelo_afectado="Administrador",
            objeto_id=str(instance.id)
        )
        # ✅ CORRECCIÓN: Indentación correcta para el return
        return super().update(request, *args, partial=partial, **kwargs)
        
