"""
==========================================
ARCHIVO: backend/utils/network_detector.py
==========================================
Detector automático de red para Django Backend.
Optimizado para rendimiento, cero dependencias externas y escalabilidad.
"""

import socket
import logging
import os
from functools import lru_cache
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)

class NetworkDetector:
    """
    Detector inteligente de configuración de red.
    Utiliza caché y métodos no bloqueantes para determinar el entorno.
    """
    
    RED_POR_DEFECTO = 'CASA'
    
    # Constantes de configuración por defecto (Fallbacks)
    DEFAULT_CONFIG = {
        'CASA': {'prefix': '192.168.1', 'ip': '192.168.1.5', 'desc': 'Red domestica WiFi'},
        'INSTITUCIONAL': {'prefix': '172.16', 'ip': '172.16.60.5', 'desc': 'Red institucional'},
        'HOTSPOT': {'prefix': '192.168.137', 'ip': '192.168.137.1', 'desc': 'Hotspot movil'},
        'DOCKER': {'prefix': '172.17', 'ip': '0.0.0.0', 'desc': 'Red Docker'}
    }

    @classmethod
    @lru_cache(maxsize=1)
    def _cargar_config_desde_env(cls) -> Dict[str, Dict[str, str]]:
        """
        Carga la configuración de redes desde variables de entorno.
        Memoriza el resultado para evitar lecturas repetitivas (Cache).
        """
        return {
            'CASA': {
                'prefijo': os.getenv('RED_CASA_PREFIX', cls.DEFAULT_CONFIG['CASA']['prefix']),
                'ip_servidor': os.getenv('RED_CASA_IP', cls.DEFAULT_CONFIG['CASA']['ip']),
                'descripcion': cls.DEFAULT_CONFIG['CASA']['desc']
            },
            'INSTITUCIONAL': {
                'prefijo': os.getenv('RED_INSTITUCIONAL_PREFIX', cls.DEFAULT_CONFIG['INSTITUCIONAL']['prefix']),
                'ip_servidor': os.getenv('RED_INSTITUCIONAL_IP', cls.DEFAULT_CONFIG['INSTITUCIONAL']['ip']),
                'descripcion': cls.DEFAULT_CONFIG['INSTITUCIONAL']['desc']
            },
            'HOTSPOT': {
                'prefijo': os.getenv('RED_HOTSPOT_PREFIX', cls.DEFAULT_CONFIG['HOTSPOT']['prefix']),
                'ip_servidor': os.getenv('RED_HOTSPOT_IP', cls.DEFAULT_CONFIG['HOTSPOT']['ip']),
                'descripcion': cls.DEFAULT_CONFIG['HOTSPOT']['desc']
            },
            'DOCKER': {
                'prefijo': cls.DEFAULT_CONFIG['DOCKER']['prefix'],
                'ip_servidor': cls.DEFAULT_CONFIG['DOCKER']['ip'],
                'descripcion': cls.DEFAULT_CONFIG['DOCKER']['desc']
            }
        }

    @staticmethod
    def _es_entorno_docker() -> bool:
        """Verifica si se está ejecutando dentro de un contenedor Docker."""
        # Verificación 1: Archivo .dockerenv
        if os.path.exists('/.dockerenv'):
            return True
        # Verificación 2: Grupos de control (cgroups)
        try:
            with open('/proc/1/cgroup', 'rt') as f:
                return 'docker' in f.read()
        except Exception:
            return False

    @classmethod
    def obtener_ip_local(cls) -> Optional[str]:
        """
        Obtiene la IP local del servidor de la interfaz principal.
        Usa una conexión UDP sin envío de datos (no requiere internet).
        """
        # Verificación de modo manual
        if os.getenv('CONNECTION_MODE', 'AUTO').upper() == 'MANUAL':
            manual_ip = os.getenv('MANUAL_SERVER_IP')
            if manual_ip:
                return manual_ip

        # Método Optimizado: UDP a IP privada (no genera tráfico real, solo consulta tabla de ruteo)
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            # Conectamos a una IP que no necesita ser alcanzable realmente
            s.connect(("10.255.255.255", 1))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            # Fallback: Hostname
            try:
                return socket.gethostbyname(socket.gethostname())
            except Exception:
                return '127.0.0.1'

    @classmethod
    def detectar_red(cls) -> Dict[str, Any]:
        """
        Detecta automáticamente la red actual y retorna la configuración.
        """
        # 1. Verificar si detección está habilitada
        if os.getenv('ENABLE_NETWORK_DETECTION', 'True').lower() != 'true':
            redes = cls._cargar_config_desde_env()
            config = redes[cls.RED_POR_DEFECTO]
            return cls._construir_respuesta(cls.RED_POR_DEFECTO, config, valida=False, modo='STATIC')

        # 2. Verificar Modo Docker explícito o implícito
        if os.getenv('CONNECTION_MODE', 'AUTO').upper() == 'DOCKER' or cls._es_entorno_docker():
            return {
                'nombre': 'DOCKER',
                'ip_local': '0.0.0.0',
                'ip_servidor': '0.0.0.0',
                'prefijo': '172.17',
                'valida': True,
                'descripcion': 'Entorno Docker Contenerizado',
                'modo': 'DOCKER'
            }

        # 3. Detección por IP
        ip_local = cls.obtener_ip_local()
        redes = cls._cargar_config_desde_env()

        for nombre_red, config in redes.items():
            if ip_local.startswith(config['prefijo']):
                # Sobrescribimos la IP local detectada sobre la configuración
                return {
                    'nombre': nombre_red,
                    'ip_local': ip_local,
                    'ip_servidor': config['ip_servidor'],
                    'prefijo': config['prefijo'],
                    'valida': True,
                    'descripcion': config['descripcion'],
                    'modo': 'AUTO'
                }

        # 4. Red Desconocida
        prefijo = '.'.join(ip_local.split('.')[:3])
        return {
            'nombre': 'DESCONOCIDA',
            'ip_local': ip_local,
            'ip_servidor': ip_local, # En desconocida, usamos la IP local como servidor
            'prefijo': prefijo,
            'valida': True,
            'descripcion': 'Red no identificada en configuracion',
            'modo': 'AUTO'
        }

    @staticmethod
    def _construir_respuesta(nombre: str, config: dict, valida: bool, modo: str) -> dict:
        """Helper para estandarizar respuestas."""
        return {
            'nombre': nombre,
            'ip_local': '127.0.0.1',
            'ip_servidor': config['ip_servidor'],
            'prefijo': config['prefijo'],
            'valida': valida,
            'descripcion': config['descripcion'],
            'modo': modo
        }

    @classmethod
    def obtener_allowed_hosts(cls, config_red: dict) -> List[str]:
        """Genera lista de ALLOWED_HOSTS evitando duplicados."""
        hosts = {
            'localhost', '127.0.0.1', '0.0.0.0', 'backend',
            config_red['ip_local'], config_red['ip_servidor']
        }
        
        # Agregar IPs de config
        redes = cls._cargar_config_desde_env()
        hosts.update(c['ip_servidor'] for c in redes.values())
        
        # Agregar extras del env
        env_hosts = os.getenv('ALLOWED_HOSTS')
        if env_hosts:
            hosts.update(h.strip() for h in env_hosts.split(',') if h.strip())
            
        return list(hosts)

    @classmethod
    def obtener_cors_origins(cls, config_red: dict, puerto: int = 8000) -> List[str]:
        """Genera lista de CORS_TRUSTED_ORIGINS."""
        origins = {
            f'http://localhost:{puerto}',
            f'http://127.0.0.1:{puerto}'
        }

        # IPs de servidor detectado
        if config_red['ip_servidor'] not in ('0.0.0.0', 'backend'):
            origins.add(f"http://{config_red['ip_servidor']}:{puerto}")

        # IPs de configuración conocida
        redes = cls._cargar_config_desde_env()
        for config in redes.values():
            if config['ip_servidor'] not in ('0.0.0.0', 'backend'):
                origins.add(f"http://{config['ip_servidor']}:{puerto}")

        # Extras del env
        extra_origins = os.getenv('CSRF_TRUSTED_ORIGINS_EXTRA')
        if extra_origins:
            origins.update(o.strip() for o in extra_origins.split(',') if o.strip())

        return list(origins)

    @classmethod
    def obtener_frontend_url(cls, config_red: dict, puerto: int = 8000) -> str:
        """Calcula la URL del frontend."""
        env_url = os.getenv('FRONTEND_URL')
        if env_url:
            return env_url
        
        ip = 'localhost' if config_red['ip_servidor'] == '0.0.0.0' else config_red['ip_servidor']
        return f"http://{ip}:{puerto}"

    @classmethod
    def imprimir_info(cls, config_red: dict):
        """Muestra resumen de red en consola (útil para logs de inicio)."""
        lines = [
            "=" * 70,
            "DELIBER - DETECCION AUTOMATICA DE RED (OPTIMIZADO)",
            "=" * 70,
            f"Red detectada:     {config_red['nombre']}",
            f"Descripcion:       {config_red['descripcion']}",
            f"Modo:              {config_red.get('modo', 'AUTO')}",
            f"IP Local:          {config_red['ip_local']}",
            f"IP Escucha:        {config_red['ip_servidor']}",
            f"Prefijo:           {config_red['prefijo']}.*",
            "-" * 70,
            f"Puerto Backend:    {os.getenv('BACKEND_PORT', '8000')}",
            "=" * 70
        ]
        print("\n".join(lines) + "\n")

# ==========================================
# GESTION DE INSTANCIA (Lazy Loading)
# ==========================================
_config_red_global: Optional[Dict[str, Any]] = None

def obtener_config_red() -> Dict[str, Any]:
    """Obtiene la configuración de red (Singleton)."""
    global _config_red_global
    if _config_red_global is None:
        _config_red_global = NetworkDetector.detectar_red()
        NetworkDetector.imprimir_info(_config_red_global)
    return _config_red_global

def refrescar_config_red() -> Dict[str, Any]:
    """Fuerza re-detección y limpia caché de configuración."""
    global _config_red_global
    logger.info("Refrescando deteccion de red...")
    NetworkDetector._cargar_config_desde_env.cache_clear()
    _config_red_global = NetworkDetector.detectar_red()
    NetworkDetector.imprimir_info(_config_red_global)
    return _config_red_global