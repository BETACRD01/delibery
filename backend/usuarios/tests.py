# usuarios/tests.py
from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

User = get_user_model()


class PerfilEndpointsTest(TestCase):
    """
    Cobertura básica de los endpoints de perfil de usuario.
    Validamos autenticación, obtención y actualización con validaciones clave.
    """

    def setUp(self):
        self.user = User.objects.create_user(
            email="demo@app.com",
            username="demo",
            password="password123",
            celular="0991234567",
            first_name="Demo",
            last_name="User",
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.url_perfil = reverse("usuarios:obtener_perfil")
        self.url_actualizar = reverse("usuarios:actualizar_perfil")

    def test_obtener_perfil_requiere_auth(self):
        """Sin autenticación debe devolver 401/403."""
        anon = APIClient()
        response = anon.get(self.url_perfil)
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_obtener_perfil_ok(self):
        """Con autenticación devuelve el perfil del usuario."""
        response = self.client.get(self.url_perfil)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("perfil", response.data)
        self.assertEqual(response.data["perfil"]["usuario_email"], self.user.email)

    def test_actualizar_perfil_telefono_invalido(self):
        """Valida regex de celular (debe empezar con 09 y tener 10 dígitos)."""
        payload = {"telefono": "12345"}  # Inválido
        response = self.client.patch(self.url_actualizar, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("telefono", response.data.get("detalles", {}))

    def test_actualizar_perfil_email_duplicado(self):
        """No permite actualizar el correo a uno que ya existe en otro usuario."""
        other = User.objects.create_user(
            email="ocupado@app.com",
            username="other",
            password="password123",
            celular="0997654321",
        )
        payload = {"email": other.email}
        response = self.client.patch(self.url_actualizar, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", response.data.get("detalles", {}))

    def test_actualizar_perfil_ok(self):
        """Actualiza nombre y preferencias cuando los datos son válidos."""
        payload = {
            "first_name": "Nuevo",
            "last_name": "Nombre",
            "notificaciones_pedido": False,
        }
        response = self.client.patch(self.url_actualizar, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get("perfil", {}).get("usuario_nombre"), "Nuevo Nombre")
        # Preferencia debe reflejar el cambio
        self.assertFalse(response.data.get("perfil", {}).get("notificaciones_pedido"))
