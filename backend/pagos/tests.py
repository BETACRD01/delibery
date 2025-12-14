from decimal import Decimal

from django.test import TestCase
from django.urls import reverse
from django.contrib.auth import get_user_model
from django.db.models.signals import post_save, pre_save
from rest_framework import status
from rest_framework.test import APIRequestFactory, APITestCase

from usuarios.models import Perfil
from pedidos.models import Pedido
from .models import MetodoPago, Pago, EstadoPago, TipoMetodoPago
from .serializers import PagoCreateSerializer, PagoReembolsoSerializer
from notificaciones import signals as notif_signals


class PagoLogicTests(TestCase):
    """
    Tests focalizados en la lógica de creación y reembolso de pagos.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Desconectamos señales de notificaciones (si existen) para aislar el dominio de pagos
        try:
            pre_save.disconnect(notif_signals.detectar_cambio_estado_pedido, sender=Pedido)
        except AttributeError:
            pass
        try:
            post_save.disconnect(notif_signals.enviar_notificacion_cambio_estado, sender=Pedido)
        except AttributeError:
            pass

    @classmethod
    def tearDownClass(cls):
        # Reconectar señales al finalizar la suite por cortesía (si existen)
        try:
            pre_save.connect(notif_signals.detectar_cambio_estado_pedido, sender=Pedido)
        except AttributeError:
            pass
        try:
            post_save.connect(notif_signals.enviar_notificacion_cambio_estado, sender=Pedido)
        except AttributeError:
            pass
        super().tearDownClass()

    def setUp(self):
        self.factory = APIRequestFactory()
        User = get_user_model()

        # Cliente dueño del pedido
        self.user_cliente = User.objects.create_user(
            username='cliente',
            email='cliente@example.com',
            password='pass1234',
            first_name='Cli',
            last_name='Ente',
            celular='+593999999999',
        )
        self.perfil_cliente, _ = Perfil.objects.get_or_create(user=self.user_cliente)

        # Otro usuario autenticado (no dueño)
        self.user_otro = User.objects.create_user(
            username='intruso',
            email='intruso@example.com',
            password='pass1234',
            first_name='No',
            last_name='Owner',
            celular='+593988888888',
        )
        self.perfil_otro, _ = Perfil.objects.get_or_create(user=self.user_otro)

        # Admin para acciones forzadas
        self.user_admin = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='admin1234',
            first_name='Ad',
            last_name='Min',
            celular='+593977777777',
        )
        self.perfil_admin, _ = Perfil.objects.get_or_create(user=self.user_admin)

        # Pedido base y métodos de pago
        self.pedido = Pedido.objects.create(
            cliente=self.perfil_cliente,
            total=Decimal('10.00'),
        )
        self.metodo_efectivo = MetodoPago.objects.create(
            tipo=TipoMetodoPago.EFECTIVO,
            nombre='Efectivo',
            activo=True,
        )
        self.metodo_transferencia = MetodoPago.objects.create(
            tipo=TipoMetodoPago.TRANSFERENCIA,
            nombre='Transferencia',
            activo=True,
            requiere_verificacion=True,
        )

    # ---------------------------------------------------------
    # Creación de pago
    # ---------------------------------------------------------
    def test_cliente_puede_crear_pago_de_su_pedido(self):
        request = self.factory.post('/pagos/')
        request.user = self.user_cliente
        serializer = PagoCreateSerializer(
            data={
                'pedido_id': self.pedido.id,
                'metodo_pago_id': self.metodo_efectivo.id,
                'monto': '10.00',
            },
            context={'request': request},
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        pago = serializer.save()
        self.assertEqual(pago.pedido, self.pedido)
        self.assertEqual(pago.metodo_pago, self.metodo_efectivo)
        self.assertEqual(pago.monto, Decimal('10.00'))

    def test_usuario_no_dueno_no_puede_crear_pago(self):
        request = self.factory.post('/pagos/')
        request.user = self.user_otro
        serializer = PagoCreateSerializer(
            data={
                'pedido_id': self.pedido.id,
                'metodo_pago_id': self.metodo_efectivo.id,
                'monto': '10.00',
            },
            context={'request': request},
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn('pedido_id', serializer.errors)

    # ---------------------------------------------------------
    # Reembolsos
    # ---------------------------------------------------------
    def test_reembolso_rechaza_monto_mayor_a_pendiente(self):
        pago = Pago.objects.create(
            pedido=self.pedido,
            metodo_pago=self.metodo_transferencia,
            monto=Decimal('10.00'),
            estado=EstadoPago.COMPLETADO,
        )
        request = self.factory.post('/pagos/reembolsar/')
        request.user = self.user_admin
        serializer = PagoReembolsoSerializer(
            data={'monto': '12.00', 'motivo': 'error'},
            context={'pago': pago, 'request': request},
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn('non_field_errors', serializer.errors)

    def test_reembolso_parcial_y_total_registran_transaccion(self):
        pago = Pago.objects.create(
            pedido=self.pedido,
            metodo_pago=self.metodo_transferencia,
            monto=Decimal('10.00'),
            estado=EstadoPago.COMPLETADO,
        )
        request = self.factory.post('/pagos/reembolsar/')
        request.user = self.user_admin

        # Reembolso parcial
        serializer = PagoReembolsoSerializer(
            data={'monto': '8.00', 'motivo': 'parcial'},
            context={'pago': pago, 'request': request},
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        serializer.save()
        pago.refresh_from_db()
        self.assertEqual(pago.monto_reembolsado, Decimal('8.00'))
        self.assertEqual(pago.estado, EstadoPago.COMPLETADO)
        self.assertEqual(pago.transacciones.filter(tipo='reembolso').count(), 1)

        # Reembolso del restante (sin monto explícito = todo pendiente)
        serializer = PagoReembolsoSerializer(
            data={'motivo': 'restante'},
            context={'pago': pago, 'request': request},
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        serializer.save()
        pago.refresh_from_db()
        self.assertEqual(pago.monto_reembolsado, Decimal('10.00'))
        self.assertEqual(pago.estado, EstadoPago.REEMBOLSADO)
        self.assertEqual(pago.transacciones.filter(tipo='reembolso').count(), 2)
        self.assertIsNotNone(pago.fecha_reembolso)


class PagoAPIPermissionsTest(APITestCase):
    """
    Pruebas ligeras de permisos/visibilidad sobre endpoints de pagos y métodos.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Desconectamos señales de notificaciones para evitar efectos colaterales
        try:
            pre_save.disconnect(notif_signals.detectar_cambio_estado_pedido, sender=Pedido)
        except AttributeError:
            pass
        try:
            post_save.disconnect(notif_signals.enviar_notificacion_cambio_estado, sender=Pedido)
        except AttributeError:
            pass

    @classmethod
    def tearDownClass(cls):
        # Reconectar señales al finalizar
        try:
            pre_save.connect(notif_signals.detectar_cambio_estado_pedido, sender=Pedido)
        except AttributeError:
            pass
        try:
            post_save.connect(notif_signals.enviar_notificacion_cambio_estado, sender=Pedido)
        except AttributeError:
            pass
        super().tearDownClass()

    def setUp(self):
        User = get_user_model()
        self.admin = User.objects.create_superuser(
            username='admin',
            email='admin@app.com',
            password='admin1234',
        )
        self.user1 = User.objects.create_user(
            username='cliente1',
            email='c1@app.com',
            password='pass1234',
        )
        self.user2 = User.objects.create_user(
            username='cliente2',
            email='c2@app.com',
            password='pass1234',
        )

        # Metodo de pago base
        self.metodo = MetodoPago.objects.create(
            tipo=TipoMetodoPago.EFECTIVO,
            nombre='Efectivo',
            activo=True,
        )
        # Pedido + pago de user1
        pedido1 = Pedido.objects.create(
            cliente=self.user1.perfil,
            total=Decimal('10.00'),
            direccion_entrega="Dir 1",
        )
        self.pago1 = Pago.objects.create(
            pedido=pedido1,
            metodo_pago=self.metodo,
            monto=Decimal('10.00'),
        )
        # Pedido + pago de user2
        pedido2 = Pedido.objects.create(
            cliente=self.user2.perfil,
            total=Decimal('20.00'),
            direccion_entrega="Dir 2",
        )
        self.pago2 = Pago.objects.create(
            pedido=pedido2,
            metodo_pago=self.metodo,
            monto=Decimal('20.00'),
        )

    def test_metodos_pago_auth_y_disponibles(self):
        url_list = reverse('pagos:metodo-pago-list')
        url_disp = reverse('pagos:metodo-pago-disponibles')

        # Anónimo no puede listar
        res_anon = self.client.get(url_list)
        self.assertEqual(res_anon.status_code, status.HTTP_401_UNAUTHORIZED)

        # Auth puede listar y ver disponibles
        self.client.force_authenticate(self.user1)
        res = self.client.get(url_list)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        res_disp = self.client.get(url_disp)
        self.assertEqual(res_disp.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res_disp.data), 1)

    def test_visibilidad_pagos_cliente_y_admin(self):
        url = reverse('pagos:pago-list')

        # Cliente 1 solo ve su pago
        self.client.force_authenticate(self.user1)
        res_c1 = self.client.get(url)
        self.assertEqual(res_c1.status_code, status.HTTP_200_OK)
        if isinstance(res_c1.data, dict) and 'results' in res_c1.data:
            ids_c1 = [p['id'] for p in res_c1.data['results']]
        else:
            ids_c1 = [p['id'] for p in res_c1.data]
        self.assertIn(self.pago1.id, ids_c1)
        self.assertNotIn(self.pago2.id, ids_c1)

        # Admin ve todos
        self.client.force_authenticate(self.admin)
        res_admin = self.client.get(url)
        self.assertEqual(res_admin.status_code, status.HTTP_200_OK)
        if isinstance(res_admin.data, dict) and 'results' in res_admin.data:
            ids_admin = [p['id'] for p in res_admin.data['results']]
        else:
            ids_admin = [p['id'] for p in res_admin.data]
        self.assertIn(self.pago1.id, ids_admin)
        self.assertIn(self.pago2.id, ids_admin)
