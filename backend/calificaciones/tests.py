from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from pedidos.models import Pedido, EstadoPedido
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from productos.models import Categoria, Producto
from .models import Calificacion, TipoCalificacion

User = get_user_model()


class CalificacionModelTest(APITestCase):
    """Pruebas de negocio para Calificacion y su manager."""

    def setUp(self):
        self.user_cliente = User.objects.create_user(
            email="cliente@app.com",
            username="cliente",
            password="password123",
            rol_activo=User.RolChoices.CLIENTE,
        )
        self.user_rep = User.objects.create_user(
            email="rep@app.com",
            username="rep",
            password="password123",
            rol_activo=User.RolChoices.REPARTIDOR,
        )
        self.rep = Repartidor.objects.create(
            user=self.user_rep,
            cedula="0102030405",
            telefono="0999999999",
            verificado=True,
            activo=True,
        )
        self.user_prov = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user_prov,
            nombre="Proveedor",
            ruc="0999999999001",
            telefono="+593999999999",
            email="prov@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )
        self.cat = Categoria.objects.create(nombre="Bebidas", activo=True)
        self.prod = Producto.objects.create(
            proveedor=self.proveedor,
            categoria=self.cat,
            nombre="Prod",
            descripcion="Desc",
            precio=10.00,
            disponible=True,
            tiene_stock=True,
            stock=5,
        )
        self.pedido = Pedido.objects.create(
            cliente=self.user_cliente.perfil,
            proveedor=self.proveedor,
            repartidor=self.rep,
            descripcion="Pedido",
            total=10,
            direccion_entrega="Dir",
            estado=EstadoPedido.ENTREGADO,
        )

    def test_calificacion_por_tipo_y_pedido_incrementa(self):
        otro_pedido = Pedido.objects.create(
            cliente=self.user_cliente.perfil,
            proveedor=self.proveedor,
            repartidor=self.rep,
            descripcion="Pedido 2",
            total=12,
            direccion_entrega="Dir2",
            estado=EstadoPedido.ENTREGADO,
        )
        Calificacion.objects.create(
            pedido=self.pedido,
            calificador=self.user_cliente,
            calificado=self.user_rep,
            tipo=TipoCalificacion.CLIENTE_A_REPARTIDOR,
            estrellas=5,
        )
        Calificacion.objects.create(
            pedido=otro_pedido,
            calificador=self.user_cliente,
            calificado=self.user_rep,
            tipo=TipoCalificacion.CLIENTE_A_REPARTIDOR,
            estrellas=4,
        )
        self.assertEqual(Calificacion.objects.count(), 2)

    def test_promedio_usuario(self):
        otro_pedido = Pedido.objects.create(
            cliente=self.user_cliente.perfil,
            proveedor=self.proveedor,
            repartidor=self.rep,
            descripcion="Pedido 2",
            total=12,
            direccion_entrega="Dir2",
            estado=EstadoPedido.ENTREGADO,
        )
        Calificacion.objects.create(
            pedido=self.pedido,
            calificador=self.user_cliente,
            calificado=self.user_rep,
            tipo=TipoCalificacion.CLIENTE_A_REPARTIDOR,
            estrellas=4,
        )
        Calificacion.objects.create(
            pedido=otro_pedido,
            calificador=self.user_cliente,
            calificado=self.user_rep,
            tipo=TipoCalificacion.CLIENTE_A_REPARTIDOR,
            estrellas=5,
        )
        stats = Calificacion.objects.promedio_usuario(self.user_rep)
        self.assertEqual(stats["promedio"], 4.5)
        self.assertEqual(stats["total_resenas"], 2)


class CalificacionAPITest(APITestCase):
    """Pruebas básicas de API para calificaciones."""

    def setUp(self):
        self.user_cliente = User.objects.create_user(
            email="cliente@app.com",
            username="cliente",
            password="password123",
            rol_activo=User.RolChoices.CLIENTE,
        )
        self.client.force_authenticate(self.user_cliente)
        self.user_rep = User.objects.create_user(
            email="rep@app.com",
            username="rep",
            password="password123",
            rol_activo=User.RolChoices.REPARTIDOR,
        )
        self.rep = Repartidor.objects.create(
            user=self.user_rep,
            cedula="0102030405",
            telefono="0999999999",
            verificado=True,
            activo=True,
        )
        self.user_prov = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user_prov,
            nombre="Proveedor",
            ruc="0999999999001",
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
            nombre="Prod",
            descripcion="Desc",
            precio=5.00,
            disponible=True,
            tiene_stock=True,
            stock=5,
        )
        self.pedido = Pedido.objects.create(
            cliente=self.user_cliente.perfil,
            proveedor=self.proveedor,
            repartidor=self.rep,
            descripcion="Pedido",
            total=5,
            direccion_entrega="Dir",
            estado=EstadoPedido.ENTREGADO,
        )
        self.url_list = reverse("calificaciones:calificacion-list")

    def test_listado_requiere_auth(self):
        anon = self.client.__class__()
        res = anon.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_crear_calificacion_cliente_a_repartidor(self):
        payload = {
            "pedido_id": self.pedido.id,
            "tipo": TipoCalificacion.CLIENTE_A_REPARTIDOR,
            "estrellas": 5,
        }
        res = self.client.post(self.url_list, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Calificacion.objects.count(), 1)
