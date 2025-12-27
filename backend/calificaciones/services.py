# calificaciones/services.py

import logging
from django.apps import apps
from django.db import transaction
from django.db.models import Avg
from django.core.exceptions import ValidationError

logger = logging.getLogger('calificaciones')


class CalificacionService:
    """
    Servicio centralizado para lógica de negocio de calificaciones.
    """

    @staticmethod
    @transaction.atomic
    def crear_calificacion(pedido, calificador, calificado, tipo, estrellas, **kwargs):
        """
        Crea una nueva calificación con todas las validaciones.
        
        Args:
            pedido: Instancia del Pedido
            calificador: User que da la calificación
            calificado: User que recibe la calificación
            tipo: TipoCalificacion
            estrellas: int (1-5)
            **kwargs: comentario, puntualidad, amabilidad, calidad_producto, es_anonima
        
        Returns:
            Calificacion: La calificación creada
        
        Raises:
            ValidationError: Si las validaciones fallan
        """
        from calificaciones.models import Calificacion, TipoCalificacion

        # Validar que el pedido esté entregado
        if pedido.estado != 'entregado':
            raise ValidationError(
                "Solo puedes calificar pedidos que hayan sido entregados."
            )

        # Verificar si ya existe esta calificación
        if Calificacion.objects.filter(pedido=pedido, calificador=calificador, tipo=tipo).exists():
            raise ValidationError(
                f"Ya has calificado este pedido como {dict(TipoCalificacion.choices).get(tipo)}."
            )

        # Crear la calificación
        calificacion = Calificacion(
            pedido=pedido,
            calificador=calificador,
            calificado=calificado,
            tipo=tipo,
            estrellas=estrellas,
            comentario=kwargs.get('comentario', ''),
            puntualidad=kwargs.get('puntualidad'),
            amabilidad=kwargs.get('amabilidad'),
            calidad_producto=kwargs.get('calidad_producto'),
            es_anonima=kwargs.get('es_anonima', False),
        )

        calificacion.full_clean()
        calificacion.save()

        logger.info(
            f"⭐ Calificación creada: {calificador.email} → {calificado.email} "
            f"({estrellas}⭐) - Pedido #{pedido.id}"
        )

        return calificacion

    @staticmethod
    @transaction.atomic
    def actualizar_promedio_usuario(user):
        """
        Actualiza el promedio de calificaciones de un usuario.
        Sincroniza con Perfil, Repartidor y Proveedor según corresponda.
        """
        from calificaciones.models import Calificacion, ResumenCalificacion

        # Obtener o crear resumen
        resumen, created = ResumenCalificacion.objects.get_or_create(user=user)
        resumen.recalcular()

        promedio = float(resumen.promedio_general)
        total = resumen.total_calificaciones

        # Sincronizar con Perfil (si existe)
        if hasattr(user, 'perfil') and user.perfil:
            user.perfil.calificacion = promedio
            user.perfil.total_resenas = total
            user.perfil.save(update_fields=['calificacion', 'total_resenas', 'actualizado_en'])
            logger.debug(f"Perfil actualizado: {user.email} → {promedio}⭐")

        # Sincronizar con Repartidor (si existe)
        if hasattr(user, 'repartidor') and user.repartidor:
            user.repartidor.calificacion_promedio = promedio
            user.repartidor.save(update_fields=['calificacion_promedio', 'actualizado_en'])
            logger.debug(f"Repartidor actualizado: {user.email} → {promedio}⭐")

        # Sincronizar con Proveedor (si existe y tiene el campo)
        if hasattr(user, 'proveedor') and user.proveedor:
            # Verificar si el modelo Proveedor tiene el campo calificacion_promedio
            if hasattr(user.proveedor, 'calificacion_promedio'):
                user.proveedor.calificacion_promedio = promedio
                user.proveedor.total_resenas = total
                user.proveedor.save(update_fields=['calificacion_promedio', 'total_resenas', 'updated_at'])
                logger.debug(f"Proveedor actualizado: {user.email} → {promedio}⭐")

        return resumen

    @staticmethod
    def obtener_calificaciones_pendientes(pedido, user):
        """
        Retorna las calificaciones que el usuario puede dar para un pedido.
        
        Returns:
            list[dict]: Lista de calificaciones pendientes con tipo y calificado
        """
        from calificaciones.models import Calificacion, TipoCalificacion

        if pedido.estado != 'entregado':
            return []

        # Determinar el rol del usuario en el pedido
        es_cliente = pedido.cliente and pedido.cliente.user_id == user.id
        es_repartidor = pedido.repartidor and pedido.repartidor.user_id == user.id
        es_proveedor = pedido.proveedor and pedido.proveedor.user_id == user.id

        # Calificaciones ya realizadas
        calificaciones_hechas = set(
            Calificacion.objects.filter(
                pedido=pedido,
                calificador=user
            ).values_list('tipo', flat=True)
        )

        pendientes = []

        # Cliente puede calificar a Repartidor y Proveedor
        if es_cliente:
            if pedido.repartidor and TipoCalificacion.CLIENTE_A_REPARTIDOR not in calificaciones_hechas:
                pendientes.append({
                    'tipo': TipoCalificacion.CLIENTE_A_REPARTIDOR,
                    'tipo_display': 'Calificar al Repartidor',
                    'calificado_id': pedido.repartidor.user_id,
                    'calificado_nombre': pedido.repartidor.user.get_full_name(),
                })

            if pedido.proveedor and TipoCalificacion.CLIENTE_A_PROVEEDOR not in calificaciones_hechas:
                pendientes.append({
                    'tipo': TipoCalificacion.CLIENTE_A_PROVEEDOR,
                    'tipo_display': 'Calificar al Proveedor',
                    'calificado_id': pedido.proveedor.user_id,
                    'calificado_nombre': pedido.proveedor.nombre,
                })

        # Repartidor puede calificar a Cliente y Proveedor
        if es_repartidor:
            if pedido.cliente and TipoCalificacion.REPARTIDOR_A_CLIENTE not in calificaciones_hechas:
                pendientes.append({
                    'tipo': TipoCalificacion.REPARTIDOR_A_CLIENTE,
                    'tipo_display': 'Calificar al Cliente',
                    'calificado_id': pedido.cliente.user_id,
                    'calificado_nombre': pedido.cliente.user.get_full_name(),
                })

            if pedido.proveedor and TipoCalificacion.REPARTIDOR_A_PROVEEDOR not in calificaciones_hechas:
                pendientes.append({
                    'tipo': TipoCalificacion.REPARTIDOR_A_PROVEEDOR,
                    'tipo_display': 'Calificar al Proveedor',
                    'calificado_id': pedido.proveedor.user_id,
                    'calificado_nombre': pedido.proveedor.nombre,
                })

        # Proveedor puede calificar al Repartidor
        if es_proveedor:
            if pedido.repartidor and TipoCalificacion.PROVEEDOR_A_REPARTIDOR not in calificaciones_hechas:
                pendientes.append({
                    'tipo': TipoCalificacion.PROVEEDOR_A_REPARTIDOR,
                    'tipo_display': 'Calificar al Repartidor',
                    'calificado_id': pedido.repartidor.user_id,
                    'calificado_nombre': pedido.repartidor.user.get_full_name(),
                })

        return pendientes

    @staticmethod
    def obtener_estadisticas_usuario(user):
        """
        Obtiene estadísticas completas de calificaciones de un usuario.
        """
        from calificaciones.models import Calificacion, ResumenCalificacion

        # Obtener o crear resumen
        resumen, _ = ResumenCalificacion.objects.get_or_create(user=user)

        # Últimas 5 calificaciones recibidas
        ultimas = Calificacion.objects.filter(
            calificado=user
        ).order_by('-created_at')[:5]

        return {
            'promedio_general': float(resumen.promedio_general),
            'total_calificaciones': resumen.total_calificaciones,
            'porcentaje_positivas': resumen.porcentaje_positivas,
            'desglose': {
                '5_estrellas': resumen.total_5_estrellas,
                '4_estrellas': resumen.total_4_estrellas,
                '3_estrellas': resumen.total_3_estrellas,
                '2_estrellas': resumen.total_2_estrellas,
                '1_estrella': resumen.total_1_estrella,
            },
            'promedios_categoria': {
                'puntualidad': float(resumen.promedio_puntualidad) if resumen.promedio_puntualidad else None,
                'amabilidad': float(resumen.promedio_amabilidad) if resumen.promedio_amabilidad else None,
                'calidad_producto': float(resumen.promedio_calidad_producto) if resumen.promedio_calidad_producto else None,
            },
            'ultimas_calificaciones': [
                {
                    'estrellas': c.estrellas,
                    'comentario': c.comentario,
                    'calificador': c.nombre_calificador_display,
                    'tiempo': c.tiempo_desde_creacion,
                }
                for c in ultimas
            ]
        }

    @staticmethod
    def solicitar_calificacion(pedido):
        """
        Envía notificación para solicitar calificaciones después de la entrega.
        Llama a este método cuando un pedido se marque como 'entregado'.
        """
        # Aquí puedes integrar con FCM o tu sistema de notificaciones
        logger.info(f"⭐ [CALIFICACIÓN] Solicitud enviada para pedido #{pedido.id}")

        # Notificar al cliente
        if pedido.cliente and hasattr(pedido.cliente, 'user'):
            logger.info(f"  → Notificar a cliente: {pedido.cliente.user.email}")
            # TODO: Enviar push notification al cliente

        # Notificar al repartidor
        if pedido.repartidor and hasattr(pedido.repartidor, 'user'):
            logger.info(f"  → Notificar a repartidor: {pedido.repartidor.user.email}")
            # TODO: Enviar push notification al repartidor

        # Notificar al proveedor
        if pedido.proveedor and hasattr(pedido.proveedor, 'user'):
            logger.info(f"  → Notificar a proveedor: {pedido.proveedor.user.email}")
            # TODO: Enviar push notification al proveedor

        return True
