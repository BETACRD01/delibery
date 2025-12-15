import os
from pathlib import Path

from django.core.files import File
from django.core.management.base import BaseCommand
from django.db import transaction
from django.conf import settings

from super_categorias.models import CategoriaSuper


class Command(BaseCommand):
    help = "Crea/actualiza categorías iniciales para Súper (farmacia, envíos, super)."

    def handle(self, *args, **options):
        base_dir = Path(settings.BASE_DIR)
        seed_dir = base_dir / "super_categorias" / "seed_images"
        if not seed_dir.exists():
          # En algunos proyectos el comando se ejecuta desde la carpeta backend
          seed_dir = base_dir / "backend" / "super_categorias" / "seed_images"

        seeds = [
            {
                "id": "farmacia",
                "nombre": "Farmacia",
                "descripcion": "Medicamentos y salud",
                "icono": 0xE548,  # medical_services
                "color": "#4CAF50",
                "orden": 1,
                "filename": "farmacia.png",
            },
            {
                "id": "envios",
                "nombre": "Envíos / Entrega",
                "descripcion": "Mensajería y entregas",
                "icono": 0xE558,  # local_shipping
                "color": "#03A9F4",
                "orden": 2,
                "filename": "envios.png",
            },
            {
                "id": "super",
                "nombre": "Súper",
                "descripcion": "Supermercados y víveres",
                "icono": 0xE8CC,  # shopping_bag
                "color": "#FF9800",
                "orden": 3,
                "filename": "super.png",
            },
            {
                "id": "bebidas",
                "nombre": "Bebidas",
                "descripcion": "Bebidas y refrescos",
                "icono": 0xE540,  # local_bar
                "color": "#9C27B0",
                "orden": 4,
                "filename": "bebidas.png",
            },
        ]

        creadas = 0
        actualizadas = 0

        with transaction.atomic():
            for seed in seeds:
                obj, created = CategoriaSuper.objects.get_or_create(
                    id=seed["id"],
                    defaults={
                        "nombre": seed["nombre"],
                        "descripcion": seed["descripcion"],
                        "icono": seed["icono"],
                        "color": seed["color"],
                        "orden": seed["orden"],
                        "activo": True,
                    },
                )

                # Actualizar valores clave por si ya existía
                obj.nombre = seed["nombre"]
                obj.descripcion = seed["descripcion"]
                obj.icono = seed["icono"]
                obj.color = seed["color"]
                obj.orden = seed["orden"]
                obj.activo = True

                # Asignar imagen seed si no tiene
                filename = seed["filename"]
                img_path = seed_dir / filename
                if img_path.exists():
                    if not obj.imagen or not obj.imagen.name or not obj.imagen.storage.exists(obj.imagen.name):
                        with img_path.open("rb") as f:
                            obj.imagen.save(filename, File(f), save=False)

                obj.save()
                if created:
                    creadas += 1
                else:
                    actualizadas += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Seed de categorías Súper completado. Creadas: {creadas}, Actualizadas: {actualizadas}"
            )
        )
