from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser
from .models import DocumentoLegal
from .serializers import DocumentoLegalSerializer, DocumentoLegalPublicoSerializer


class DocumentoLegalViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar documentos legales.

    - GET /api/legal/ - Listar todos los documentos (solo admin)
    - GET /api/legal/{id}/ - Ver un documento específico (solo admin)
    - POST /api/legal/ - Crear documento (solo admin)
    - PUT/PATCH /api/legal/{id}/ - Actualizar documento (solo admin)
    - DELETE /api/legal/{id}/ - Eliminar documento (solo admin)

    Endpoints públicos:
    - GET /api/legal/terminos/ - Ver términos y condiciones (público)
    - GET /api/legal/privacidad/ - Ver política de privacidad (público)
    """
    queryset = DocumentoLegal.objects.all()
    serializer_class = DocumentoLegalSerializer

    def get_permissions(self):
        """
        Solo administradores pueden crear/editar/eliminar.
        Endpoints públicos (terminos, privacidad) son accesibles sin autenticación.
        """
        if self.action in ['terminos', 'privacidad']:
            return [AllowAny()]
        return [IsAdminUser()]

    def get_serializer_class(self):
        """
        Usar serializer público para endpoints públicos
        """
        if self.action in ['terminos', 'privacidad']:
            return DocumentoLegalPublicoSerializer
        return DocumentoLegalSerializer

    @action(detail=False, methods=['get'])
    def terminos(self, request):
        """
        Endpoint público para obtener los términos y condiciones vigentes.
        GET /api/legal/terminos/
        """
        try:
            documento = DocumentoLegal.objects.get(tipo='terminos', activo=True)
            serializer = self.get_serializer(documento)
            return Response(serializer.data)
        except DocumentoLegal.DoesNotExist:
            return Response(
                {'detail': 'Términos y condiciones no disponibles'},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['get'])
    def privacidad(self, request):
        """
        Endpoint público para obtener la política de privacidad vigente.
        GET /api/legal/privacidad/
        """
        try:
            documento = DocumentoLegal.objects.get(tipo='privacidad', activo=True)
            serializer = self.get_serializer(documento)
            return Response(serializer.data)
        except DocumentoLegal.DoesNotExist:
            return Response(
                {'detail': 'Política de privacidad no disponible'},
                status=status.HTTP_404_NOT_FOUND
            )
