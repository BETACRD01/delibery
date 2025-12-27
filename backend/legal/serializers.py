from rest_framework import serializers
from .models import DocumentoLegal


class DocumentoLegalSerializer(serializers.ModelSerializer):
    """
    Serializer para los documentos legales
    """
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)

    class Meta:
        model = DocumentoLegal
        fields = [
            'id',
            'tipo',
            'tipo_display',
            'contenido',
            'version',
            'activo',
            'fecha_creacion',
            'fecha_modificacion',
            'modificado_por'
        ]
        read_only_fields = ['fecha_creacion', 'fecha_modificacion']


class DocumentoLegalPublicoSerializer(serializers.ModelSerializer):
    """
    Serializer público para mostrar documentos legales a usuarios
    (sin campos administrativos)
    """
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)

    class Meta:
        model = DocumentoLegal
        fields = [
            'tipo',
            'tipo_display',
            'contenido',
            'version',
            'fecha_modificacion'
        ]
