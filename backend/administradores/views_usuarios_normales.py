# administradores/views_usuarios_normales.py

from django.contrib.auth import get_user_model
from rest_framework import mixins, viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .serializers import UsuarioNormalSerializer

from .permissions import (
    EsAdministrador,
    AdministradorActivo,
)

User = get_user_model()


class UsuariosNormalesViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """
    Devuelve SOLO usuarios normales:
    - Sin perfil_admin
    - Sin proveedor
    - Sin repartidor
    """

    permission_classes = [
        IsAuthenticated,
        EsAdministrador,
        AdministradorActivo,
    ]
    
    serializer_class = UsuarioNormalSerializer

    def get_queryset(self):
        return User.objects.filter(
            perfil_admin__isnull=True,
            proveedor__isnull=True,
            repartidor__isnull=True
        )

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()

        data = [
            {
                "id": u.id,
                "email": u.email,
                "first_name": u.first_name,
                "last_name": u.last_name,
                "is_active": u.is_active,
                "last_login": u.last_login,
            }
            for u in queryset
        ]

        return Response(data, status=status.HTTP_200_OK)
