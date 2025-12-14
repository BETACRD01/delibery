# -*- coding: utf-8 -*-
# rifas/serializers.py
"""
Serializadores para API REST de Rifas

 FUNCIONALIDADES:
- Serialización completa de rifas
- Elegibilidad de usuarios
- Participantes y ganadores
- Estadísticas en tiempo real
- Optimización de queries
"""

from rest_framework import serializers
from django.utils import timezone
from django.db.models import Count, Q
from .models import Rifa, Participacion, EstadoRifa, Premio
from authentication.models import User
from pedidos.models import EstadoPedido
import logging

logger = logging.getLogger('rifas')


# ============================================
#  SERIALIZER: USUARIO SIMPLE
# ============================================

class UsuarioSimpleSerializer(serializers.ModelSerializer):
    """
    Serializer básico para mostrar info de usuarios
    (usado en ganadores y participantes)
    """

    nombre_completo = serializers.CharField(
        source='get_full_name',
        read_only=True
    )

    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'first_name',
            'last_name',
            'nombre_completo'
        ]
        read_only_fields = fields


# ============================================
# SERIALIZER: PREMIO
# ============================================

class PremioSerializer(serializers.ModelSerializer):
    """
    Serializer para premios individuales de una rifa
    """

    ganador = UsuarioSimpleSerializer(read_only=True)
    imagen_url = serializers.SerializerMethodField()
    posicion_display = serializers.SerializerMethodField()

    class Meta:
        model = Premio
        fields = [
            'id',
            'posicion',
            'posicion_display',
            'descripcion',
            'imagen',
            'imagen_url',
            'ganador'
        ]
        read_only_fields = ['id', 'ganador']

    def get_imagen_url(self, obj):
        """URL completa de la imagen del premio"""
        if obj.imagen:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url)
            return obj.imagen.url
        return None

    def get_posicion_display(self, obj):
        """Nombre descriptivo de la posición"""
        nombres = {1: '1er Lugar', 2: '2do Lugar', 3: '3er Lugar'}
        return nombres.get(obj.posicion, f'{obj.posicion}° Lugar')


class PremioWriteSerializer(serializers.ModelSerializer):
    """
    Serializer para crear/actualizar premios
    """

    class Meta:
        model = Premio
        fields = ['posicion', 'descripcion', 'imagen']

    def validate_posicion(self, value):
        """Validar que la posición sea 1, 2 o 3"""
        if value not in [1, 2, 3]:
            raise serializers.ValidationError("La posición debe ser 1, 2 o 3")
        return value


class PremioGanadoSerializer(serializers.Serializer):
    """
    Serializer para representar el resultado de un premio sorteado
    """

    posicion = serializers.IntegerField()
    descripcion = serializers.CharField()
    ganador = UsuarioSimpleSerializer(allow_null=True)


# ============================================
# SERIALIZER: RIFA (LISTADO)
# ============================================

class RifaListSerializer(serializers.ModelSerializer):
    """
    Serializer para listado de rifas (sin detalles pesados)
    Optimizado para performance en listas
    """

    estado_display = serializers.CharField(
        source='get_estado_display',
        read_only=True
    )

    mes_nombre = serializers.CharField(read_only=True)

    dias_restantes = serializers.IntegerField(read_only=True)

    total_participantes = serializers.SerializerMethodField()

    # Múltiples premios
    premios = PremioSerializer(many=True, read_only=True)

    imagen_url = serializers.SerializerMethodField()

    class Meta:
        model = Rifa
        fields = [
            'id',
            'titulo',
            'imagen_url',
            'fecha_inicio',
            'fecha_fin',
            'mes',
            'anio',
            'mes_nombre',
            'estado',
            'estado_display',
            'dias_restantes',
            'total_participantes',
            'premios'
        ]
        read_only_fields = fields

    def get_total_participantes(self, obj):
        """Calcula total de participantes elegibles"""
        # Usamos el método del modelo que ya está optimizado
        return obj.total_participantes

    def get_imagen_url(self, obj):
        """URL completa de la imagen de la rifa"""
        if obj.imagen:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url)
            return obj.imagen.url
        return None


# ============================================
# SERIALIZER: ELEGIBILIDAD DE USUARIO
# ============================================

class ElegibilidadSerializer(serializers.Serializer):
    """
    Serializer para verificar elegibilidad de un usuario
    """

    elegible = serializers.BooleanField()
    pedidos = serializers.IntegerField()
    faltantes = serializers.IntegerField()
    razon = serializers.CharField()

    class Meta:
        fields = [
            'elegible',
            'pedidos',
            'faltantes',
            'razon'
        ]


# ============================================
# SERIALIZER: PARTICIPANTE
# ============================================

class ParticipanteSerializer(serializers.Serializer):
    """
    Serializer para participantes elegibles de una rifa
    """

    usuario = UsuarioSimpleSerializer()
    pedidos_completados = serializers.IntegerField()
    elegible = serializers.BooleanField()

    class Meta:
        fields = [
            'usuario',
            'pedidos_completados',
            'elegible'
        ]


# ============================================
#  SERIALIZER: RIFA (DETALLE COMPLETO)
# ============================================

class RifaDetailSerializer(serializers.ModelSerializer):
    """
    Serializer completo con todos los detalles de la rifa
    Incluye estadísticas y participantes
    """

    estado_display = serializers.CharField(
        source='get_estado_display',
        read_only=True
    )

    mes_nombre = serializers.CharField(read_only=True)

    dias_restantes = serializers.IntegerField(read_only=True)

    esta_activa = serializers.BooleanField(read_only=True)

    total_participantes = serializers.SerializerMethodField()

    # Múltiples premios
    premios = PremioSerializer(many=True, read_only=True)

    creado_por = UsuarioSimpleSerializer(read_only=True)

    imagen_url = serializers.SerializerMethodField()

    # Elegibilidad del usuario actual
    mi_elegibilidad = serializers.SerializerMethodField()

    # Estadísticas adicionales
    estadisticas = serializers.SerializerMethodField()

    class Meta:
        model = Rifa
        fields = [
            'id',
            'titulo',
            'descripcion',
            'imagen_url',
            'fecha_inicio',
            'fecha_fin',
            'pedidos_minimos',
            'mes',
            'anio',
            'mes_nombre',
            'estado',
            'estado_display',
            'esta_activa',
            'dias_restantes',
            'total_participantes',
            'premios',
            'creado_por',
            'creado_en',
            'actualizado_en',
            'mi_elegibilidad',
            'estadisticas'
        ]
        read_only_fields = fields

    def get_total_participantes(self, obj):
        """Total de participantes elegibles"""
        return obj.total_participantes

    def get_imagen_url(self, obj):
        """URL completa de la imagen de la rifa"""
        if obj.imagen:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url)
            return obj.imagen.url
        return None

    def get_mi_elegibilidad(self, obj):
        """
        Verifica elegibilidad del usuario autenticado
        Solo se incluye si hay un usuario autenticado
        """
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None

        elegibilidad = obj.usuario_es_elegible(request.user)
        return ElegibilidadSerializer(elegibilidad).data

    def get_estadisticas(self, obj):
        """Estadísticas adicionales de la rifa"""
        premios_info = []
        for premio in obj.premios.all().order_by('-posicion'):
            premios_info.append({
                'posicion': premio.posicion,
                'descripcion': premio.descripcion,
                'tiene_ganador': premio.ganador is not None,
                'ganador': UsuarioSimpleSerializer(premio.ganador).data if premio.ganador else None
            })

        return {
            'total_participantes': obj.total_participantes,
            'dias_restantes': obj.dias_restantes,
            'pedidos_minimos_requeridos': obj.pedidos_minimos,
            'total_premios': obj.premios.count(),
            'premios': premios_info
        }


# ============================================
# SERIALIZER: CREAR/ACTUALIZAR RIFA (ADMIN)
# ============================================

class RifaWriteSerializer(serializers.ModelSerializer):
    """
    Serializer para crear/actualizar rifas (solo admin)
    Ahora soporta múltiples premios
    """

    premios = PremioWriteSerializer(many=True, required=False)

    class Meta:
        model = Rifa
        fields = [
            'titulo',
            'descripcion',
            'imagen',
            'fecha_inicio',
            'fecha_fin',
            'pedidos_minimos',
            'estado',
            'premios'
        ]

    def to_internal_value(self, data):
        """
        Sobrescribir para parsear premios desde multipart antes de validación
        """
        import re

        # Si no hay premios en data pero hay campos multipart tipo premios[0][posicion]
        if 'premios' not in data or not data.get('premios'):
            premios_dict = {}

            for key in list(data.keys()):
                if key.startswith('premios['):
                    try:
                        match = re.match(r'premios\[(\d+)\]\[(\w+)\]', key)
                        if match:
                            index = int(match.group(1))
                            field = match.group(2)

                            if index not in premios_dict:
                                premios_dict[index] = {}

                            value = data[key]

                            # Skip imagen fields - esos vienen en FILES
                            if field == 'imagen':
                                continue

                            # Convertir posicion a int
                            if field == 'posicion':
                                value = int(value) if value else None

                            # Solo agregar si no está vacío
                            if value:
                                premios_dict[index][field] = value
                    except (ValueError, IndexError, AttributeError) as e:
                        logger.warning(f"Error parseando key {key}: {e}")
                        continue

            # Convertir a lista y agregar a data
            if premios_dict:
                premios_list = [premios_dict[i] for i in sorted(premios_dict.keys())]
                # Crear una copia mutable de data
                data = data.copy()
                data['premios'] = premios_list
                logger.info(f"Premios parseados: {premios_list}")

        return super().to_internal_value(data)

    def validate_fecha_fin(self, value):
        """Validar que fecha_fin sea posterior a fecha_inicio"""
        fecha_inicio = self.initial_data.get('fecha_inicio')

        if fecha_inicio:
            from datetime import datetime
            from django.utils import timezone

            if isinstance(fecha_inicio, str):
                # Limpiar el string y parsear
                fecha_str = fecha_inicio.replace('Z', '+00:00')
                fecha_inicio = datetime.fromisoformat(fecha_str)

            # Asegurar que ambas fechas tengan el mismo nivel de timezone awareness
            if timezone.is_naive(fecha_inicio):
                fecha_inicio = timezone.make_aware(fecha_inicio)

            if timezone.is_naive(value):
                value = timezone.make_aware(value)

            if value <= fecha_inicio:
                raise serializers.ValidationError(
                    "La fecha de fin debe ser posterior a la fecha de inicio"
                )

        return value

    def validate_premios(self, value):
        """Validar premios"""
        # Si value está vacío, la validación se hará en create() con datos multipart
        if not value:
            return value

        if len(value) > 3:
            raise serializers.ValidationError("Solo puede crear hasta 3 premios")

        # Validar que no se repitan posiciones
        posiciones = [p['posicion'] for p in value]
        if len(posiciones) != len(set(posiciones)):
            raise serializers.ValidationError("No puede haber premios con la misma posición")

        return value

    def validate(self, attrs):
        """Validaciones adicionales"""
        # Validar pedidos mínimos
        pedidos_minimos = attrs.get('pedidos_minimos', 3)
        if pedidos_minimos < 1:
            raise serializers.ValidationError({
                'pedidos_minimos': 'Debe requerir al menos 1 pedido'
            })

        # Validar que no exista otra rifa activa en el mismo mes/año
        fecha_inicio = attrs.get('fecha_inicio')
        estado = attrs.get('estado', EstadoRifa.ACTIVA)

        if fecha_inicio and estado == EstadoRifa.ACTIVA:
            mes = fecha_inicio.month
            anio = fecha_inicio.year

            # En modo actualización, excluir la rifa actual
            queryset = Rifa.objects.filter(
                mes=mes,
                anio=anio,
                estado=EstadoRifa.ACTIVA
            )

            # Si estamos actualizando, excluir la instancia actual
            if self.instance:
                queryset = queryset.exclude(pk=self.instance.pk)

            if queryset.exists():
                rifa_existente = queryset.first()
                raise serializers.ValidationError({
                    'fecha_inicio': f'Ya existe una rifa activa para {rifa_existente.mes_nombre} {anio}: "{rifa_existente.titulo}". '
                                   f'Debes finalizarla o cancelarla antes de crear una nueva rifa para este mes.'
                })

        return attrs

    def create(self, validated_data):
        """Crear rifa con premios"""
        premios_data = validated_data.pop('premios', [])

        # Validar que haya al menos 1 premio
        if not premios_data or len(premios_data) == 0:
            raise serializers.ValidationError({
                'premios': 'Debe crear al menos 1 premio'
            })

        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['creado_por'] = request.user

        rifa = super().create(validated_data)

        # Crear premios
        for premio_data in premios_data:
            Premio.objects.create(rifa=rifa, **premio_data)

        return rifa

    def update(self, instance, validated_data):
        """Actualizar rifa y premios"""
        premios_data = validated_data.pop('premios', None)

        # Actualizar rifa
        rifa = super().update(instance, validated_data)

        # Si se enviaron premios, actualizar
        if premios_data is not None:
            # Eliminar premios existentes que no tienen ganador
            rifa.premios.filter(ganador__isnull=True).delete()

            # Crear nuevos premios
            for premio_data in premios_data:
                Premio.objects.create(rifa=rifa, **premio_data)

        return rifa


# ============================================
# SERIALIZER: PARTICIPACIÓN
# ============================================

class ParticipacionSerializer(serializers.ModelSerializer):
    """
    Serializer para participaciones en rifas
    """

    rifa = RifaListSerializer(read_only=True)
    usuario = UsuarioSimpleSerializer(read_only=True)

    class Meta:
        model = Participacion
        fields = [
            'id',
            'rifa',
            'usuario',
            'ganador',
            'pedidos_completados',
            'fecha_registro'
        ]
        read_only_fields = fields


class ParticipacionSimpleSerializer(serializers.ModelSerializer):
    """
    Serializer simple para participaciones (sin datos anidados)
    """

    rifa_titulo = serializers.CharField(source='rifa.titulo', read_only=True)
    usuario_nombre = serializers.CharField(source='usuario.get_full_name', read_only=True)

    class Meta:
        model = Participacion
        fields = [
            'id',
            'rifa_titulo',
            'usuario_nombre',
            'ganador',
            'pedidos_completados',
            'fecha_registro'
        ]
        read_only_fields = fields


# ============================================
#  SERIALIZER: REALIZAR SORTEO (ADMIN)
# ============================================

class RealizarSorteoSerializer(serializers.Serializer):
    """
    Serializer para endpoint de realizar sorteo
    """

    confirmar = serializers.BooleanField(
        required=True,
        help_text="Debe ser true para confirmar el sorteo"
    )

    def validate_confirmar(self, value):
        """Validar que se confirme el sorteo"""
        if not value:
            raise serializers.ValidationError(
                "Debe confirmar el sorteo estableciendo 'confirmar' en true"
            )
        return value


class SorteoResultadoSerializer(serializers.Serializer):
    """
    Serializer para el resultado del sorteo
    """

    success = serializers.BooleanField()
    message = serializers.CharField()
    premios_ganados = PremioGanadoSerializer(many=True)
    rifa = RifaListSerializer()
    total_participantes = serializers.IntegerField()
    sin_participantes = serializers.BooleanField()


# ============================================
#  SERIALIZER: HISTORIAL DE GANADORES
# ============================================

class HistorialGanadoresSerializer(serializers.Serializer):
    """
    Serializer para historial de ganadores
    """

    rifa_id = serializers.UUIDField(source='id')
    titulo = serializers.CharField()
    mes_nombre = serializers.CharField()
    anio = serializers.IntegerField()
    premios = PremioGanadoSerializer(many=True)
    fecha_fin = serializers.DateTimeField()
    total_participantes = serializers.IntegerField()

    class Meta:
        fields = [
            'rifa_id',
            'titulo',
            'mes_nombre',
            'anio',
            'premios',
            'fecha_fin',
            'total_participantes'
        ]


# ============================================
# SERIALIZER: ESTADÍSTICAS GENERALES
# ============================================

class EstadisticasRifasSerializer(serializers.Serializer):
    """
    Serializer para estadísticas generales del sistema de rifas
    """

    rifa_activa = RifaListSerializer(allow_null=True)

    total_rifas_realizadas = serializers.IntegerField()
    total_ganadores = serializers.IntegerField()

    ultimos_ganadores = HistorialGanadoresSerializer(many=True)

    mi_participaciones = serializers.IntegerField()
    mis_victorias = serializers.IntegerField()

    class Meta:
        fields = [
            'rifa_activa',
            'total_rifas_realizadas',
            'total_ganadores',
            'ultimos_ganadores',
            'mi_participaciones',
            'mis_victorias'
        ]


# ============================================
# SERIALIZER: LISTA DE PARTICIPANTES (ADMIN)
# ============================================

class ListaParticipantesSerializer(serializers.Serializer):
    """
    Serializer para lista completa de participantes elegibles
    Solo accesible por admin
    """

    total = serializers.IntegerField()
    participantes = serializers.ListField(
        child=ParticipanteSerializer()
    )

    class Meta:
        fields = [
            'total',
            'participantes'
        ]


# ============================================
# SERIALIZER: RIFA ACTIVA (APP MÓVIL)
# ============================================

class RifaActivaAppSerializer(serializers.ModelSerializer):
    """
    Serializer optimizado para app móvil
    Solo la información esencial de la rifa activa
    """

    estado_display = serializers.CharField(
        source='get_estado_display',
        read_only=True
    )

    mes_nombre = serializers.CharField(read_only=True)
    dias_restantes = serializers.IntegerField(read_only=True)
    total_participantes = serializers.IntegerField(read_only=True)

    imagen_url = serializers.SerializerMethodField()

    premios = PremioSerializer(many=True, read_only=True)

    # Elegibilidad del usuario
    puedo_participar = serializers.SerializerMethodField()
    mis_pedidos = serializers.SerializerMethodField()
    pedidos_faltantes = serializers.SerializerMethodField()

    class Meta:
        model = Rifa
        fields = [
        'id',
        'titulo',
        'descripcion',
        'premios',
        'imagen_url',
        'fecha_fin',
        'mes_nombre',
        'dias_restantes',
        'total_participantes',
            'pedidos_minimos',
            'puedo_participar',
            'mis_pedidos',
            'pedidos_faltantes',
            'estado_display'
        ]

    def get_imagen_url(self, obj):
        """URL de imagen"""
        if obj.imagen:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.imagen.url)
            return obj.imagen.url
        return None

    def get_puedo_participar(self, obj):
        """Verifica si el usuario puede participar"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False

        elegibilidad = obj.usuario_es_elegible(request.user)
        return elegibilidad['elegible']

    def get_mis_pedidos(self, obj):
        """Pedidos completados del usuario"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return 0

        elegibilidad = obj.usuario_es_elegible(request.user)
        return elegibilidad['pedidos']

    def get_pedidos_faltantes(self, obj):
        """Pedidos que le faltan al usuario"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return obj.pedidos_minimos

        elegibilidad = obj.usuario_es_elegible(request.user)
        return elegibilidad['faltantes']
