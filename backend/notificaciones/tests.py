import uuid
from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from pedidos.models import Pedido
from .models import Notificacion, TipoNotificacion

User = get_user_model()


class NotificacionModelTest(APITestCase):
    """Pruebas de dominio del modelo Notificacion y su manager."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
        )
        self.notif = Notificacion.objects.create(
            usuario=self.user,
            titulo="Hola",
            mensaje="Test",
            tipo=TipoNotificacion.SISTEMA,
        )

    def test_marcar_leida(self):
        self.notif.marcar_leida()
        self.notif.refresh_from_db()
        self.assertTrue(self.notif.leida)
        self.assertIsNotNone(self.notif.leida_en)

    def test_manager_no_leidas(self):
        count = Notificacion.objects.contar_no_leidas(self.user)
        self.assertEqual(count, 1)


class NotificacionAPITest(APITestCase):
    """Cobertura básica de endpoints de notificaciones (listado y marcar leídas)."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
        )
        self.notif1 = Notificacion.objects.create(
            usuario=self.user,
            titulo="N1",
            mensaje="Msg1",
            tipo=TipoNotificacion.SISTEMA,
        )
        self.notif2 = Notificacion.objects.create(
            usuario=self.user,
            titulo="N2",
            mensaje="Msg2",
            tipo=TipoNotificacion.PEDIDO,
        )
        self.url_list = reverse("notificaciones:notificacion-list")
        self.url_estadisticas = reverse("notificaciones:notificacion-estadisticas")

    def test_listado_requiere_auth(self):
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listado_autenticado(self):
        self.client.force_authenticate(self.user)
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        if isinstance(res.data, dict) and 'results' in res.data:
            self.assertIsInstance(res.data['results'], list)
            ids = [n["id"] for n in res.data['results']]
        else:
            self.assertIsInstance(res.data, list)
            ids = [n["id"] for n in res.data] if isinstance(res.data, list) else []
        self.assertIn(str(self.notif1.id), ids)
        self.assertIn(str(self.notif2.id), ids)

    def test_marcar_todas_leidas(self):
        self.client.force_authenticate(self.user)
        url = reverse("notificaciones:notificacion-marcar-todas-leidas")
        res = self.client.post(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.notif1.refresh_from_db()
        self.notif2.refresh_from_db()
        self.assertTrue(self.notif1.leida)
        self.assertTrue(self.notif2.leida)

    def test_estadisticas(self):
        self.client.force_authenticate(self.user)
        res = self.client.get(self.url_estadisticas)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("no_leidas", res.data)
