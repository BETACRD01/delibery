from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from proveedores.models import Proveedor
from .models import Categoria, Producto, Promocion

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


class PromocionAPITest(APITestCase):
    """Pruebas para la creación y asociación de productos a promociones."""

    def setUp(self):
        # Crear usuario y proveedor
        self.user = User.objects.create_user(
            email="proveedor@test.com",
            username="proveedor",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user,
            nombre="Proveedor Test",
            ruc="0999999999001",
            telefono="+593999999999",
            email="proveedor@test.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )

        # Crear categoría
        self.categoria = Categoria.objects.create(nombre="Comida", activo=True)

        # Crear productos para asociar
        self.producto1 = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.categoria,
            nombre="Pizza",
            descripcion="Pizza deliciosa",
            precio=15.00,
            disponible=True,
        )
        self.producto2 = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.categoria,
            nombre="Hamburguesa",
            descripcion="Hamburguesa grande",
            precio=12.00,
            disponible=True,
        )
        self.producto3 = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.categoria,
            nombre="Hot Dog",
            descripcion="Hot dog especial",
            precio=8.00,
            disponible=True,
        )

        # Autenticar como proveedor
        self.client.force_authenticate(user=self.user)

    def test_crear_promocion_con_productos_asociados(self):
        """Test: Crear una promoción con múltiples productos asociados."""
        url = reverse("productos:provider-promocion-list")

        data = {
            "titulo": "Combo Familiar",
            "descripcion": "Pizza + Hamburguesa + Hot Dog",
            "descuento": "30% OFF",
            "color": "#E91E63",
            "tipo_promocion": "porcentaje",
            "valor_descuento": 30,
            "activa": True,
            "productos_asociados": [self.producto1.id, self.producto2.id, self.producto3.id],
        }

        response = self.client.post(url, data, format="json")

        # Verificar que la promoción se creó exitosamente
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["titulo"], "Combo Familiar")

        # Verificar que los productos se asociaron correctamente
        promocion_id = response.data["id"]
        promocion = Promocion.objects.get(id=promocion_id)

        productos_asociados = list(promocion.productos_asociados.all().values_list('id', flat=True))
        self.assertEqual(len(productos_asociados), 3)
        self.assertIn(self.producto1.id, productos_asociados)
        self.assertIn(self.producto2.id, productos_asociados)
        self.assertIn(self.producto3.id, productos_asociados)

        print(f"\n✅ Promoción creada: {promocion.titulo}")
        print(f"✅ Productos asociados: {productos_asociados}")

    def test_actualizar_productos_asociados_promocion(self):
        """Test: Actualizar los productos asociados de una promoción existente."""
        # Crear promoción inicial con 2 productos
        promocion = Promocion.objects.create(
            proveedor=self.proveedor,
            titulo="Promo Original",
            descripcion="Descripción",
            descuento="20% OFF",
            color="#E91E63",
            activa=True,
        )
        promocion.productos_asociados.set([self.producto1.id, self.producto2.id])

        # Actualizar para cambiar los productos asociados
        url = reverse("productos:provider-promocion-detail", args=[promocion.id])
        data = {
            "titulo": "Promo Actualizada",
            "productos_asociados": [self.producto2.id, self.producto3.id],  # Cambiar productos
        }

        response = self.client.patch(url, data, format="json")

        # Verificar que se actualizó
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Verificar productos asociados actualizados
        promocion.refresh_from_db()
        productos_asociados = list(promocion.productos_asociados.all().values_list('id', flat=True))

        self.assertEqual(len(productos_asociados), 2)
        self.assertIn(self.producto2.id, productos_asociados)
        self.assertIn(self.producto3.id, productos_asociados)
        self.assertNotIn(self.producto1.id, productos_asociados)  # Producto1 ya no debe estar

        print(f"\n✅ Promoción actualizada: {promocion.titulo}")
        print(f"✅ Nuevos productos asociados: {productos_asociados}")

    def test_listar_promocion_devuelve_productos_asociados(self):
        """Test: Verificar que al listar promociones se devuelven los IDs de productos asociados."""
        # Crear promoción con productos
        promocion = Promocion.objects.create(
            proveedor=self.proveedor,
            titulo="Promo Test",
            descripcion="Test",
            descuento="15% OFF",
            color="#E91E63",
            activa=True,
        )
        promocion.productos_asociados.set([self.producto1.id, self.producto2.id])

        # Listar promociones
        url = reverse("productos:provider-promocion-list")
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Buscar nuestra promoción en la respuesta
        promo_data = next((p for p in response.data if p["id"] == promocion.id), None)
        self.assertIsNotNone(promo_data)

        # Verificar que devuelve los productos asociados
        self.assertIn("productos_asociados", promo_data)
        self.assertEqual(len(promo_data["productos_asociados"]), 2)
        self.assertIn(self.producto1.id, promo_data["productos_asociados"])
        self.assertIn(self.producto2.id, promo_data["productos_asociados"])

        print(f"\n✅ Promoción listada correctamente")
        print(f"✅ Productos en respuesta API: {promo_data['productos_asociados']}")
