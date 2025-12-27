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
from .models import Pedido, EstadoPedido, EstadoPago, TipoPedido, ItemPedido
from .serializers import PedidoDetailSerializer

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


class CalificarProveedorTest(APITestCase):
    """Pruebas para verificar que el botón de calificar proveedor aparece correctamente."""

    def setUp(self):
        # Cliente
        self.cliente_user = User.objects.create_user(
            email="cliente@app.com",
            username="cliente",
            password="password123",
            rol_activo=User.RolChoices.CLIENTE,
        )

        # Proveedor 1
        self.prov1_user = User.objects.create_user(
            email="prov1@app.com",
            username="prov1",
            password="password123",
            rol_activo=User.RolChoices.PROVEEDOR,
        )
        self.proveedor1 = Proveedor.objects.create(
            user=self.prov1_user,
            nombre="Proveedor 1",
            ruc="0999999999001",
            telefono="+593999999991",
            email="prov1@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )

        # Proveedor 2
        self.prov2_user = User.objects.create_user(
            email="prov2@app.com",
            username="prov2",
            password="password123",
            rol_activo=User.RolChoices.PROVEEDOR,
        )
        self.proveedor2 = Proveedor.objects.create(
            user=self.prov2_user,
            nombre="Proveedor 2",
            ruc="0999999999002",
            telefono="+593999999992",
            email="prov2@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )

        # Repartidor
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

        # Categoría y productos
        self.cat = Categoria.objects.create(nombre="Comida", activo=True)
        self.prod1 = Producto.objects.create(
            proveedor=self.proveedor1,
            categoria=self.cat,
            nombre="Producto 1",
            descripcion="Desc 1",
            precio=10.00,
            disponible=True,
            tiene_stock=True,
            stock=10,
        )
        self.prod2 = Producto.objects.create(
            proveedor=self.proveedor2,
            categoria=self.cat,
            nombre="Producto 2",
            descripcion="Desc 2",
            precio=15.00,
            disponible=True,
            tiene_stock=True,
            stock=10,
        )

    def test_pedido_proveedor_unico_entregado_puede_calificar(self):
        """Cliente puede calificar proveedor en pedido con proveedor único cuando está entregado."""
        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=self.proveedor1,
            descripcion="Pedido con proveedor único",
            total=Decimal("10.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
        )
        ItemPedido.objects.create(
            pedido=pedido,
            producto=self.prod1,
            cantidad=1,
            precio_unitario=Decimal("10.00"),
        )

        # Autenticar como cliente
        self.client.force_authenticate(self.cliente_user)

        # Serializar pedido
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.cliente_user})()})
        data = serializer.data

        # Verificar que puede calificar proveedor
        self.assertTrue(data.get('puede_calificar_proveedor', False),
                       "El cliente debería poder calificar al proveedor en pedido entregado con proveedor único")

    def test_pedido_proveedor_unico_no_entregado_no_puede_calificar(self):
        """Cliente NO puede calificar proveedor si el pedido no está entregado."""
        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=self.proveedor1,
            descripcion="Pedido en proceso",
            total=Decimal("10.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.EN_PROCESO,
        )

        self.client.force_authenticate(self.cliente_user)
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.cliente_user})()})
        data = serializer.data

        self.assertFalse(data.get('puede_calificar_proveedor', False),
                        "No debería poder calificar si el pedido no está entregado")

    def test_pedido_multi_proveedor_entregado_puede_calificar(self):
        """Cliente puede calificar en pedido multi-proveedor (proveedor=None) cuando está entregado."""
        # Crear pedido SIN proveedor único (pedido multi-proveedor)
        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=None,  # Multi-proveedor
            descripcion="Pedido con múltiples proveedores",
            total=Decimal("25.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.CARRITO,
            estado=EstadoPedido.ENTREGADO,
        )
        # Items de diferentes proveedores
        ItemPedido.objects.create(
            pedido=pedido,
            producto=self.prod1,
            cantidad=1,
            precio_unitario=Decimal("10.00"),
        )
        ItemPedido.objects.create(
            pedido=pedido,
            producto=self.prod2,
            cantidad=1,
            precio_unitario=Decimal("15.00"),
        )

        self.client.force_authenticate(self.cliente_user)
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.cliente_user})()})
        data = serializer.data

        self.assertTrue(data.get('puede_calificar_proveedor', False),
                       "El cliente debería poder calificar en pedido multi-proveedor entregado")

    def test_pedido_multi_proveedor_no_entregado_no_puede_calificar(self):
        """Cliente NO puede calificar en pedido multi-proveedor si no está entregado."""
        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=None,
            descripcion="Pedido multi-proveedor en camino",
            total=Decimal("25.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.CARRITO,
            estado=EstadoPedido.EN_CAMINO,
        )
        ItemPedido.objects.create(
            pedido=pedido,
            producto=self.prod1,
            cantidad=1,
            precio_unitario=Decimal("10.00"),
        )

        self.client.force_authenticate(self.cliente_user)
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.cliente_user})()})
        data = serializer.data

        self.assertFalse(data.get('puede_calificar_proveedor', False),
                        "No debería poder calificar si el pedido multi-proveedor no está entregado")

    def test_proveedor_no_puede_calificarse_a_si_mismo(self):
        """El proveedor NO puede calificarse a sí mismo en su propio pedido."""
        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=self.proveedor1,
            descripcion="Pedido del proveedor",
            total=Decimal("10.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
        )

        # Autenticar como el mismo proveedor
        self.client.force_authenticate(self.prov1_user)
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.prov1_user})()})
        data = serializer.data

        self.assertFalse(data.get('puede_calificar_proveedor', False),
                        "El proveedor no debería poder calificarse a sí mismo")

    def test_pedido_ya_calificado_no_puede_calificar_nuevamente(self):
        """Cliente NO puede calificar nuevamente si ya calificó al proveedor."""
        from calificaciones.models import Calificacion, TipoCalificacion

        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=self.proveedor1,
            descripcion="Pedido ya calificado",
            total=Decimal("10.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
        )

        # Crear calificación previa
        Calificacion.objects.create(
            pedido=pedido,
            calificador=self.cliente_user,
            calificado=self.prov1_user,
            tipo=TipoCalificacion.CLIENTE_A_PROVEEDOR,
            puntuacion=5,
            comentario="Ya calificado"
        )

        self.client.force_authenticate(self.cliente_user)
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.cliente_user})()})
        data = serializer.data

        self.assertFalse(data.get('puede_calificar_proveedor', False),
                        "No debería poder calificar nuevamente si ya calificó")

    def test_pedido_multi_proveedor_ya_calificado_no_puede_calificar(self):
        """Cliente NO puede calificar nuevamente en pedido multi-proveedor si ya calificó."""
        from calificaciones.models import Calificacion, TipoCalificacion

        pedido = Pedido.objects.create(
            cliente=self.cliente_user.perfil,
            proveedor=None,  # Multi-proveedor
            descripcion="Pedido multi ya calificado",
            total=Decimal("25.00"),
            direccion_entrega="Direccion",
            tipo=TipoPedido.CARRITO,
            estado=EstadoPedido.ENTREGADO,
        )
        ItemPedido.objects.create(
            pedido=pedido,
            producto=self.prod1,
            cantidad=1,
            precio_unitario=Decimal("10.00"),
        )

        # Crear calificación previa para pedido multi-proveedor
        Calificacion.objects.create(
            pedido=pedido,
            calificador=self.cliente_user,
            calificado=self.prov1_user,  # Uno de los proveedores
            tipo=TipoCalificacion.CLIENTE_A_PROVEEDOR,
            puntuacion=4,
            comentario="Ya calificado multi"
        )

        self.client.force_authenticate(self.cliente_user)
        serializer = PedidoDetailSerializer(pedido, context={'request': type('Request', (), {'user': self.cliente_user})()})
        data = serializer.data

        self.assertFalse(data.get('puede_calificar_proveedor', False),
                        "No debería poder calificar nuevamente en pedido multi-proveedor si ya calificó")
