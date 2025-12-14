# prueba_vinculos.py
import os
import django

# --- CORRECCIÓN AQUÍ ---
# Usamos el nombre que encontramos con grep
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings.settings')
django.setup()

from pedidos.models import Pedido
from usuarios.models import Perfil
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from django.contrib.auth import get_user_model

def probar():
    User = get_user_model()
    
    # 1. Obtener un Cliente
    # Usamos filter().first() para evitar errores si la tabla está vacía
    usuario = User.objects.first()
    
    if not usuario:
        # Si no hay usuarios, intentamos crear uno temporal o avisamos
        print("❌ ERROR: No hay usuarios registrados en la base de datos.")
        print("   -> Crea un superusuario primero con: python manage.py createsuperuser")
        return

    # Crear o obtener perfil
    try:
        perfil_cliente, _ = Perfil.objects.get_or_create(user=usuario)
    except Exception as e:
        print(f"❌ Error con el perfil del usuario {usuario.email}: {e}")
        return

    # 2. Obtener o Crear un Proveedor
    proveedor, _ = Proveedor.objects.get_or_create(
        nombre="Pizza Test", 
        defaults={"direccion": "Calle 123", "telefono": "0999999999", "activo": True, "verificado": True}
    )
    print("✅ Proveedor listo.")

    # 3. Crear el Pedido
    try:
        nuevo_pedido = Pedido.objects.create(
            cliente=perfil_cliente,
            proveedor=proveedor,
            total=15.50,
            direccion_entrega="Mi Casa",
            descripcion="Pedido de prueba script",
            tipo='proveedor' # Aseguramos un tipo válido
        )
        print(f"✅ PEDIDO CREADO: {nuevo_pedido.numero_pedido} (ID: {nuevo_pedido.id})")
    except Exception as e:
        print(f"❌ Error creando pedido: {e}")
        return

    # 4. Verificar Vínculo con Proveedor
    if nuevo_pedido.proveedor:
        print(f"✅ VÍNCULO PROVEEDOR EXITOSO: {nuevo_pedido.proveedor.nombre}")
    else:
        print("❌ ERROR: No se vinculó el proveedor.")

    # 5. Asignar Repartidor
    repartidor = Repartidor.objects.first()
    if repartidor:
        nuevo_pedido.repartidor = repartidor
        nuevo_pedido.save()
        print(f"✅ VÍNCULO REPARTIDOR EXITOSO: {nuevo_pedido.repartidor.user.email}")
    else:
        print("⚠️ AVISO: No hay repartidores creados en el sistema para probar la asignación.")

if __name__ == "__main__":
    probar()