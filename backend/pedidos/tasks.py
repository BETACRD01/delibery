# pedidos/tasks.py (OPTIMIZADO + CONSCIENTE DE LOGÍSTICA)

from celery import shared_task
from django.utils import timezone
from django.db.models import Sum, Count, Avg
from datetime import timedelta
import logging

# IMPORTACIONES SEGURAS (DENTRO DE TRY/EXCEPT O FUNCIONES)
try:
    from notificaciones.services import (
        notificar_admin_pedidos_sin_asignar,
        enviar_recordatorio_calificacion,
        notificar_repartidor_pedido_listo,
        enviar_push
    )
    NOTIFICACIONES_ACTIVE = True
except ImportError:
    NOTIFICACIONES_ACTIVE = False

try:
    from envios.models import Envio
    ENVIOS_ACTIVE = True
except ImportError:
    ENVIOS_ACTIVE = False

logger = logging.getLogger('pedidos.tasks')


# ==========================================================
# MONITOREO DE RETRASOS Y LOGÍSTICA
# ==========================================================

@shared_task(name='pedidos.verificar_pedidos_retrasados')
def verificar_pedidos_retrasados():
    """
    Revisa pedidos 'En Ruta' que llevan mucho tiempo sin entregarse.
    Si tiene logística, verifica el tiempo estimado vs real.
    """
    from .models import Pedido, EstadoPedido
    from .signals import pedido_retrasado

    # Límite general: 45 min sin actualización
    tiempo_limite = timezone.now() - timedelta(minutes=45)

    # Optimización: Cargar datos de envío en la misma consulta
    qs = Pedido.objects.filter(
        estado=EstadoPedido.EN_CAMINO,
        actualizado_en__lt=tiempo_limite
    ).select_related('cliente__user', 'repartidor__user')
    
    if ENVIOS_ACTIVE:
        qs = qs.select_related('datos_envio')

    contador = 0
    for pedido in qs:
        # Lógica inteligente con Envios
        if ENVIOS_ACTIVE and hasattr(pedido, 'datos_envio'):
            estimado = pedido.datos_envio.tiempo_estimado_mins
            transcurrido = (timezone.now() - pedido.fecha_en_ruta).seconds / 60
            
            # Solo alertar si superamos el tiempo estimado de Google Maps + 20 min de gracia
            if transcurrido < (estimado + 20):
                continue 

        tiempo_retraso = int((timezone.now() - pedido.actualizado_en).total_seconds() / 60)
        logger.warning(f"ALERTA: Pedido #{pedido.numero_pedido} retrasado {tiempo_retraso} min")
        
        # Disparar señal para notificaciones/compensaciones
        pedido_retrasado.send(sender=Pedido, pedido=pedido, tiempo_retraso=tiempo_retraso)
        contador += 1

    return f"Procesados {contador} pedidos retrasados"


@shared_task(name='pedidos.verificar_sin_asignar')
def verificar_pedidos_sin_repartidor():
    """Alerta si hay pedidos confirmados que nadie acepta"""
    from .models import Pedido, EstadoPedido

    limite = timezone.now() - timedelta(minutes=10)
    
    pedidos = Pedido.objects.filter(
        estado=EstadoPedido.ASIGNADO_REPARTIDOR,
        repartidor__isnull=True,
        creado_en__lt=limite
    )

    count = pedidos.count()
    if count > 0 and NOTIFICACIONES_ACTIVE:
        notificar_admin_pedidos_sin_asignar(pedidos)
        logger.warning(f"{count} pedidos esperando repartidor > 10min")

    return count


# ==========================================================
#  REPORTES DIARIOS
# ==========================================================

@shared_task(name='pedidos.generar_reporte_diario')
def generar_reporte_diario():
    """Genera estadísticas financieras y logísticas del día"""
    from .models import Pedido, EstadoPedido
    from reportes.services import enviar_reporte_diario # Asumiendo que existe

    hoy = timezone.now().date()
    pedidos_hoy = Pedido.objects.filter(creado_en__date=hoy)
    
    if not pedidos_hoy.exists():
        return "Sin pedidos hoy"

    # Agregaciones financieras
    finanzas = pedidos_hoy.filter(estado=EstadoPedido.ENTREGADO).aggregate(
        ventas=Sum('total'),
        ganancia=Sum('ganancia_app'),
        promedio=Avg('total')
    )

    # Agregaciones logísticas (si aplica)
    km_totales = 0
    if ENVIOS_ACTIVE:
        # Sumar distancia de todos los pedidos entregados
        km_totales = Envio.objects.filter(
            pedido__in=pedidos_hoy, 
            pedido__estado=EstadoPedido.ENTREGADO
        ).aggregate(km=Sum('distancia_km'))['km'] or 0

    stats = {
        'fecha': str(hoy),
        'total_pedidos': pedidos_hoy.count(),
        'entregados': pedidos_hoy.filter(estado=EstadoPedido.ENTREGADO).count(),
        'cancelados': pedidos_hoy.filter(estado=EstadoPedido.CANCELADO).count(),
        'ventas_totales': float(finanzas['ventas'] or 0),
        'ganancia_neta': float(finanzas['ganancia'] or 0),
        'km_recorridos': float(km_totales)
    }

    try:
        enviar_reporte_diario(stats)
    except NameError:
        logger.info(f"Reporte Diario (Simulado): {stats}")

    return stats


# ==========================================================
# TAREAS DE SEGUIMIENTO AL CLIENTE
# ==========================================================

@shared_task(name='pedidos.recordatorio_calificacion')
def enviar_recordatorio_calificacion_task(pedido_id):
    """Envía push notification 24h después si no ha calificado"""
    from .models import Pedido
    
    try:
        pedido = Pedido.objects.get(id=pedido_id)
        
        # Verificar si ya calificó (asumiendo relación inversa 'calificacion')
        if hasattr(pedido, 'calificacion'):
            return "Ya calificado"

        if NOTIFICACIONES_ACTIVE:
            enviar_push(
                usuario=pedido.cliente.user,
                titulo="¿Qué tal tu pedido?",
                cuerpo=f"Ayúdanos calificando tu experiencia con {pedido.proveedor.nombre if pedido.proveedor else 'nosotros'} ⭐"
            )
            return "Recordatorio enviado"
            
    except Pedido.DoesNotExist:
        return "Pedido no existe"
    except Exception as e:
        logger.error(f"Error recordatorio calificación: {e}")


# ==========================================================
#  MANTENIMIENTO DEL SISTEMA
# ==========================================================

@shared_task(name='pedidos.limpieza_pedidos_abandonados')
def limpiar_pedidos_abandonados():
    """Cancela automáticamente pedidos 'Confirmados' de hace > 24h"""
    from .models import Pedido, EstadoPedido

    limite = timezone.now() - timedelta(hours=24)
    
    # Pedidos que se quedaron "Confirmados" pero nadie aceptó ni procesó
    abandonados = Pedido.objects.filter(
        estado=EstadoPedido.ASIGNADO_REPARTIDOR,
        creado_en__lt=limite
    )
    
    count = 0
    for p in abandonados:
        p.cancelar(motivo="Cancelación automática por inactividad (24h)", actor="Sistema")
        count += 1
        
    if count > 0:
        logger.info(f"Limpieza: {count} pedidos abandonados cancelados.")
    
    return count
