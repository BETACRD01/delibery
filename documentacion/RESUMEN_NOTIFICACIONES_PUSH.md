# Resumen: Notificaciones Push para Comprobantes de Pago

## ✅ Implementación Completada

Se ha implementado exitosamente el sistema de notificaciones push que alerta al repartidor cuando un cliente sube un comprobante de pago.

---

## 🔧 Cambios Realizados

### Backend

#### 1. **Servicio de Notificaciones** (`backend/notificaciones/services.py`)
```python
def notificar_comprobante_subido(pago):
    """Notifica al repartidor cuando el cliente sube un comprobante de pago."""
```
- **Ubicación**: Línea ~120
- **Función**: Crea y envía una notificación FCM al repartidor
- **Datos enviados**:
  - `accion`: 'ver_comprobante'
  - `pago_id`: ID del pago
  - `pedido_id`: ID del pedido
  - `monto`: Monto del pago

#### 2. **Vista de Pagos** (`backend/pagos/views.py`)
```python
# 🔔 Enviar notificación push al repartidor
try:
    from notificaciones.services import notificar_comprobante_subido
    notificar_comprobante_subido(pago_actualizado)
except Exception as e:
    logger.error(f'Error enviando notificación de comprobante: {e}')
```
- **Ubicación**: Línea 437-445 (dentro de `subir_comprobante` ViewSet)
- **Función**: Llama al servicio de notificaciones después de guardar el comprobante
- **Seguridad**: No-blocking - si falla, solo registra el error sin afectar la subida

---

### Frontend (Flutter)

#### 1. **NotificationHandler** (`mobile/lib/services/notification_handler.dart`)
**Clase singleton que maneja las notificaciones push**

- **Método `initialize(BuildContext)`**: Inicializa los listeners de Firebase
- **Método `_handleForegroundMessage`**: Muestra banner in-app cuando la app está activa
- **Método `_handleNotificationTap`**: Navega a la pantalla correcta al tocar la notificación
- **Método `_navegarAVerComprobante`**: Navega a `/delivery/ver-comprobante` con el pagoId

**Estados manejados**:
- ✅ Foreground: Muestra banner animado
- ✅ Background: Navega al tocar
- ✅ Terminated: Verifica mensaje inicial y navega

#### 2. **NotificacionInApp** (`mobile/lib/widgets/notificacion_in_app.dart`)
**Widget overlay para mostrar notificaciones cuando la app está en primer plano**

Características:
- Banner animado con slide-in desde arriba
- Auto-dismiss después de 5 segundos
- Tap para navegar a la pantalla de comprobante
- Botón de cerrar manual
- Diseño con gradiente del tema

#### 3. **Integración en main.dart** (`mobile/lib/main.dart`)

**Cambios realizados**:

1. **Importación del NotificationHandler** (Línea 12)
2. **Conversión de MyApp a StatefulWidget** (Línea 105-117)
3. **Inicialización del handler** (Línea 126-136):
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     if (_navigatorKey.currentContext != null) {
       final notificationHandler = NotificationHandler();
       notificationHandler.initialize(_navigatorKey.currentContext!);
     }
   });
   ```

4. **NavigatorKey global** (Línea 120):
   ```dart
   final _navigatorKey = GlobalKey<NavigatorState>();
   ```

5. **Handler onGenerateRoute** (Línea 208-221):
   ```dart
   onGenerateRoute: (settings) {
     if (settings.name == '/delivery/ver-comprobante') {
       final args = settings.arguments as Map<String, dynamic>?;
       final pagoId = args?['pagoId'] as int?;
       if (pagoId != null) {
         return MaterialPageRoute(
           builder: (_) => PantallaVerComprobante(pagoId: pagoId),
           settings: settings,
         );
       }
     }
     return null;
   }
   ```

#### 4. **Rutas** (`mobile/lib/config/rutas.dart`)

**Nuevas constantes agregadas**:
- `static const String verComprobante = '/delivery/ver-comprobante';`
- `static const String datosBancarios = '/delivery/datos-bancarios';`
- `static const String subirComprobante = '/user/subir-comprobante';`

**Nueva ruta en el mapa**:
```dart
datosBancarios: (_) => const PantallaDatosBancarios(),
```

---

## 🔄 Flujo Completo

### Escenario: Cliente sube comprobante de pago

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Cliente sube imagen del comprobante                      │
│    POST /api/pagos/{id}/subir-comprobante/                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Backend guarda el comprobante en el modelo Pago          │
│    - comprobante_imagen = archivo subido                    │
│    - comprobante_visible_repartidor = True                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Backend llama notificar_comprobante_subido(pago)         │
│    - Obtiene el FCM token del repartidor                    │
│    - Crea notificación en BD                                │
│    - Envía push notification vía FCM                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. FCM entrega la notificación al dispositivo del           │
│    repartidor con data:                                     │
│    {                                                        │
│      "accion": "ver_comprobante",                          │
│      "pago_id": "123",                                     │
│      "pedido_id": "456",                                   │
│      "monto": "25.50"                                      │
│    }                                                        │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐   ┌──────────────────────┐
│ App en FOREGROUND │   │ App en BACKGROUND    │
│                   │   │ o TERMINATED         │
│ - Muestra banner  │   │                      │
│   in-app animado  │   │ - Muestra            │
│ - Auto-dismiss    │   │   notificación del   │
│   5 segundos      │   │   sistema            │
│ - Tap para ir a   │   │ - Tap abre la app    │
│   comprobante     │   │   y navega           │
└──────────────────┘   └──────────────────────┘
        │                         │
        └────────────┬────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Repartidor ve PantallaVerComprobante                     │
│    - Imagen del comprobante                                 │
│    - Info del cliente                                       │
│    - Botón "Marcar como visto"                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Repartidor marca como visto                              │
│    PUT /api/pagos/{id}/marcar-visto/                       │
│    - fecha_visualizacion_repartidor = now()                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Experiencia de Usuario

### Cliente
1. Hace transferencia bancaria a la cuenta del repartidor
2. Toma foto del comprobante
3. Sube el comprobante desde la pantalla del pedido
4. Ve confirmación "Comprobante subido exitosamente"

### Repartidor

**Caso 1: App Activa (Foreground)**
1. Recibe banner animado en la parte superior
2. Banner muestra: "Comprobante de pago recibido"
3. Tap en el banner → navega directamente a ver el comprobante
4. O espera 5 segundos → banner se cierra automáticamente

**Caso 2: App en Background**
1. Recibe notificación del sistema
2. Tap en notificación → abre la app
3. Navega automáticamente a PantallaVerComprobante
4. Ve la imagen del comprobante
5. Presiona "Marcar como visto"

**Caso 3: App Cerrada (Terminated)**
1. Recibe notificación del sistema
2. Tap en notificación → abre la app
3. Después de login/router, navega a PantallaVerComprobante
4. Mismo flujo que caso 2

---

## 🧪 Testing

### Backend
```bash
# Probar endpoint de subir comprobante
curl -X POST http://localhost:8000/api/pagos/1/subir-comprobante/ \
  -H "Authorization: Bearer TOKEN" \
  -F "transferencia_comprobante=@comprobante.jpg" \
  -F "banco_origen=Banco Pichincha" \
  -F "numero_operacion=123456789"

# Verificar logs
tail -f logs/app.log | grep "Notificación de comprobante"
```

### Frontend
1. **Test de banner in-app**:
   - Abrir app como repartidor
   - Desde otro dispositivo/cuenta, subir comprobante
   - Verificar que aparece el banner animado

2. **Test de navegación desde notificación**:
   - Cerrar completamente la app
   - Subir comprobante desde otra cuenta
   - Tap en la notificación
   - Verificar que navega a PantallaVerComprobante

3. **Test de visualización**:
   - Ver el comprobante
   - Presionar "Marcar como visto"
   - Verificar que desaparece el botón y muestra "Comprobante visto"

---

## 🔍 Debugging

### Ver logs de notificaciones

**Backend**:
```python
import logging
logger = logging.getLogger('notificaciones')
logger.info('Mensaje de debug')
```

**Frontend**:
```dart
import 'dart:developer' as developer;
developer.log('Mensaje de debug', name: 'NotificationHandler');
```

### Comandos útiles
```bash
# Ver logs de Flutter
flutter logs

# Ver solo logs de NotificationHandler
flutter logs | grep NotificationHandler

# Reiniciar completamente la app
flutter run --hot-restart
```

---

## ⚙️ Configuración Requerida

### Firebase Cloud Messaging

1. **Verificar que el proyecto tiene FCM configurado**:
   - `google-services.json` en `android/app/`
   - `GoogleService-Info.plist` en `ios/Runner/`

2. **Permisos en AndroidManifest.xml**:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```

3. **Token FCM debe estar guardado en el backend**:
   - El token se guarda en `Usuario.fcm_token`
   - Se actualiza automáticamente al login
   - El servicio de notificaciones usa este token

### Verificar configuración
```dart
// En main.dart o cualquier pantalla
final messaging = FirebaseMessaging.instance;
final token = await messaging.getToken();
print('FCM Token: $token');
```

---

## 📋 Checklist de Implementación

- ✅ Backend: Función `notificar_comprobante_subido` creada
- ✅ Backend: Llamada al servicio en `subir_comprobante` ViewSet
- ✅ Frontend: NotificationHandler implementado como singleton
- ✅ Frontend: NotificacionInApp widget creado
- ✅ Frontend: NotificationHandler inicializado en main.dart
- ✅ Frontend: MyApp convertido a StatefulWidget
- ✅ Frontend: NavigatorKey global configurado
- ✅ Frontend: onGenerateRoute handler agregado
- ✅ Frontend: Rutas agregadas en rutas.dart
- ✅ Frontend: PantallaVerComprobante importada y manejada
- ✅ Documentación: CONFIGURACION_NOTIFICACIONES_PUSH.md creado
- ✅ Documentación: RESUMEN_NOTIFICACIONES_PUSH.md creado

---

## 🎯 Próximos Pasos (Opcional)

### Mejoras Sugeridas

1. **Notificaciones locales**:
   - Usar `flutter_local_notifications` para notificaciones programadas
   - Recordar al cliente si no sube comprobante en X horas

2. **Sonido personalizado**:
   - Agregar sonido custom para notificaciones de comprobantes
   - Diferente al sonido de pedidos nuevos

3. **Badge contador**:
   - Mostrar número de comprobantes sin revisar
   - Actualizar en tiempo real

4. **Analytics**:
   - Trackear cuántos repartidores ven los comprobantes
   - Tiempo promedio de respuesta

5. **Notificaciones agrupadas**:
   - Si hay múltiples comprobantes, agrupar en una sola notificación

---

## 📞 Soporte

Si encuentras algún problema:

1. Verificar logs del backend: `tail -f logs/app.log`
2. Verificar logs de Flutter: `flutter logs`
3. Revisar que el FCM token esté guardado en la BD
4. Verificar permisos de notificaciones en el dispositivo
5. Comprobar que Firebase está inicializado correctamente

---

## 📚 Referencias

- [Firebase Cloud Messaging - Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Background Handler](https://firebase.google.com/docs/cloud-messaging/flutter/receive#background_messages)

---

**Fecha de implementación**: 2025-12-12
**Versión**: 1.0
**Estado**: ✅ Completado y listo para producción
