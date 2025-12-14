# 🚀 INSTRUCCIONES PARA ACTIVAR EL SISTEMA SUPER

## ⚠️ IMPORTANTE
Las categorías NO existen en la base de datos todavía. Por eso ves el error cuando haces clic en una categoría.

## 📋 PASOS PARA CONFIGURAR

### 1️⃣ Abre una terminal en la carpeta backend:
```bash
cd /home/willian/Escritorio/Deliber_1.0/backend
```

### 2️⃣ Activa el entorno virtual:
```bash
source .venv/bin/activate
```

Deberías ver `(.venv)` al inicio de tu línea de comando.

### 3️⃣ Aplica las migraciones:
```bash
python manage.py migrate super_categorias
```

### 4️⃣ Ejecuta el script de creación de categorías:
```bash
python crear_categorias_super.py
```

O si prefieres, crea las categorías manualmente con Django shell:
```bash
python manage.py shell
```

Y luego copia y pega este código:
```python
from super_categorias.models import CategoriaSuper

categorias = [
    {'id': 'supermercados', 'nombre': 'Supermercados', 'descripcion': 'Encuentra los mejores supermercados', 'icono': 57534, 'color': '#FF9800', 'destacado': False},
    {'id': 'farmacias', 'nombre': 'Farmacias', 'descripcion': 'Encuentra las mejores farmacias', 'icono': 58820, 'color': '#E91E63', 'destacado': False},
    {'id': 'bebidas', 'nombre': 'Bebidas', 'descripcion': 'Encuentra las mejores bebidas', 'icono': 57495, 'color': '#00BCD4', 'destacado': False},
    {'id': 'mensajeria', 'nombre': 'Mensajería', 'descripcion': 'Envíos rápidos y seguros', 'icono': 57696, 'color': '#9C27B0', 'destacado': True},
    {'id': 'tiendas', 'nombre': 'Tiendas', 'descripcion': 'Encuentra las mejores tiendas', 'icono': 57491, 'color': '#4CAF50', 'destacado': False},
]

for cat_data in categorias:
    categoria, created = CategoriaSuper.objects.update_or_create(
        id=cat_data['id'],
        defaults={
            'nombre': cat_data['nombre'],
            'descripcion': cat_data['descripcion'],
            'icono': cat_data['icono'],
            'color': cat_data['color'],
            'activo': True,
            'destacado': cat_data['destacado'],
            'orden': 0,
        }
    )
    print(f"{'✅ Creada' if created else '🔄 Actualizada'}: {categoria.nombre}")

print(f"\n✅ Total de categorías: {CategoriaSuper.objects.count()}")
```

Luego sal del shell con:
```python
exit()
```

### 5️⃣ Verifica que las categorías se crearon:
```bash
python manage.py shell
```

```python
from super_categorias.models import CategoriaSuper
for cat in CategoriaSuper.objects.all():
    print(f"{cat.nombre} ({cat.id})")
exit()
```

### 6️⃣ Reinicia el servidor Django:
Si tienes el servidor corriendo, detenlo (Ctrl+C) y vuelve a iniciarlo:
```bash
python manage.py runserver 0.0.0.0:8000
```

### 7️⃣ En Flutter, haz hot reload:
En la terminal de Flutter, presiona `r` para recargar.

### 8️⃣ Prueba la app:
- Ve a la pestaña "Super"
- Haz clic en cualquier categoría
- Debería mostrar "No hay proveedores disponibles" (esto es normal, aún no hay proveedores)

---

## 🔍 VERIFICAR QUE FUNCIONA

### Prueba directa con curl:
```bash
curl http://10.0.2.2:8000/api/super/categorias/
```

O si estás en la misma máquina:
```bash
curl http://localhost:8000/api/super/categorias/
```

Deberías ver un JSON con las 5 categorías.

---

## 📝 SIGUIENTE PASO (OPCIONAL)

Una vez que las categorías funcionen, puedes agregar proveedores de prueba:

```bash
python manage.py shell
```

```python
from super_categorias.models import CategoriaSuper, ProveedorSuper

# Obtener categoría de mensajería
mensajeria = CategoriaSuper.objects.get(id='mensajeria')

# Crear proveedor de prueba
ProveedorSuper.objects.create(
    categoria=mensajeria,
    nombre='DHL Express',
    descripcion='Envíos rápidos y seguros',
    direccion='Calle Principal 123',
    telefono='123456789',
    email='dhl@example.com',
    horario_apertura='08:00',
    horario_cierre='18:00',
    activo=True,
    verificado=True,
    calificacion=4.5,
)

print("✅ Proveedor de prueba creado")
exit()
```

---

## ❓ SI HAY PROBLEMAS

### Error: "no module named django"
```bash
# Asegúrate de activar el entorno virtual:
source .venv/bin/activate
```

### Error: "no such table: super_categorias_categoriasuper"
```bash
# Aplica las migraciones:
python manage.py migrate super_categorias
```

### Las categorías no aparecen en la app
1. Verifica que el servidor Django esté corriendo
2. Verifica la URL con curl
3. Haz hot reload en Flutter
4. Revisa los logs de Flutter

---

## ✅ CUANDO TERMINES

Deberías poder:
- ✅ Ver las 5 categorías en la pestaña "Super"
- ✅ Hacer clic en cualquier categoría
- ✅ Ver "No hay proveedores disponibles" (normal si aún no agregaste proveedores)
- ✅ El error "FormatException: Invalid port" ya NO debería aparecer

---

**¿Necesitas ayuda?** Ejecuta estos comandos y muéstrame la salida.
