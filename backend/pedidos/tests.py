from decimal import Decimal
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.exceptions import ValidationError
from rest_framework import status
from rest_framework.test import APITestCase

from usuarios.models import Perfil
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from productos.models import Categoria, Producto
from .models import Pedido, EstadoPedido, EstadoPago, TipoPedido

User = get_user_model()


class PedidoModelTest(APITestCase):
    """Pruebas de negocio del modelo Pedido."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
            rol_activo=User.RolChoices.CLIENTE,
        )
        self.proveedor_user = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.proveedor_user,
            nombre="Proveedor",
            ruc="0999999999001",
            telefono="+593999999999",
            email="prov@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )
        self.rep_user = User.objects.create_user(
            email="rep@app.com",
            username="rep",
            password="password123",
            rol_activo=User.RolChoices.REPARTIDOR,
        )
        self.repartidor = Repartidor.objects.create(
            user=self.rep_user,
            cedula="0102030405",
            telefono="0999999999",
            verificado=True,
            activo=True,
        )
        self.cat = Categoria.objects.create(nombre="Bebidas", activo=True)
        self.prod = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.cat,
            nombre="Producto",
            descripcion="Desc",
            precio=10.00,
            disponible=True,
            tiene_stock=True,
            stock=10,
        )
        self.pedido = Pedido.objects.create(
            cliente=self.user.perfil,
            proveedor=self.proveedor,
            descripcion="Test",
            total=Decimal("20.00"),
            direccion_entrega="Dir",
            tipo=TipoPedido.PROVEEDOR,
        )

    def test_generar_numero_pedido(self):
        self.assertTrue(self.pedido.numero_pedido.startswith(f"JP-{timezone.now().year}-"))

    def test_confirmar_por_proveedor_cambia_estado(self):
        self.pedido.confirmar_por_proveedor()
        self.pedido.refresh_from_db()
        self.assertEqual(self.pedido.estado, EstadoPedido.EN_PROCESO)

    def test_aceptar_por_repartidor(self):
        self.pedido.aceptar_por_repartidor(self.repartidor)
        self.pedido.refresh_from_db()
        self.assertEqual(self.pedido.repartidor, self.repartidor)
        self.assertTrue(self.pedido.aceptado_por_repartidor)

    def test_marcar_entregado_actualiza_pago(self):
        self.pedido.aceptar_por_repartidor(self.repartidor)
        self.pedido.marcar_entregado()
        self.pedido.refresh_from_db()
        self.assertEqual(self.pedido.estado, EstadoPedido.ENTREGADO)
        self.assertEqual(self.pedido.estado_pago, EstadoPago.PAGADO)
        self.assertGreaterEqual(self.pedido.ganancia_app, Decimal("0.00"))

    def test_cancelar_no_permite_entregado(self):
        self.pedido.estado = EstadoPedido.ENTREGADO
        self.pedido.save(update_fields=["estado"])
        with self.assertRaises(ValidationError):
            self.pedido.cancelar("No", "test")


class PedidoAPIViewTest(APITestCase):
    """Smoke tests para endpoints públicos de productos/pedidos."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
            rol_activo=User.RolChoices.CLIENTE,
        )
        self.client.force_authenticate(self.user)

        self.prov_user = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.prov_user,
            nombre="Proveedor",
            ruc="0999999999002",
            telefono="+593999999999",
            email="prov@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )
        self.cat = Categoria.objects.create(nombre="Snacks", activo=True)
        self.prod = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.cat,
            nombre="Snack",
            descripcion="Desc",
            precio=5.00,
            disponible=True,
            tiene_stock=True,
            stock=10,
        )
        self.pedido = Pedido.objects.create(
            cliente=self.user.perfil,
            proveedor=self.proveedor,
            descripcion="Pedido API",
            total=Decimal("5.00"),
            direccion_entrega="Dir",
        )

    def test_listado_productos_publico(self):
        url = reverse("productos:producto-list")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_checkout_carrito_endpoint_auth(self):
        # checkout requiere auth; ya autenticado
        url = reverse("productos:checkout")
        res = self.client.post(url, {}, format="json")
        self.assertNotIn(res.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_estados_endpoint_requiere_auth(self):
        url = reverse("pedidos:lista_crear_pedidos")
        anon = self.client.__class__()
        res = anon.get(url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
