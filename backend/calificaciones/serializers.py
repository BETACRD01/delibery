# calificaciones/serializers.py

from django.apps import apps
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Calificacion, ResumenCalificacion, TipoCalificacion
from .services import CalificacionService
from rest_framework.exceptions import ValidationError

User = get_user_model()


# ============================================
# SERIALIZERS DE LECTURA
# ============================================


class CalificacionListSerializer(serializers.ModelSerializer):
    """Serializer para listado de calificaciones"""

    calificador_nombre = serializers.SerializerMethodField()
    calificado_nombre = serializers.CharField(
        source="calificado.get_full_name", read_only=True
    )
    tipo_display = serializers.CharField(source="get_tipo_display", read_only=True)
    tiempo_desde_creacion = serializers.CharField(read_only=True)

    class Meta:
        model = Calificacion
        fields = [
            "id",
            "pedido_id",
            "tipo",
            "tipo_display",
            "calificador_nombre",
            "calificado_nombre",
            "estrellas",
            "comentario",
            "es_anonima",
            "es_positiva",
            "tiempo_desde_creacion",
            "created_at",
        ]

    def get_calificador_nombre(self, obj):
        return obj.nombre_calificador_display


class CalificacionDetailSerializer(serializers.ModelSerializer):
    """Serializer para detalle completo de calificación"""

    calificador = serializers.SerializerMethodField()
    calificado = serializers.SerializerMethodField()
    tipo_display = serializers.CharField(source="get_tipo_display", read_only=True)
    pedido_numero = serializers.CharField(source="pedido.numero_pedido", read_only=True)
    tiempo_desde_creacion = serializers.CharField(read_only=True)

    class Meta:
        model = Calificacion
        fields = [
            "id",
            "pedido_id",
            "pedido_numero",
            "tipo",
            "tipo_display",
            "calificador",
            "calificado",
            "estrellas",
            "comentario",
            "puntualidad",
            "amabilidad",
            "calidad_producto",
            "es_anonima",
            "es_positiva",
            "es_negativa",
            "es_neutral",
            "editada",
            "tiempo_desde_creacion",
            "created_at",
            "updated_at",
        ]

    def get_calificador(self, obj):
        if obj.es_anonima:
            return {"nombre": "Usuario Anónimo"}
        return {
            "id": obj.calificador.id,
            "nombre": obj.calificador.get_full_name(),
            "email": obj.calificador.email,
        }

    def get_calificado(self, obj):
        return {
            "id": obj.calificado.id,
            "nombre": obj.calificado.get_full_name(),
            "email": obj.calificado.email,
        }


# ============================================
# SERIALIZERS DE ESCRITURA
# ============================================


class CrearCalificacionSerializer(serializers.Serializer):
    """Serializer para crear una nueva calificación"""

    pedido_id = serializers.IntegerField()
    tipo = serializers.ChoiceField(choices=TipoCalificacion.choices)
    estrellas = serializers.IntegerField(min_value=1, max_value=5)
    comentario = serializers.CharField(required=False, allow_blank=True, max_length=500)
    puntualidad = serializers.IntegerField(
        required=False, min_value=1, max_value=5, allow_null=True
    )
    amabilidad = serializers.IntegerField(
        required=False, min_value=1, max_value=5, allow_null=True
    )
    calidad_producto = serializers.IntegerField(
        required=False, min_value=1, max_value=5, allow_null=True
    )
    es_anonima = serializers.BooleanField(default=False)

    def validate_pedido_id(self, value):
        """Valida que el pedido exista"""
        from pedidos.models import Pedido

        try:
            pedido = Pedido.objects.get(id=value)
        except Pedido.DoesNotExist:
            raise serializers.ValidationError(f"Pedido con ID {value} no encontrado.")

        if pedido.estado != "entregado":
            raise serializers.ValidationError(
                "Solo puedes calificar pedidos que hayan sido entregados."
            )

        # Guardar el pedido para usarlo después
        self._pedido = pedido
        return value

    def validate(self, data):
        """Validaciones cruzadas"""
        user = self.context["request"].user
        pedido = self._pedido
        tipo = data["tipo"]

        # Verificar que no exista ya esta calificación
        if Calificacion.objects.filter(
            pedido=pedido, calificador=user, tipo=tipo
        ).exists():
            raise serializers.ValidationError(
                {
                    "tipo": f"Ya has dado una calificación de tipo '{dict(TipoCalificacion.choices).get(tipo)}'."
                }
            )

        # Determinar el calificado según el tipo
        calificado = self._obtener_calificado(pedido, tipo, user)
        if not calificado:
            raise serializers.ValidationError(
                {"tipo": "No puedes dar este tipo de calificación para este pedido."}
            )

        data["calificado"] = calificado
        data["pedido"] = pedido

        return data

    def _obtener_calificado(self, pedido, tipo, calificador):
        """Determina quién debe recibir la calificación según el tipo"""
        cliente_user = pedido.cliente.user if pedido.cliente else None
        repartidor_user = pedido.repartidor.user if pedido.repartidor else None
        proveedor_user = pedido.proveedor.user if pedido.proveedor else None

        mapeo = {
            TipoCalificacion.CLIENTE_A_REPARTIDOR: {
                "calificador_valido": cliente_user,
                "calificado": repartidor_user,
            },
            TipoCalificacion.REPARTIDOR_A_CLIENTE: {
                "calificador_valido": repartidor_user,
                "calificado": cliente_user,
            },
            TipoCalificacion.CLIENTE_A_PROVEEDOR: {
                "calificador_valido": cliente_user,
                "calificado": proveedor_user,
            },
            TipoCalificacion.PROVEEDOR_A_REPARTIDOR: {
                "calificador_valido": proveedor_user,
                "calificado": repartidor_user,
            },
            TipoCalificacion.REPARTIDOR_A_PROVEEDOR: {
                "calificador_valido": repartidor_user,
                "calificado": proveedor_user,
            },
        }

        config = mapeo.get(tipo)
        if not config:
            return None

        # Verificar que el calificador sea el correcto
        if (
            config["calificador_valido"]
            and config["calificador_valido"].id != calificador.id
        ):
            return None

        return config["calificado"]

    def create(self, validated_data):
        """Crea la calificación"""
        user = self.context["request"].user
        pedido = validated_data.pop("pedido")
        calificado = validated_data.pop("calificado")

        # Remover pedido_id ya que usamos el objeto pedido
        validated_data.pop("pedido_id", None)

        calificacion = CalificacionService.crear_calificacion(
            pedido=pedido, calificador=user, calificado=calificado, **validated_data
        )

        return calificacion


class ActualizarCalificacionSerializer(serializers.ModelSerializer):
    """Serializer para actualizar una calificación existente"""

    class Meta:
        model = Calificacion
        fields = [
            "estrellas",
            "comentario",
            "puntualidad",
            "amabilidad",
            "calidad_producto",
        ]

    def validate(self, data):
        """Valida que el usuario sea el calificador"""
        user = self.context["request"].user

        if self.instance.calificador_id != user.id:
            raise serializers.ValidationError(
                "Solo puedes editar tus propias calificaciones."
            )

        return data


# ============================================
# SERIALIZERS DE RESUMEN Y ESTADÍSTICAS
# ============================================


class ResumenCalificacionSerializer(serializers.ModelSerializer):
    """Serializer para resumen de calificaciones de un usuario"""

    usuario_nombre = serializers.CharField(source="user.get_full_name", read_only=True)
    porcentaje_positivas = serializers.FloatField(read_only=True)

    class Meta:
        model = ResumenCalificacion
        fields = [
            "usuario_nombre",
            "promedio_general",
            "total_calificaciones",
            "total_5_estrellas",
            "total_4_estrellas",
            "total_3_estrellas",
            "total_2_estrellas",
            "total_1_estrella",
            "promedio_puntualidad",
            "promedio_amabilidad",
            "promedio_calidad_producto",
            "porcentaje_positivas",
            "updated_at",
        ]


class CalificacionPendienteSerializer(serializers.Serializer):
    """Serializer para calificaciones pendientes de dar"""

    tipo = serializers.CharField()
    tipo_display = serializers.CharField()
    calificado_id = serializers.IntegerField()
    calificado_nombre = serializers.CharField()


class EstadisticasCalificacionSerializer(serializers.Serializer):
    """Serializer para estadísticas completas de calificaciones"""

    promedio_general = serializers.FloatField()
    total_calificaciones = serializers.IntegerField()
    porcentaje_positivas = serializers.FloatField()
    desglose = serializers.DictField()
    promedios_categoria = serializers.DictField()
    ultimas_calificaciones = serializers.ListField()


# ============================================
# SERIALIZERS PARA RESPUESTAS ESPECÍFICAS
# ============================================


class CalificacionRapidaSerializer(serializers.Serializer):
    """
    Serializer simplificado para calificación rápida.
    Útil para el flujo de entrega en la app móvil.
    Ahora incluye campos opcionales detallados para calificación de proveedores.
    """

    pedido_id = serializers.IntegerField()
    proveedor_id = serializers.IntegerField(required=False, allow_null=True)  # ✅ Para pedidos multi-proveedor
    tipo = serializers.ChoiceField(choices=TipoCalificacion.choices)
    estrellas = serializers.IntegerField(min_value=1, max_value=5)
    comentario = serializers.CharField(required=False, allow_blank=True, max_length=500)

    # Campos opcionales para calificación detallada (proveedores)
    puntualidad = serializers.IntegerField(
        required=False, min_value=1, max_value=5, allow_null=True
    )
    amabilidad = serializers.IntegerField(
        required=False, min_value=1, max_value=5, allow_null=True
    )
    calidad_producto = serializers.IntegerField(
        required=False, min_value=1, max_value=5, allow_null=True
    )

    def validate(self, data):
        # Validaciones adicionales si son necesarias
        return data

    def validate_pedido_id(self, value):
        from pedidos.models import Pedido

        try:
            self._pedido = Pedido.objects.get(id=value)
        except Pedido.DoesNotExist:
            raise serializers.ValidationError("Pedido no encontrado.")

        # Validar que el pedido esté en estado correcto para calificar
        if self._pedido.estado not in ['entregado', 'finalizado']:
            estado_actual = self._pedido.get_estado_display()
            print(f"[DEBUG] Error estado: {self._pedido.estado}")
            raise serializers.ValidationError(
                f"Solo puedes calificar pedidos entregados o finalizados. Estado actual del pedido: {estado_actual}"
            )

        return value

    def validate(self, data):
        print(f"[DEBUG] Validating data: {data}")
        # Validaciones adicionales si son necesarias
        return super().validate(data)

    def create(self, validated_data):
        user = self.context["request"].user
        pedido = self._pedido
        tipo = validated_data["tipo"]
        proveedor_id = validated_data.get("proveedor_id")

        # Obtener calificado según el tipo
        calificado = None

        if tipo == TipoCalificacion.CLIENTE_A_REPARTIDOR and pedido.repartidor:
            calificado = pedido.repartidor.user

        elif tipo == TipoCalificacion.CLIENTE_A_PROVEEDOR:
            # Soporte para pedidos multi-proveedor
            if proveedor_id:
                # Si se proporciona proveedor_id, usar ese proveedor específico
                from proveedores.models import Proveedor
                try:
                    proveedor = Proveedor.objects.get(id=proveedor_id)
                    if not proveedor.user:
                         print(f"[DEBUG] Proveedor {proveedor.id} sin usuario")
                         raise serializers.ValidationError(
                             f"El proveedor '{proveedor.nombre}' no tiene un usuario asociado para recibir la calificación."
                         )
                    calificado = proveedor.user
                except Proveedor.DoesNotExist:
                    raise serializers.ValidationError(
                        f"Proveedor con ID {proveedor_id} no encontrado."
                    )
            elif pedido.proveedor:
                # Pedido de un solo proveedor
                calificado = pedido.proveedor.user
            else:
                # Intentar obtener proveedor desde los items (pedido multi-proveedor)
                proveedores_items = pedido.items.values_list(
                    'producto__proveedor', flat=True
                ).distinct()
                if proveedores_items.count() == 1:
                    # Solo hay un proveedor en los items
                    from proveedores.models import Proveedor
                    try:
                        proveedor = Proveedor.objects.get(id=proveedores_items.first())
                        calificado = proveedor.user
                    except Proveedor.DoesNotExist:
                        pass

        elif tipo == TipoCalificacion.REPARTIDOR_A_CLIENTE and pedido.cliente:
            calificado = pedido.cliente.user
        elif tipo == TipoCalificacion.REPARTIDOR_A_PROVEEDOR and pedido.proveedor:
            calificado = pedido.proveedor.user
        elif tipo == TipoCalificacion.PROVEEDOR_A_REPARTIDOR and pedido.repartidor:
            calificado = pedido.repartidor.user

        if not calificado:
            raise serializers.ValidationError(
                "No se pudo determinar a quién calificar. "
                "Para pedidos multi-proveedor, proporciona el 'proveedor_id'."
            )

        # Evitar autocalificación (DESACTIVADO PARA PRUEBAS)
        # if calificado.id == user.id:
        #     raise serializers.ValidationError(
        #         "No puedes calificarte a ti mismo. El cliente y el repartidor son la misma persona en este pedido."
        #     )

        try:
            return CalificacionService.crear_calificacion(
                pedido=pedido,
                calificador=user,
                calificado=calificado,
                tipo=tipo,
                estrellas=validated_data["estrellas"],
                comentario=validated_data.get("comentario"),
                puntualidad=validated_data.get("puntualidad"),
                amabilidad=validated_data.get("amabilidad"),
                calidad_producto=validated_data.get("calidad_producto"),
            )
        except ValidationError as e:
            # Normalizar errores de modelo a respuesta DRF
            raise serializers.ValidationError(e.message_dict or e.messages)
