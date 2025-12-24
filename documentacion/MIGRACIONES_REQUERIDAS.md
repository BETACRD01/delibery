# Migraciones de Base de Datos Requeridas

Este documento lista las migraciones que deben ejecutarse después de las mejoras implementadas.

## Cambios en los Modelos

### 1. Modelo `Promocion` (productos/models.py)
Se agregaron los siguientes campos:
- `tipo_promocion`: CharField con choices para diferentes tipos de promociones
- `valor_descuento`: DecimalField para almacenar el valor numérico del descuento

### 2. Modelo `Producto` (productos/models.py)
Se agregó el siguiente campo:
- `productos_relacionados`: ManyToManyField para productos relacionados

## Comandos para Ejecutar

```bash
# 1. Crear las migraciones
python manage.py makemigrations productos

# 2. Aplicar las migraciones
python manage.py migrate productos

# 3. Opcional: Crear datos de prueba para promociones
python manage.py shell
```

### Script para Actualizar Promociones Existentes

```python
from productos.models import Promocion

# Actualizar todas las promociones existentes al tipo por defecto si no tienen tipo
Promocion.objects.filter(tipo_promocion__isnull=True).update(tipo_promocion='porcentaje')

# O actualizar manualmente cada promoción según corresponda
for promo in Promocion.objects.all():
    # Analizar el campo 'descuento' y asignar tipo correspondiente
    if '2x1' in promo.descuento.lower() or '2 x 1' in promo.descuento.lower():
        promo.tipo_promocion = '2x1'
    elif '3x2' in promo.descuento.lower() or '3 x 2' in promo.descuento.lower():
        promo.tipo_promocion = '3x2'
    elif '%' in promo.descuento:
        promo.tipo_promocion = 'porcentaje'
        # Intentar extraer el porcentaje del texto
        import re
        match = re.search(r'(\d+)\s*%', promo.descuento)
        if match:
            promo.valor_descuento = float(match.group(1))
    elif 'combo' in promo.descuento.lower():
        promo.tipo_promocion = 'combo'
    elif 'envío' in promo.descuento.lower() or 'gratis' in promo.descuento.lower():
        promo.tipo_promocion = 'envio_gratis'
    else:
        promo.tipo_promocion = 'otro'

    promo.save()
```

## Verificación

Después de ejecutar las migraciones, verifica que:

1. Las tablas se hayan creado correctamente:
```sql
-- Verificar nueva tabla many-to-many
SELECT * FROM productos_producto_productos_relacionados LIMIT 5;

-- Verificar nuevos campos en promociones
DESCRIBE promociones;
```

2. Las promociones existentes tengan valores por defecto:
```python
from productos.models import Promocion
Promocion.objects.values('id', 'tipo_promocion', 'valor_descuento')[:5]
```

## Notas Importantes

- El campo `productos_relacionados` es opcional (blank=True) y no afectará productos existentes
- El campo `tipo_promocion` tiene un valor por defecto ('porcentaje')
- El campo `valor_descuento` es opcional (null=True, blank=True)
- Todos los serializers ya están actualizados para incluir estos nuevos campos
