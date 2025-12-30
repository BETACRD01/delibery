"""
asociar_productos_banners.py - Asocia productos a TODOS los banners existentes
"""

from django.core.management.base import BaseCommand
from django.db import transaction

from productos.models import Producto, Promocion


class Command(BaseCommand):
    help = "Asocia hasta 4 productos de cada proveedor a sus banners/promociones"

    def handle(self, *args, **options):
        with transaction.atomic():
            # Obtener todas las promociones
            promociones = Promocion.objects.filter(activa=True)
            
            total_actualizadas = 0
            
            for promo in promociones:
                # Si ya tiene productos asociados, saltar
                if promo.productos_asociados.exists():
                    self.stdout.write(f"⊙ {promo.titulo} ya tiene {promo.productos_asociados.count()} productos")
                    continue
                
                # Obtener productos del proveedor de la promoción
                if promo.proveedor:
                    productos = Producto.objects.filter(
                        proveedor=promo.proveedor,
                        disponible=True
                    ).order_by('?')[:4]  # Hasta 4 productos aleatorios
                else:
                    # Si no tiene proveedor, tomar productos aleatorios del sistema
                    productos = Producto.objects.filter(
                        disponible=True
                    ).order_by('?')[:4]
                
                if productos.exists():
                    promo.productos_asociados.set(productos)
                    promo.save()
                    total_actualizadas += 1
                    productos_nombres = ", ".join([p.nombre for p in productos])
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"✓ {promo.titulo} -> {productos.count()} productos: {productos_nombres[:60]}..."
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f"⚠ {promo.titulo} - No hay productos disponibles")
                    )

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Proceso completado: {total_actualizadas} promociones actualizadas"
        ))
