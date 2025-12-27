# pedidos/serializers.py (VERSIÓN FINAL OPTIMIZADA CON INTEGRACIÓN LOGÍSTICA)

from django.apps import apps
from rest_framework import serializers
from django.utils import timezone
from django.db import transaction
from django.db.models import F
from django.core.exceptions import ValidationError as DjangoValidationError
from decimal import Decimal

# Importación de modelos externos
from repartidores.models import Repartidor
from repartidores.models import Repartidor
from proveedores.models import Proveedor
from productos.models import Producto

# Importación de modelos locales
from .models import (
    Pedido, ItemPedido, EstadoPedido, TipoPedido, 
    EstadoPago, ConfiguracionComisiones
)

# 🟢 INTEGRACIÓN LOGÍSTICA: Intentamos importar el modelo de Envio de forma segura
try:
    from envios.models import Envio
    ENVIOS_INSTALLED = True
except ImportError:
    ENVIOS_INSTALLED = False


# ==========================================================
#  VALIDADORES PERSONALIZADOS
# ==========================================================

def validar_latitud_ecuador(value):
    """Valida latitud para Ecuador (-5.0° a 2.0°)"""
    if value is None: return value
    if not isinstance(value, (int, float, Decimal)):
        raise serializers.ValidationError("La latitud debe ser un número")
    if not (-5.0 <= float(value) <= 2.0):
        raise serializers.ValidationError(f"Latitud fuera de rango Ecuador: {value}")
    return value

def validar_longitud_ecuador(value):
    """Valida longitud para Ecuador (-92.0° a -75.0°)"""
    if value is None: return value
    if not isinstance(value, (int, float, Decimal)):
        raise serializers.ValidationError("La longitud debe ser un número")
    if not (-92.0 <= float(value) <= -75.0):
        raise serializers.ValidationError(f"Longitud fuera de rango Ecuador: {value}")
    return value

def validar_direccion(value):
    """Valida formato mínimo de dirección"""
    if not value or not value.strip():
        raise serializers.ValidationError("La dirección no puede estar vacía")
    if len(value.strip()) < 5: # Reducido a 5 para ser más flexible
        raise serializers.ValidationError("Dirección muy corta")
    return value.strip()


# ==========================================================
#  SERIALIZER PARA ITEMS DEL PEDIDO
# ==========================================================

class ItemPedidoSerializer(serializers.ModelSerializer):
    """Serializer para items individuales del pedido"""
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    producto_imagen = serializers.SerializerMethodField()

    class Meta:
        model = ItemPedido
        fields = [
            'id',
            'producto',  # ID del producto (Foreign Key)
            'producto_nombre',
            'producto_imagen',
            'cantidad',
            'precio_unitario',
            'subtotal',
            'notas',
        ]
        read_only_fields = ['subtotal']

    def get_producto_imagen(self, obj):
        if not obj.producto:
            return None
        # Prioriza URL absoluta configurada; si no, usa el archivo almacenado
        if obj.producto.imagen_url:
            return obj.producto.imagen_url
        if obj.producto.imagen:
            try:
                return obj.producto.imagen.url
            except Exception:
                return None
        return None

    def validate_cantidad(self, value):
        if value <= 0:
            raise serializers.ValidationError("Cantidad debe ser mayor a 0")
        if value > 100:
            raise serializers.ValidationError("Máximo 100 unidades por item")
        return value

    def validate_precio_unitario(self, value):
        if value < 0:
            raise serializers.ValidationError("Precio no puede ser negativo")
        return value


# ==========================================================
#  SERIALIZER PARA DATOS DE ENVÍO (LOGÍSTICA)
# ==========================================================

class DatosEnvioInputSerializer(serializers.Serializer):
    """
    Recibe los datos calculados por la cotización de envío.
    El frontend envía esto dentro de 'datos_envio'.
    """
    ciudad_origen = serializers.CharField(max_length=50, required=False, allow_blank=True)
    zona_destino = serializers.CharField(max_length=20, required=False, allow_blank=True)
    distancia_km = serializers.DecimalField(max_digits=10, decimal_places=2)
    tiempo_mins = serializers.IntegerField(required=False, default=0)
    costo_base = serializers.DecimalField(max_digits=10, decimal_places=2)
    costo_km_extra = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, default=0)
    recargo_nocturno = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, default=0)
    total_envio = serializers.DecimalField(max_digits=10, decimal_places=2)


# ==========================================================
#  CREACIÓN DE PEDIDO (CON ITEMS Y ENVÍO)
# ==========================================================

class PedidoCreateSerializer(serializers.ModelSerializer):
    """
    Serializer principal para crear pedidos.
    Maneja transacciones atómicas para Pedido + Items + Logística.
    """
    items = ItemPedidoSerializer(many=True)
    datos_envio = DatosEnvioInputSerializer(required=False, write_only=True)
    cargo_extra = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
        default=Decimal('0.00'),
        help_text="Sobrecargos adicionales (ej. multi-proveedor, servicio)"
    )
    
    # Validadores de coordenadas
    latitud_destino = serializers.FloatField(required=False, allow_null=True, validators=[validar_latitud_ecuador])
    longitud_destino = serializers.FloatField(required=False, allow_null=True, validators=[validar_longitud_ecuador])
    latitud_origen = serializers.FloatField(required=False, allow_null=True, validators=[validar_latitud_ecuador])
    longitud_origen = serializers.FloatField(required=False, allow_null=True, validators=[validar_longitud_ecuador])
    direccion_entrega = serializers.CharField(validators=[validar_direccion])

    class Meta:
        model = Pedido
        fields = [
            'id',
            'tipo',
            'descripcion',
            'proveedor',
            'direccion_origen', 'latitud_origen', 'longitud_origen',
            'direccion_entrega', 'latitud_destino', 'longitud_destino',
            'metodo_pago',
            'total',
            'cargo_extra',
            'items',        # Lista de productos
            'datos_envio',  # Objeto de logística (opcional)
            'instrucciones_entrega',  # Instrucciones del cliente
        ]

    def validate_total(self, value):
        if value <= 0: raise serializers.ValidationError("Total debe ser positivo")
        return value

    def validate(self, data):
        """Validaciones de negocio cruzadas"""
        tipo = data.get('tipo')
        proveedor = data.get('proveedor')
        items = data.get('items', [])

        # 1. Validar Proveedor según tipo
        if tipo == TipoPedido.PROVEEDOR:
            # Para pedidos multi-proveedor, proveedor puede ser None
            # Solo requerir proveedor si es un pedido de un solo proveedor
            if proveedor:
                # Auto-completar origen si falta
                if not data.get('direccion_origen'):
                    data['direccion_origen'] = proveedor.direccion or "Ubicación Proveedor"
                    # Convertir Decimal a float si es necesario
                    data['latitud_origen'] = float(proveedor.latitud) if proveedor.latitud else None
                    data['longitud_origen'] = float(proveedor.longitud) if proveedor.longitud else None

        elif tipo == TipoPedido.DIRECTO:
            if not data.get('descripcion'):
                raise serializers.ValidationError({'descripcion': "Requerida para encargos"})

        # 2. Validar que todos los items tengan productos válidos
        if items:
            for item in items:
                if not item.get('producto'):
                    raise serializers.ValidationError({'items': "Todos los items deben tener un producto válido"})

        # 3. Validar totales (Suma de items)
        if items:
            suma_items = sum(item['cantidad'] * item['precio_unitario'] for item in items)
            # Obtenemos costo de envío si existe
            costo_envio = Decimal('0.00')
            if 'datos_envio' in data:
                costo_envio = Decimal(str(data['datos_envio'].get('total_envio', 0)))
            cargo_extra = Decimal(str(data.get('cargo_extra', 0)))

            # El total que envía el frontend debería ser: Items + Envío
            total_esperado = suma_items + costo_envio + cargo_extra
            total_recibido = Decimal(str(data['total']))

            # Tolerancia de $0.05 por redondeos
            if abs(total_recibido - total_esperado) > Decimal('0.05'):
                raise serializers.ValidationError({
                    'total': f"Discrepancia en total. Recibido: ${total_recibido}, Calculado (Items+Envío): ${total_esperado}"
                })

        return data

    def create(self, validated_data):
        """
        Crea Pedido, Items y Registro de Envío en una sola transacción.
        """
        items_data = validated_data.pop('items', [])
        datos_envio_data = validated_data.pop('datos_envio', None)
        # Remover campos no mapeados al modelo
        validated_data.pop('cargo_extra', None)
        
        request = self.context.get('request')
        # Asignar cliente automáticamente desde el usuario autenticado
        if request and hasattr(request.user, 'perfil'):
            validated_data['cliente'] = request.user.perfil
        
        # TRANSACCIÓN ATÓMICA
        with transaction.atomic():
            # 1. Crear Pedido Base
            pedido = Pedido.objects.create(**validated_data)
            
            # 2. Crear Items
            items_objs = []
            for item in items_data:
                prod_instance = item.get('producto')
                cantidad = item.get('cantidad') or 0
                
                # --- LOGICA DE STOCK (ATÓMICA) ---
                if prod_instance.tiene_stock:
                    # Intentar descontar stock solo si es suficiente
                    # update retorna el número de filas modificadas
                    updated = Producto.objects.filter(
                        id=prod_instance.id, 
                        stock__gte=cantidad
                    ).update(stock=F('stock') - cantidad, veces_vendido=F('veces_vendido') + cantidad)
                    
                    if updated == 0:
                        # Falló la actualización -> Stock insuficiente o producto desapareció
                        # Re-consultamos para dar feedback preciso
                        current_prod = Producto.objects.get(id=prod_instance.id)
                        if current_prod.stock < cantidad:
                            raise serializers.ValidationError(
                                f"Stock insuficiente para '{current_prod.nombre}'. Disponible: {current_prod.stock}"
                            )
                        else:
                            raise serializers.ValidationError(f"Error actualizando stock de {current_prod.nombre}")
                else:
                    # Si no maneja stock, solo sumamos ventas
                    Producto.objects.filter(id=prod_instance.id).update(veces_vendido=F('veces_vendido') + cantidad)
                
                # Crear objeto item en memoria
                precio_unitario = item.get('precio_unitario') or Decimal('0')
                subtotal = Decimal(cantidad) * Decimal(precio_unitario)
                items_objs.append(
                    ItemPedido(
                        pedido=pedido,
                        producto=prod_instance,
                        cantidad=cantidad,
                        precio_unitario=precio_unitario,
                        subtotal=subtotal,
                        notas=item.get('notas', ''),
                    )
                )
            ItemPedido.objects.bulk_create(items_objs)

            # 3. Crear Registro de Logística (Si existe la app envios y enviaron datos)
            if ENVIOS_INSTALLED and datos_envio_data:
                Envio.objects.create(
                    pedido=pedido,
                    ciudad_origen=datos_envio_data.get('ciudad_origen'),
                    zona_destino=datos_envio_data.get('zona_destino'),
                    distancia_km=datos_envio_data.get('distancia_km'),
                    tiempo_estimado_mins=datos_envio_data.get('tiempo_mins', 0),
                    costo_base=datos_envio_data.get('costo_base'),
                    costo_km_adicional=datos_envio_data.get('costo_km_extra', 0),
                    recargo_nocturno=datos_envio_data.get('recargo_nocturno', 0),
                    total_envio=datos_envio_data.get('total_envio'),
                    # Guardamos coordenadas exactas para auditoría futura
                    lat_origen_calc=validated_data.get('latitud_origen'),
                    lng_origen_calc=validated_data.get('longitud_origen'),
                    lat_destino_calc=validated_data.get('latitud_destino'),
                    lng_destino_calc=validated_data.get('longitud_destino'),
                )

        return pedido


# ==========================================================
#  LISTADO DE PEDIDOS
# ==========================================================

class PedidoListSerializer(serializers.ModelSerializer):
    """Optimizado para listar pedidos rápidamente"""
    cliente_nombre = serializers.SerializerMethodField()
    proveedor_nombre = serializers.SerializerMethodField()
    repartidor_nombre = serializers.SerializerMethodField()
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    estado_display = serializers.SerializerMethodField()
    estado_pago = serializers.CharField(read_only=True)
    estado_pago_display = serializers.CharField(source='get_estado_pago_display', read_only=True)
    metodo_pago = serializers.CharField(read_only=True)
    metodo_pago_display = serializers.CharField(source='get_metodo_pago_display', read_only=True)
    tiempo_transcurrido = serializers.CharField(read_only=True)
    cantidad_items = serializers.SerializerMethodField()
    primer_producto_imagen = serializers.SerializerMethodField()
    # Logística básica en lista
    costo_envio = serializers.SerializerMethodField()

    class Meta:
        model = Pedido
        fields = [
            'id', 'numero_pedido', 
            'tipo', 'tipo_display',
            'estado', 'estado_display',
            'estado_pago', 'estado_pago_display',
            'cliente_nombre', 'proveedor_nombre', 'repartidor_nombre',
            'total', 'costo_envio', 'metodo_pago', 'metodo_pago_display',
            'direccion_entrega', 'tiempo_transcurrido',
            'creado_en', 'actualizado_en',
            'cantidad_items', 'primer_producto_imagen',
        ]

    def get_costo_envio(self, obj):
        """Retorna costo de envío si existe registro de logística"""
        if ENVIOS_INSTALLED and hasattr(obj, 'datos_envio'):
            return obj.datos_envio.total_envio
        return 0

    def get_cliente_nombre(self, obj):
        return obj.cliente.user.get_full_name() if obj.cliente else None

    def get_proveedor_nombre(self, obj):
        return obj.proveedor.nombre if obj.proveedor else None

    def get_repartidor_nombre(self, obj):
        return obj.repartidor.user.get_full_name() if obj.repartidor else ""

    def get_cantidad_items(self, obj):
        # Evita errores si la relación no está prefetcheada
        try:
            return obj.items.count()
        except Exception:
            return 0

    def get_primer_producto_imagen(self, obj):
        try:
            item = obj.items.select_related('producto').first()
            if item and item.producto:
                prod = item.producto
                if prod.imagen_url:
                    return prod.imagen_url
                if prod.imagen:
                    return prod.imagen.url
        except Exception:
            pass
        return None

    def get_estado_display(self, obj):
        # Estado amigable si aún no hay repartidor asignado
        if obj.estado == EstadoPedido.PENDIENTE_REPARTIDOR and obj.repartidor is None:
            return "En espera de repartidor"
        return obj.get_estado_display()

    def to_representation(self, instance):
        """Estandariza strings vacíos para evitar null en cliente móvil."""
        data = super().to_representation(instance)
        for key in [
            'cliente_nombre', 'proveedor_nombre', 'repartidor_nombre',
            'numero_pedido', 'direccion_entrega',
            'metodo_pago', 'metodo_pago_display',
            'estado_pago', 'estado_pago_display'
        ]:
            if data.get(key) is None:
                data[key] = ""
        # Asegurar timestamps
        if data.get('actualizado_en') is None:
            data['actualizado_en'] = data.get('creado_en')
        return data


# ==========================================================
# DETALLE DEL PEDIDO
# ==========================================================

class PedidoDetailSerializer(serializers.ModelSerializer):
    """Detalle completo del pedido"""
    cliente = serializers.SerializerMethodField()
    proveedor = serializers.SerializerMethodField()
    repartidor = serializers.SerializerMethodField()
    items = ItemPedidoSerializer(many=True, read_only=True)
    
    # Displays
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    estado_display = serializers.SerializerMethodField()
    metodo_pago_display = serializers.CharField(source='get_metodo_pago_display', read_only=True)
    
    # Propiedades
    tiempo_transcurrido = serializers.CharField(read_only=True)
    es_pedido_activo = serializers.BooleanField(read_only=True)
    puede_ser_cancelado = serializers.BooleanField(read_only=True)
    pago_id = serializers.SerializerMethodField()
    transferencia_comprobante_url = serializers.SerializerMethodField()
    estado_pago_actual = serializers.SerializerMethodField()
    
    # 🟢 Logística Detallada
    datos_envio = serializers.SerializerMethodField()
    puede_calificar_repartidor = serializers.SerializerMethodField()
    calificacion_repartidor = serializers.SerializerMethodField()
    puede_calificar_proveedor = serializers.SerializerMethodField()
    calificacion_proveedor = serializers.SerializerMethodField()

    class Meta:
        model = Pedido
        fields = '__all__' # Incluye todos los campos del modelo + los method fields

    def get_cliente(self, obj):
        if not obj.cliente: return None
        return {
            'id': obj.cliente.id,
            'nombre': obj.cliente.user.get_full_name(),
            'telefono': getattr(obj.cliente.user, 'celular', None),
            'foto': obj.cliente.foto_perfil.url if obj.cliente.foto_perfil else None
        }

    def get_proveedor(self, obj):
        """
        Devuelve información completa del proveedor con todos los campos necesarios.
        Construye URLs absolutas para las fotos.
        """
        request = self.context.get('request')

        # Para pedidos multi-proveedor, devolver lista de proveedores
        if not obj.proveedor:
            # Obtener proveedores únicos de los items
            proveedores_items = obj.items.values_list('producto__proveedor', flat=True).distinct()
            if proveedores_items:
                proveedores_data = []
                for prov_id in proveedores_items:
                    try:
                        from proveedores.models import Proveedor
                        prov = Proveedor.objects.get(id=prov_id)

                        # Construir URL completa de la foto
                        foto_url = None
                        if prov.logo:
                            try:
                                foto_url = prov.logo.url
                                if request and not foto_url.startswith('http'):
                                    foto_url = request.build_absolute_uri(foto_url)
                            except Exception:
                                foto_url = None

                        proveedores_data.append({
                            'id': prov.id,
                            'nombre': prov.nombre,
                            'telefono': prov.telefono,
                            'direccion': prov.direccion,
                            'foto_perfil': foto_url,
                        })
                    except Proveedor.DoesNotExist:
                        continue
                return proveedores_data
            return None

        # Pedido de un solo proveedor
        # Construir URL completa de la foto
        foto_url = None
        if obj.proveedor.logo:
            try:
                foto_url = obj.proveedor.logo.url
                if request and not foto_url.startswith('http'):
                    foto_url = request.build_absolute_uri(foto_url)
            except Exception:
                foto_url = None

        return {
            'id': obj.proveedor.id,
            'nombre': obj.proveedor.nombre,
            'telefono': obj.proveedor.telefono,
            'direccion': obj.proveedor.direccion,
            'foto_perfil': foto_url,
        }

    def get_repartidor(self, obj):
        if not obj.repartidor:
            return None
        from repartidores.serializers import RepartidorPublicoSerializer

        serializer = RepartidorPublicoSerializer(
            obj.repartidor,
            context=self.context,
        )

        repartidor_data = dict(serializer.data)
        repartidor_data.update({
            'telefono': getattr(obj.repartidor.user, 'celular', None),
            'ubicacion_actual': {
                'lat': obj.repartidor.latitud,
                'lng': obj.repartidor.longitud
            }
        })
        return repartidor_data

    def get_datos_envio(self, obj):
        """Retorna el objeto de logística si existe"""
        if ENVIOS_INSTALLED and hasattr(obj, 'datos_envio'):
            envio = obj.datos_envio
            return {
                'ciudad_origen': envio.ciudad_origen,
                'zona_destino': envio.zona_destino,
                'zona_nombre': dict(envio.ZONAS_CHOICES).get(envio.zona_destino) if envio.zona_destino else None,
                'distancia_km': envio.distancia_km,
                'tiempo_estimado_mins': envio.tiempo_estimado_mins,
                'costo_base': envio.costo_base,
                'costo_km_adicional': envio.costo_km_adicional,
                'recargo_nocturno': envio.recargo_nocturno,
                'costo_envio': envio.total_envio,
                'en_camino': envio.en_camino,
                'recargo_nocturno_aplicado': envio.recargo_nocturno > 0
            }
        return None

    def get_estado_display(self, obj):
        # Si aún no hay repartidor asignado y está pendiente, lo mostramos como "En espera de repartidor"
        if obj.estado == EstadoPedido.PENDIENTE_REPARTIDOR and obj.repartidor is None:
            return "En espera de repartidor"
        return obj.get_estado_display()

    def get_puede_calificar_repartidor(self, obj):
        """
        Habilita la calificación del repartidor cuando el pedido está ENTREGADO
        y el cliente aún no lo ha calificado.
        """
        request = self.context.get('request')
        user = getattr(request, 'user', None)

        if not user or not user.is_authenticated:
            return False
        if obj.estado != EstadoPedido.ENTREGADO:
            return False
        if not obj.repartidor:
            return False
        if getattr(obj.repartidor, 'user_id', None) == getattr(user, 'id', None):
            return False

        try:
          from calificaciones.models import Calificacion, TipoCalificacion
          ya_califico = Calificacion.objects.filter(
              pedido=obj,
              calificador=user,
              tipo=TipoCalificacion.CLIENTE_A_REPARTIDOR
          ).exists()
          return not ya_califico
        except Exception:
          return False

    def get_calificacion_repartidor(self, obj):
        """
        Devuelve la calificación que el cliente ya dio al repartidor (si existe).
        """
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if not user or not user.is_authenticated:
            return None
        try:
            from calificaciones.models import Calificacion, TipoCalificacion
            cal = Calificacion.objects.filter(
                pedido=obj,
                calificador=user,
                tipo=TipoCalificacion.CLIENTE_A_REPARTIDOR
            ).first()
            if cal:
                return {
                    'estrellas': cal.estrellas,
                    'comentario': cal.comentario,
                    'fecha': cal.created_at if hasattr(cal, 'created_at') else None,
                }
        except Exception:
            return None
        return None

    def get_puede_calificar_proveedor(self, obj):
        """
        Habilita la calificación del proveedor cuando el pedido está ENTREGADO
        y el cliente aún no lo ha calificado.
        Funciona tanto para pedidos de un solo proveedor como multi-proveedor.
        """
        request = self.context.get('request')
        user = getattr(request, 'user', None)

        if not user or not user.is_authenticated:
            return False
        # Permitir calificar solo en ENTREGADO
        if obj.estado != EstadoPedido.ENTREGADO:
            return False

        # Verificar si hay proveedor (un solo proveedor)
        if obj.proveedor:
            # Evitar autocalificación
            if getattr(obj.proveedor, 'user_id', None) == getattr(user, 'id', None):
                return False

            try:
                from calificaciones.models import Calificacion, TipoCalificacion
                ya_califico = Calificacion.objects.filter(
                    pedido=obj,
                    calificador=user,
                    tipo=TipoCalificacion.CLIENTE_A_PROVEEDOR
                ).exists()
                return not ya_califico
            except Exception:
                return False
        else:
            # Pedido multi-proveedor: verificar si hay proveedores en los items
            proveedores_items = obj.items.values_list('producto__proveedor', flat=True).distinct()
            if proveedores_items and len(proveedores_items) > 0:
                # Para pedidos multi-proveedor, permitir calificar
                # (cada proveedor se calificará individualmente en el futuro)
                try:
                    from calificaciones.models import Calificacion, TipoCalificacion
                    # Verificar si ya calificó a algún proveedor de este pedido
                    ya_califico = Calificacion.objects.filter(
                        pedido=obj,
                        calificador=user,
                        tipo=TipoCalificacion.CLIENTE_A_PROVEEDOR
                    ).exists()
                    return not ya_califico
                except Exception:
                    return False
            return False

    def get_calificacion_proveedor(self, obj):
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if not user or not user.is_authenticated:
            return None
        try:
            from calificaciones.models import Calificacion, TipoCalificacion
            cal = Calificacion.objects.filter(
                pedido=obj,
                calificador=user,
                tipo=TipoCalificacion.CLIENTE_A_PROVEEDOR
            ).first()
            if cal:
                return {
                    'estrellas': cal.estrellas,
                    'comentario': cal.comentario,
                    'fecha': cal.created_at if hasattr(cal, 'created_at') else None,
                }
        except Exception:
            return None
        return None

    def get_pago_id(self, obj):
        try:
            return obj.pago.id
        except Exception:
            return None

    def get_transferencia_comprobante_url(self, obj):
        try:
            pago = obj.pago
            if pago.transferencia_comprobante:
                request = self.context.get('request')
                url = pago.transferencia_comprobante.url
                if request:
                    return request.build_absolute_uri(url)
                return url
        except Exception:
            return None
        return None

    def get_estado_pago_actual(self, obj):
        try:
            return obj.pago.estado
        except Exception:
            return None


# ==========================================================
# SERIALIZERS DE ACCIÓN (Se mantienen ligeros)
# ==========================================================

class PedidoRepartidorResumidoSerializer(serializers.ModelSerializer):
    """
    Serializer RESUMIDO para repartidores cuando el pedido está PENDIENTE.
    Solo muestra información básica sin datos sensibles del cliente.
    """
    proveedor_nombre = serializers.SerializerMethodField()
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    metodo_pago_display = serializers.CharField(source='get_metodo_pago_display', read_only=True)
    zona_entrega = serializers.SerializerMethodField()

    class Meta:
        model = Pedido
        fields = [
            'id',
            'numero_pedido',
            'tipo',
            'tipo_display',
            'estado',
            'estado_display',
            'proveedor_nombre',
            'total',
            'metodo_pago',
            'metodo_pago_display',
            'comision_repartidor',
            'tarifa_servicio',
            'descripcion',  # Descripción general del pedido (no sensible)
            'zona_entrega',  # Solo zona general, NO dirección exacta
            'latitud_destino',  # Coordenadas para mostrar en mapa
            'longitud_destino',
            'creado_en',
        ]

    def get_proveedor_nombre(self, obj):
        return obj.proveedor.nombre if obj.proveedor else None

    def get_zona_entrega(self, obj):
        """
        Retorna solo una referencia general de la zona, no la dirección completa.
        Por ejemplo: "Sector Norte", "Centro", etc.
        """
        if obj.direccion_entrega:
            # Tomar solo las primeras palabras o una referencia general
            # Puedes ajustar esta lógica según cómo estén estructuradas tus direcciones
            palabras = obj.direccion_entrega.split(',')
            if len(palabras) > 1:
                # Retornar solo el barrio/sector (usualmente la segunda parte)
                return palabras[1].strip() if len(palabras[1].strip()) > 0 else "Zona no especificada"
            return "Ver en mapa"
        return "Zona no especificada"


class PedidoRepartidorDetalladoSerializer(serializers.ModelSerializer):
    """
    Serializer COMPLETO para repartidores cuando el pedido está ASIGNADO al repartidor.
    Incluye todos los datos sensibles necesarios para completar la entrega.
    """
    cliente = serializers.SerializerMethodField()
    proveedor = serializers.SerializerMethodField()
    items = ItemPedidoSerializer(many=True, read_only=True)

    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    metodo_pago_display = serializers.CharField(source='get_metodo_pago_display', read_only=True)
    tiempo_transcurrido = serializers.SerializerMethodField()
    pago_id = serializers.SerializerMethodField()
    transferencia_comprobante_url = serializers.SerializerMethodField()
    estado_pago_actual = serializers.SerializerMethodField()

    class Meta:
        model = Pedido
        fields = [
            'id',
            'numero_pedido',
            'tipo',
            'tipo_display',
            'estado',
            'estado_display',
            'estado_pago',
            'metodo_pago',
            'metodo_pago_display',
            'pago_id',
            'estado_pago_actual',
            'transferencia_comprobante_url',
            'cliente',  # INCLUYE datos completos del cliente
            'proveedor',
            'items',
            'descripcion',
            'total',
            'comision_repartidor',
            'tarifa_servicio',
            'direccion_origen',  # Dirección de recogida (proveedor)
            'latitud_origen',
            'longitud_origen',
            'direccion_entrega',  # Dirección COMPLETA del cliente
            'latitud_destino',
            'longitud_destino',
            'instrucciones_entrega',  # Instrucciones especiales del cliente
            'creado_en',
            'actualizado_en',
            'fecha_asignado',
            'fecha_en_proceso',
            'fecha_en_camino',
            'tiempo_transcurrido',
        ]

    def get_cliente(self, obj):
        """Datos COMPLETOS del cliente (solo para repartidor asignado)"""
        if not obj.cliente:
            return None
        return {
            'id': obj.cliente.id,
            'nombre': obj.cliente.user.get_full_name(),
            'telefono': getattr(obj.cliente.user, 'celular', None),  # DATO SENSIBLE
            'foto': obj.cliente.foto_perfil.url if obj.cliente.foto_perfil else None
        }

    def get_proveedor(self, obj):
        if not obj.proveedor:
            return None

        # Construir URL completa de la foto
        request = self.context.get('request')
        foto_url = None
        if obj.proveedor.logo:
            try:
                foto_url = obj.proveedor.logo.url
                if request and not foto_url.startswith('http'):
                    foto_url = request.build_absolute_uri(foto_url)
            except Exception:
                foto_url = None

        return {
            'id': obj.proveedor.id,
            'nombre': obj.proveedor.nombre,
            'telefono': obj.proveedor.telefono,  # Teléfono del proveedor para coordinar recogida
            'direccion': obj.proveedor.direccion,
            'foto_perfil': foto_url,  # ✅ Cambiado de 'foto' a 'foto_perfil' para consistencia
        }

    def get_tiempo_transcurrido(self, obj):
        """Calcula el tiempo transcurrido desde que se creó el pedido"""
        if not obj.creado_en:
            return None

        delta = timezone.now() - obj.creado_en
        minutos = int(delta.total_seconds() / 60)

        if minutos < 60:
            return f"{minutos} min"

        horas = minutos // 60
        mins_restantes = minutos % 60

        if horas < 24:
            return f"{horas}h {mins_restantes}min"

        dias = horas // 24
        horas_restantes = horas % 24
        return f"{dias}d {horas_restantes}h"

    def get_pago_id(self, obj):
        try:
            return obj.pago.id
        except Exception:
            return None

    def get_transferencia_comprobante_url(self, obj):
        try:
            pago = obj.pago
            if pago.transferencia_comprobante:
                request = self.context.get('request')
                url = pago.transferencia_comprobante.url
                if request:
                    return request.build_absolute_uri(url)
                return url
        except Exception:
            return None
        return None

    def get_estado_pago_actual(self, obj):
        try:
            return obj.pago.estado
        except Exception:
            return None


class PedidoAceptarRepartidorSerializer(serializers.Serializer):
    repartidor_id = serializers.IntegerField()
    def save(self):
        self.context['pedido'].aceptar_por_repartidor(self.instance)

class PedidoConfirmarProveedorSerializer(serializers.Serializer):
    proveedor_id = serializers.IntegerField()
    def save(self):
        self.context['pedido'].confirmar_por_proveedor()

class PedidoEstadoUpdateSerializer(serializers.Serializer):
    nuevo_estado = serializers.ChoiceField(choices=EstadoPedido.choices)
    imagen_evidencia = serializers.ImageField(required=False)
    def update(self, instance, validated_data):
        # Lógica de cambio de estado (simplificada aquí para brevedad, ver views)
        instance.estado = validated_data['nuevo_estado']
        if 'imagen_evidencia' in validated_data:
            instance.imagen_evidencia = validated_data['imagen_evidencia']
        instance.save()
        return instance

class PedidoCancelacionSerializer(serializers.Serializer):
    motivo = serializers.CharField(max_length=500)
    def save(self):
        self.context['pedido'].cancelar(self.validated_data['motivo'], "API")

class PedidoGananciasSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pedido
        fields = ['id', 'total', 'comision_repartidor', 'comision_proveedor', 'ganancia_app']
