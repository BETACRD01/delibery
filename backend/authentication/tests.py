from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class AuthenticationAPITest(APITestCase):
    """Pruebas básicas de registro y login."""

    def setUp(self):
        self.register_url = reverse("authentication:registro")
        self.login_url = reverse("authentication:login")

    def test_registro_exitoso(self):
        payload = {
            "first_name": "Juan",
            "last_name": "Perez",
            "username": "juanp",
            "email": "juan@app.com",
            "celular": "+593999999999",
            "password": "Passw0rd!",
            "password2": "Passw0rd!",
            "terminos_aceptados": True,
            "notificaciones_email": True,
            "notificaciones_marketing": False,
            "notificaciones_push": True,
        }
        res = self.client.post(self.register_url, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(email="juan@app.com").exists())

    def test_registro_email_duplicado(self):
        User.objects.create_user(
            first_name="A",
            last_name="B",
            username="existente",
            email="dup@app.com",
            celular="+593988888888",
            password="Passw0rd!",
        )
        payload = {
            "first_name": "Juan",
            "last_name": "Perez",
            "username": "juanp2",
            "email": "dup@app.com",
            "celular": "+593999999999",
            "password": "Passw0rd!",
            "password2": "Passw0rd!",
            "terminos_aceptados": True,
        }
        res = self.client.post(self.register_url, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", res.data)

    def test_login_exitoso(self):
        user = User.objects.create_user(
            first_name="A",
            last_name="B",
            username="loginuser",
            email="login@app.com",
            celular="+593911111111",
            password="Passw0rd!",
        )
        payload = {
            "identificador": "login@app.com",
            "password": "Passw0rd!",
        }
        res = self.client.post(self.login_url, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("tokens", res.data)

    def test_login_credenciales_invalidas(self):
        payload = {
            "identificador": "noexiste@app.com",
            "password": "wrong",
        }
        res = self.client.post(self.login_url, payload, format="json")
        self.assertIn(res.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_401_UNAUTHORIZED])
