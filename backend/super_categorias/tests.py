# super_categorias/tests.py
from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from .models import CategoriaSuper, ProveedorSuper, ProductoSuper

User = get_user_model()


class CategoriaSuperAPITest(APITestCase):
    """Cobertura básica de listados públicos y restricciones admin."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.cat_activa = CategoriaSuper.objects.create(
            id="supermercados",
            nombre="Supermercados",
            descripcion="Todo para tu despensa",
            icono=57524,
            color="#4CAF50",
            activo=True,
            orden=1,
        )
        self.cat_inactiva = CategoriaSuper.objects.create(
            id="farmacias",
            nombre="Farmacias",
            descripcion="Salud y bienestar",
            icono=57524,
            color="#2196F3",
            activo=False,
            orden=2,
        )

    def test_listado_publico_solo_activos(self):
        url = reverse("super_categorias:categoriasuper-list")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.data['results'] if isinstance(res.data, dict) and 'results' in res.data else res.data
        ids = [item["id"] for item in data]
        self.assertIn(self.cat_activa.id, ids)
        self.assertNotIn(self.cat_inactiva.id, ids)

    def test_detalle_publico_categoria_activa(self):
        url = reverse("super_categorias:categoriasuper-detail", args=[self.cat_activa.id])
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["id"], self.cat_activa.id)

    def test_creacion_restringida_a_admin(self):
        url = reverse("super_categorias:categoriasuper-list")
        payload = {
            "id": "bebidas",
            "nombre": "Bebidas",
            "descripcion": "Bebidas frías y calientes",
            "icono": 57524,
            "color": "#FF9800",
            "activo": True,
            "orden": 3,
        }
        # Usuario anon debería ser 403/401
        res = self.client.post(url, payload, format="json")
        self.assertIn(res.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

        # Admin debe poder crear
        self.client.force_authenticate(self.admin)
        res_admin = self.client.post(url, payload, format="json")
        self.assertEqual(res_admin.status_code, status.HTTP_201_CREATED)
        self.assertEqual(CategoriaSuper.objects.filter(id="bebidas").count(), 1)


class ProveedorSuperAPITest(APITestCase):
    """Verifica listados públicos y scopes de proveedores."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.categoria = CategoriaSuper.objects.create(
            id="mensajeria",
            nombre="Mensajería",
            descripcion="Envíos rápidos",
            icono=57524,
            color="#00BCD4",
            activo=True,
            orden=1,
        )
        self.prov_activo = ProveedorSuper.objects.create(
            categoria=self.categoria,
            nombre="Mensajería Express",
            descripcion="Rápido y seguro",
            direccion="Calle 1",
            calificacion=4.5,
            total_resenas=10,
            activo=True,
            verificado=True,
        )
        self.prov_inactivo = ProveedorSuper.objects.create(
            categoria=self.categoria,
            nombre="Mensajería Slow",
            descripcion="Lento pero seguro",
            direccion="Calle 2",
            calificacion=3.0,
            total_resenas=1,
            activo=False,
            verificado=False,
        )

    def test_listado_publico_filtra_activos(self):
        url = reverse("super_categorias:proveedorsuper-list")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.data['results'] if isinstance(res.data, dict) and 'results' in res.data else res.data
        nombres = [p["nombre"] for p in data]
        self.assertIn(self.prov_activo.nombre, nombres)
        self.assertNotIn(self.prov_inactivo.nombre, nombres)

    def test_por_categoria_requiere_param(self):
        url = reverse("super_categorias:proveedorsuper-por-categoria")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("categoria", res.data.get("error", "").lower())

    def test_por_categoria_devuelve_activos(self):
        url = reverse("super_categorias:proveedorsuper-por-categoria")
        res = self.client.get(url, {"categoria": self.categoria.id})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.data['results'] if isinstance(res.data, dict) and 'results' in res.data else res.data
        nombres = [p["nombre"] for p in data]
        self.assertIn(self.prov_activo.nombre, nombres)
        self.assertNotIn(self.prov_inactivo.nombre, nombres)

    def test_creacion_restringida_a_admin(self):
        url = reverse("super_categorias:proveedorsuper-list")
        payload = {
            "categoria": self.categoria.id,
            "nombre": "Nuevo",
            "descripcion": "Test",
            "direccion": "Calle 3",
            "calificacion": 5.0,
            "total_resenas": 0,
            "activo": True,
            "verificado": False,
        }
        res = self.client.post(url, payload, format="json")
        self.assertIn(res.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

        self.client.force_authenticate(self.admin)
        res_admin = self.client.post(url, payload, format="json")
        self.assertEqual(res_admin.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ProveedorSuper.objects.filter(nombre="Nuevo").count(), 1)


class ProductoSuperAPITest(APITestCase):
    """Cubre listados públicos, filtros y ofertas/destacados."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.categoria = CategoriaSuper.objects.create(
            id="tiendas",
            nombre="Tiendas",
            descripcion="Todo en tiendas",
            icono=57524,
            color="#9C27B0",
            activo=True,
            orden=1,
        )
        self.proveedor = ProveedorSuper.objects.create(
            categoria=self.categoria,
            nombre="Tienda Central",
            descripcion="Productos varios",
            direccion="Av. Central",
            calificacion=4.0,
            total_resenas=5,
            activo=True,
            verificado=True,
        )
        self.prod_normal = ProductoSuper.objects.create(
            proveedor=self.proveedor,
            nombre="Producto Normal",
            descripcion="Desc",
            precio=10.00,
            stock=5,
            disponible=True,
            destacado=False,
        )
        self.prod_oferta = ProductoSuper.objects.create(
            proveedor=self.proveedor,
            nombre="Producto Oferta",
            descripcion="Desc",
            precio=8.00,
            precio_anterior=10.00,
            stock=3,
            disponible=True,
            destacado=False,
        )
        self.prod_destacado = ProductoSuper.objects.create(
            proveedor=self.proveedor,
            nombre="Producto Destacado",
            descripcion="Desc",
            precio=12.00,
            stock=10,
            disponible=True,
            destacado=True,
        )
        self.prod_sin_stock = ProductoSuper.objects.create(
            proveedor=self.proveedor,
            nombre="Sin stock",
            descripcion="Desc",
            precio=5.00,
            stock=0,
            disponible=True,
            destacado=True,
        )

    def test_listado_publico_filtra_disponibles_con_stock(self):
        url = reverse("super_categorias:productosuper-list")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        data = res.data['results'] if isinstance(res.data, dict) and 'results' in res.data else res.data
        nombres = [p["nombre"] for p in data]
        self.assertIn(self.prod_normal.nombre, nombres)
        self.assertIn(self.prod_oferta.nombre, nombres)
        self.assertIn(self.prod_destacado.nombre, nombres)
        self.assertNotIn(self.prod_sin_stock.nombre, nombres)  # sin stock no debe aparecer

    def test_endpoint_ofertas(self):
        url = reverse("super_categorias:productosuper-ofertas")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        nombres = [p["nombre"] for p in res.data]
        self.assertIn(self.prod_oferta.nombre, nombres)
        self.assertNotIn(self.prod_normal.nombre, nombres)

    def test_endpoint_destacados(self):
        url = reverse("super_categorias:productosuper-destacados")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        nombres = [p["nombre"] for p in res.data]
        self.assertIn(self.prod_destacado.nombre, nombres)
        self.assertNotIn(self.prod_normal.nombre, nombres)

    def test_creacion_restringida_a_admin(self):
        url = reverse("super_categorias:productosuper-list")
        payload = {
            "proveedor": self.proveedor.id,
            "nombre": "Nuevo Producto",
            "descripcion": "Desc",
            "precio": 20.00,
            "stock": 2,
            "disponible": True,
            "destacado": False,
        }
        res = self.client.post(url, payload, format="json")
        self.assertIn(res.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

        self.client.force_authenticate(self.admin)
        res_admin = self.client.post(url, payload, format="json")
        self.assertEqual(res_admin.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ProductoSuper.objects.filter(nombre="Nuevo Producto").count(), 1)
