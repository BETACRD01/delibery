# -*- coding: utf-8 -*-
# authentication/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class CustomUserAdmin(BaseUserAdmin):
    """
    Admin personalizado para gestionar usuarios normales
    Los roles se gestionan en otra app
    """

    list_display = [
        "email",
        "username",
        "full_name",
        "celular",
        "is_active",
        "cuenta_desactivada",
        "created_at",
    ]

    list_filter = [
        "is_active",
        "cuenta_desactivada",
        "terminos_aceptados",
        "notificaciones_email",
        "notificaciones_marketing",
        "created_at",
        "updated_at",
    ]

    search_fields = ["email", "username", "first_name", "last_name", "celular"]

    ordering = ["-created_at"]
    date_hierarchy = "created_at"

    # Campos de solo lectura
    readonly_fields = [
        "created_at",
        "updated_at",
        "last_login",
        "terminos_fecha_aceptacion",
        "terminos_ip_aceptacion",
        "fecha_desactivacion",
        "ultimo_login_ip",
        "intentos_login_fallidos",
        "cuenta_bloqueada_hasta",
        "reset_password_expire",
        "reset_password_attempts",
    ]

    fieldsets = (
        (None, {"fields": ("username", "password")}),
        (
            "Información Personal",
            {
                "fields": (
                    "first_name",
                    "last_name",
                    "email",
                    "celular",
                    "fecha_nacimiento",
                )
            },
        ),
        (
            "Permisos",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        (
            "Términos y Condiciones",
            {
                "fields": (
                    "terminos_aceptados",
                    "terminos_fecha_aceptacion",
                    "terminos_version_aceptada",
                    "terminos_ip_aceptacion",
                ),
                "classes": ("collapse",),
            },
        ),
        (
            "Preferencias de Notificaciones",
            {
                "fields": (
                    "notificaciones_email",
                    "notificaciones_marketing",
                    "notificaciones_push",
                ),
                "classes": ("collapse",),
            },
        ),
        (
            "Seguridad y Recuperación de Contraseña",
            {
                "fields": (
                    "intentos_login_fallidos",
                    "cuenta_bloqueada_hasta",
                    "ultimo_login_ip",
                    "reset_password_code",
                    "reset_password_expire",
                    "reset_password_attempts",
                ),
                "classes": ("collapse",),
            },
        ),
        (
            "Estado de Cuenta",
            {
                "fields": (
                    "cuenta_desactivada",
                    "fecha_desactivacion",
                    "razon_desactivacion",
                ),
                "classes": ("collapse",),
            },
        ),
        (
            "Auditoría",
            {
                "fields": ("created_at", "updated_at", "last_login"),
                "classes": ("collapse",),
            },
        ),
    )

    actions = [
        "activar_cuentas",
        "desactivar_cuentas",
        "resetear_intentos_login",
        "resetear_preferencias_notificaciones",
    ]

    # ==========================================
    # MÉTODOS PERSONALIZADOS PARA DISPLAY
    # ==========================================

    def full_name(self, obj):
        """Muestra el nombre completo del usuario"""
        full_name = obj.get_full_name()
        return full_name if full_name else "-"

    full_name.short_description = "Nombre Completo"

    # ==========================================
    # ACCIONES MASIVAS
    # ==========================================

    def activar_cuentas(self, request, queryset):
        """Activa cuentas de usuarios"""
        updated = queryset.update(is_active=True, cuenta_desactivada=False)
        self.message_user(request, f"{updated} cuentas activadas exitosamente")

    activar_cuentas.short_description = "✓ Activar cuentas seleccionadas"

    def desactivar_cuentas(self, request, queryset):
        """Desactiva cuentas de usuarios"""
        updated = queryset.update(is_active=False)
        self.message_user(request, f"✗ {updated} cuentas desactivadas")

    desactivar_cuentas.short_description = "✗ Desactivar cuentas seleccionadas"

    def resetear_intentos_login(self, request, queryset):
        """Resetea los intentos de login fallidos y desbloquea cuentas"""
        updated = queryset.update(
            intentos_login_fallidos=0, cuenta_bloqueada_hasta=None
        )
        self.message_user(request, f"{updated} cuentas desbloqueadas exitosamente")

    resetear_intentos_login.short_description = (
        " Resetear intentos de login y desbloquear"
    )

    def resetear_preferencias_notificaciones(self, request, queryset):
        """Activa todas las preferencias de notificación"""
        updated = queryset.update(
            notificaciones_email=True,
            notificaciones_marketing=True,
            notificaciones_push=True,
        )
        self.message_user(
            request, f"{updated} usuarios con notificaciones activadas"
        )

    resetear_preferencias_notificaciones.short_description = (
        " Activar todas las notificaciones"
    )

    # ==========================================
    # OPTIMIZACIÓN DE QUERYSET
    # ==========================================

    def get_queryset(self, request):
        """Optimiza las consultas"""
        qs = super().get_queryset(request)
        return qs.select_related()

    # ==========================================
    # PERMISOS
    # ==========================================

    def has_delete_permission(self, request, obj=None):
        """Solo superusuarios pueden eliminar usuarios"""
        return request.user.is_superuser

    def has_add_permission(self, request):
        """Solo superusuarios y staff pueden agregar usuarios"""
        return request.user.is_staff

    # ==========================================
    # MEDIA Y CSS PERSONALIZADO
    # ==========================================

    class Media:
        css = {"all": ("admin/css/custom_admin.css",)}
        js = ("admin/js/custom_admin.js",)