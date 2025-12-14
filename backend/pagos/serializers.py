# backend/pagos/serializers.py
"""
Serializers para el módulo de Pagos (Django REST Framework).

CARACTERÍSTICAS ACTUALIZADAS:
- Soporte para subida de comprobantes (Cliente).
- Visualización de datos bancarios del chofer.
- Serialización completa de estados de verificación.
- Validaciones de negocio robustas.
"""
from rest_framework import serializers
from django.utils import timezone
from django.db import transaction
from decimal import Decimal
from .models import (
    MetodoPago, Pago, Transaccion, EstadisticasPago,
    EstadoPago, TipoMetodoPago, TipoTransaccion
)
import logging

logger = logging.getLogger('pagos')


# ==========================================================
# [NUEVO] SERIALIZERS OPERATIVOS (FLUJO APP)
# ==========================================================

class PagoSubirComprobanteSerializer(serializers.ModelSerializer):
    """
    USO: Cliente sube la foto de la transferencia.
    Endpoint: /api/pagos/pagos/{id}/subir_comprobante/
    """
    class Meta:
        model = Pago
        fields = [
            'transferencia_comprobante',
            'transferencia_banco_origen',
            'transferencia_numero_operacion',
        ]
        extra_kwargs = {
            'transferencia_banco_origen': {'required': False, 'allow_blank': True},
            'transferencia_numero_operacion': {'required': False, 'allow_blank': True},
        }

    def validate_transferencia_comprobante(self, value):
        if not value:
            raise serializers.ValidationError("El archivo del comprobante es obligatorio.")
        # Opcional: Validar tamaño o tipo de archivo aquí
        return value


class DatosBancariosChoferSerializer(serializers.Serializer):
    """
    USO: Mostrar al cliente a dónde transferir.
    Obtiene los datos del perfil del Chofer asignado al pedido.
    Endpoint: /api/pagos/pagos/{id}/datos_transferencia/
    """
    banco = serializers.CharField(source='pedido.repartidor.perfil.banco_nombre', read_only=True)
    tipo_cuenta = serializers.CharField(source='pedido.repartidor.perfil.banco_tipo_cuenta', read_only=True)
    numero_cuenta = serializers.CharField(source='pedido.repartidor.perfil.banco_numero_cuenta', read_only=True)
    titular = serializers.CharField(source='pedido.repartidor.get_full_name', read_only=True)
    cedula = serializers.CharField(source='pedido.repartidor.perfil.cedula', read_only=True)
    telefono = serializers.CharField(source='pedido.repartidor.perfil.telefono', read_only=True)


class ConfirmacionPagoSerializer(serializers.Serializer):
    """
    USO: Documentación y validación simple para la confirmación de dinero.
    """
    confirmado = serializers.BooleanField(default=True)
    notas = serializers.CharField(required=False, allow_blank=True)


# ==========================================================
# [SERIALIZER] METODO DE PAGO
# ==========================================================

class MetodoPagoSerializer(serializers.ModelSerializer):
    """Serializer completo para métodos de pago"""
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    total_pagos_hoy = serializers.SerializerMethodField()

    class Meta:
        model = MetodoPago
        fields = [
            'id', 'tipo', 'tipo_display', 'nombre', 'descripcion',
            'activo', 'requiere_verificacion', 'permite_reembolso',
            'pasarela_nombre', 'total_pagos_hoy', 'creado_en'
        ]
        read_only_fields = ['id', 'creado_en']

    def get_total_pagos_hoy(self, obj):
        hoy = timezone.now().date()
        return obj.pagos.filter(creado_en__date=hoy).count()


class MetodoPagoListSerializer(serializers.ModelSerializer):
    """Serializer ligero para listar en el checkout"""
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)

    class Meta:
        model = MetodoPago
        fields = [
            'id', 'tipo', 'tipo_display', 'nombre', 
            'descripcion', 'activo', 'requiere_verificacion'
        ]


# ==========================================================
# [SERIALIZER] TRANSACCION
# ==========================================================

class TransaccionSerializer(serializers.ModelSerializer):
    """Serializer para el historial de transacciones"""
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    estado_visual = serializers.SerializerMethodField()

    class Meta:
        model = Transaccion
        fields = [
            'id', 'tipo', 'tipo_display', 'monto', 'exitosa',
            'estado_visual', 'descripcion', 'codigo_respuesta',
            'mensaje_respuesta', 'metadata', 'creado_en'
        ]
        read_only_fields = ['id', 'creado_en']

    def get_estado_visual(self, obj):
        if obj.exitosa is True:
            return {'texto': 'Exitosa', 'color': 'green'}
        elif obj.exitosa is False:
            return {'texto': 'Fallida', 'color': 'red'}
        return {'texto': 'En proceso', 'color': 'orange'}


class TransaccionListSerializer(serializers.ModelSerializer):
    """Serializer ligero para listas"""
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)

    class Meta:
        model = Transaccion
        fields = ['id', 'tipo', 'tipo_display', 'monto', 'exitosa', 'descripcion', 'creado_en']


# ==========================================================
# [SERIALIZER] PAGO (DETALLADO)
# ==========================================================

class PagoDetailSerializer(serializers.ModelSerializer):
    """
    Serializer principal para ver el detalle de un pago.
    Incluye campos nuevos como 'transferencia_comprobante' y 'verificado_por'.
    """
    metodo_pago = MetodoPagoListSerializer(read_only=True)
    transacciones = TransaccionListSerializer(many=True, read_only=True)

    # Info del Pedido
    pedido_id = serializers.IntegerField(source='pedido.id', read_only=True)
    pedido_estado = serializers.CharField(source='pedido.get_estado_display', read_only=True)
    
    # Info del Cliente
    cliente_nombre = serializers.SerializerMethodField()
    
    # Info de Verificación (Auditoría)
    verificado_por_nombre = serializers.SerializerMethodField()
    
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    monto_pendiente_reembolso = serializers.SerializerMethodField()

    class Meta:
        model = Pago
        fields = [
            'id', 'referencia', 
            'pedido_id', 'pedido_estado', 
            'cliente_nombre',
            'metodo_pago', 
            'monto', 
            'estado', 'estado_display',
            # Campos de Transferencia / Evidencia
            'transferencia_comprobante',
            'transferencia_banco_origen',
            'transferencia_numero_operacion',
            # Campos de Auditoría
            'verificado_por_nombre',
            'fecha_verificacion',
            'notas',
            # Campos de Reembolso
            'monto_reembolsado',
            'monto_pendiente_reembolso',
            'fecha_reembolso',
            # Fechas Generales
            'creado_en', 'actualizado_en', 'fecha_completado',
            # Historial
            'transacciones'
        ]
        read_only_fields = ['id', 'referencia', 'creado_en', 'fecha_verificacion']

    def get_cliente_nombre(self, obj):
        if obj.pedido and obj.pedido.cliente and obj.pedido.cliente.user:
            return obj.pedido.cliente.user.get_full_name()
        return "Cliente"

    def get_verificado_por_nombre(self, obj):
        if obj.verificado_por:
            rol = "Admin" if obj.verificado_por.is_staff else "Chofer"
            return f"{obj.verificado_por.get_full_name()} ({rol})"
        return None

    def get_monto_pendiente_reembolso(self, obj):
        return obj.monto - obj.monto_reembolsado


# ==========================================================
# [SERIALIZER] PAGO (LISTA)
# ==========================================================

class PagoListSerializer(serializers.ModelSerializer):
    """Serializer optimizado para listas grandes"""
    metodo_pago_nombre = serializers.CharField(source='metodo_pago.nombre', read_only=True)
    metodo_pago_tipo = serializers.CharField(source='metodo_pago.tipo', read_only=True)
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    pedido_id = serializers.IntegerField(source='pedido.id', read_only=True)
    cliente_nombre = serializers.SerializerMethodField()

    class Meta:
        model = Pago
        fields = [
            'id', 'referencia', 'pedido_id', 'cliente_nombre',
            'metodo_pago_nombre', 'metodo_pago_tipo',
            'monto', 'estado', 'estado_display', 'creado_en',
            'transferencia_comprobante' # Útil para ver en lista si ya subieron foto
        ]

    def get_cliente_nombre(self, obj):
        if obj.pedido and obj.pedido.cliente and obj.pedido.cliente.user:
            return obj.pedido.cliente.user.get_full_name()
        return "N/A"


# ==========================================================
# [SERIALIZER] CREAR PAGO
# ==========================================================

class PagoCreateSerializer(serializers.ModelSerializer):
    """
    Serializer para iniciar un pago.
    """
    metodo_pago_id = serializers.IntegerField(write_only=True)
    pedido_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = Pago
        fields = [
            'pedido_id', 'metodo_pago_id', 'monto',
            'transferencia_banco_origen',
            'transferencia_numero_operacion',
            'metadata', 'notas'
        ]

    def validate(self, data):
        user = self.context['request'].user
        pedido_id = data.get('pedido_id')
        metodo_pago_id = data.get('metodo_pago_id')
        monto = data.get('monto')

        # 1. Validar Pedido (Importación lazy para evitar ciclos)
        from pedidos.models import Pedido
        try:
            pedido = Pedido.objects.get(pk=pedido_id)
        except Pedido.DoesNotExist:
            raise serializers.ValidationError({'pedido_id': 'El pedido no existe'})

        if hasattr(pedido, 'pago'):
            raise serializers.ValidationError({'pedido_id': 'Este pedido ya tiene un pago iniciado'})

        # 2. Validar Método
        try:
            metodo = MetodoPago.objects.get(pk=metodo_pago_id)
        except MetodoPago.DoesNotExist:
            raise serializers.ValidationError({'metodo_pago_id': 'Método de pago no válido'})

        if not metodo.activo:
            raise serializers.ValidationError({'metodo_pago_id': 'Este método de pago no está activo'})

        # 3. Validar Monto
        # Se permite un margen de error de 1 centavo por redondeos
        if abs(float(monto) - float(pedido.total)) > 0.01:
            raise serializers.ValidationError({
                'monto': f'El monto (${monto}) no coincide con el total del pedido (${pedido.total})'
            })

        # 4. Validar autoría: solo el cliente dueño del pedido (o admin) puede iniciar el pago
        es_dueno_pedido = pedido.cliente and pedido.cliente.user_id == user.id
        if not (user.is_staff or es_dueno_pedido):
            raise serializers.ValidationError({'pedido_id': 'No puedes iniciar pagos de pedidos ajenos'})

        data['pedido'] = pedido
        data['metodo_pago'] = metodo
        return data

    @transaction.atomic
    def create(self, validated_data):
        pedido = validated_data.pop('pedido')
        metodo_pago = validated_data.pop('metodo_pago')
        
        # Limpieza de campos write_only
        validated_data.pop('pedido_id', None)
        validated_data.pop('metodo_pago_id', None)

        pago = Pago.objects.create(
            pedido=pedido,
            metodo_pago=metodo_pago,
            **validated_data
        )

        # Si es efectivo o transferencia, nace como PENDIENTE
        # Si fuera tarjeta, aquí se integraría la lógica de 'marcar_procesando'

        logger.info(f"Pago creado: {pago.referencia} ({metodo_pago.tipo})")
        return pago


# ==========================================================
# [SERIALIZER] ACTUALIZAR ESTADO (ADMIN)
# ==========================================================

class PagoUpdateEstadoSerializer(serializers.Serializer):
    """Para intervenciones manuales del Admin"""
    estado = serializers.ChoiceField(choices=EstadoPago.choices)
    motivo = serializers.CharField(required=False, allow_blank=True)

    def update(self, instance, validated_data):
        nuevo_estado = validated_data.get('estado')
        motivo = validated_data.get('motivo', '')

        if nuevo_estado == EstadoPago.COMPLETADO:
            # Si el admin fuerza completado, él es el verificador
            user = self.context['request'].user
            instance.marcar_completado(verificado_por=user)
            instance.notas += f"\n[ADMIN] Completado forzado: {motivo}"
        
        elif nuevo_estado == EstadoPago.FALLIDO:
            instance.marcar_fallido(motivo)
        
        elif nuevo_estado == EstadoPago.CANCELADO:
            instance.estado = EstadoPago.CANCELADO
            instance.notas += f"\n[ADMIN] Cancelado: {motivo}"
        
        else:
            instance.estado = nuevo_estado
        
        instance.save()
        return instance


# ==========================================================
# [SERIALIZER] REEMBOLSO
# ==========================================================

class PagoReembolsoSerializer(serializers.Serializer):
    monto = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False, allow_null=True
    )
    motivo = serializers.CharField(required=True)

    def validate(self, data):
        pago = self.context.get('pago')
        if not pago.metodo_pago.permite_reembolso:
            raise serializers.ValidationError("Este método de pago no permite reembolsos automáticos.")
        if pago.estado != EstadoPago.COMPLETADO:
            raise serializers.ValidationError("Solo se pueden reembolsar pagos completados.")
        monto = data.get('monto')
        # Valor por defecto: reembolsar todo lo pendiente
        pendiente = pago.monto_pendiente_reembolso
        monto_objetivo = pendiente if monto is None else monto
        if monto_objetivo <= 0:
            raise serializers.ValidationError("El monto a reembolsar debe ser mayor a 0.")
        if monto_objetivo > pendiente:
            raise serializers.ValidationError(f"El monto excede lo pendiente (${pendiente}).")
        data['monto_resuelto'] = monto_objetivo
        return data

    def save(self):
        pago = self.context.get('pago')
        monto = self.validated_data['monto_resuelto']
        motivo = self.validated_data.get('motivo')
        user = self.context.get('request').user if self.context.get('request') else None
        # Delegamos la lógica de estado y auditoría al modelo
        pago.procesar_reembolso(monto=monto, motivo=motivo, usuario=user)
        return pago


# ==========================================================
# [SERIALIZER] ESTADISTICAS Y RESUMEN
# ==========================================================

class EstadisticasPagoSerializer(serializers.ModelSerializer):
    class Meta:
        model = EstadisticasPago
        fields = '__all__'

class PagoResumenSerializer(serializers.Serializer):
    referencia = serializers.UUIDField()
    monto = serializers.DecimalField(max_digits=10, decimal_places=2)
    estado = serializers.CharField()
    metodo = serializers.CharField()
    fecha = serializers.DateTimeField(source='creado_en')


# ==========================================================
# [NUEVO] COMPROBANTES DE PAGO PARA REPARTIDORES
# ==========================================================

class ComprobanteVerRepartidorSerializer(serializers.ModelSerializer):
    """
    Serializer para que el repartidor vea el comprobante de transferencia.
    Incluye información del cliente y del pedido.
    """
    cliente_nombre = serializers.SerializerMethodField()
    pedido_numero = serializers.CharField(source='pedido.numero_pedido', read_only=True)
    comprobante_url = serializers.SerializerMethodField()
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)

    class Meta:
        model = Pago
        fields = [
            'id',
            'referencia',
            'pedido_numero',
            'cliente_nombre',
            'monto',
            'estado',
            'estado_display',
            'transferencia_comprobante',
            'comprobante_url',
            'transferencia_banco_origen',
            'transferencia_numero_operacion',
            'comprobante_visible_repartidor',
            'fecha_visualizacion_repartidor',
            'creado_en',
        ]
        read_only_fields = fields

    def get_cliente_nombre(self, obj):
        """Retorna nombre del cliente"""
        if obj.pedido and obj.pedido.cliente and obj.pedido.cliente.user:
            return obj.pedido.cliente.user.get_full_name()
        return "Cliente"

    def get_comprobante_url(self, obj):
        """Construye URL completa del comprobante"""
        if not obj.transferencia_comprobante:
            return None

        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.transferencia_comprobante.url)

        return obj.transferencia_comprobante.url


class ComprobanteMarcarVistoSerializer(serializers.Serializer):
    """
    Serializer para marcar que el repartidor vio el comprobante.
    """
    visto = serializers.BooleanField(default=True, required=False)

    def validate(self, data):
        """Valida que el pago tenga comprobante"""
        pago = self.context.get('pago')

        if not pago:
            raise serializers.ValidationError('Pago no encontrado en el contexto.')

        if not pago.transferencia_comprobante:
            raise serializers.ValidationError('Este pago no tiene comprobante de transferencia.')

        if not pago.comprobante_visible_repartidor:
            raise serializers.ValidationError('El comprobante aún no está visible para el repartidor.')

        return data

    def save(self):
        """Marca el comprobante como visto por el repartidor"""
        pago = self.context.get('pago')

        # Solo marcar si aún no se ha marcado
        if not pago.fecha_visualizacion_repartidor:
            pago.fecha_visualizacion_repartidor = timezone.now()
            pago.save(update_fields=['fecha_visualizacion_repartidor'])

        return pago


class PagoConComprobanteSerializer(serializers.ModelSerializer):
    """
    Serializer extendido que incluye información del comprobante
    y del repartidor asignado para el cliente.
    """
    metodo_pago_nombre = serializers.CharField(source='metodo_pago.nombre', read_only=True)
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    pedido_numero = serializers.CharField(source='pedido.numero_pedido', read_only=True)
    comprobante_url = serializers.SerializerMethodField()
    repartidor_nombre = serializers.SerializerMethodField()
    datos_bancarios_repartidor = serializers.SerializerMethodField()

    class Meta:
        model = Pago
        fields = [
            'id',
            'referencia',
            'pedido_numero',
            'metodo_pago_nombre',
            'monto',
            'estado',
            'estado_display',
            'transferencia_comprobante',
            'comprobante_url',
            'transferencia_banco_origen',
            'transferencia_numero_operacion',
            'repartidor_asignado',
            'repartidor_nombre',
            'datos_bancarios_repartidor',
            'comprobante_visible_repartidor',
            'fecha_visualizacion_repartidor',
            'creado_en',
            'actualizado_en',
        ]
        read_only_fields = [
            'id', 'referencia', 'repartidor_asignado',
            'comprobante_visible_repartidor', 'fecha_visualizacion_repartidor',
            'creado_en', 'actualizado_en'
        ]

    def get_comprobante_url(self, obj):
        """Construye URL completa del comprobante"""
        if not obj.transferencia_comprobante:
            return None

        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.transferencia_comprobante.url)

        return obj.transferencia_comprobante.url

    def get_repartidor_nombre(self, obj):
        """Retorna nombre del repartidor asignado"""
        if obj.repartidor_asignado and obj.repartidor_asignado.user:
            return obj.repartidor_asignado.user.get_full_name()
        return None

    def get_datos_bancarios_repartidor(self, obj):
        """
        Retorna datos bancarios del repartidor asignado
        (solo si está asignado y tiene datos bancarios completos)
        """
        if not obj.repartidor_asignado:
            return None

        repartidor = obj.repartidor_asignado

        # Verificar que tenga datos bancarios completos
        if not all([
            repartidor.banco_nombre,
            repartidor.banco_tipo_cuenta,
            repartidor.banco_numero_cuenta,
            repartidor.banco_titular,
            repartidor.banco_cedula_titular
        ]):
            return None

        return {
            'banco': repartidor.banco_nombre,
            'tipo_cuenta': repartidor.banco_tipo_cuenta,
            'tipo_cuenta_display': repartidor.get_banco_tipo_cuenta_display(),
            'numero_cuenta': repartidor.banco_numero_cuenta,
            'titular': repartidor.banco_titular,
            'cedula_titular': repartidor.banco_cedula_titular,
            'verificado': repartidor.banco_verificado,
        }
