from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.db.models import Count, Q
from django.utils.safestring import mark_safe
from .models import Proveedor
import logging

logger = logging.getLogger('proveedores')


@admin.register(Proveedor)
class ProveedorAdmin(admin.ModelAdmin):
    """
    Admin mejorado para Proveedor con integración completa de User

     MEJORAS IMPLEMENTADAS:
    - Muestra datos del usuario vinculado
    - Badges de color para estados
    - Acciones masivas con sincronización
    - Búsqueda por campos de User
    - Filtros avanzados
    - Fieldsets organizados
    - Validación de unicidad de User
    - Links directos al User en admin
    """

    # ============================================
    # LIST DISPLAY CON DATOS DE USUARIO
    # ============================================
    list_display = [
        'id',
        'nombre',
        'ruc',
        'get_usuario_vinculado',
        'get_email_usuario',
        'get_celular_usuario',
        'tipo_proveedor',
        'ciudad',
        'verificado_badge',
        'activo_badge',
        'comision_porcentaje',
        'created_at'
    ]

    # ============================================
    # FILTROS MEJORADOS
    # ============================================
    list_filter = [
        'activo',
        'verificado',
        'tipo_proveedor',
        'ciudad',
        ('user', admin.EmptyFieldListFilter),
        'created_at',
        'updated_at'
    ]

    # ============================================
    # BÚSQUEDA AMPLIADA (INCLUYE USER)
    # ============================================
    search_fields = [
        'nombre',
        'ruc',
        'email',
        'telefono',
        'ciudad',
        'descripcion',
        #  NUEVO: Buscar por datos del usuario vinculado
        'user__email',
        'user__username',
        'user__first_name',
        'user__last_name',
        'user__celular',
    ]

    # ============================================
    # CAMPOS DE SOLO LECTURA
    # ============================================
    readonly_fields = [
        'created_at',
        'updated_at',
        'user',
        'get_datos_usuario_completos',
        'get_link_usuario',
        'ruc'
    ]

    # ============================================
    #  FIELDSETS REORGANIZADOS
    # ============================================
    fieldsets = (
        ('Usuario Vinculado', {
            'fields': (
                'user',
                'get_link_usuario',
                'get_datos_usuario_completos'
            ),
            'description': (
                '<strong>Información del usuario registrado</strong><br>'
                'Este usuario se creó automáticamente al registrarse como proveedor.'
            ),
            'classes': ('wide',)
        }),

        ('Información Básica', {
            'fields': (
                'nombre',
                'ruc',
                'tipo_proveedor',
                'descripcion'
            )
        }),

        ('Contacto', {
            'fields': (
                'telefono',
                'email',
                'direccion',
                'ciudad'
            ),
            'description': (
                '<div style="background: #fff3cd; padding: 10px; border-left: 4px solid #ffc107;">'
                '<strong>ADVERTENCIA:</strong> Los campos <code>email</code> y '
                '<code>telefono</code> están <strong>deprecados</strong>.<br>'
                'Los datos oficiales provienen del usuario vinculado. '
                'Para cambiar email/celular, edita el perfil del usuario.'
                '</div>'
            )
        }),

        ('Configuración', {
            'fields': (
                'activo',
                'verificado',
                'comision_porcentaje'
            )
        }),

        ('Horarios', {
            'fields': (
                'horario_apertura',
                'horario_cierre'
            ),
            'classes': ('collapse',)
        }),

        ('Ubicación', {
            'fields': (
                'latitud',
                'longitud'
            ),
            'classes': ('collapse',)
        }),

        ('Imagen', {
            'fields': ('logo',)
        }),

        ('Auditoría', {
            'fields': (
                'created_at',
                'updated_at'
            ),
            'classes': ('collapse',)
        }),
    )

    # ============================================
    # ORDENAMIENTO Y JERARQUÍA
    # ============================================
    ordering = ['-created_at']
    date_hierarchy = 'created_at'

    # ============================================
    # PAGINACIÓN
    # ============================================
    list_per_page = 25
    list_max_show_all = 100

    # ============================================
    # ACCIONES MASIVAS MEJORADAS
    # ============================================
    actions = [
        'verificar_proveedores',
        'desverificar_proveedores',
        'activar_proveedores',
        'desactivar_proveedores',
        'sincronizar_con_usuarios',
        'exportar_csv'
    ]

    # ============================================
    # MÉTODOS PERSONALIZADOS PARA DISPLAY
    # ============================================
    def get_usuario_vinculado(self, obj):
        if obj.user:
            url = reverse('admin:authentication_user_change', args=[obj.user.id])
            return format_html(
                '<a href="{}" style="text-decoration: none;">'
                '<span style="color: #0066cc;">👤 {}</span>'
                '</a>',
                url,
                obj.user.get_full_name() or obj.user.username
            )
        return format_html(
            '<span style="color: #dc3545; font-weight: bold;"> Sin usuario</span>'
        )
    get_usuario_vinculado.short_description = 'Usuario'
    get_usuario_vinculado.admin_order_field = 'user__first_name'

    def get_email_usuario(self, obj):
        if obj.user:
            return obj.user.email
        return format_html(
            '<span style="color: #6c757d; font-style: italic;">{}</span>',
            obj.email or '—'
        )
    get_email_usuario.short_description = 'Email'
    get_email_usuario.admin_order_field = 'user__email'

    def get_celular_usuario(self, obj):
        if obj.user:
            return obj.user.celular
        return format_html(
            '<span style="color: #6c757d; font-style: italic;">{}</span>',
            obj.telefono or '—'
        )
    get_celular_usuario.short_description = 'Celular'
    get_celular_usuario.admin_order_field = 'user__celular'

    def verificado_badge(self, obj):
        if obj.verificado:
            return format_html(
                '<span style="background: #28a745; color: white; padding: 3px 10px; '
                'border-radius: 12px; font-size: 11px; font-weight: bold;">'
                '✓ VERIFICADO'
                '</span>'
            )
        else:
            return format_html(
                '<span style="background: #ffc107; color: #000; padding: 3px 10px; '
                'border-radius: 12px; font-size: 11px; font-weight: bold;">'
                '⚠ SIN VERIFICAR'
                '</span>'
            )
    verificado_badge.short_description = 'Verificado'
    verificado_badge.admin_order_field = 'verificado'

    def activo_badge(self, obj):
        if obj.activo:
            return format_html(
                '<span style="background: #007bff; color: white; padding: 3px 10px; '
                'border-radius: 12px; font-size: 11px; font-weight: bold;">'
                '● ACTIVO'
                '</span>'
            )
        else:
            return format_html(
                '<span style="background: #dc3545; color: white; padding: 3px 10px; '
                'border-radius: 12px; font-size: 11px; font-weight: bold;">'
                '● INACTIVO'
                '</span>'
            )
    activo_badge.short_description = 'Estado'
    activo_badge.admin_order_field = 'activo'

    # ============================================
    # MÉTODOS PARA READONLY_FIELDS
    # ============================================
    def get_link_usuario(self, obj):
        if obj.user:
            url = reverse('admin:authentication_user_change', args=[obj.user.id])
            return format_html(
                '<a href="{}" class="button" target="_blank">'
                '👤 Ver Usuario en Admin'
                '</a>',
                url
            )
        return format_html(
            '<span style="color: #dc3545;"> No hay usuario vinculado</span>'
        )
    get_link_usuario.short_description = 'Acceso Rápido'

    def get_datos_usuario_completos(self, obj):
        if not obj.user:
            return format_html(
                '<div style="background: #f8d7da; padding: 15px; border-left: 4px solid #dc3545;">'
                '<strong style="color: #721c24;"> SIN USUARIO VINCULADO</strong><br>'
                'Este proveedor fue creado antes de implementar la vinculación automática.<br>'
                'Considera vincular manualmente o usar la acción "Sincronizar con usuarios".'
                '</div>'
            )

        user = obj.user

        email_sync = '' if obj.email == user.email else 'Desincronizado'
        telefono_sync = '' if obj.telefono == user.celular else ' Desincronizado'

        return format_html(
            '<div style="background: #d4edda; padding: 15px; border-left: 4px solid #28a745; '
            'font-family: monospace; line-height: 1.8;">'
            '<strong style="font-size: 14px;">👤 INFORMACIÓN DEL USUARIO</strong><br><br>'

            '<strong>ID:</strong> {}<br>'
            '<strong>Nombre completo:</strong> {}<br>'
            '<strong>Username:</strong> {}<br>'
            '<strong>Email:</strong> {} {}<br>'
            '<strong>Celular:</strong> {} {}<br>'
            '<strong>Rol activo:</strong> <span style="background: #007bff; color: white; padding: 2px 8px; '
            'border-radius: 3px;">{}</span><br>'
            '<strong>Cuenta activa:</strong> {}<br>'
            '<strong>Fecha registro:</strong> {}<br>'
            '<strong>Último acceso:</strong> {}<br>'
            '</div>',

            user.id,
            user.get_full_name() or '—',
            user.username,
            user.email,
            email_sync,
            user.celular,
            telefono_sync,
            user.rol_activo.upper(),
            'Sí' if user.is_active else 'No',
            user.created_at.strftime('%d/%m/%Y %H:%M'),
            user.last_login.strftime('%d/%m/%Y %H:%M') if user.last_login else '—'
        )
    get_datos_usuario_completos.short_description = 'Detalles del Usuario'

    # ============================================
    # ACCIONES MASIVAS
    # ============================================
    def verificar_proveedores(self, request, queryset):
        updated_proveedores = 0
        for proveedor in queryset:
            if not proveedor.verificado:
                proveedor.verificado = True
                proveedor.save(update_fields=['verificado'])
                updated_proveedores += 1

        mensaje = f"{updated_proveedores} proveedores verificados"
        self.message_user(request, mensaje)
        logger.info(f"Admin {request.user.email}: {mensaje}")

    verificar_proveedores.short_description = "Verificar proveedores seleccionados"

    def desverificar_proveedores(self, request, queryset):
        updated_proveedores = queryset.update(verificado=False)
        mensaje = f"{updated_proveedores} proveedores desverificados"
        self.message_user(request, mensaje, level='warning')
        logger.warning(f"Admin {request.user.email}: {mensaje}")

    desverificar_proveedores.short_description = "Desverificar proveedores seleccionados"

    def activar_proveedores(self, request, queryset):
        updated = queryset.update(activo=True)
        self.message_user(request, f"{updated} proveedores activados")
        logger.info(f"Admin {request.user.email} activó {updated} proveedores")

    activar_proveedores.short_description = "Activar proveedores seleccionados"

    def desactivar_proveedores(self, request, queryset):
        updated = queryset.update(activo=False)
        self.message_user(request, f"{updated} proveedores desactivados", level='warning')
        logger.warning(f"Admin {request.user.email} desactivó {updated} proveedores")

    desactivar_proveedores.short_description = "Desactivar proveedores seleccionados"

    def sincronizar_con_usuarios(self, request, queryset):
        sincronizados = 0
        sin_usuario = 0

        for proveedor in queryset:
            if proveedor.user:
                cambios = False

                if proveedor.email != proveedor.user.email:
                    proveedor.email = proveedor.user.email
                    cambios = True

                if proveedor.telefono != proveedor.user.celular:
                    proveedor.telefono = proveedor.user.celular
                    cambios = True

                if cambios:
                    proveedor.save(update_fields=['email', 'telefono'])
                    sincronizados += 1
            else:
                sin_usuario += 1

        mensaje = f"{sincronizados} proveedores sincronizados"
        if sin_usuario > 0:
            mensaje += f" | {sin_usuario} sin usuario vinculado"

        self.message_user(request, mensaje)
        logger.info(f"Admin {request.user.email}: {mensaje}")

    sincronizar_con_usuarios.short_description = "Sincronizar datos con usuarios"

    def exportar_csv(self, request, queryset):
        import csv
        from django.http import HttpResponse
        from datetime import datetime

        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = f'attachment; filename="proveedores_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv"'

        response.write('\ufeff')

        writer = csv.writer(response)
        writer.writerow([
            'ID',
            'Nombre',
            'RUC',
            'Tipo',
            'Email Usuario',
            'Celular Usuario',
            'Nombre Usuario',
            'Ciudad',
            'Verificado',
            'Activo',
            'Comisión %',
            'Fecha Creación'
        ])

        for proveedor in queryset:
            writer.writerow([
                proveedor.id,
                proveedor.nombre,
                proveedor.ruc,
                proveedor.get_tipo_proveedor_display(),
                proveedor.user.email if proveedor.user else proveedor.email,
                proveedor.user.celular if proveedor.user else proveedor.telefono,
                proveedor.user.get_full_name() if proveedor.user else '—',
                proveedor.ciudad,
                'Sí' if proveedor.verificado else 'No',
                'Sí' if proveedor.activo else 'No',
                proveedor.comision_porcentaje,
                proveedor.created_at.strftime('%d/%m/%Y %H:%M')
            ])

        self.message_user(request, f"{queryset.count()} proveedores exportados a CSV")
        return response

    exportar_csv.short_description = "Exportar seleccionados a CSV"

    # ============================================
    # VALIDACIÓN EN SAVE
    # ============================================
    def save_model(self, request, obj, form, change):
        if change and obj.user:
            if obj.email != obj.user.email:
                self.message_user(
                    request,
                    f"Email desincronizado. User: {obj.user.email}, Proveedor: {obj.email}",
                    level='warning'
                )

            if obj.telefono != obj.user.celular:
                self.message_user(
                    request,
                    f"Teléfono desincronizado. User: {obj.user.celular}, Proveedor: {obj.telefono}",
                    level='warning'
                )

        super().save_model(request, obj, form, change)

        logger.info(
            f"Admin {request.user.email} {'editó' if change else 'creó'} "
            f"proveedor {obj.nombre} (ID: {obj.id})"
        )

    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('user')

    class Media:
        css = {
            'all': ('admin/css/proveedores_admin.css',)
        }
        js = ('admin/js/proveedores_admin.js',)