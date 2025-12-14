# backend/pagos/filters.py
"""
Filtros avanzados para la API de Pagos.

ADAPTADO PARA LOGICA:
- Filtrado por Repartidor (Chofer).
- Filtros de estado 'Esperando Verificación'.
- Búsqueda de comprobantes.
"""
import django_filters
from django.db.models import Q
from django.utils import timezone
from .models import (
    Pago, Transaccion, MetodoPago,
    EstadoPago, TipoMetodoPago, TipoTransaccion
)

# ==========================================================
# [FILTER] PAGO
# ==========================================================

class PagoFilter(django_filters.FilterSet):
    """
    Filtros para listar Pagos.
    
    Ejemplos útiles para la App del Chofer:
    - Ver mis pagos pendientes de verificar:
      ?repartidor=MY_ID&estado=esperando_verificacion
    
    - Ver pagos en efectivo que debo cobrar:
      ?repartidor=MY_ID&metodo_pago_tipo=efectivo&estado=pendiente
    """

    # --- FILTROS DE ESTADO Y TIPO ---
    estado = django_filters.MultipleChoiceFilter(
        field_name='estado',
        choices=EstadoPago.choices,
        help_text='Filtrar por uno o varios estados (ej: esperando_verificacion)'
    )

    metodo_pago_tipo = django_filters.ChoiceFilter(
        field_name='metodo_pago__tipo',
        choices=TipoMetodoPago.choices
    )

    # --- FILTROS DE RELACIÓN (CRUCIALES) ---
    repartidor = django_filters.NumberFilter(
        field_name='pedido__repartidor__id',
        help_text='ID del Repartidor asignado (Para que el chofer vea sus pagos)'
    )

    cliente = django_filters.NumberFilter(
        field_name='pedido__cliente__user__id',
        help_text='ID del Usuario Cliente'
    )

    pedido = django_filters.NumberFilter(
        field_name='pedido__id',
        help_text='ID del Pedido'
    )

    # --- FILTROS DE EVIDENCIA (ADMIN/CHOFER) ---
    tiene_comprobante = django_filters.BooleanFilter(
        method='filter_tiene_comprobante',
        help_text='Pagos que ya tienen foto subida'
    )

    esperando_verificacion = django_filters.BooleanFilter(
        method='filter_esperando_verificacion',
        help_text='Shortcut para estado=esperando_verificacion'
    )

    # --- FILTROS DE FECHA ---
    creado_desde = django_filters.DateFilter(field_name='creado_en', lookup_expr='date__gte')
    creado_hasta = django_filters.DateFilter(field_name='creado_en', lookup_expr='date__lte')
    fecha_exacta = django_filters.DateFilter(field_name='creado_en', lookup_expr='date')

    # --- BÚSQUEDA GENERAL ---
    buscar = django_filters.CharFilter(
        method='filter_buscar',
        help_text='Busca por referencia, nombre cliente, email o num operación'
    )

    # --- MÉTODOS CUSTOM ---

    def filter_tiene_comprobante(self, queryset, name, value):
        """Filtra si el cliente ya subió la foto"""
        if value:
            return queryset.exclude(transferencia_comprobante='')
        return queryset.filter(transferencia_comprobante='')

    def filter_esperando_verificacion(self, queryset, name, value):
        """Shortcut para encontrar pagos donde el chofer debe actuar"""
        if value:
            return queryset.filter(estado=EstadoPago.ESPERANDO_VERIFICACION)
        return queryset.exclude(estado=EstadoPago.ESPERANDO_VERIFICACION)

    def filter_buscar(self, queryset, name, value):
        """Búsqueda global inteligente"""
        return queryset.filter(
            Q(referencia__icontains=value) |
            Q(pedido__id__icontains=value) |
            Q(pedido__cliente__user__email__icontains=value) |
            Q(pedido__cliente__user__first_name__icontains=value) |
            Q(pedido__cliente__user__last_name__icontains=value) |
            Q(transferencia_numero_operacion__icontains=value) |
            # Buscar también por nombre del repartidor
            Q(pedido__repartidor__first_name__icontains=value) |
            Q(pedido__repartidor__last_name__icontains=value)
        )

    class Meta:
        model = Pago
        fields = {
            'monto': ['exact', 'gte', 'lte'],
            'verificado_por': ['exact', 'isnull'], # Filtrar si ya fue verificado
        }


# ==========================================================
# [FILTER] TRANSACCIÓN
# ==========================================================

class TransaccionFilter(django_filters.FilterSet):
    """Filtros para el historial de transacciones"""
    
    tipo = django_filters.ChoiceFilter(choices=TipoTransaccion.choices)
    
    pago_referencia = django_filters.CharFilter(
        field_name='pago__referencia',
        lookup_expr='icontains'
    )

    fecha_desde = django_filters.DateFilter(field_name='creado_en', lookup_expr='date__gte')
    fecha_hasta = django_filters.DateFilter(field_name='creado_en', lookup_expr='date__lte')

    exitosa = django_filters.BooleanFilter(field_name='exitosa')

    class Meta:
        model = Transaccion
        fields = ['tipo', 'exitosa']


# ==========================================================
# [FILTER] MÉTODO DE PAGO
# ==========================================================

class MetodoPagoFilter(django_filters.FilterSet):
    """Filtros para configuración de métodos"""
    
    activo = django_filters.BooleanFilter(field_name='activo')
    tipo = django_filters.ChoiceFilter(choices=TipoMetodoPago.choices)
    requiere_verificacion = django_filters.BooleanFilter(field_name='requiere_verificacion')

    class Meta:
        model = MetodoPago
        fields = ['activo', 'tipo', 'requiere_verificacion']