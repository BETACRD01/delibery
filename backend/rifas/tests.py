from datetime import timedelta
from django.utils import timezone
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from rest_framework import status
from rest_framework.test import APITestCase

from pedidos.models import Pedido, EstadoPedido
from .models import Rifa, Premio, EstadoRifa, Participacion

User = get_user_model()


class RifaModelTest(APITestCase):
    """Pruebas de negocio en el modelo Rifa."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.fecha_inicio = timezone.now() - timedelta(days=1)
        self.fecha_fin = timezone.now() + timedelta(days=1)

    def _crear_rifa(self, **kwargs):
        base = dict(
            titulo="Rifa Test",
            descripcion="Descripcion",
            fecha_inicio=self.fecha_inicio,
            fecha_fin=self.fecha_fin,
            pedidos_minimos=3,
            estado=EstadoRifa.ACTIVA,
            creado_por=self.admin,
            mes=self.fecha_inicio.month,
            anio=self.fecha_inicio.year,
        )
        base.update(kwargs)
        return Rifa.objects.create(**base)

    def test_unica_rifa_activa_por_mes(self):
        self._crear_rifa(titulo="Rifa 1")
        with self.assertRaises(ValidationError):
            r2 = Rifa(
                titulo="Rifa 2",
                descripcion="Otra",
                fecha_inicio=self.fecha_inicio,
                fecha_fin=self.fecha_fin,
                pedidos_minimos=2,
                estado=EstadoRifa.ACTIVA,
                creado_por=self.admin,
            )
            r2.full_clean()

    def test_usuario_es_elegible(self):
        rifa = self._crear_rifa()
        cliente = User.objects.create_user(
            email="cliente@app.com",
            username="cliente",
            password="pass123",
            rol_activo=User.RolChoices.CLIENTE,
        )
        # Dos pedidos entregados: no elegible aún
        Pedido.objects.create(
            cliente=cliente.perfil,
            estado=EstadoPedido.ENTREGADO,
            fecha_entregado=self.fecha_inicio + timedelta(hours=1),
            total=10,
        )
        Pedido.objects.create(
            cliente=cliente.perfil,
            estado=EstadoPedido.ENTREGADO,
            fecha_entregado=self.fecha_inicio + timedelta(hours=2),
            total=12,
        )
        eleg = rifa.usuario_es_elegible(cliente)
        self.assertFalse(eleg["elegible"])
        self.assertEqual(eleg["faltantes"], 1)

        # Tercer pedido: ahora elegible
        Pedido.objects.create(
            cliente=cliente.perfil,
            estado=EstadoPedido.ENTREGADO,
            fecha_entregado=self.fecha_inicio + timedelta(hours=3),
            total=8,
        )
        eleg = rifa.usuario_es_elegible(cliente)
        self.assertTrue(eleg["elegible"])
        self.assertEqual(eleg["pedidos"], 3)

    def test_realizar_sorteo_asigna_ganadores(self):
        rifa = self._crear_rifa()
        premio1 = Premio.objects.create(rifa=rifa, posicion=1, descripcion="Premio 1")
        premio2 = Premio.objects.create(rifa=rifa, posicion=2, descripcion="Premio 2")
        premio3 = Premio.objects.create(rifa=rifa, posicion=3, descripcion="Premio 3")

        participantes = []
        for i in range(4):
            u = User.objects.create_user(
                email=f"user{i}@app.com",
                username=f"user{i}",
                password="pass123",
                rol_activo=User.RolChoices.CLIENTE,
            )
            # Cumple pedidos mínimos
            for h in range(3):
                Pedido.objects.create(
                    cliente=u.perfil,
                    estado=EstadoPedido.ENTREGADO,
                    fecha_entregado=self.fecha_inicio + timedelta(hours=h),
                    total=5,
                )
            participantes.append(u)

        resultado = rifa.realizar_sorteo()
        self.assertFalse(resultado["sin_participantes"])
        self.assertEqual(len(resultado["premios_ganados"]), 3)
        # La rifa debe quedar finalizada
        rifa.refresh_from_db()
        self.assertEqual(rifa.estado, EstadoRifa.FINALIZADA)
        # Registrar participaciones como ganadores
        self.assertEqual(Participacion.objects.filter(rifa=rifa, ganador=True).count(), 3)


class RifaAPIViewTest(APITestCase):
    """Pruebas de API para rifas (listado, rifa activa y sorteo admin)."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="password123",
            rol_activo=User.RolChoices.CLIENTE,
        )
        self.client.force_authenticate(self.user)

        self.fecha_inicio = timezone.now() - timedelta(days=1)
        self.fecha_fin = timezone.now() + timedelta(days=1)
        self.rifa = Rifa.objects.create(
            titulo="Rifa API",
            descripcion="Desc",
            fecha_inicio=self.fecha_inicio,
            fecha_fin=self.fecha_fin,
            pedidos_minimos=1,
            estado=EstadoRifa.ACTIVA,
            creado_por=self.admin,
            mes=self.fecha_inicio.month,
            anio=self.fecha_inicio.year,
        )
        self.premio = Premio.objects.create(rifa=self.rifa, posicion=1, descripcion="Premio API")

    def test_listado_requiere_auth(self):
        anon = self.client.__class__()
        url = reverse("rifas:rifa-list")
        res = anon.get(url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listado_authenticated_ok(self):
        url = reverse("rifas:rifa-list")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res.data), 1)

    def test_rifa_activa(self):
        url = reverse("rifas:rifa-activa")
        res = self.client.get(url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data.get("id"), str(self.rifa.id))

    def test_sorteo_restringido_admin(self):
        url = reverse("rifas:rifa-sortear", args=[self.rifa.id])
        res = self.client.post(url, {"confirmar": True}, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        # Como admin
        self.client.force_authenticate(self.admin)
        res_admin = self.client.post(url, {"confirmar": True}, format="json")
        self.assertEqual(res_admin.status_code, status.HTTP_200_OK)
        self.rifa.refresh_from_db()
        self.assertEqual(self.rifa.estado, EstadoRifa.FINALIZADA)
