from datetime import timedelta
from django.utils import timezone
from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from pedidos.models import Pedido, EstadoPedido, TipoPedido
from proveedores.models import Proveedor
from repartidores.models import Repartidor
from usuarios.models import Perfil

User = get_user_model()


class ReporteAdminAPITest(APITestCase):
    """Pruebas básicas del reporte admin: auth y estadísticas."""

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
        )
        self.url_list = reverse("reportes:reporte-admin-list")
        self.url_estadisticas = reverse("reportes:reporte-admin-estadisticas")

    def test_listado_requiere_admin(self):
        # Usuario normal autenticado
        self.client.force_authenticate(self.user)
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        # Admin puede listar (aunque no haya pedidos)
        self.client.force_authenticate(self.admin)
        res_admin = self.client.get(self.url_list)
        self.assertEqual(res_admin.status_code, status.HTTP_200_OK)

    def test_estadisticas_requiere_admin(self):
        self.client.force_authenticate(self.user)
        res = self.client.get(self.url_estadisticas)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        self.client.force_authenticate(self.admin)
        res_admin = self.client.get(self.url_estadisticas)
        self.assertEqual(res_admin.status_code, status.HTTP_200_OK)
        self.assertIn("total_pedidos", res_admin.data)


class ReporteProveedorAPITest(APITestCase):
    """Verifica que un proveedor vea solo sus pedidos y no los de otros."""

    def setUp(self):
        # Usuarios
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.user_prov = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.user_prov.roles_aprobados = ['proveedor']
        self.user_prov.rol_activo = 'proveedor'
        self.user_prov.save(update_fields=['roles_aprobados', 'rol_activo'])
        self.user_otro = User.objects.create_user(
            email="otro@app.com",
            username="otro",
            password="password123",
        )
        self.user_otro.roles_aprobados = ['proveedor']
        self.user_otro.rol_activo = 'proveedor'
        self.user_otro.save(update_fields=['roles_aprobados', 'rol_activo'])

        # Proveedores
        self.proveedor = Proveedor.objects.create(
            user=self.user_prov,
            nombre="Mi Proveedor",
            ruc="0999999999001",
            tipo_proveedor="restaurante",
            latitud=0,
            longitud=0,
            activo=True,
        )
        self.otro_proveedor = Proveedor.objects.create(
            user=self.user_otro,
            nombre="Otro",
            ruc="1799999999001",
            tipo_proveedor="restaurante",
            latitud=0,
            longitud=0,
            activo=True,
        )

        # Pedidos
        self.pedido_mio = Pedido.objects.create(
            cliente=self.user_prov.perfil,
            proveedor=self.proveedor,
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
            total=20,
            creado_en=timezone.now(),
        )
        self.pedido_otro = Pedido.objects.create(
            cliente=self.user_otro.perfil,
            proveedor=self.otro_proveedor,
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
            total=15,
            creado_en=timezone.now(),
        )

        self.url_list = reverse("reportes:reporte-proveedor-list")

    def test_proveedor_ve_solo_sus_pedidos(self):
        self.client.force_authenticate(self.user_prov)
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        if isinstance(res.data, dict) and 'results' in res.data:
            ids = [p["id"] for p in res.data['results']]
        else:
            ids = [p["id"] for p in res.data]
        self.assertIn(self.pedido_mio.id, ids)
        self.assertNotIn(self.pedido_otro.id, ids)

    def test_proveedor_bloqueado_para_otro(self):
        self.client.force_authenticate(self.user_otro)
        res = self.client.get(self.url_list)
        if isinstance(res.data, dict) and 'results' in res.data:
            ids = [p["id"] for p in res.data['results']]
        else:
            ids = [p["id"] for p in res.data]
        self.assertIn(self.pedido_otro.id, ids)
        self.assertNotIn(self.pedido_mio.id, ids)

    def test_admin_puede_ver_todo(self):
        self.client.force_authenticate(self.admin)
        res = self.client.get(self.url_list)
        if isinstance(res.data, dict) and 'results' in res.data:
            ids = [p["id"] for p in res.data['results']]
        else:
            ids = [p["id"] for p in res.data]
        self.assertIn(self.pedido_mio.id, ids)
        self.assertIn(self.pedido_otro.id, ids)


class ReporteRepartidorAPITest(APITestCase):
    """Verifica que el repartidor vea solo sus entregas."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.user_rep = User.objects.create_user(
            email="rep@app.com",
            username="rep",
            password="password123",
        )
        self.user_rep.roles_aprobados = ['repartidor']
        self.user_rep.rol_activo = 'repartidor'
        self.user_rep.save(update_fields=['roles_aprobados', 'rol_activo'])
        self.user_otro = User.objects.create_user(
            email="otro@app.com",
            username="otro",
            password="password123",
        )
        self.user_otro.roles_aprobados = ['repartidor']
        self.user_otro.rol_activo = 'repartidor'
        self.user_otro.save(update_fields=['roles_aprobados', 'rol_activo'])

        self.repartidor = Repartidor.objects.create(
            user=self.user_rep,
            cedula="1111111111",
            telefono="0999999999",
            verificado=True,
            activo=True,
        )
        self.otro_repartidor = Repartidor.objects.create(
            user=self.user_otro,
            cedula="2222222222",
            telefono="0988888888",
            verificado=True,
            activo=True,
        )

        self.pedido_mio = Pedido.objects.create(
            cliente=self.user_rep.perfil,
            repartidor=self.repartidor,
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
            total=30,
            creado_en=timezone.now(),
        )
        self.pedido_otro = Pedido.objects.create(
            cliente=self.user_otro.perfil,
            repartidor=self.otro_repartidor,
            tipo=TipoPedido.PROVEEDOR,
            estado=EstadoPedido.ENTREGADO,
            total=25,
            creado_en=timezone.now(),
        )

        self.url_list = reverse("reportes:reporte-repartidor-list")

    def test_repartidor_ve_solo_sus_entregas(self):
        self.client.force_authenticate(self.user_rep)
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        if isinstance(res.data, dict) and 'results' in res.data:
            ids = [p["id"] for p in res.data['results']]
        else:
            ids = [p["id"] for p in res.data]
        self.assertIn(self.pedido_mio.id, ids)
        self.assertNotIn(self.pedido_otro.id, ids)

    def test_admin_puede_ver_todo(self):
        self.client.force_authenticate(self.admin)
        res = self.client.get(self.url_list)
        if isinstance(res.data, dict) and 'results' in res.data:
            ids = [p["id"] for p in res.data['results']]
        else:
            ids = [p["id"] for p in res.data]
        self.assertIn(self.pedido_mio.id, ids)
        self.assertIn(self.pedido_otro.id, ids)
