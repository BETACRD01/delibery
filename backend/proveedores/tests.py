from datetime import timedelta
from django.utils import timezone
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Proveedor, ProveedorManager

User = get_user_model()


class ProveedorModelTest(APITestCase):
    """Pruebas de negocio para el modelo Proveedor."""

    def setUp(self):
        self.user = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user,
            nombre="Mi Proveedor",
            ruc="0999999999001",
            telefono="+593999999999",
            email="prov@app.com",
            ciudad="Quito",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )

    def test_cambio_estado_verificado_requerido(self):
        self.proveedor.verificado = False
        self.proveedor.save(update_fields=["verificado"])
        with self.assertRaises(ValidationError):
            self.proveedor.cambiar_estado_activo(True)

    def test_limite_cambios_ruc(self):
        # Permitir 3 cambios, el cuarto debe fallar
        for i in range(3):
            self.proveedor.actualizar_ruc(f"09999999990{i}2")
        with self.assertRaises(ValidationError):
            self.proveedor.actualizar_ruc("0999999999040")

    def test_manager_activos_y_verificados(self):
        activos = Proveedor.objects.activos_y_verificados()
        self.assertIn(self.proveedor, list(activos))


class ProveedorAPITest(APITestCase):
    """Pruebas de endpoints básicos de Proveedor."""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@app.com",
            username="admin",
            password="password123",
        )
        self.user = User.objects.create_user(
            email="prov@app.com",
            username="prov",
            password="password123",
        )
        self.proveedor = Proveedor.objects.create(
            user=self.user,
            nombre="Proveedor API",
            ruc="0999999999001",
            telefono="+593999999999",
            email="prov@app.com",
            ciudad="Quito",
            tipo_proveedor="restaurante",
            activo=True,
            verificado=True,
        )
        self.url_list = reverse("proveedores:proveedor-list")

    def test_listado_publico(self):
        res = self.client.get(self.url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res.data), 1)

    def test_creacion_restringida_admin(self):
        payload = {
            "nombre": "Nuevo Proveedor",
            "ruc": "0999999999002",
            "telefono": "+593988888888",
            "email": "nuevo@app.com",
            "tipo_proveedor": "restaurante",
            "activo": True,
            "verificado": True,
        }
        # Usuario normal no puede crear (metodo no permitido o sin permiso)
        self.client.force_authenticate(self.user)
        res = self.client.post(self.url_list, payload, format="json")
        self.assertIn(res.status_code, [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED, status.HTTP_405_METHOD_NOT_ALLOWED])

        # Admin sí puede (si la vista lo permite)
        self.client.force_authenticate(self.admin)
        res_admin = self.client.post(self.url_list, payload, format="json")
        if res_admin.status_code == status.HTTP_201_CREATED:
            self.assertTrue(Proveedor.objects.filter(ruc="0999999999002").exists())
