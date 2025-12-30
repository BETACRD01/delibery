"""
seed_proveedores.py - Script para generar datos de prueba
Crea ~40 proveedores con productos, categorías y promociones
"""

import random
from datetime import time, timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from proveedores.models import Proveedor
from productos.models import Categoria, Producto, Promocion


class Command(BaseCommand):
    help = "Genera datos de prueba: 40 proveedores, 400 productos, categorías y promociones"

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Elimina datos existentes antes de crear nuevos',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING("Eliminando datos existentes..."))
            Promocion.objects.all().delete()
            Producto.objects.all().delete()
            Proveedor.objects.filter(user__isnull=True).delete()
            Categoria.objects.all().delete()

        with transaction.atomic():
            categorias = self.crear_categorias()
            proveedores = self.crear_proveedores()
            self.crear_productos(proveedores, categorias)
            self.crear_promociones(proveedores)

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Seed completado:\n"
            f"   - Categorías: {Categoria.objects.count()}\n"
            f"   - Proveedores: {Proveedor.objects.count()}\n"
            f"   - Productos: {Producto.objects.count()}\n"
            f"   - Promociones: {Promocion.objects.count()}"
        ))

    def crear_categorias(self):
        """Crea las categorías de productos"""
        self.stdout.write("Creando categorías...")
        
        categorias_data = [
            {"nombre": "Pizzas", "imagen_url": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400"},
            {"nombre": "Hamburguesas", "imagen_url": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400"},
            {"nombre": "Pollo", "imagen_url": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400"},
            {"nombre": "Sushi", "imagen_url": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400"},
            {"nombre": "Comida Mexicana", "imagen_url": "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400"},
            {"nombre": "Postres", "imagen_url": "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400"},
            {"nombre": "Bebidas", "imagen_url": "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400"},
            {"nombre": "Cafetería", "imagen_url": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400"},
            {"nombre": "Ensaladas", "imagen_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400"},
            {"nombre": "Farmacia", "imagen_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400"},
        ]

        categorias = {}
        for data in categorias_data:
            cat, _ = Categoria.objects.get_or_create(
                nombre=data["nombre"],
                defaults={"imagen_url": data["imagen_url"], "activo": True}
            )
            categorias[data["nombre"]] = cat
        
        return categorias

    def crear_proveedores(self):
        """Crea los 40 proveedores"""
        self.stdout.write("Creando proveedores...")
        
        proveedores_data = [
            # Restaurantes de Pizza
            {"nombre": "Pizza Hut", "tipo": "restaurante", "desc": "Las mejores pizzas con ingredientes premium", "cats": ["Pizzas"]},
            {"nombre": "Domino's Pizza", "tipo": "restaurante", "desc": "Pizza caliente en 30 minutos o menos", "cats": ["Pizzas"]},
            {"nombre": "Papa John's", "tipo": "restaurante", "desc": "Mejores ingredientes, mejor pizza", "cats": ["Pizzas"]},
            {"nombre": "Little Caesars", "tipo": "restaurante", "desc": "Pizza! Pizza! Hot-N-Ready", "cats": ["Pizzas"]},
            
            # Hamburguesas
            {"nombre": "McDonald's", "tipo": "restaurante", "desc": "Me encanta! Hamburguesas y más", "cats": ["Hamburguesas", "Bebidas"]},
            {"nombre": "Burger King", "tipo": "restaurante", "desc": "A la parrilla sabe mejor", "cats": ["Hamburguesas", "Bebidas"]},
            {"nombre": "Wendy's", "tipo": "restaurante", "desc": "Carne fresca nunca congelada", "cats": ["Hamburguesas"]},
            {"nombre": "Carl's Jr.", "tipo": "restaurante", "desc": "Hamburguesas premium estilo western", "cats": ["Hamburguesas"]},
            {"nombre": "Five Guys", "tipo": "restaurante", "desc": "Burgers and Fries hechos a tu gusto", "cats": ["Hamburguesas"]},
            
            # Pollo
            {"nombre": "KFC", "tipo": "restaurante", "desc": "Para chuparse los dedos", "cats": ["Pollo"]},
            {"nombre": "Popeyes", "tipo": "restaurante", "desc": "Louisiana Kitchen - Pollo cajún", "cats": ["Pollo"]},
            {"nombre": "Pollos Gus", "tipo": "restaurante", "desc": "El mejor pollo asado ecuatoriano", "cats": ["Pollo"]},
            {"nombre": "Church's Chicken", "tipo": "restaurante", "desc": "Pollo crujiente y delicioso", "cats": ["Pollo"]},
            
            # Comida Mexicana
            {"nombre": "Taco Bell", "tipo": "restaurante", "desc": "Live Más - Auténtico sabor mexicano", "cats": ["Comida Mexicana"]},
            {"nombre": "Chipotle", "tipo": "restaurante", "desc": "Burritos y bowls frescos", "cats": ["Comida Mexicana"]},
            {"nombre": "Los Tacos del Chef", "tipo": "restaurante", "desc": "Tacos artesanales mexicanos", "cats": ["Comida Mexicana"]},
            {"nombre": "El Azteca", "tipo": "restaurante", "desc": "Sabores auténticos de México", "cats": ["Comida Mexicana"]},
            
            # Sushi
            {"nombre": "Sushi Express", "tipo": "restaurante", "desc": "Sushi fresco a domicilio", "cats": ["Sushi"]},
            {"nombre": "Tokyo Dining", "tipo": "restaurante", "desc": "Auténtica cocina japonesa", "cats": ["Sushi"]},
            {"nombre": "Sakura Sushi", "tipo": "restaurante", "desc": "El arte del sushi japonés", "cats": ["Sushi"]},
            {"nombre": "Nippon House", "tipo": "restaurante", "desc": "Experiencia culinaria japonesa", "cats": ["Sushi"]},
            
            # Cafetería
            {"nombre": "Starbucks", "tipo": "restaurante", "desc": "El mejor café del mundo", "cats": ["Cafetería", "Postres"]},
            {"nombre": "Juan Valdez Café", "tipo": "restaurante", "desc": "100% café colombiano", "cats": ["Cafetería"]},
            {"nombre": "Sweet & Coffee", "tipo": "restaurante", "desc": "Café y postres ecuatorianos", "cats": ["Cafetería", "Postres"]},
            {"nombre": "Dunkin'", "tipo": "restaurante", "desc": "America runs on Dunkin", "cats": ["Cafetería", "Postres"]},
            
            # Postres
            {"nombre": "Dairy Queen", "tipo": "restaurante", "desc": "Helados y postres deliciosos", "cats": ["Postres"]},
            {"nombre": "Baskin Robbins", "tipo": "restaurante", "desc": "31 sabores de helado", "cats": ["Postres"]},
            {"nombre": "Krispy Kreme", "tipo": "restaurante", "desc": "Donas frescas y café", "cats": ["Postres", "Cafetería"]},
            {"nombre": "Cinnabon", "tipo": "restaurante", "desc": "Rollos de canela irresistibles", "cats": ["Postres"]},
            
            # Restaurantes varios
            {"nombre": "Restaurante Gamos", "tipo": "restaurante", "desc": "Comida casera ecuatoriana", "cats": ["Ensaladas"]},
            {"nombre": "Subway", "tipo": "restaurante", "desc": "Come fresco - Sándwiches a tu gusto", "cats": ["Ensaladas"]},
            {"nombre": "Panda Express", "tipo": "restaurante", "desc": "Comida china americana", "cats": ["Ensaladas"]},
            {"nombre": "Chili's", "tipo": "restaurante", "desc": "Grill & Bar americano", "cats": ["Hamburguesas", "Ensaladas"]},
            {"nombre": "TGI Friday's", "tipo": "restaurante", "desc": "Casual dining americano", "cats": ["Hamburguesas", "Ensaladas"]},
            {"nombre": "Applebee's", "tipo": "restaurante", "desc": "Neighborhood grill & bar", "cats": ["Hamburguesas", "Ensaladas"]},
            
            # Bebidas
            {"nombre": "Coca-Cola Express", "tipo": "tienda", "desc": "Distribuidor oficial de Coca-Cola", "cats": ["Bebidas"]},
            {"nombre": "Pepsi Store", "tipo": "tienda", "desc": "Refrescos Pepsi a domicilio", "cats": ["Bebidas"]},
            {"nombre": "Jugos del Valle", "tipo": "tienda", "desc": "Jugos naturales y bebidas", "cats": ["Bebidas"]},
            
            # Farmacias
            {"nombre": "Farmacia Cruz Azul", "tipo": "farmacia", "desc": "Tu farmacia de confianza 24h", "cats": ["Farmacia"]},
            {"nombre": "Fybeca", "tipo": "farmacia", "desc": "Salud y bienestar para tu familia", "cats": ["Farmacia"]},
        ]

        ciudades = ["Quito", "Guayaquil", "Cuenca", "Ambato", "Manta", "Loja", "Machala"]
        calles = ["Av. Amazonas", "Av. 6 de Diciembre", "Av. República", "Calle Eloy Alfaro", 
                  "Av. Naciones Unidas", "Av. 10 de Agosto", "Calle Sucre", "Av. Patria"]
        
        logos = {
            "Pizza Hut": "https://upload.wikimedia.org/wikipedia/sco/thumb/d/d2/Pizza_Hut_logo.svg/200px-Pizza_Hut_logo.svg.png",
            "Domino's Pizza": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Dominos_pizza_logo.svg/200px-Dominos_pizza_logo.svg.png",
            "McDonald's": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/McDonald%27s_Golden_Arches.svg/200px-McDonald%27s_Golden_Arches.svg.png",
            "Burger King": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Burger_King_logo_%281999%29.svg/200px-Burger_King_logo_%281999%29.svg.png",
            "KFC": "https://upload.wikimedia.org/wikipedia/sco/thumb/b/bf/KFC_logo.svg/200px-KFC_logo.svg.png",
            "Starbucks": "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/200px-Starbucks_Corporation_Logo_2011.svg.png",
            "Subway": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Subway_2016_logo.svg/200px-Subway_2016_logo.svg.png",
            "Taco Bell": "https://upload.wikimedia.org/wikipedia/en/thumb/b/b3/Taco_Bell_2016.svg/200px-Taco_Bell_2016.svg.png",
        }

        proveedores = []
        for i, data in enumerate(proveedores_data):
            ruc = f"{1790000000 + i:013d}"
            ciudad = random.choice(ciudades)
            calle = random.choice(calles)
            numero = random.randint(100, 9999)
            
            hora_apertura = time(random.randint(7, 10), 0)
            hora_cierre = time(random.randint(20, 23), 0)
            
            prov, created = Proveedor.objects.get_or_create(
                ruc=ruc,
                defaults={
                    "nombre": data["nombre"],
                    "tipo_proveedor": data["tipo"],
                    "descripcion": data["desc"],
                    "direccion": f"{calle} {numero}, {ciudad}",
                    "ciudad": ciudad,
                    "horario_apertura": hora_apertura,
                    "horario_cierre": hora_cierre,
                    "activo": True,
                    "verificado": True,
                    "comision_porcentaje": Decimal("10.00"),
                    "calificacion_promedio": Decimal(str(round(random.uniform(3.5, 5.0), 2))),
                    "total_resenas": random.randint(10, 500),
                }
            )
            prov._categorias = data["cats"]
            prov._logo_url = logos.get(data["nombre"])
            proveedores.append(prov)
            
        return proveedores

    def crear_productos(self, proveedores, categorias):
        """Crea ~10 productos por proveedor"""
        self.stdout.write("Creando productos...")
        
        productos_por_categoria = {
            "Pizzas": [
                ("Pizza Margarita", "Salsa de tomate, mozzarella fresca y albahaca", 8.99, "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400"),
                ("Pizza Pepperoni", "Pepperoni premium y queso mozzarella", 10.99, "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400"),
                ("Pizza Hawaiana", "Jamón, piña y queso mozzarella", 11.99, "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400"),
                ("Pizza Suprema", "Pepperoni, champiñones, pimientos y cebolla", 13.99, "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400"),
                ("Pizza BBQ Chicken", "Pollo BBQ, cebolla roja y cilantro", 14.99, "https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=400"),
                ("Pizza Meat Lovers", "Pepperoni, salchicha, jamón y tocino", 15.99, "https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=400"),
                ("Pizza Vegetariana", "Pimientos, champiñones, aceitunas y tomate", 11.99, "https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=400"),
                ("Pizza Cuatro Quesos", "Mozzarella, parmesano, gorgonzola y provolone", 13.99, "https://images.unsplash.com/photo-1548369937-47519962c11a?w=400"),
                ("Palitos de Ajo", "Pan con ajo y mantequilla, salsa marinara", 4.99, "https://images.unsplash.com/photo-1619531040576-f9416aeadae8?w=400"),
                ("Alitas BBQ", "8 alitas de pollo con salsa BBQ", 7.99, "https://images.unsplash.com/photo-1608039755401-742074f0548d?w=400"),
            ],
            "Hamburguesas": [
                ("Hamburguesa Clásica", "Carne 100% res, lechuga, tomate y cebolla", 6.99, "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400"),
                ("Hamburguesa con Queso", "Doble queso cheddar derretido", 7.99, "https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400"),
                ("Hamburguesa BBQ", "Tocino, cebolla caramelizada y salsa BBQ", 9.99, "https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400"),
                ("Hamburguesa Doble", "Doble carne, doble queso, doble sabor", 11.99, "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400"),
                ("Hamburguesa Vegetariana", "Medallón de lentejas y vegetales", 8.99, "https://images.unsplash.com/photo-1520072959219-c595dc870360?w=400"),
                ("Hamburguesa Pollo", "Pechuga de pollo crujiente", 8.99, "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400"),
                ("Papas Fritas Grandes", "Papas crujientes con sal", 3.99, "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400"),
                ("Aros de Cebolla", "Crujientes aros de cebolla empanizados", 4.99, "https://images.unsplash.com/photo-1639024471283-03518883512d?w=400"),
                ("Nuggets x10", "Nuggets de pollo crujientes", 5.99, "https://images.unsplash.com/photo-1562967914-608f82629710?w=400"),
                ("Combo Familiar", "4 hamburguesas + 2 papas grandes + 4 bebidas", 29.99, "https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=400"),
            ],
            "Pollo": [
                ("Balde 8 Piezas", "8 piezas de pollo crujiente", 15.99, "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400"),
                ("Balde 12 Piezas", "12 piezas de pollo crujiente", 22.99, "https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=400"),
                ("Balde 16 Piezas", "16 piezas de pollo crujiente", 28.99, "https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400"),
                ("Combo Personal", "2 piezas + papas + bebida", 7.99, "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=400"),
                ("Alitas Picantes", "10 alitas con salsa picante", 9.99, "https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=400"),
                ("Strips de Pollo", "5 strips crujientes con salsa", 6.99, "https://images.unsplash.com/photo-1562967915-92ae0c320a01?w=400"),
                ("Pollo Asado", "Pollo entero asado al carbón", 12.99, "https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=400"),
                ("Ensalada César", "Lechuga, crutones, parmesano y pollo", 8.99, "https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400"),
                ("Puré de Papas", "Cremoso puré con mantequilla", 2.99, "https://images.unsplash.com/photo-1595295333158-4742f28fbd85?w=400"),
                ("Coleslaw", "Ensalada de col cremosa", 2.49, "https://images.unsplash.com/photo-1625944525533-473f1a3d54e7?w=400"),
            ],
            "Sushi": [
                ("Roll California", "8 piezas - cangrejo, aguacate, pepino", 9.99, "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400"),
                ("Roll Philadelphia", "8 piezas - salmón, queso crema", 11.99, "https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=400"),
                ("Roll Tempura", "8 piezas - camarón tempura", 12.99, "https://images.unsplash.com/photo-1559410545-0bdcd187e0a6?w=400"),
                ("Roll Dragon", "8 piezas - anguila, aguacate", 14.99, "https://images.unsplash.com/photo-1553621042-f6e147245754?w=400"),
                ("Nigiri Salmón", "2 piezas de nigiri de salmón", 5.99, "https://images.unsplash.com/photo-1611143669185-af224c5e3252?w=400"),
                ("Nigiri Atún", "2 piezas de nigiri de atún", 6.99, "https://images.unsplash.com/photo-1617196034183-421b4917c92d?w=400"),
                ("Sashimi Mixto", "12 piezas variadas", 18.99, "https://images.unsplash.com/photo-1580822184713-fc5400e7fe10?w=400"),
                ("Combo Sushi", "20 piezas + sopa miso", 24.99, "https://images.unsplash.com/photo-1583623025817-d180a2221d0a?w=400"),
                ("Gyoza", "5 dumplings japoneses", 5.99, "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=400"),
                ("Edamame", "Vainas de soya con sal", 3.99, "https://images.unsplash.com/photo-1564093497595-593b96d80180?w=400"),
            ],
            "Comida Mexicana": [
                ("Tacos al Pastor", "3 tacos con piña y cilantro", 7.99, "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400"),
                ("Burrito Supreme", "Carne, frijoles, arroz, crema y guacamole", 9.99, "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400"),
                ("Quesadilla Grande", "Queso derretido con pollo o carne", 8.99, "https://images.unsplash.com/photo-1618040996337-56904b7850b9?w=400"),
                ("Nachos Supreme", "Nachos con carne, queso, jalapeños", 10.99, "https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400"),
                ("Enchiladas Rojas", "3 enchiladas bañadas en salsa roja", 11.99, "https://images.unsplash.com/photo-1534352956036-cd81e27dd615?w=400"),
                ("Guacamole Fresco", "Aguacate, tomate, cebolla y limón", 5.99, "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400"),
                ("Elote Mexicano", "Maíz con mayonesa, chile y queso", 3.99, "https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400"),
                ("Churros con Chocolate", "4 churros con salsa de chocolate", 4.99, "https://images.unsplash.com/photo-1624371414361-e670edf4898c?w=400"),
                ("Fajitas Mixtas", "Res y pollo con pimientos", 14.99, "https://images.unsplash.com/photo-1611250503393-0a6a5ad3f115?w=400"),
                ("Tostadas de Ceviche", "2 tostadas con ceviche fresco", 8.99, "https://images.unsplash.com/photo-1535399831218-d5bd36d1a6b3?w=400"),
            ],
            "Cafetería": [
                ("Café Americano", "Espresso con agua caliente", 2.49, "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400"),
                ("Cappuccino", "Espresso, leche vaporizada y espuma", 3.49, "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400"),
                ("Latte", "Espresso con leche cremosa", 3.99, "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400"),
                ("Mocha", "Espresso, chocolate y leche", 4.49, "https://images.unsplash.com/photo-1578314675249-a6910f80cc4e?w=400"),
                ("Frappuccino", "Café helado cremoso", 4.99, "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400"),
                ("Té Chai Latte", "Té especiado con leche", 3.99, "https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=400"),
                ("Chocolate Caliente", "Chocolate cremoso con leche", 3.49, "https://images.unsplash.com/photo-1542990253-aass92f2e3ae?w=400"),
                ("Croissant", "Croissant francés de mantequilla", 2.49, "https://images.unsplash.com/photo-1555507036-ab1f4038c54b?w=400"),
                ("Muffin de Arándanos", "Muffin esponjoso con arándanos", 2.99, "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400"),
                ("Sándwich Desayuno", "Huevo, queso y jamón", 4.99, "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400"),
            ],
            "Postres": [
                ("Brownie con Helado", "Brownie caliente con helado de vainilla", 5.99, "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400"),
                ("Cheesecake New York", "Clásico cheesecake cremoso", 5.49, "https://images.unsplash.com/photo-1524351199678-941a58a3df50?w=400"),
                ("Tiramisú", "Postre italiano con café y mascarpone", 6.49, "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400"),
                ("Helado 3 Bolas", "Elige tus sabores favoritos", 4.99, "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400"),
                ("Milkshake", "Batido cremoso de leche", 4.49, "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400"),
                ("Donas Glaseadas", "3 donas con glaseado variado", 3.99, "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400"),
                ("Flan de Caramelo", "Flan cremoso con caramelo", 3.99, "https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400"),
                ("Pastel de Chocolate", "Porción de pastel triple chocolate", 5.99, "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400"),
                ("Crêpe de Nutella", "Crêpe con Nutella y frutas", 5.49, "https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400"),
                ("Sundae", "Helado con topping y crema", 4.99, "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400"),
            ],
            "Bebidas": [
                ("Coca-Cola 500ml", "Refresco Coca-Cola original", 1.50, "https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400"),
                ("Coca-Cola 2L", "Botella familiar Coca-Cola", 2.99, "https://images.unsplash.com/photo-1561758033-48d52648ae8b?w=400"),
                ("Sprite 500ml", "Refresco de lima-limón", 1.50, "https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400"),
                ("Fanta Naranja 500ml", "Refresco sabor naranja", 1.50, "https://images.unsplash.com/photo-1624517452488-04869289c4ca?w=400"),
                ("Agua Mineral 500ml", "Agua pura embotellada", 0.99, "https://images.unsplash.com/photo-1560023907-5f339617ea30?w=400"),
                ("Jugo de Naranja 1L", "Jugo natural de naranja", 3.49, "https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?w=400"),
                ("Red Bull", "Bebida energética", 2.99, "https://images.unsplash.com/photo-1527960471264-932f39eb5846?w=400"),
                ("Cerveza Pilsener 6pk", "Pack de 6 cervezas nacionales", 8.99, "https://images.unsplash.com/photo-1608270586620-248524c67de9?w=400"),
                ("Gatorade 500ml", "Bebida isotónica", 1.99, "https://images.unsplash.com/photo-1632818924360-68d4994cfdb2?w=400"),
                ("Limonada Natural 1L", "Limonada fresca casera", 2.99, "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400"),
            ],
            "Ensaladas": [
                ("Ensalada César", "Lechuga romana, crutones, parmesano", 7.99, "https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400"),
                ("Ensalada Griega", "Tomate, pepino, aceitunas, feta", 8.49, "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400"),
                ("Ensalada Mediterránea", "Quinoa, garbanzos, vegetales", 9.99, "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400"),
                ("Ensalada de Pollo", "Mix de lechugas con pollo grillado", 10.99, "https://images.unsplash.com/photo-1604909052743-94e838986d24?w=400"),
                ("Ensalada Caprese", "Tomate, mozzarella fresca, albahaca", 8.99, "https://images.unsplash.com/photo-1608032077018-c9aad9565d29?w=400"),
                ("Wrap Vegetariano", "Tortilla con vegetales frescos", 7.49, "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400"),
                ("Bowl de Quinoa", "Quinoa, aguacate, edamame", 11.99, "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400"),
                ("Sopa del Día", "Sopa casera caliente", 4.99, "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400"),
                ("Hummus con Pita", "Hummus cremoso con pan pita", 5.99, "https://images.unsplash.com/photo-1577805947697-89e18249d767?w=400"),
                ("Smoothie Verde", "Espinaca, manzana, jengibre", 5.49, "https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=400"),
            ],
            "Farmacia": [
                ("Paracetamol 500mg", "Analgésico y antipirético - 20 tabletas", 2.99, "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400"),
                ("Ibuprofeno 400mg", "Antiinflamatorio - 20 tabletas", 3.49, "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400"),
                ("Vitamina C 1000mg", "Suplemento vitamínico - 30 tabletas", 8.99, "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400"),
                ("Alcohol Antiséptico", "Alcohol 70% - 500ml", 3.99, "https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=400"),
                ("Mascarillas x50", "Mascarillas desechables", 9.99, "https://images.unsplash.com/photo-1584634731339-252c581abfc5?w=400"),
                ("Curitas x100", "Banditas adhesivas variadas", 4.99, "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=400"),
                ("Termómetro Digital", "Medición precisa de temperatura", 12.99, "https://images.unsplash.com/photo-1584515933487-779824d37e59?w=400"),
                ("Gel Antibacterial", "Gel desinfectante - 250ml", 3.49, "https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=400"),
                ("Jarabe para Tos", "Alivio natural de la tos - 120ml", 6.99, "https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400"),
                ("Protector Solar SPF50", "Protección solar alta - 100ml", 14.99, "https://images.unsplash.com/photo-1556227703-a5d8e3d7c64d?w=400"),
            ],
        }

        for proveedor in proveedores:
            cats_proveedor = getattr(proveedor, '_categorias', [])
            productos_creados = 0
            
            for cat_nombre in cats_proveedor:
                if cat_nombre in categorias and cat_nombre in productos_por_categoria:
                    categoria = categorias[cat_nombre]
                    productos_lista = productos_por_categoria[cat_nombre]
                    
                    for nombre, desc, precio, img in productos_lista:
                        if productos_creados >= 10:
                            break
                        
                        precio_decimal = Decimal(str(precio))
                        precio_anterior = None
                        if random.random() < 0.3:
                            precio_anterior = precio_decimal * Decimal("1.2")
                        
                        Producto.objects.get_or_create(
                            proveedor=proveedor,
                            nombre=nombre,
                            defaults={
                                "categoria": categoria,
                                "descripcion": desc,
                                "precio": precio_decimal,
                                "precio_anterior": precio_anterior,
                                "imagen_url": img,
                                "disponible": random.random() > 0.1,
                                "destacado": random.random() < 0.2,
                                "veces_vendido": random.randint(0, 1000),
                            }
                        )
                        productos_creados += 1
                    
                    if productos_creados >= 10:
                        break

    def crear_promociones(self, proveedores):
        """Crea banners promocionales"""
        self.stdout.write("Creando promociones...")
        
        ahora = timezone.now()
        en_30_dias = ahora + timedelta(days=30)
        
        promociones_data = [
            {"titulo": "¡2x1 en Pizzas!", "desc": "Todos los martes llévate 2 pizzas por el precio de 1", "tipo": "2x1", "valor": None, "descuento": "2x1", "color": "#E91E63"},
            {"titulo": "30% OFF Hamburguesas", "desc": "Descuento en todas las hamburguesas del menú", "tipo": "porcentaje", "valor": 30, "descuento": "30% OFF", "color": "#FF5722"},
            {"titulo": "Combo Familiar $19.99", "desc": "4 hamburguesas + papas + bebidas", "tipo": "precio_fijo", "valor": 19.99, "descuento": "$19.99", "color": "#4CAF50"},
            {"titulo": "Envío Gratis", "desc": "En pedidos mayores a $15", "tipo": "envio_gratis", "valor": None, "descuento": "FREE", "color": "#2196F3"},
            {"titulo": "Happy Hour 50%", "desc": "De 2pm a 5pm, mitad de precio en bebidas", "tipo": "porcentaje", "valor": 50, "descuento": "50% OFF", "color": "#9C27B0"},
            {"titulo": "Menú del Día $5.99", "desc": "Plato principal + bebida + postre", "tipo": "precio_fijo", "valor": 5.99, "descuento": "$5.99", "color": "#FF9800"},
            {"titulo": "3x2 en Sushi", "desc": "Lleva 3 rolls y paga solo 2", "tipo": "3x2", "valor": None, "descuento": "3x2", "color": "#F44336"},
            {"titulo": "20% Primer Pedido", "desc": "Descuento para nuevos clientes", "tipo": "porcentaje", "valor": 20, "descuento": "20% OFF", "color": "#3F51B5"},
        ]
        
        imagenes_promociones = [
            "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800",
            "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800",
            "https://images.unsplash.com/photo-1561758033-48d52648ae8b?w=800",
            "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=800",
            "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800",
        ]
        
        proveedores_destacados = proveedores[:20]
        
        for i, proveedor in enumerate(proveedores_destacados):
            promo_data = promociones_data[i % len(promociones_data)]
            img = imagenes_promociones[i % len(imagenes_promociones)]
            
            Promocion.objects.get_or_create(
                proveedor=proveedor,
                titulo=promo_data["titulo"],
                defaults={
                    "descripcion": promo_data["desc"],
                    "tipo_promocion": promo_data["tipo"],
                    "valor_descuento": Decimal(str(promo_data["valor"])) if promo_data["valor"] else None,
                    "descuento": promo_data["descuento"],
                    "color": promo_data["color"],
                    "imagen_url": img,
                    "fecha_inicio": ahora,
                    "fecha_fin": en_30_dias,
                    "activa": True,
                }
            )
