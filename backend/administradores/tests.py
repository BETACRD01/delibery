from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.db.models.signals import pre_save, post_save
from rest_framework import status
from rest_framework.test import APIRequestFactory, force_authenticate, APITestCase

from notificaciones import signals as notif_signals
from usuarios.models import Perfil
from .models import Administrador, AccionAdministrativa, ConfiguracionSistema
from .views import GestionUsuariosViewSet, registrar_accion_admin


class AdministradoresLogicTests(TestCase):
    """
    Pruebas focalizadas en lógica de administradores:
    - Creación de configuración sin admin asignado.
    - Registro de acciones con/ sin perfil admin.
    - Cambio de rol usa rol_activo/roles_aprobados.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Evitar efectos colaterales de notificaciones durante pruebas (si existen)
        try:
            pre_save.disconnect(notif_signals.detectar_cambio_estado_pedido, dispatch_uid=None)
        except AttributeError:
            pass
        try:
            post_save.disconnect(notif_signals.enviar_notificacion_cambio_estado, dispatch_uid=None)
        except AttributeError:
            pass

    @classmethod
    def tearDownClass(cls):
        # Reconectar señales si existen
        try:
            pre_save.connect(notif_signals.detectar_cambio_estado_pedido, dispatch_uid=None)
        except AttributeError:
            pass
        try:
            post_save.connect(notif_signals.enviar_notificacion_cambio_estado, dispatch_uid=None)
        except AttributeError:
            pass
        super().tearDownClass()

    def setUp(self):
        self.factory = APIRequestFactory()
        User = get_user_model()

        # Admin operativo con perfil
        self.user_admin = User.objects.create_user(
            email="admin@example.com",
            username="admin",
            password="admin123",
            first_name="Ad",
            last_name="Min",
            celular="+593999000000",
            is_staff=True,
        )
        Perfil.objects.get_or_create(user=self.user_admin)
        # Perfil admin puede existir por migraciones/fixtures, aseguramos obtener o crear
        self.perfil_admin, _ = Administrador.objects.get_or_create(
            user=self.user_admin,
            defaults={
                "puede_gestionar_usuarios": True,
                "puede_configurar_sistema": True,
            },
        )

        # Usuario regular
        self.user_cliente = User.objects.create_user(
            email="cliente@example.com",
            username="cliente",
            password="cliente123",
            first_name="Cli",
            last_name="Ente",
            celular="+593988888888",
        )
        Perfil.objects.get_or_create(user=self.user_cliente)

    def test_configuracion_sistema_puede_guardar_sin_modificador(self):
        cfg = ConfiguracionSistema.obtener()
        self.assertEqual(cfg.pk, 1)
        self.assertIsNone(cfg.modificado_por)

    def test_registrar_accion_requiere_perfil_admin(self):
        # Usuario regular sin perfil admin no registra acción
        from django.contrib.auth import get_user_model
        user_regular = get_user_model().objects.create_user(
            email="regular@example.com",
            username="regular",
            password="regular123",
            is_staff=False,
            first_name="Reg",
            last_name="User",
            celular="+593977777777",
        )
        Perfil.objects.get_or_create(user=user_regular)
        request = self.factory.get("/admin/accion")
        request.user = user_regular

        accion = registrar_accion_admin(request, "editar_usuario", "prueba sin perfil")
        self.assertIsNone(accion)
        self.assertEqual(AccionAdministrativa.objects.count(), 0)

    def test_registrar_accion_con_perfil_admin(self):
        request = self.factory.get("/admin/accion")
        request.user = self.user_admin
        accion = registrar_accion_admin(
            request,
            "editar_usuario",
            "probando registro",
            modelo_afectado="User",
            objeto_id="1",
        )
        self.assertIsNotNone(accion)
        self.assertEqual(AccionAdministrativa.objects.count(), 1)

    def test_cambiar_rol_actualiza_rol_activo(self):
        view = GestionUsuariosViewSet.as_view({"post": "cambiar_rol"})
        data = {"nuevo_rol": "proveedor", "motivo": "test"}
        request = self.factory.post(
            f"/api/admin/usuarios/{self.user_cliente.pk}/cambiar_rol/",
            data,
            format="json",
        )
        force_authenticate(request, user=self.user_admin)

        response = view(request, pk=self.user_cliente.pk)
        self.assertEqual(response.status_code, 200)

        self.user_cliente.refresh_from_db()
        self.assertEqual(self.user_cliente.rol_activo, "proveedor")
        self.assertIn("proveedor", self.user_cliente.roles_aprobados)

    def test_resetear_password_por_admin(self):
        view = GestionUsuariosViewSet.as_view({"post": "resetear_password"})
        data = {"nueva_password": "NuevaPass123", "confirmar_password": "NuevaPass123"}
        request = self.factory.post(
            f"/api/admin/usuarios/{self.user_cliente.pk}/resetear_password/",
            data,
            format="json",
        )
        force_authenticate(request, user=self.user_admin)

        response = view(request, pk=self.user_cliente.pk)
        self.assertEqual(response.status_code, 200)

        # La contraseña debe validar con check_password
        self.user_cliente.refresh_from_db()
        self.assertTrue(self.user_cliente.check_password("NuevaPass123"))


class AdministradoresAPIPermissionsTest(APITestCase):
    """
    Cobertura ligera de permisos de endpoints admin:
    - Listado de usuarios y administradores bloquea a no staff.
    - Configuración de sistema accesible para staff.
    """

    def setUp(self):
        User = get_user_model()
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="admin123",
            first_name="Ad",
            last_name="Min",
            celular="+593999000000",
        )
        self.user = User.objects.create_user(
            email="user@app.com",
            username="user",
            password="user123",
            first_name="User",
            last_name="Test",
            celular="+593988888888",
        )
        self.url_users = reverse("administradores:admin-usuarios-list")
        self.url_admins = reverse("administradores:admin-administradores-list")
        self.url_config = reverse("administradores:admin-configuracion")

    def test_listados_bloquean_a_no_admin(self):
        self.client.force_authenticate(self.user)
        res_users = self.client.get(self.url_users)
        res_admins = self.client.get(self.url_admins)
        self.assertIn(res_users.status_code, [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED])
        self.assertIn(res_admins.status_code, [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED])

    def test_listados_permiten_admin(self):
        self.client.force_authenticate(self.admin)
        res_users = self.client.get(self.url_users)
        res_admins = self.client.get(self.url_admins)
        self.assertEqual(res_users.status_code, status.HTTP_200_OK)
        self.assertEqual(res_admins.status_code, status.HTTP_200_OK)

    def test_configuracion_disponible_para_admin(self):
        self.client.force_authenticate(self.admin)
        res = self.client.get(self.url_config)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
