
import os
from django.core.management.base import BaseCommand
from django.core.files import File
from proveedores.models import Proveedor

class Command(BaseCommand):
    help = 'Asigna logos reales generados por IA a los proveedores según su categoría'

    def handle(self, *args, **options):
        # Mapeo de rutas de imágenes generadas
        LOGOS = {
            'pizza': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_pizza_1767131991464.png',
            'burger': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_burger_1767132005254.png',
            'chicken': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_chicken_1767132020113.png',
            'asian': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_asian_1767132032172.png',
            'coffee': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_coffee_1767132043805.png',
            'taco': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_taco_1767132056667.png',
            'generic': '/Users/willian/.gemini/antigravity/brain/986c86b6-d1e9-470c-91e7-489f63876e86/logo_generic_1767132068462.png',
        }

        # Palabras clave para asignar categoría
        KEYWORDS = {
            'pizza': ['pizza', 'domino', 'papa', 'caesar', 'hut', 'italiana'],
            'burger': ['burger', 'hamburguesa', 'mcdonald', 'wendy', 'carl', 'five guys', 'king'],
            'chicken': ['chicken', 'pollo', 'kfc', 'popeye', 'church', 'wings', 'alitas'],
            'asian': ['sushi', 'asian', 'china', 'japonesa', 'tokyo', 'panda', 'nippon', 'sakura'],
            'coffee': ['coffee', 'cafe', 'café', 'starbucks', 'dunkin', 'crepe', 'juan valdez', 'sweet', 'bakery', 'pasteleria'],
            'taco': ['taco', 'mexic', 'azteca', 'chipotle', 'burrito'],
        }

        count = 0
        proveedores = Proveedor.objects.all()
        
        self.stdout.write(f"Procesando {proveedores.count()} proveedores...")

        for p in proveedores:
            nombre = p.nombre.lower()
            categoria_asignada = 'generic'
            
            # Buscar coincidencia
            for cat, words in KEYWORDS.items():
                if any(w in nombre for w in words):
                    categoria_asignada = cat
                    break
            
            ruta_imagen = LOGOS.get(categoria_asignada)
            if not ruta_imagen or not os.path.exists(ruta_imagen):
                self.stdout.write(self.style.WARNING(f"Imagen no encontrada para {p.nombre} ({categoria_asignada})"))
                continue

            try:
                # Abrir y asignar imagen
                with open(ruta_imagen, 'rb') as f:
                    # Usar nombre de archivo único para evitar colisiones excesivas si es necesario, 
                    # pero Django maneja esto. Usaremos 'logo_CAT_ID.png'
                    filename = f"logo_{categoria_asignada}_{p.id}.png"
                    p.logo.save(filename, File(f), save=True)
                    count += 1
                    self.stdout.write(self.style.SUCCESS(f"Asignado logo '{categoria_asignada}' a: {p.nombre}"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error asignando a {p.nombre}: {e}"))

        self.stdout.write(self.style.SUCCESS(f"¡Proceso completado! {count} logos actualizados."))
