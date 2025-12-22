# -*- coding: utf-8 -*-
# rifas/admin.py
"""
Django Admin para Sistema de Rifas

 FUNCIONALIDADES:
- Gestión completa de rifas desde el admin
- Botón para realizar sorteo manual
    - Vista de participantes registrados
- Historial de ganadores
- Filtros avanzados
- Acciones masivas
"""

from django.contrib import admin
from django.utils.html import format_html
from django.urls import path, reverse
from django.shortcuts import redirect, render
from django.contrib import messages
from django.utils import timezone
from django.db.models import Count, Q
from .models import Rifa, Participacion, EstadoRifa, Premio
from pedidos.models import EstadoPedido
import logging

logger = logging.getLogger('rifas')


# ============================================
# INLINES
# ============================================

class PremioInline(admin.TabularInline):
    """Permite gestionar los premios de la rifa desde el admin"""
    model = Premio
    extra = 1
    max_num = 3
    fields = ['posicion', 'descripcion', 'imagen', 'ganador']
    readonly_fields = ['ganador']


# ============================================
# ADMIN: RIFA
# ============================================

@admin.register(Rifa)
class RifaAdmin(admin.ModelAdmin):
    """
    Admin personalizado para Rifas

     CARACTERÍSTICAS:
    - Ver participantes registrados
    - Realizar sorteo con un clic
    - Filtros por estado, mes, año
    - Campos calculados (participantes, días restantes)
    """

    inlines = [PremioInline]

    list_display = [
        'titulo_con_emoji',
        'mes_anio',
        'estado_badge',
        'total_participantes_badge',
        'premios_badge',
        'dias_restantes_badge',
        'ganadores_badge',
        'acciones_rapidas'
    ]

    list_filter = [
        'estado',
        'anio',
        'mes',
        'fecha_inicio',
    ]

    search_fields = [
        'titulo',
        'descripcion',
        'premios__descripcion',
        'premios__ganador__email',
        'premios__ganador__first_name',
        'premios__ganador__last_name'
    ]

    readonly_fields = [
        'id',
        'mes',
        'anio',
        'creado_en',
        'actualizado_en',
        'mostrar_participantes_elegibles',
        'mostrar_estadisticas',
        'creado_por'
    ]

    fieldsets = (
        ('Información Básica', {
            'fields': (
                'id',
                'titulo',
                'descripcion',
                'imagen'
            )
        }),
        ('Fechas', {
            'fields': (
                'fecha_inicio',
                'fecha_fin',
                'mes',
                'anio'
            )
        }),  # <--- CORRECCIÓN: Comma agregada aquí
        ('Configuración', {
            'fields': (
                'pedidos_minimos',
                'estado'
            )
        }),
        ('Estadísticas', {
            'fields': (
                'mostrar_estadisticas',
                'mostrar_participantes_elegibles'
            ),
            'classes': ('collapse',)
        }),
        ('Auditoría', {
            'fields': (
                'creado_por',
                'creado_en',
                'actualizado_en'
            ),
            'classes': ('collapse',)
        })
    )

    actions = [
        'realizar_sorteo_masivo',
        'finalizar_rifas',
        'cancelar_rifas'
    ]

    # ============================================
    # MÉTODOS DE VISUALIZACIÓN
    # ============================================

    def titulo_con_emoji(self, obj):
        """Título con emoji según estado"""
        emojis = {
            EstadoRifa.ACTIVA: '',
            EstadoRifa.FINALIZADA: '',
            EstadoRifa.CANCELADA: ''
        }
        emoji = emojis.get(obj.estado, '')
        return f"{emoji} {obj.titulo}"
    titulo_con_emoji.short_description = 'Rifa'

    def mes_anio(self, obj):
        """Muestra mes y año"""
        return f"{obj.mes_nombre} {obj.anio}"
    mes_anio.short_description = 'Período'

    def estado_badge(self, obj):
        """Badge de estado con colores"""
        colors = {
            EstadoRifa.ACTIVA: '#28a745',
            EstadoRifa.FINALIZADA: '#6c757d',
            EstadoRifa.CANCELADA: '#dc3545'
        }
        color = colors.get(obj.estado, '#6c757d')

        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold;">{}</span>',
            color,
            obj.get_estado_display()
        )
    estado_badge.short_description = 'Estado'

    def total_participantes_badge(self, obj):
        """Badge con total de participantes"""
        total = obj.total_participantes
        color = '#28a745' if total > 0 else '#dc3545'

        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold;">{}</span>',
            color,
            total
        )
    total_participantes_badge.short_description = 'Participantes'

    def premios_badge(self, obj):
        """Badge con total de premios configurados"""
        total = obj.premios.count()
        color = '#28a745' if total > 0 else '#dc3545'

        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold;">{} premio(s)</span>',
            color,
            total
        )
    premios_badge.short_description = 'Premios'

    def dias_restantes_badge(self, obj):
        """Badge con días restantes"""
        if obj.estado != EstadoRifa.ACTIVA:
            return '—'

        dias = obj.dias_restantes

        if dias > 7:
            color = '#28a745'
            
        elif dias > 3:
            color = '#ffc107'
           
        else:
            color = '#dc3545'

        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold;">{} días</span>',
            color,
            dias
        )
    dias_restantes_badge.short_description = 'Días Restantes'

    def ganadores_badge(self, obj):
        """Resumen rápido de ganadores"""
        ganadores = obj.premios.filter(ganador__isnull=False).select_related('ganador')
        total = ganadores.count()
        total_premios = obj.premios.count()

        if total == 0:
            return '—'

        nombres = ', '.join([g.ganador.get_full_name() for g in ganadores if g.ganador])
        return format_html(
            '<span style="background-color: #17a2b8; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold;">{}/{} ganadores</span><br><small>{}</small>',
            total,
            total_premios,
            nombres or 'Pendiente'
        )
    ganadores_badge.short_description = 'Ganadores'

    def acciones_rapidas(self, obj):
        """Botones de acción rápida"""
        tiene_ganadores = obj.premios.filter(ganador__isnull=False).exists()

        if obj.estado == EstadoRifa.ACTIVA and not tiene_ganadores:
            url = reverse('admin:rifas_realizar_sorteo', args=[obj.pk])
            return format_html(
                '<a class="button" href="{}" style="background-color: #28a745; '
                'color: white; padding: 5px 10px; text-decoration: none; '
                'border-radius: 3px;">Sortear</a>',
                url
            )
        elif obj.estado == EstadoRifa.FINALIZADA and tiene_ganadores:
            return format_html(
                '<span style="color: #28a745; font-weight: bold;">Sorteada</span>'
            )

        return '—'
    acciones_rapidas.short_description = 'Acciones'

    # ============================================
    #  CAMPOS READONLY PERSONALIZADOS
    # ============================================

    def mostrar_estadisticas(self, obj):
        """Muestra estadísticas detalladas"""
        if not obj.pk:
            return "Guarda la rifa para ver estadísticas"

        total_participantes = obj.total_participantes
        dias_restantes = obj.dias_restantes if obj.esta_activa else 0
        total_premios = obj.premios.count()
        premios_con_ganador = obj.premios.filter(ganador__isnull=False).count()

        html = f"""
        <div style="background: #f8f9fa; padding: 15px; border-radius: 5px;">
            <h3 style="margin-top: 0;">Estadísticas</h3>

            <table style="width: 100%;">
                <tr>
                    <td><strong> Participantes Registrados:</strong></td>
                    <td style="text-align: right;">{total_participantes}</td>
                </tr>
                <tr>
                    <td><strong> Días Restantes:</strong></td>
                    <td style="text-align: right;">{dias_restantes}</td>
                </tr>
                <tr>
                    <td><strong> Pedidos Mínimos:</strong></td>
                    <td style="text-align: right;">{obj.pedidos_minimos}</td>
                </tr>
                <tr>
                    <td><strong> Premios Configurados:</strong></td>
                    <td style="text-align: right;">{total_premios}</td>
                </tr>
                <tr>
                    <td><strong> Premios con Ganador:</strong></td>
                    <td style="text-align: right;">{premios_con_ganador}</td>
                </tr>
            </table>
        </div>
        """

        return format_html(html)
    mostrar_estadisticas.short_description = 'Estadísticas'

    def mostrar_participantes_elegibles(self, obj):
        """Muestra lista de participantes registrados"""
        if not obj.pk:
            return "Guarda la rifa para ver participantes"

        participaciones = obj.participaciones.select_related('usuario').order_by('-fecha_registro')
        total = participaciones.count()

        if total == 0:
            return format_html(
                '<div style="background: #fff3cd; padding: 15px; border-radius: 5px; '
                'border-left: 4px solid #ffc107;">'
                '<strong>No hay participantes registrados aún</strong><br>'
                '<small>Los usuarios deben completar al menos {} pedidos durante el período de la rifa.</small>'
                '</div>',
                obj.pedidos_minimos
            )

        # Mostrar primeros 10 participantes
        lista_html = "<ul style='margin: 10px 0; padding-left: 20px;'>"

        for participacion in participaciones[:10]:
            participante = participacion.usuario
            pedidos = participacion.pedidos_completados

            lista_html += f"""
            <li style="margin: 5px 0;">
                <strong>{participante.get_full_name()}</strong>
                ({participante.email})
                <br>
                <small style="color: #666;">
                    {pedidos} pedidos completados
                </small>
            </li>
            """

        if total > 10:
            lista_html += f"<li><em>... y {total - 10} participantes más</em></li>"

        lista_html += "</ul>"

        html = f"""
        <div style="background: #d4edda; padding: 15px; border-radius: 5px;
                    border-left: 4px solid #28a745;">
            <h3 style="margin-top: 0;">👥 Participantes Registrados ({total})</h3>
            {lista_html}
        </div>
        """

        return format_html(html)
    mostrar_participantes_elegibles.short_description = 'Participantes Registrados'

    # ============================================
    #  SORTEO MANUAL
    # ============================================

    def get_urls(self):
        """Añade URL personalizada para realizar sorteo"""
        urls = super().get_urls()
        custom_urls = [
            path(
                '<uuid:rifa_id>/sortear/',
                self.admin_site.admin_view(self.realizar_sorteo_view),
                name='rifas_realizar_sorteo'
            ),
        ]
        return custom_urls + urls

    def realizar_sorteo_view(self, request, rifa_id):
        """Vista para realizar sorteo manual"""
        rifa = self.get_object(request, rifa_id)

        if not rifa:
            self.message_user(
                request,
                "Rifa no encontrada",
                level=messages.ERROR
            )
            return redirect('admin:rifas_rifa_changelist')

        if not rifa.premios.exists():
            self.message_user(
                request,
                "Esta rifa no tiene premios configurados",
                level=messages.ERROR
            )
            return redirect('admin:rifas_rifa_change', rifa_id)

        # Verificar si se puede sortear
        if rifa.estado != EstadoRifa.ACTIVA:
            self.message_user(
                request,
                f" No se puede sortear una rifa {rifa.get_estado_display().lower()}",
                level=messages.WARNING
            )
            return redirect('admin:rifas_rifa_change', rifa_id)

        if rifa.premios.filter(ganador__isnull=False).exists():
            self.message_user(
                request,
                " Esta rifa ya tiene ganadores asignados",
                level=messages.WARNING
            )
            return redirect('admin:rifas_rifa_change', rifa_id)

        # Confirmar sorteo
        if request.method == 'POST':
            try:
                resultado = rifa.realizar_sorteo()

                if resultado and not resultado.get('sin_participantes'):
                    premios_ganados = resultado.get('premios_ganados', [])
                    ganadores_msg = ", ".join([
                        f"{p['posicion']}°: {p['ganador'].get_full_name()}"
                        for p in premios_ganados
                        if p.get('ganador')
                    ])

                    self.message_user(
                        request,
                        f"¡Sorteo realizado! Ganadores: {ganadores_msg or 'Asignados'}",
                        level=messages.SUCCESS
                    )

                    for premio in premios_ganados:
                        ganador = premio.get('ganador')
                        if ganador:
                            logger.info(
                                f"Sorteo manual realizado por {request.user.email} "
                                f"para rifa {rifa.titulo}. Premio {premio['posicion']}: {ganador.email}"
                            )
                else:
                    self.message_user(
                        request,
                        "No hay participantes registrados para sortear",
                        level=messages.WARNING
                    )

                return redirect('admin:rifas_rifa_change', rifa_id)

            except Exception as e:
                self.message_user(
                    request,
                    f"Error al realizar sorteo: {str(e)}",
                    level=messages.ERROR
                )
                logger.error(f"Error en sorteo manual: {str(e)}")
                return redirect('admin:rifas_rifa_change', rifa_id)

        # Mostrar página de confirmación
        participantes = rifa.participaciones.select_related('usuario').order_by('-fecha_registro')

        context = {
            **self.admin_site.each_context(request),
            'title': f'Realizar Sorteo: {rifa.titulo}',
            'rifa': rifa,
            'total_participantes': participantes.count(),
            'participantes': [p.usuario for p in participantes[:20]],
            'opts': self.model._meta,
        }

        return render(
            request,
            'admin/rifas/confirmar_sorteo.html',
            context
        )

    # ============================================
    #  ACCIONES MASIVAS
    # ============================================

    @admin.action(description='Realizar sorteo en rifas seleccionadas')
    def realizar_sorteo_masivo(self, request, queryset):
        """Realiza sorteo en múltiples rifas"""
        rifas_activas = queryset.filter(
            estado=EstadoRifa.ACTIVA
        ).prefetch_related('premios')

        if not rifas_activas.exists():
            self.message_user(
                request,
                "No hay rifas activas en la selección",
                level=messages.WARNING
            )
            return

        sorteadas = 0
        sin_premios = 0
        sin_participantes = 0

        for rifa in rifas_activas:
            if not rifa.premios.exists():
                sin_premios += 1
                continue

            if rifa.premios.filter(ganador__isnull=False).exists():
                continue

            try:
                resultado = rifa.realizar_sorteo()
                if resultado and not resultado.get('sin_participantes'):
                    sorteadas += 1
                else:
                    sin_participantes += 1
            except Exception as e:
                logger.error(f"Error al sortear {rifa.titulo}: {str(e)}")

        mensaje = f"{sorteadas} rifa(s) sorteada(s)"
        if sin_participantes > 0:
            mensaje += f" | {sin_participantes} sin participantes"
        if sin_premios > 0:
            mensaje += f" | {sin_premios} sin premios configurados"

        self.message_user(request, mensaje, level=messages.SUCCESS)

    @admin.action(description='Finalizar rifas seleccionadas')
    def finalizar_rifas(self, request, queryset):
        """Finaliza rifas activas"""
        actualizadas = queryset.filter(
            estado=EstadoRifa.ACTIVA
        ).update(estado=EstadoRifa.FINALIZADA)

        self.message_user(
            request,
            f"{actualizadas} rifa(s) finalizada(s)",
            level=messages.SUCCESS
        )

    @admin.action(description='Cancelar rifas seleccionadas')
    def cancelar_rifas(self, request, queryset):
        """Cancela rifas"""
        actualizadas = queryset.filter(
            estado__in=[EstadoRifa.ACTIVA, EstadoRifa.FINALIZADA]
        ).update(estado=EstadoRifa.CANCELADA)

        self.message_user(
            request,
            f"{actualizadas} rifa(s) cancelada(s)",
            level=messages.SUCCESS
        )

    # ============================================
    #  SAVE OVERRIDE
    # ============================================

    def save_model(self, request, obj, form, change):
        """Asigna creado_por automáticamente"""
        if not change:  # Solo en creación
            obj.creado_por = request.user

        super().save_model(request, obj, form, change)

        if not change:
            logger.info(f"Rifa creada por {request.user.email}: {obj.titulo}")


# ============================================
#  ADMIN: PARTICIPACIÓN
# ============================================

@admin.register(Participacion)
class ParticipacionAdmin(admin.ModelAdmin):
    """
    Admin para Participaciones en Rifas
    """

    list_display = [
        'usuario_info',
        'rifa_titulo',
        'pedidos_completados_badge',
        'ganador_badge',
        'fecha_registro'
    ]

    list_filter = [
        'ganador',
        'rifa__mes',
        'rifa__anio',
        'fecha_registro'
    ]

    search_fields = [
        'usuario__email',
        'usuario__first_name',
        'usuario__last_name',
        'rifa__titulo'
    ]

    readonly_fields = [
        'id',
        'rifa',
        'usuario',
        'pedidos_completados',
        'ganador',
        'fecha_registro'
    ]

    def has_add_permission(self, request):
        """No permitir crear manualmente"""
        return False

    def has_change_permission(self, request, obj=None):
        """No permitir editar"""
        return False

    def usuario_info(self, obj):
        """Información del usuario"""
        return format_html(
            '<strong>{}</strong><br>'
            '<small style="color: #666;">{}</small>',
            obj.usuario.get_full_name(),
            obj.usuario.email
        )
    usuario_info.short_description = 'Usuario'

    def rifa_titulo(self, obj):
        """Título de la rifa"""
        return obj.rifa.titulo
    rifa_titulo.short_description = 'Rifa'

    def pedidos_completados_badge(self, obj):
        """Badge de pedidos"""
        return format_html(
            '<span style="background-color: #007bff; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-weight: bold;"> {}</span>',
            obj.pedidos_completados
        )
    pedidos_completados_badge.short_description = 'Pedidos'

    def ganador_badge(self, obj):
        """Badge de ganador"""
        if obj.ganador:
            return format_html(
                '<span style="background-color: #ffd700; color: #000; padding: 3px 10px; '
                'border-radius: 3px; font-weight: bold;"> GANADOR</span>'
            )
        return '—'
    ganador_badge.short_description = 'Resultado'
