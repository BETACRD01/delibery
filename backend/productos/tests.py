from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from proveedores.models import Proveedor
from .models import Categoria, Producto

User = get_user_model()


class ProductoAPITest(APITestCase):
    """Pruebas básicas de los endpoints públicos de productos."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user,
            nombre="Proveedor Test",
            ruc="0999999999001",
            telefono="+593999999999",
            email="user@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )
        self.cat = Categoria.objects.create(nombre="Bebidas", activo=True)
        self.prod = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.cat,
            nombre="Producto Test",
            descripcion="Desc",
            precio=10.00,
            precio_anterior=12.00,
            disponible=True,
            destacado=True,
            tiene_stock=True,
            stock=5,
        )
        self.url_list = reverse("productos:producto-list")

    def test_listado_publico(self):
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res.data), 1)

    def test_detalle_publico(self):
        url = reverse("productos:producto-detail", args=[self.prod.id])
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["id"], self.prod.id)

    def test_endpoint_ofertas(self):
        url = reverse("productos:producto-ofertas")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [p["id"] for p in res.data]
        self.assertIn(self.prod.id, ids)

    def test_endpoint_destacados(self):
        url = reverse("productos:producto-destacados")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [p["id"] for p in res.data]
        self.assertIn(self.prod.id, ids)

    def test_endpoint_novedades(self):
        url = reverse("productos:producto-novedades")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [p["id"] for p in res.data]
        self.assertIn(self.prod.id, ids)

    def test_endpoint_mas_populares(self):
        url = reverse("productos:producto-mas-populares")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [p["id"] for p in res.data]
        self.assertIn(self.prod.id, ids)
