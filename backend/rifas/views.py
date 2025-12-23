# -*- coding: utf-8 -*-
# rifas/views.py
"""
Views/ViewSets para API REST de Rifas

FUNCIONALIDADES:
- CRUD de rifas (solo admin)
- Consulta de rifa activa (usuarios)
- Verificar elegibilidad personal
- Realizar sorteo (admin)
- Historial de ganadores
- Estadísticas
"""

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction, IntegrityError
from django.utils import timezone
from django.core.exceptions import ValidationError
from .models import Rifa, Participacion, EstadoRifa, Premio, TipoSorteo
from .serializers import (
    RifaListSerializer,
    RifaDetailSerializer,
    RifaWriteSerializer,
    RifaActivaAppSerializer,
    RifaMesActualSerializer,
    RifaDetalleAppSerializer,
    ParticipacionSerializer,
    ParticipacionSimpleSerializer,
    ElegibilidadSerializer,
    RealizarSorteoSerializer,
    SorteoResultadoSerializer,
    HistorialGanadoresSerializer,
    EstadisticasRifasSerializer,
    ListaParticipantesSerializer,
    ParticipanteSerializer,
    UsuarioSimpleSerializer,
)
from authentication.models import User
from pedidos.models import Pedido, EstadoPedido

import logging

logger = logging.getLogger("rifas")


# ============================================
# 🔐 PERMISOS PERSONALIZADOS
# ============================================


class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Permite lectura a todos, escritura solo a admin
    """

    def has_permission(self, request, view):
        # Lectura permitida para todos los autenticados
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated

        # Escritura solo para admin
        return request.user and request.user.is_staff


class IsAdmin(permissions.BasePermission):
    """
    Solo admin puede acceder
    """

    def has_permission(self, request, view):
        return request.user and request.user.is_staff


# ============================================
# 🎲 VIEWSET: RIFAS
# ============================================


class RifaViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestión de Rifas

    ✅ ENDPOINTS:
    - GET    /api/rifas/              - Listar todas las rifas
    - GET    /api/rifas/{id}/         - Detalle de rifa
    - POST   /api/rifas/              - Crear rifa (admin)
    - PUT    /api/rifas/{id}/         - Actualizar rifa (admin)
    - DELETE /api/rifas/{id}/         - Eliminar rifa (admin)

    ✅ CUSTOM ACTIONS:
    - GET    /api/rifas/activa/                  - Rifa activa actual
    - GET    /api/rifas/{id}/elegibilidad/       - Mi elegibilidad
    - POST   /api/rifas/{id}/participar/         - Registrar participación
    - POST   /api/rifas/{id}/sortear/            - Realizar sorteo (admin)
    - GET    /api/rifas/{id}/participantes/      - Lista participantes (admin)
    - GET    /api/rifas/historial_ganadores/     - Historial
    - GET    /api/rifas/estadisticas/            - Estadísticas generales
    """

    queryset = (
        Rifa.objects.all()
        .select_related("creado_por")
        .prefetch_related("premios__ganador")
        .order_by("-fecha_inicio")
    )

    permission_classes = [IsAdminOrReadOnly]

    def get_serializer_class(self):
        """Seleccionar serializer según acción"""
        if self.action == "list":
            return RifaListSerializer
        elif self.action in ["create", "update", "partial_update"]:
            return RifaWriteSerializer
        elif self.action == "activa":
            return RifaActivaAppSerializer
        elif self.action == "mes_actual":
            return RifaMesActualSerializer
        elif self.action == "detalle":
            return RifaDetalleAppSerializer
        elif self.action == "sortear":
            return SorteoResultadoSerializer
        elif self.action == "participantes":
            return ListaParticipantesSerializer
        elif self.action == "historial_ganadores":
            return HistorialGanadoresSerializer
        elif self.action == "estadisticas":
            return EstadisticasRifasSerializer
        else:
            return RifaDetailSerializer

    def get_permissions(self):
        """Permisos según acción"""
        if self.action in [
            "sortear",
            "participantes",
            "create",
            "update",
            "partial_update",
            "destroy",
        ]:
            return [IsAdmin()]
        return [IsAuthenticated()]

    def get_queryset(self):
        # Protección básica para Swagger en el queryset principal
        if getattr(self, "swagger_fake_view", False):
            return Rifa.objects.none()
        return super().get_queryset()

    # ============================================
    # 📋 CRUD ESTÁNDAR
    # ============================================

    def list(self, request, *args, **kwargs):
        """
        Lista todas las rifas

        Query params opcionales:
        - estado: filtrar por estado (activa/finalizada/cancelada)
        - mes: filtrar por mes (1-12)
        - anio: filtrar por año
        """
        queryset = self.get_queryset()

        # Filtros opcionales
        estado = request.query_params.get("estado")
        mes = request.query_params.get("mes")
        anio = request.query_params.get("anio")

        if estado:
            queryset = queryset.filter(estado=estado)

        if mes:
            queryset = queryset.filter(mes=int(mes))

        if anio:
            queryset = queryset.filter(anio=int(anio))

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        """Detalle de una rifa específica"""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        """
        Crear nueva rifa (solo admin)
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)

            # Retornar detalle completo
            rifa = serializer.instance
            detail_serializer = RifaDetailSerializer(rifa, context={"request": request})

            logger.info(f"Rifa creada por {request.user.email}: {rifa.titulo}")

            return Response(detail_serializer.data, status=status.HTTP_201_CREATED)
        except IntegrityError:
            return Response(
                {
                    "error": "Error de base de datos: Posiblemente ya existe una rifa activa para este mes."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        except ValidationError as e:
            return Response(
                {"error": e.message_dict if hasattr(e, "message_dict") else str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

    @transaction.atomic
    def update(self, request, *args, **kwargs):
        """Actualizar rifa (solo admin)"""
        try:
            partial = kwargs.pop("partial", False)
            instance = self.get_object()
            serializer = self.get_serializer(
                instance, data=request.data, partial=partial
            )
            serializer.is_valid(raise_exception=True)
            self.perform_update(serializer)

            # Retornar detalle completo
            detail_serializer = RifaDetailSerializer(
                instance, context={"request": request}
            )

            logger.info(f"Rifa actualizada por {request.user.email}: {instance.titulo}")

            return Response(detail_serializer.data)
        except IntegrityError:
            return Response(
                {"error": "Error de base de datos al actualizar la rifa."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except ValidationError as e:
            return Response(
                {"error": e.message_dict if hasattr(e, "message_dict") else str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

    def destroy(self, request, *args, **kwargs):
        """
        Eliminar rifa (solo admin)
        Solo se pueden eliminar rifas canceladas o finalizadas
        """
        instance = self.get_object()

        if instance.estado not in [EstadoRifa.CANCELADA, EstadoRifa.FINALIZADA]:
            return Response(
                {
                    "error": "Solo se pueden eliminar rifas canceladas o finalizadas",
                    "detail": "Cancela o finaliza la rifa antes de eliminarla",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        titulo = instance.titulo
        self.perform_destroy(instance)

        logger.warning(f"Rifa eliminada por {request.user.email}: {titulo}")

        return Response(
            {"message": f'Rifa "{titulo}" eliminada correctamente'},
            status=status.HTTP_204_NO_CONTENT,
        )

    # ============================================
    # 🎯 CUSTOM ACTIONS
    # ============================================

    @action(detail=False, methods=["get"], url_path="activa")
    def activa(self, request):
        """
        GET /api/rifas/activa/

        Obtiene la rifa activa actual
        Incluye elegibilidad del usuario autenticado
        """
        rifa = Rifa.obtener_rifa_activa()

        if not rifa:
            return Response(
                {"message": "No hay rifa activa en este momento", "rifa": None},
                status=status.HTTP_200_OK,
            )

        serializer = self.get_serializer(rifa)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="mes-actual")
    def mes_actual(self, request):
        """
        GET /api/rifas/mes-actual/

        Lista rifas del mes actual (app)
        """
        ahora = timezone.localtime()
        queryset = (
            Rifa.objects.filter(mes=ahora.month, anio=ahora.year)
            .prefetch_related("premios")
            .order_by("-fecha_inicio")
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["get"], url_path="detalle")
    def detalle(self, request, pk=None):
        """
        GET /api/rifas/{id}/detalle/

        Detalle de rifa con progreso del usuario
        """
        rifa = self.get_object()
        serializer = self.get_serializer(rifa)
        return Response(serializer.data)

    @action(detail=True, methods=["get"], url_path="elegibilidad")
    def elegibilidad(self, request, pk=None):
        """
        GET /api/rifas/{id}/elegibilidad/

        Verifica si el usuario actual es elegible para participar
        """
        rifa = self.get_object()

        elegibilidad = rifa.usuario_es_elegible(request.user)
        serializer = ElegibilidadSerializer(elegibilidad)

        return Response(
            {
                "rifa": {
                    "id": str(rifa.id),
                    "titulo": rifa.titulo,
                    "pedidos_minimos": rifa.pedidos_minimos,
                },
                "elegibilidad": serializer.data,
            }
        )

    @action(detail=True, methods=["post"], url_path="participar")
    def participar(self, request, pk=None):
        """
        POST /api/rifas/{id}/participar/

        Registra la participación del usuario autenticado.
        """
        rifa = self.get_object()
        ahora = timezone.now()

        if not rifa.esta_vigente(ahora):
            return Response(
                {
                    "success": False,
                    "message": "La rifa no está disponible para participar",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if Participacion.objects.filter(rifa=rifa, usuario=request.user).exists():
            return Response(
                {
                    "success": False,
                    "message": "Ya estás participando en esta rifa",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        elegibilidad = rifa.usuario_es_elegible(request.user)
        if not elegibilidad.get("elegible"):
            return Response(
                {
                    "success": False,
                    "message": elegibilidad.get("razon", "No cumples los requisitos"),
                    "elegibilidad": elegibilidad,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        participacion = Participacion.objects.create(
            rifa=rifa,
            usuario=request.user,
            pedidos_completados=elegibilidad.get("pedidos", 0),
        )

        return Response(
            {
                "success": True,
                "message": "Participación registrada correctamente",
                "participacion": ParticipacionSerializer(
                    participacion,
                    context={"request": request},
                ).data,
                "rifa": RifaActivaAppSerializer(
                    rifa,
                    context={"request": request},
                ).data,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(
        detail=True, methods=["post"], url_path="sortear", permission_classes=[IsAdmin]
    )
    @transaction.atomic
    def sortear(self, request, pk=None):
        """
        POST /api/rifas/{id}/sortear/

        Realiza el sorteo de la rifa (solo admin)

        Body: {"confirmar": true}
        """
        rifa = self.get_object()
        rifa = Rifa.objects.select_for_update().get(pk=pk)

        # Validar input
        input_serializer = RealizarSorteoSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)
        forzar = input_serializer.validated_data.get("forzar", False)

        if (
            rifa.tipo_sorteo == TipoSorteo.MANUAL
            and timezone.now() < rifa.fecha_fin
            and not forzar
        ):
            return Response(
                {
                    "success": False,
                    "error": "El sorteo manual solo puede realizarse después de la fecha de finalización de la rifa.",
                    "puede_forzar": True,
                    "fecha_fin": rifa.fecha_fin,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Verificar estado
        if rifa.estado != EstadoRifa.ACTIVA:
            return Response(
                {
                    "success": False,
                    "error": f"No se puede sortear una rifa {rifa.get_estado_display().lower()}",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if rifa.premios.filter(ganador__isnull=False).exists():
            return Response(
                {"success": False, "error": "Esta rifa ya tiene ganadores asignados"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Realizar sorteo
        try:
            resultado = rifa.realizar_sorteo()

            if resultado.get("sin_participantes"):
                return Response(
                    {
                        "success": False,
                        "message": "No hay participantes registrados para sortear",
                        "premios_ganados": [],
                        "rifa": RifaListSerializer(
                            rifa, context={"request": request}
                        ).data,
                        "total_participantes": 0,
                        "sin_participantes": True,
                    }
                )

            premios_ganados = resultado.get("premios_ganados", [])
            premios_data = [
                {
                    "posicion": p["posicion"],
                    "descripcion": p["descripcion"],
                    "ganador": (
                        UsuarioSimpleSerializer(p["ganador"]).data
                        if p.get("ganador")
                        else None
                    ),
                }
                for p in premios_ganados
            ]

            logger.info(
                f"Sorteo realizado por {request.user.email} "
                f"para rifa {rifa.titulo} | Premios: {len(premios_ganados)}"
            )

            return Response(
                {
                    "success": True,
                    "message": "¡Sorteo realizado!",
                    "premios_ganados": premios_data,
                    "rifa": RifaListSerializer(rifa, context={"request": request}).data,
                    "total_participantes": rifa.total_participantes,
                    "sin_participantes": False,
                }
            )

        except ValidationError as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Error al realizar sorteo: {str(e)}")
            return Response(
                {"success": False, "error": "Error interno al realizar el sorteo"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    @action(
        detail=True,
        methods=["get"],
        url_path="participantes",
        permission_classes=[IsAdmin],
    )
    def participantes(self, request, pk=None):
        """
        GET /api/rifas/{id}/participantes/

        Lista todos los participantes registrados (solo admin)
        """
        rifa = self.get_object()

        participaciones = rifa.participaciones.select_related("usuario").order_by(
            "-fecha_registro"
        )
        participantes_data = [
            {
                "usuario": participacion.usuario,
                "pedidos_completados": participacion.pedidos_completados,
                "elegible": True,
            }
            for participacion in participaciones
        ]

        return Response(
            {
                "total": len(participantes_data),
                "participantes": ParticipanteSerializer(
                    participantes_data, many=True
                ).data,
            }
        )

    @action(detail=False, methods=["get"], url_path="historial-ganadores")
    def historial_ganadores(self, request):
        """
        GET /api/rifas/historial-ganadores/

        Obtiene historial de ganadores recientes

        Query params:
        - limit: cantidad de registros (default: 10)
        """
        limit = int(request.query_params.get("limit", 10))

        historial = Rifa.obtener_historial_ganadores(limit=limit)

        data = []
        for rifa in historial:
            premios_data = []
            for premio in rifa.premios.all().order_by("-posicion"):
                if premio.ganador:
                    premios_data.append(
                        {
                            "posicion": premio.posicion,
                            "descripcion": premio.descripcion,
                            "ganador": premio.ganador,
                        }
                    )

            data.append(
                {
                    "id": rifa.id,
                    "titulo": rifa.titulo,
                    "mes_nombre": rifa.mes_nombre,
                    "anio": rifa.anio,
                    "premios": premios_data,
                    "fecha_fin": rifa.fecha_fin,
                    "total_participantes": rifa.total_participantes,
                }
            )

        serializer = HistorialGanadoresSerializer(data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="estadisticas")
    def estadisticas(self, request):
        """
        GET /api/rifas/estadisticas/

        Obtiene estadísticas generales del sistema de rifas
        """
        # Rifa activa
        rifa_activa = Rifa.obtener_rifa_activa()

        # Totales
        total_rifas = Rifa.objects.filter(estado=EstadoRifa.FINALIZADA).count()
        total_ganadores = Premio.objects.filter(ganador__isnull=False).count()

        # Últimos ganadores
        ultimos_ganadores = Rifa.obtener_historial_ganadores(limit=5)

        # Estadísticas personales del usuario
        mis_participaciones = Participacion.objects.filter(usuario=request.user).count()

        mis_victorias = Participacion.objects.filter(
            usuario=request.user, ganador=True
        ).count()

        # Construir datos para serializer
        ultimos_ganadores_data = []
        for rifa in ultimos_ganadores:
            premios_data = []
            for premio in rifa.premios.all().order_by("-posicion"):
                if premio.ganador:
                    premios_data.append(
                        {
                            "posicion": premio.posicion,
                            "descripcion": premio.descripcion,
                            "ganador": premio.ganador,
                        }
                    )

            ultimos_ganadores_data.append(
                {
                    "id": rifa.id,
                    "titulo": rifa.titulo,
                    "mes_nombre": rifa.mes_nombre,
                    "anio": rifa.anio,
                    "premios": premios_data,
                    "fecha_fin": rifa.fecha_fin,
                    "total_participantes": rifa.total_participantes,
                }
            )

        data = {
            "rifa_activa": rifa_activa,
            "total_rifas_realizadas": total_rifas,
            "total_ganadores": total_ganadores,
            "ultimos_ganadores": ultimos_ganadores_data,
            "mi_participaciones": mis_participaciones,
            "mis_victorias": mis_victorias,
        }

        serializer = EstadisticasRifasSerializer(data, context={"request": request})
        return Response(serializer.data)

    @action(
        detail=True,
        methods=["post"],
        url_path="premios/(?P<premio_pk>[^/.]+)/cancelar",
        permission_classes=[IsAdmin],
    )
    def cancelar_premio(self, request, pk=None, premio_pk=None):
        """
        POST /api/rifas/{id}/premios/{premio_id}/cancelar/

        Cancela un premio específico de una rifa (solo admin).
        Un premio no puede ser cancelado si ya tiene un ganador.
        """
        rifa = self.get_object()
        premio = get_object_or_404(Premio, pk=premio_pk, rifa=rifa)

        if premio.ganador:
            return Response(
                {"error": "No se puede cancelar un premio que ya tiene un ganador."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if premio.estado == EstadoPremio.CANCELADO:
            return Response(
                {"message": "El premio ya se encontraba cancelado."},
                status=status.HTTP_200_OK,
            )

        premio.estado = EstadoPremio.CANCELADO
        premio.save()

        logger.warning(
            f"Premio {premio.posicion} ({premio.descripcion}) de la rifa '{rifa.titulo}' "
            f"cancelado por {request.user.email}."
        )

        # Usamos el serializer de premios para devolver el estado actualizado
        from .serializers import PremioSerializer

        return Response(
            {
                "success": True,
                "message": "Premio cancelado correctamente.",
                "premio": PremioSerializer(premio, context={"request": request}).data,
            }
        )

    @action(
        detail=True, methods=["post"], url_path="cancelar", permission_classes=[IsAdmin]
    )
    def cancelar(self, request, pk=None):
        """
        POST /api/rifas/{id}/cancelar/

        Cancela una rifa (solo admin)

        Body (opcional): {"motivo": "razón de cancelación"}
        """
        rifa = self.get_object()

        motivo = request.data.get("motivo", "Sin motivo especificado")

        try:
            rifa.cancelar_rifa(motivo=motivo)

            logger.warning(
                f"Rifa cancelada por {request.user.email}: {rifa.titulo}. "
                f"Motivo: {motivo}"
            )

            return Response(
                {
                    "success": True,
                    "message": f'Rifa "{rifa.titulo}" cancelada correctamente',
                    "motivo": motivo,
                    "rifa": RifaListSerializer(rifa, context={"request": request}).data,
                }
            )

        except ValidationError as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )


# ============================================
# 🎟️ VIEWSET: PARTICIPACIONES
# ============================================


class ParticipacionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet de solo lectura para Participaciones

    ✅ ENDPOINTS:
    - GET /api/participaciones/              - Listar participaciones
    - GET /api/participaciones/{id}/         - Detalle de participación
    - GET /api/participaciones/mis-participaciones/  - Mis participaciones
    """

    queryset = (
        Participacion.objects.all()
        .select_related("rifa", "usuario")
        .order_by("-fecha_registro")
    )

    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Seleccionar serializer"""
        if self.action == "list":
            return ParticipacionSimpleSerializer
        return ParticipacionSerializer

    def get_queryset(self):
        """
        Filtrar queryset según usuario:
        - Admin: ve todas
        - Usuario: solo sus participaciones
        """
        # 1. Protección para Swagger (Evita Error 500 con AnonymousUser)
        if getattr(self, "swagger_fake_view", False):
            return Participacion.objects.none()

        # 2. Protección para usuario no autenticado
        if not self.request.user.is_authenticated:
            return Participacion.objects.none()

        queryset = super().get_queryset()

        # 3. Lógica de negocio
        if self.request.user.is_staff:
            return queryset

        return queryset.filter(usuario=self.request.user)

    @action(detail=False, methods=["get"], url_path="mis-participaciones")
    def mis_participaciones(self, request):
        """
        GET /api/participaciones/mis-participaciones/

        Obtiene todas las participaciones del usuario actual
        """
        # Protección adicional si se llama directamente
        if not request.user.is_authenticated:
            return Response(status=status.HTTP_401_UNAUTHORIZED)

        participaciones = (
            Participacion.objects.filter(usuario=request.user)
            .select_related("rifa")
            .order_by("-fecha_registro")
        )

        serializer = ParticipacionSerializer(
            participaciones, many=True, context={"request": request}
        )

        return Response(
            {
                "total": participaciones.count(),
                "victorias": participaciones.filter(ganador=True).count(),
                "participaciones": serializer.data,
            }
        )
