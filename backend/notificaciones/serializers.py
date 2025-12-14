# notificaciones/serializers.py (VERSIÓN CORREGIDA Y FINAL)
"""
Serializers para la API de Notificaciones.
Transforma los datos del modelo para enviarlos a la App Móvil.
"""

from rest_framework import serializers
from notificaciones.models import Notificacion
from pedidos.models import Pedido


# ==========================================================
#  SERIALIZERS AUXILIARES
# ==========================================================

class PedidoMiniSerializer(serializers.ModelSerializer):
    """
    Versión ligera del Pedido para incrustar en la notificación.
    Evita ciclos infinitos y datos innecesarios.
    """
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    
    class Meta:
        model = Pedido
        fields = ['id', 'numero_pedido', 'estado', 'estado_display', 'total']
        read_only_fields = fields


# ==========================================================
#  SERIALIZERS PRINCIPALES
# ==========================================================

class NotificacionSerializer(serializers.ModelSerializer):
    """
    Serializer COMPLETO para ver detalles (incluye JSON extra y pedido).
    """
    # Campos calculados y formateados
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    hace_cuanto = serializers.CharField(read_only=True) # "Hace 5 min"
    
    # Relación anidada optimizada (solo lectura)
    pedido_info = PedidoMiniSerializer(source='pedido', read_only=True)

    class Meta:
        model = Notificacion
        fields = [
            'id',
            'tipo',
            'tipo_display',
            'titulo',
            'mensaje',
            'leida',
            'leida_en',
            'creada_en',
            'hace_cuanto',   # <--- Campo útil para UI
            'datos_extra',   # JSON para navegación en App
            'pedido_info',   # Objeto pedido incrustado
        ]
        read_only_fields = [
            'id', 'tipo', 'titulo', 'mensaje', 
            'creada_en', 'hace_cuanto', 'datos_extra', 'pedido_info'
        ]


class NotificacionListSerializer(serializers.ModelSerializer):
    """
    Serializer LIGERO para listados.
    No incluye datos_extra pesados ni el objeto pedido completo.
    """
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    hace_cuanto = serializers.CharField(read_only=True)

    class Meta:
        model = Notificacion
        fields = [
            'id',
            'tipo',
            'tipo_display',
            'titulo',
            'mensaje',
            'leida',
            'creada_en',
            'hace_cuanto',
        ]
        read_only_fields = fields


# ==========================================================
#  SERIALIZERS DE ACCIÓN (INPUT)
# ==========================================================

class MarcarLeidaSerializer(serializers.Serializer):
    """
    Valida la petición para marcar una o varias notificaciones.
    """
    ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        help_text="Lista de IDs para marcar (opcional si marcar_todas=True)"
    )
    marcar_todas = serializers.BooleanField(
        default=False,
        help_text="Si es True, marca todo lo del usuario como leído"
    )

    def validate(self, data):
        """Asegura que el cliente envíe una instrucción clara"""
        if not data.get('marcar_todas') and not data.get('ids'):
            raise serializers.ValidationError(
                "Debes enviar una lista de 'ids' o 'marcar_todas': true"
            )
        return data


class EstadisticasNotificacionesSerializer(serializers.Serializer):
    """
    Estructura de respuesta para el endpoint de conteo (Badge de campana).
    """
    total = serializers.IntegerField()
    no_leidas = serializers.IntegerField()
    leidas = serializers.IntegerField()
    ultimas_5 = NotificacionListSerializer(many=True) # Usamos el ligero aquí