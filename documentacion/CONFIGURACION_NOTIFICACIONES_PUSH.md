# Configuración de Notificaciones Push - Comprobantes de Pago

Este documento explica cómo funcionan las notificaciones push cuando se sube un comprobante de pago.

## 🔔 Flujo de Notificaciones

### Backend (Automático)
1. Cliente sube comprobante desde la app
2. Backend guarda el comprobante y asigna el repartidor
3. **Backend envía notificación push automáticamente** al repartidor
4. Se guarda registro en la base de datos

### Frontend (Repartidor)
1. Repartidor recibe la notificación en su dispositivo
2. Al tocar la notificación, se abre la pantalla de ver comprobante
3. Repartidor puede ver la imagen y marcar como visto

---

## 🚀 Implementación Backend (YA COMPLETADA)

### Archivo: `backend/notificaciones/services.py`

Se agregó la función `notificar_comprobante_subido()`:

```python
def notificar_comprobante_subido(pago):
    """
    Notifica al repartidor cuando el cliente sube un comprobante de pago.
    """
    if not pago.repartidor_asignado:
        return

    pedido = pago.pedido
    cliente_nombre = pedido.cliente.user.get_full_name() or pedido.cliente.user.email

    crear_y_enviar_notificacion(
        usuario=pago.repartidor_asignado.user,
        titulo="Comprobante de pago recibido",
        mensaje=f"{cliente_nombre} ha subido el comprobante de pago del pedido #{pedido.numero_pedido}. Monto: ${pago.monto}",
        tipo='pago',
        pedido=pedido,
        datos_extra={
            'accion': 'ver_comprobante',
            'pago_id': str(pago.id),
            'pedido_id': str(pedido.id),
            'monto': str(pago.monto)
        }
    )
```

### Archivo: `backend/pagos/views.py`

Se agregó la llamada después de guardar el comprobante:

```python
# 🔔 Enviar notificación push al repartidor
try:
    from notificaciones.services import notificar_comprobante_subido
    notificar_comprobante_subido(pago_actualizado)
except Exception as e:
    logger.error(f'Error enviando notificación de comprobante: {e}')
```

---

## 📱 Configuración Frontend

### 1. Verificar Firebase Messaging

Asegurarse de que `firebase_messaging` está en `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^14.7.0
  firebase_core: ^2.24.0
```

### 2. Inicializar NotificationHandler

En `/lib/main.dart`, agregar después de inicializar Firebase:

```dart
import 'services/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializar el manejador de notificaciones
  final notificationHandler = NotificationHandler();

  runApp(MyApp(notificationHandler: notificationHandler));
}

class MyApp extends StatelessWidget {
  final NotificationHandler notificationHandler;

  const MyApp({required this.notificationHandler});

  @override
  Widget build(BuildContext context) {
    // Inicializar con el contexto de navegación
    notificationHandler.initialize(context);

    return MaterialApp(
      // ... resto de la configuración
    );
  }
}
```

### 3. Agregar Ruta para Ver Comprobante

En `/lib/config/rutas.dart` o donde manejes las rutas:

```dart
import '../screens/delivery/pantalla_ver_comprobante.dart';

static const String verComprobante = '/delivery/ver-comprobante';

// En el switch de rutas:
case Rutas.verComprobante:
  final args = settings.arguments as Map<String, dynamic>;
  return MaterialPageRoute(
    builder: (_) => PantallaVerComprobante(
      pagoId: args['pagoId'],
    ),
  );
```

---

## 🎯 Datos de la Notificación

Cuando se envía la notificación, incluye:

```json
{
  "notification": {
    "title": "Comprobante de pago recibido",
    "body": "Juan Pérez ha subido el comprobante de pago del pedido #12345. Monto: $25.50"
  },
  "data": {
    "accion": "ver_comprobante",
    "pago_id": "123",
    "pedido_id": "456",
    "monto": "25.50",
    "tipo_evento": "pago",
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "timestamp": "1234567890.123"
  }
}
```

---

## 📊 Estados de la Notificación

### App en Primer Plano
- La notificación se muestra como banner
- Se ejecuta `onMessage`
- Puedes mostrar un SnackBar in-app

### App en Segundo Plano
- El sistema muestra la notificación
- Al tocarla, se ejecuta `onMessageOpenedApp`
- Navega automáticamente a la pantalla de comprobante

### App Cerrada
- El sistema muestra la notificación
- Al tocarla, se abre la app
- Se ejecuta `getInitialMessage`
- Navega a la pantalla de comprobante

---

## 🔧 Personalización del Manejador

### Agregar Más Acciones

En `/lib/services/notification_handler.dart`:

```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final accion = data['accion'];

  switch (accion) {
    case 'ver_comprobante':
      _navegarAVerComprobante(data);
      break;
    case 'pedido_entregado':
      _navegarAPedidoEntregado(data);
      break;
    // Agregar más casos aquí
    default:
      developer.log('Acción desconocida: $accion');
  }
}
```

### Mostrar Notificación In-App

Para mostrar un SnackBar cuando la app está en primer plano:

```dart
void _handleForegroundMessage(RemoteMessage message) {
  if (_context == null) return;

  final notification = message.notification;
  if (notification == null) return;

  ScaffoldMessenger.of(_context!).showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(notification.body ?? ''),
        ],
      ),
      action: SnackBarAction(
        label: 'Ver',
        onPressed: () => _handleNotificationTap(message),
      ),
    ),
  );
}
```

---

## 🔒 Permisos Requeridos

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS (`Info.plist`)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## 🧪 Testing

### 1. Probar en Desarrollo

```dart
// Enviar notificación de prueba desde Firebase Console
// O usar el endpoint de backend directamente
```

### 2. Verificar Logs

Backend:
```bash
# Ver logs de Django
tail -f backend/logs/notificaciones.log
```

Flutter:
```bash
# Ver logs del dispositivo
flutter logs
```

### 3. Casos de Prueba

✅ **App en primer plano:**
1. Abrir la app como repartidor
2. Desde otro dispositivo, subir comprobante como cliente
3. Verificar que aparece banner de notificación

✅ **App en segundo plano:**
1. Minimizar la app
2. Subir comprobante
3. Tocar la notificación
4. Verificar que abre la pantalla correcta

✅ **App cerrada:**
1. Cerrar completamente la app
2. Subir comprobante
3. Tocar la notificación
4. Verificar que abre la app y navega

---

## 🐛 Troubleshooting

### No llegan notificaciones
1. Verificar que Firebase está configurado correctamente
2. Verificar que el repartidor tiene FCM token guardado
3. Revisar logs del backend (`notificaciones.log`)
4. Verificar permisos en el dispositivo

### La notificación llega pero no navega
1. Verificar que el manejador está inicializado
2. Verificar que las rutas están correctamente definidas
3. Revisar logs de Flutter para errores de navegación

### Token FCM se pierde
1. El token se guarda en `usuarios.models.Perfil.fcm_token`
2. Si el usuario desinstala la app, el backend lo marca como inválido
3. Al reinstalar, debe obtener un nuevo token

---

## 📈 Métricas y Monitoreo

El backend guarda cada notificación en la tabla `notificaciones_notificacion`:

```sql
SELECT
    tipo,
    COUNT(*) as total,
    SUM(CASE WHEN enviada_push THEN 1 ELSE 0 END) as enviadas,
    SUM(CASE WHEN leida THEN 1 ELSE 0 END) as leidas
FROM notificaciones_notificacion
WHERE tipo = 'pago'
GROUP BY tipo;
```

---

## 🔄 Flujo Completo de Ejemplo

```
1. Cliente: Realiza pedido → Backend: Asigna repartidor
2. Cliente: Sube comprobante → Backend: Guarda imagen
3. Backend: Envía notificación push → FCM: Entrega al dispositivo
4. Repartidor: Toca notificación → App: Navega a ver comprobante
5. Repartidor: Ve imagen → Marca como visto
6. Repartidor: Inicia entrega
```

---

## 📚 Referencias

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview/)
- [Handling Interaction](https://firebase.flutter.dev/docs/messaging/notifications/#handling-interaction)

---

## ✅ Checklist de Implementación

- [x] Función de notificación en backend
- [x] Llamada en endpoint de subir comprobante
- [x] NotificationHandler creado
- [ ] NotificationHandler inicializado en main.dart
- [ ] Ruta de ver comprobante agregada
- [ ] Permisos configurados (Android/iOS)
- [ ] Testing en desarrollo
- [ ] Testing en producción
