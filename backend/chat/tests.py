import uuid
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.exceptions import ValidationError
from rest_framework import status
from rest_framework.test import APITestCase

from pedidos.models import Pedido, EstadoPedido
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from productos.models import Categoria, Producto
from .models import Chat, Mensaje, TipoChat, TipoMensaje

User = get_user_model()


class ChatModelTest(APITestCase):
    """Pruebas de dominio para Chat y Mensaje."""

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
            estado=EstadoPedido.ASIGNADO_REPARTIDOR,
        )

    def test_crear_chats_para_pedido(self):
        chats = Chat.crear_chats_para_pedido(self.pedido)
        self.assertIn("cliente_repartidor", chats)
        self.assertIn("proveedor_repartidor", chats)
        self.assertEqual(chats["cliente_repartidor"].participantes.count(), 2)
        self.assertEqual(chats["proveedor_repartidor"].participantes.count(), 2)

    def test_crear_chat_sin_pedido_lanza_error(self):
        pedido_sin_rep = Pedido.objects.create(
            cliente=self.user_cliente.perfil,
            proveedor=self.proveedor,
            descripcion="Sin rep",
            total=5,
            direccion_entrega="Dir",
        )
        with self.assertRaises(ValidationError):
            Chat.crear_chats_para_pedido(pedido_sin_rep)

    def test_mensajes_no_leidos(self):
        chat = Chat.objects.create(tipo=TipoChat.SOPORTE, proveedor=self.proveedor)
        chat.participantes.add(self.user_prov, self.user_rep)
        Mensaje.objects.create(chat=chat, remitente=self.user_prov, tipo=TipoMensaje.TEXTO, contenido="Hola")
        self.assertEqual(chat.contar_no_leidos(self.user_rep), 1)
        chat.marcar_todos_como_leidos(self.user_rep)
        self.assertEqual(chat.contar_no_leidos(self.user_rep), 0)


class ChatAPITest(APITestCase):
    """Smoke tests de endpoints de chat (listado y creación de mensaje)."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
        )
        self.user_prov = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user_prov,
            nombre="Proveedor Chat",
            ruc="0999999999002",
            telefono="+593999999999",
            email="prov@app.com",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )
        self.client.force_authenticate(self.user)
        self.chat = Chat.objects.create(tipo=TipoChat.SOPORTE, proveedor=self.proveedor)
        self.chat.participantes.add(self.user, self.user_prov)
        self.url_list = reverse("chat:chat-list")

    def test_listado_requiere_auth(self):
        anon = self.client.__class__()
        res = anon.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listado_autenticado(self):
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        if isinstance(res.data, dict):
            chats = res.data.get('results') or res.data.get('chats') or []
        else:
            chats = res.data
        ids = [c["id"] for c in chats]
        self.assertIn(str(self.chat.id), ids)
