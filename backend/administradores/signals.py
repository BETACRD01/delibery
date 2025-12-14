# -*- coding: utf-8 -*-
# administradores/signals.py
"""
Manejadores de señales (Signals) para el módulo de administradores
Creación automática de perfiles para superusuarios/staff
Inicialización automática de configuración del sistema (Singleton)
Sincronización de permisos críticos
"""

import logging
from django.db.models.signals import post_save, post_migrate
from django.dispatch import receiver
from django.contrib.auth import get_user_model

from .models import Administrador, ConfiguracionSistema

# Usar get_user_model es más robusto que importar User directamente
User = get_user_model()

logger = logging.getLogger('administradores')


# ============================================
# SIGNAL: GESTIÓN DE PERFIL ADMINISTRADOR
# ============================================

@receiver(post_save, sender=User)
def gestionar_perfil_administrador(sender, instance, created, **kwargs):
    """
    Crea o actualiza el perfil de Administrador cuando se guarda un User.
    Garantiza que staff y superusuarios siempre tengan perfil asociado.
    """
    # 1. Si no es staff ni superusuario, no debe tener perfil administrativo.
    if not (instance.is_staff or instance.is_superuser):
        return

    # 2. Definir valores por defecto según el rol
    es_super = instance.is_superuser
    
    defaults = {
        'activo': True,
        'cargo': 'Super Administrador' if es_super else 'Administrador',
        'departamento': 'Tecnología' if es_super else 'Operaciones',
        # Permisos críticos
        'puede_configurar_sistema': es_super,
        'puede_gestionar_solicitudes': True,
        'puede_gestionar_usuarios': True,
        'puede_ver_reportes': True
    }

    # 3. Crear o recuperar el perfil
    try:
        perfil, nuevo = Administrador.objects.get_or_create(
            user=instance,
            defaults=defaults
        )

        if nuevo:
            logger.info(f"Perfil de administrador creado para: {instance.email}")
        
        # 4. Caso especial: Si un usuario existente se promueve a Superusuario
        elif es_super and not perfil.puede_configurar_sistema:
            perfil.puede_configurar_sistema = True
            perfil.cargo = 'Super Administrador'
            perfil.save(update_fields=['puede_configurar_sistema', 'cargo'])
            logger.info(f"Permisos de superusuario otorgados a: {instance.email}")

    except Exception as e:
        logger.error(f"Error gestionando perfil de admin para {instance.email}: {e}")


# ============================================
# SIGNAL: INICIALIZACIÓN DE CONFIGURACIÓN
# ============================================

@receiver(post_migrate)
def inicializar_configuracion_sistema(sender, **kwargs):
    """
    Se ejecuta tras las migraciones.
    Garantiza que exista la Configuración del Sistema (ID 1).
    """
    if sender.name != 'administradores':
        return

    try:
        # Obtener un Administrador (no User) para el campo modificado_por
        administrador = Administrador.objects.filter(
            user__is_superuser=True,
            activo=True
        ).first()

        defaults = {
            'comision_app_proveedor': 10.00,
            'comision_app_directo': 15.00,
            'comision_repartidor_proveedor': 25.00,
            'comision_repartidor_directo': 85.00,
            'pedidos_minimos_rifa': 3,
            'pedido_maximo': 1000.00,
            'pedido_minimo': 5.00,
            'tiempo_maximo_entrega': 60,
            'mantenimiento': False,
        }
        
        # Solo agregar modificado_por si existe un administrador
        if administrador:
            defaults['modificado_por'] = administrador

        obj, created = ConfiguracionSistema.objects.get_or_create(
            pk=1,
            defaults=defaults
        )

        if created:
            logger.info("Configuración inicial del sistema creada exitosamente")
        
    except Exception as e:
        logger.critical(f"Error crítico inicializando configuración del sistema: {e}")