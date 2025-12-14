# settings/celery.py

import os
import logging
from celery import Celery
from celery.signals import task_prerun, task_postrun, task_failure

# Configuración de logger específico para Celery
logger = logging.getLogger("celery")

# Establecer el módulo de configuración de Django por defecto
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings.settings')

app = Celery('settings')

# Cargar configuración desde el objeto settings de Django usando el namespace 'CELERY'
app.config_from_object('django.conf:settings', namespace='CELERY')

# Autodescubrir tareas en las apps instaladas
app.autodiscover_tasks()

# ==========================================================
# CONFIGURACIÓN DE RENDIMIENTO Y LÍMITES
# ==========================================================
app.conf.update(
    task_soft_time_limit=300,   # 5 minutos (Soft limit)
    task_time_limit=600,        # 10 minutos (Hard limit)
    task_default_retry_delay=60,
    task_max_retries=3,
    result_expires=86400,       # 24 horas
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,
    timezone='America/Guayaquil',
    enable_utc=True,
    accept_content=['json'],
    task_serializer='json',
    result_serializer='json',
)

# ==========================================================
# TAREA DE DIAGNÓSTICO
# ==========================================================
@app.task(bind=True, name='debug_task')
def debug_task(self):
    """Tarea de diagnóstico para verificar conectividad del broker."""
    logger.info(f'Debug task request: {self.request!r}')
    return {
        'status': 'ok',
        'worker_pid': os.getpid(),
        'task_id': self.request.id
    }

# ==========================================================
# MONITORIZACIÓN (SIGNALS)
# ==========================================================
@task_prerun.connect
def task_prerun_handler(task_id=None, task=None, **kwargs):
    logger.info(f'Iniciando tarea: {task.name} [{task_id}]')

@task_postrun.connect
def task_postrun_handler(task_id=None, task=None, **kwargs):
    logger.info(f'Tarea finalizada: {task.name} [{task_id}]')

@task_failure.connect
def task_failure_handler(task_id=None, exception=None, traceback=None, **kwargs):
    logger.error(f'Tarea fallida [{task_id}]: {exception}', exc_info=True)

if __name__ == '__main__':
    app.start()