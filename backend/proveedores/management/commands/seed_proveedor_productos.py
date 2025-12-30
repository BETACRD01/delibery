"""
seed_proveedor_productos.py - Script para agregar productos y banners a un proveedor específico
"""

from decimal import Decimal
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from django.contrib.auth import get_user_model
from proveedores.models import Proveedor
from productos.models import Categoria, Producto, Promocion

User = get_user_model()


class Command(BaseCommand):
    help = "Agrega productos y banners con promociones a un proveedor específico por email"

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            default='wd1501074@gmail.com',
            help='Email del proveedor',
        )

    def handle(self, *args, **options):
        email = options['email']
        
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"No existe usuario con email: {email}"))
            return
        
        try:
            proveedor = Proveedor.objects.get(user=user)
        except Proveedor.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"El usuario {email} no tiene proveedor asociado"))
            return

        self.stdout.write(self.style.SUCCESS(f"Proveedor encontrado: {proveedor.nombre}"))

        with transaction.atomic():
            # Obtener o crear categorías
            categorias = self.obtener_categorias()
            
            # Crear productos
            productos_creados = self.crear_productos(proveedor, categorias)
            
            # Crear banners/promociones con productos asociados
            self.crear_promociones_con_productos(proveedor, productos_creados)

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Completado para proveedor: {proveedor.nombre}\n"
            f"   - Productos creados: {len(productos_creados)}\n"
            f"   - Promociones del proveedor: {proveedor.promociones.count()}"
        ))

    def obtener_categorias(self):
        """Obtiene las categorías existentes"""
        categorias = {}
        for cat in Categoria.objects.all():
            categorias[cat.nombre] = cat
        return categorias

    def crear_productos(self, proveedor, categorias):
        """Crea productos variados para el proveedor"""
        self.stdout.write("Creando productos...")
        
        # Definir productos por categoría
        productos_data = [
            # Hamburguesas
            {
                "nombre": "Hamburguesa Clásica",
                "descripcion": "Deliciosa hamburguesa con carne de res 100% premium, lechuga, tomate, cebolla y nuestra salsa especial",
                "precio": Decimal("6.99"),
                "categoria": "Hamburguesas",
                "imagen_url": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400"
            },
            {
                "nombre": "Hamburguesa BBQ",
                "descripcion": "Hamburguesa con carne asada, tocino crocante, queso cheddar y salsa BBQ ahumada",
                "precio": Decimal("8.99"),
                "categoria": "Hamburguesas",
                "imagen_url": "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400"
            },
            {
                "nombre": "Hamburguesa Doble Queso",
                "descripcion": "Doble carne, doble queso americano, pepinillos y salsa especial",
                "precio": Decimal("10.99"),
                "categoria": "Hamburguesas",
                "imagen_url": "https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400"
            },
            {
                "nombre": "Hamburguesa Especial de la Casa",
                "descripcion": "Triple carne, queso suizo, champiñones salteados y salsa de la casa",
                "precio": Decimal("12.99"),
                "categoria": "Hamburguesas",
                "imagen_url": "https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400"
            },
            
            # Pizzas
            {
                "nombre": "Pizza Margarita",
                "descripcion": "Salsa de tomate, mozzarella fresca y hojas de albahaca",
                "precio": Decimal("9.99"),
                "categoria": "Pizzas",
                "imagen_url": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400"
            },
            {
                "nombre": "Pizza Pepperoni",
                "descripcion": "Abundante pepperoni sobre queso mozzarella derretido",
                "precio": Decimal("11.99"),
                "categoria": "Pizzas",
                "imagen_url": "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400"
            },
            {
                "nombre": "Pizza Hawaiana",
                "descripcion": "Jamón premium y piña dulce sobre base de mozzarella",
                "precio": Decimal("11.99"),
                "categoria": "Pizzas",
                "imagen_url": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400"
            },
            
            # Bebidas
            {
                "nombre": "Coca-Cola 500ml",
                "descripcion": "Refrescante Coca-Cola original en botella de 500ml",
                "precio": Decimal("1.50"),
                "categoria": "Bebidas",
                "imagen_url": "https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400"
            },
            {
                "nombre": "Sprite 500ml",
                "descripcion": "Sprite refrescante con limón-lima",
                "precio": Decimal("1.50"),
                "categoria": "Bebidas",
                "imagen_url": "https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400"
            },
            {
                "nombre": "Limonada Casera",
                "descripcion": "Limonada fresca hecha con limones naturales y un toque de menta",
                "precio": Decimal("2.99"),
                "categoria": "Bebidas",
                "imagen_url": "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400"
            },
            
            # Postres
            {
                "nombre": "Brownie con Helado",
                "descripcion": "Brownie de chocolate caliente con helado de vainilla y salsa de chocolate",
                "precio": Decimal("4.99"),
                "categoria": "Postres",
                "imagen_url": "https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400"
            },
            {
                "nombre": "Cheesecake de Fresa",
                "descripcion": "Cremoso cheesecake con coulis de fresa fresca",
                "precio": Decimal("5.99"),
                "categoria": "Postres",
                "imagen_url": "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=400"
            },
            
            # Pollo
            {
                "nombre": "Alitas BBQ (12 unidades)",
                "descripcion": "Crujientes alitas de pollo bañadas en salsa BBQ ahumada",
                "precio": Decimal("8.99"),
                "categoria": "Pollo",
                "imagen_url": "https://images.unsplash.com/photo-1608039755401-742074f0548d?w=400"
            },
            {
                "nombre": "Combo Pollo Frito",
                "descripcion": "3 piezas de pollo crujiente con papas fritas y ensalada",
                "precio": Decimal("7.99"),
                "categoria": "Pollo",
                "imagen_url": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400"
            },
            
            # Ensaladas
            {
                "nombre": "Ensalada César",
                "descripcion": "Lechuga romana, crutones, queso parmesano y aderezo César",
                "precio": Decimal("6.49"),
                "categoria": "Ensaladas",
                "imagen_url": "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400"
            },
        ]

        productos_creados = []
        for data in productos_data:
            categoria_nombre = data.pop("categoria")
            categoria = categorias.get(categoria_nombre)
            
            if not categoria:
                # Crear categoría si no existe
                categoria, _ = Categoria.objects.get_or_create(
                    nombre=categoria_nombre,
                    defaults={"activo": True}
                )
                categorias[categoria_nombre] = categoria
            
            producto, created = Producto.objects.get_or_create(
                proveedor=proveedor,
                nombre=data["nombre"],
                defaults={
                    "descripcion": data["descripcion"],
                    "precio": data["precio"],
                    "categoria": categoria,
                    "imagen_url": data["imagen_url"],
                    "disponible": True,
                }
            )
            
            if created:
                productos_creados.append(producto)
                self.stdout.write(f"  ✓ {producto.nombre}")
            else:
                productos_creados.append(producto)
                self.stdout.write(f"  ⊙ {producto.nombre} (ya existía)")
        
        return productos_creados

    def crear_promociones_con_productos(self, proveedor, productos):
        """Crea banners/promociones y asocia productos"""
        self.stdout.write("\nCreando promociones/banners...")
        
        ahora = timezone.now()
        fin_mes = ahora + timedelta(days=30)
        
        # Obtener productos por tipo para las promociones
        hamburguesas = [p for p in productos if "hamburguesa" in p.nombre.lower() or "burger" in p.nombre.lower()]
        pizzas = [p for p in productos if "pizza" in p.nombre.lower()]
        bebidas = [p for p in productos if p.categoria and p.categoria.nombre == "Bebidas"]
        postres = [p for p in productos if p.categoria and p.categoria.nombre == "Postres"]
        pollos = [p for p in productos if "pollo" in p.nombre.lower() or "alitas" in p.nombre.lower()]
        
        promociones_data = [
            {
                "titulo": "🍔 2x1 en Hamburguesas",
                "descripcion": "¡Compra una hamburguesa y llévate la segunda GRATIS! Válido todos los martes y jueves.",
                "tipo_promocion": "2x1",
                "valor_descuento": Decimal("50.00"),
                "descuento": "2x1",
                "color": "#FF5722",
                "imagen_url": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800",
                "productos": hamburguesas,
            },
            {
                "titulo": "🍕 30% OFF en Pizzas",
                "descripcion": "¡30% de descuento en todas nuestras pizzas! Promoción válida por tiempo limitado.",
                "tipo_promocion": "porcentaje",
                "valor_descuento": Decimal("30.00"),
                "descuento": "30% OFF",
                "color": "#E91E63",
                "imagen_url": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800",
                "productos": pizzas,
            },
            {
                "titulo": "🥤 Bebidas a mitad de precio",
                "descripcion": "Todas las bebidas al 50% de descuento con tu combo. ¡Refréscate por menos!",
                "tipo_promocion": "porcentaje",
                "valor_descuento": Decimal("50.00"),
                "descuento": "50% OFF",
                "color": "#00BCD4",
                "imagen_url": "https://images.unsplash.com/photo-1554866585-cd94860890b7?w=800",
                "productos": bebidas,
            },
            {
                "titulo": "🍰 Postre GRATIS",
                "descripcion": "¡Llévate un postre GRATIS con pedidos mayores a $15! Endulza tu día sin costo extra.",
                "tipo_promocion": "combo",
                "valor_descuento": None,
                "descuento": "GRATIS",
                "color": "#9C27B0",
                "imagen_url": "https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=800",
                "productos": postres,
            },
            {
                "titulo": "🍗 Combo Familiar de Pollo",
                "descripcion": "Combo para toda la familia: 12 piezas de pollo + papas + bebidas por solo $19.99",
                "tipo_promocion": "combo",
                "valor_descuento": Decimal("19.99"),
                "descuento": "$19.99",
                "color": "#FF9800",
                "imagen_url": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=800",
                "productos": pollos,
            },
            {
                "titulo": "🚚 Envío GRATIS",
                "descripcion": "¡Envío gratis en pedidos mayores a $10! Sin mínimo los fines de semana.",
                "tipo_promocion": "envio_gratis",
                "valor_descuento": None,
                "descuento": "ENVÍO GRATIS",
                "color": "#4CAF50",
                "imagen_url": "https://images.unsplash.com/photo-1526367790999-0150786686a2?w=800",
                "productos": productos[:5],  # Los primeros 5 productos
            },
        ]

        for data in promociones_data:
            productos_promo = data.pop("productos", [])
            
            promo, created = Promocion.objects.get_or_create(
                proveedor=proveedor,
                titulo=data["titulo"],
                defaults={
                    "descripcion": data["descripcion"],
                    "tipo_promocion": data["tipo_promocion"],
                    "valor_descuento": data["valor_descuento"],
                    "descuento": data["descuento"],
                    "color": data["color"],
                    "imagen_url": data["imagen_url"],
                    "fecha_inicio": ahora,
                    "fecha_fin": fin_mes,
                    "activa": True,
                }
            )
            
            # Asociar productos
            if productos_promo:
                promo.productos_asociados.set(productos_promo)
                promo.save()
            
            status = "✓" if created else "⊙"
            productos_count = len(productos_promo)
            self.stdout.write(f"  {status} {data['titulo']} ({productos_count} productos asociados)")
