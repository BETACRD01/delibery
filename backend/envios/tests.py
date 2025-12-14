# envios/tests.py
from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status
from decimal import Decimal
from unittest.mock import patch, MagicMock

from .services import CalculadoraEnvioService

User = get_user_model()

class CalculadoraServiceTest(TestCase):
    """
    Pruebas unitarias para la lógica de cálculo de precios.
    Usamos @patch para NO llamar a Google Maps realmente (ahorra dinero y es más rápido).
    """

    def setUp(self):
        # Coordenadas de prueba cercanas a Baños
        self.destino_banos = (-1.3964, -78.4247)
        # Coordenadas cercanas a Tena
        self.destino_tena = (-0.9938, -77.8129)

    @patch('envios.services.googlemaps.Client')
    def test_calculo_distancia_corta(self, mock_gmaps):
        """
        Caso: Distancia menor a 1.5km (Solo Tarifa Base).
        """
        mock_client = MagicMock()
        mock_gmaps.return_value = mock_client
        
        # Google devuelve 1000 metros (1.0 km)
        mock_client.distance_matrix.return_value = {
            'status': 'OK',
            'rows': [{'elements': [{'status': 'OK', 'distance': {'value': 1000}, 'duration': {'value': 600}}]}]
        }

        resultado = CalculadoraEnvioService.cotizar_envio(
            lat_destino=self.destino_banos[0],
            lng_destino=self.destino_banos[1],
            tipo_servicio='delivery'
        )

        # 1.0 km es menor a 1.5km, así que solo paga base ($1.50)
        self.assertEqual(resultado['costo_base'], 1.50)
        self.assertEqual(resultado['costo_km_extra'], 0.00)
        self.assertEqual(resultado['total_envio'], 1.50)

    @patch('envios.services.googlemaps.Client')
    def test_calculo_distancia_larga(self, mock_gmaps):
        """
        Caso: Distancia de 10km (Base + KM extras).
        """
        mock_client = MagicMock()
        mock_gmaps.return_value = mock_client
        
        # Google devuelve 10,000 metros (10 km)
        mock_client.distance_matrix.return_value = {
            'status': 'OK',
            'rows': [{'elements': [{'status': 'OK', 'distance': {'value': 10000}, 'duration': {'value': 1200}}]}]
        }

        resultado = CalculadoraEnvioService.cotizar_envio(
            lat_destino=self.destino_banos[0],
            lng_destino=self.destino_banos[1]
        )

        # Cálculo esperado:
        # Base: $1.50 (cubre 1.5km)
        # Extra: 8.5km * $0.60 = $5.10
        # Total: $6.60
        self.assertEqual(resultado['distancia_km'], 10.00)
        self.assertEqual(resultado['costo_km_extra'], 5.10)
        self.assertEqual(resultado['total_envio'], 6.60)

    @patch('envios.services.googlemaps.Client')
    @patch('envios.services.CalculadoraEnvioService._es_horario_nocturno')
    def test_recargo_nocturno(self, mock_es_nocturno, mock_gmaps):
        """
        Caso: Es de noche, debe sumar el recargo.
        """
        mock_es_nocturno.return_value = True 
        
        mock_client = MagicMock()
        mock_gmaps.return_value = mock_client
        mock_client.distance_matrix.return_value = {
            'status': 'OK',
            'rows': [{'elements': [{'status': 'OK', 'distance': {'value': 1000}, 'duration': {'value': 600}}]}]
        }

        resultado = CalculadoraEnvioService.cotizar_envio(
            lat_destino=self.destino_banos[0],
            lng_destino=self.destino_banos[1]
        )

        # Base ($1.50) + Nocturno ($1.00) = $2.50
        self.assertEqual(resultado['recargo_nocturno'], 1.00)
        self.assertEqual(resultado['total_envio'], 2.50)
        self.assertTrue(resultado['es_horario_nocturno'])

    def test_deteccion_hub_banos(self):
        """
        Caso: Cliente cerca de Baños debe usar hub de Baños.
        """
        # Coordenadas muy cercanas al centro de Baños
        lat_cerca_banos = -1.3970
        lng_cerca_banos = -78.4250
        
        hub = CalculadoraEnvioService._detectar_hub_mas_cercano(lat_cerca_banos, lng_cerca_banos)
        
        self.assertEqual(hub['nombre'], 'Baños de Agua Santa')
        self.assertEqual(hub['lat'], -1.3964)

    def test_deteccion_hub_tena(self):
        """
        Caso: Cliente cerca de Tena debe usar hub de Tena.
        """
        # Coordenadas muy cercanas al centro de Tena
        lat_cerca_tena = -0.9940
        lng_cerca_tena = -77.8130
        
        hub = CalculadoraEnvioService._detectar_hub_mas_cercano(lat_cerca_tena, lng_cerca_tena)
        
        self.assertEqual(hub['nombre'], 'Tena')
        self.assertEqual(hub['lat'], -0.9938)

    @patch('envios.services.googlemaps.Client')
    def test_fallback_cuando_gmaps_falla(self, mock_gmaps):
        """
        Caso: Si Google Maps falla, debe usar cálculo Haversine.
        """
        mock_client = MagicMock()
        mock_gmaps.return_value = mock_client
        
        # Simulamos que Google Maps devuelve error
        mock_client.distance_matrix.return_value = {
            'status': 'REQUEST_DENIED'
        }

        resultado = CalculadoraEnvioService.cotizar_envio(
            lat_destino=self.destino_banos[0],
            lng_destino=self.destino_banos[1]
        )

        # Debe haber calculado algo (no 0)
        # El cálculo Haversine entre el centro de Baños y el mismo punto da ~0
        # Usemos coordenadas ligeramente diferentes
        resultado = CalculadoraEnvioService.cotizar_envio(
            lat_destino=-1.4000,  # 4km aprox del centro
            lng_destino=-78.4300
        )
        
        self.assertGreater(resultado['distancia_km'], 0)
        # El método debe indicar que usó estimación
        self.assertIn('Estimación', resultado['metodo_calculo'])

    @patch('envios.services.googlemaps.Client')
    def test_validacion_cobertura_maxima(self, mock_gmaps):
        """
        Caso: Si la distancia excede el radio de cobertura, debe advertir.
        """
        mock_client = MagicMock()
        mock_gmaps.return_value = mock_client
        
        # Simulamos distancia muy larga (50km)
        mock_client.distance_matrix.return_value = {
            'status': 'OK',
            'rows': [{'elements': [{'status': 'OK', 'distance': {'value': 50000}, 'duration': {'value': 3600}}]}]
        }

        resultado = CalculadoraEnvioService.cotizar_envio(
            lat_destino=self.destino_banos[0],
            lng_destino=self.destino_banos[1]
        )

        # Verificar que se calculó la distancia
        self.assertEqual(resultado['distancia_km'], 50.0)
        
        # Verificar si excede cobertura (Baños tiene radio de 15km)
        self.assertGreater(resultado['distancia_km'], 15.0)
        
        # Debe existir advertencia
        self.assertIn('advertencia', resultado)
        self.assertIn('fuera del radio', resultado['advertencia'].lower())


class CotizarEnvioViewTest(TestCase):
    """
    Pruebas de integración para el Endpoint (API).
    Verifica que la URL responda y valide datos.
    """

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='test@app.com', 
            username='testuser',
            password='password123'
        )
        # Configurar el cliente con autenticación forzada para TODOS los tests
        self.client.force_authenticate(user=self.user)
        self.url = reverse('envios:cotizar_envio')

    def test_acceso_sin_token(self):
        """Intento de acceso sin login debe fallar (401 o 403)"""
        # Crear un cliente SIN autenticación para este test específico
        client_sin_auth = APIClient()
        response = client_sin_auth.post(self.url, {})
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    @patch('envios.views.CalculadoraEnvioService.cotizar_envio')
    def test_cotizacion_exitosa(self, mock_servicio):
        """
        Petición válida con token debe devolver 200 OK y datos.
        """
        # Ya está autenticado desde setUp

        mock_servicio.return_value = {
            'distancia_km': 5.0,
            'tiempo_mins': 15,
            'costo_base': 1.50,
            'costo_km_extra': 2.10,
            'recargo_nocturno': 0.0,
            'total_envio': 3.60,
            'origen_referencia': 'Centro de Baños de Agua Santa',
            'es_horario_nocturno': False,
            'metodo_calculo': 'Google Maps API'
        }

        data = {
            "lat_destino": -1.3970,
            "lng_destino": -78.4250,
            "tipo_servicio": "delivery"
        }

        response = self.client.post(self.url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_envio'], 3.60)
        self.assertEqual(response.data['distancia_km'], 5.0)

    def test_datos_incompletos(self):
        """Faltan coordenadas, debe dar error 400"""
        # Ya está autenticado desde setUp
        
        response = self.client.post(self.url, {}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('lat_destino', response.data)
        self.assertIn('lng_destino', response.data)

    def test_coordenadas_invalidas(self):
        """Coordenadas fuera de rango deben dar error 400"""
        # Ya está autenticado desde setUp
        
        data = {
            "lat_destino": 999.0,  # Latitud inválida
            "lng_destino": -78.4250,
        }
        
        response = self.client.post(self.url, data, format='json')
        
        # Debe ser 400 por validación del serializer
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)