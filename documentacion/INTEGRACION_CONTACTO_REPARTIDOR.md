# Integración de Contacto Cliente-Repartidor

Este documento explica cómo integrar los widgets de contacto WhatsApp en las pantallas de pedidos.

## Widgets Disponibles

Se han creado 3 widgets reutilizables en `/lib/widgets/`:

### 1. `BotonContactoWhatsApp`
Widget básico para abrir WhatsApp con un mensaje predefinido.

### 2. `OpcionesContacto`
Card completo con opciones de llamada telefónica y WhatsApp.

### 3. `CardContactoRepartidor`
Card especializado para mostrar información del repartidor con opciones de contacto.

---

## Integración en Pantalla de Detalles del Pedido

### Paso 1: Importar el widget

```dart
import '../../../widgets/card_contacto_repartidor.dart';
```

### Paso 2: Agregar el widget en el body

En el archivo `/lib/screens/user/pedidos/pedido_detalle_screen.dart`, agregar después de la información del pedido:

```dart
// Dentro del build, después de mostrar la información del pedido
if (pedido.repartidor != null &&
    pedido.estado == 'en_ruta' || pedido.estado == 'en_preparacion') {
  const SizedBox(height: 16),
  CardContactoRepartidor(
    nombreRepartidor: pedido.repartidor!.nombre,
    telefonoRepartidor: pedido.repartidor!.telefono,
    numeroPedido: pedido.numeroPedido,
  ),
}
```

### Ejemplo completo de integración:

```dart
Widget _buildDetallesPedido(Pedido pedido) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ... Información del pedido existente ...

        // Información del estado
        _buildEstadoCard(pedido),
        const SizedBox(height: 16),

        // Información de items
        _buildItemsCard(pedido),
        const SizedBox(height: 16),

        // ✨ NUEVO: Contacto con el repartidor
        if (pedido.repartidor != null &&
            (pedido.estado == 'en_ruta' ||
             pedido.estado == 'en_preparacion' ||
             pedido.estado == 'confirmado')) ...[
          CardContactoRepartidor(
            nombreRepartidor: pedido.repartidor!.nombre,
            telefonoRepartidor: pedido.repartidor!.telefono,
            numeroPedido: pedido.numeroPedido,
          ),
          const SizedBox(height: 16),
        ],

        // ... Resto de la información ...
      ],
    ),
  );
}
```

---

## Integración en Pantalla de Seguimiento en Tiempo Real

Si tienes una pantalla de seguimiento con mapa, puedes usar el FloatingActionButton:

```dart
import '../../../widgets/boton_contacto_whatsapp.dart';

class PantallaSeguimientoPedido extends StatelessWidget {
  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seguimiento')),
      body: _buildMapa(),
      floatingActionButton: pedido.repartidor?.telefono != null
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: const Color(0xFF25D366),
              icon: const Icon(Icons.chat_bubble, color: Colors.white),
              label: BotonContactoWhatsApp(
                telefono: pedido.repartidor!.telefono!,
                mensaje: 'Hola, soy el cliente del pedido #${pedido.numeroPedido}',
                esBotonCompleto: true,
                textoBoton: 'Contactar',
              ),
            )
          : null,
    );
  }
}
```

---

## Integración Simple (Solo Botón)

Para una integración más simple, usa el `BotonWhatsAppRepartidor`:

```dart
import '../../../widgets/card_contacto_repartidor.dart';

// En cualquier lugar donde tengas la información del pedido
BotonWhatsAppRepartidor(
  telefonoRepartidor: pedido.repartidor?.telefono,
  numeroPedido: pedido.numeroPedido,
)
```

---

## Personalización del Mensaje

Puedes personalizar el mensaje de WhatsApp según el estado del pedido:

```dart
String _generarMensaje(Pedido pedido) {
  switch (pedido.estado) {
    case 'en_preparacion':
      return 'Hola, mi pedido #${pedido.numeroPedido} está en preparación. ¿Cuánto falta?';
    case 'en_ruta':
      return 'Hola, soy el cliente del pedido #${pedido.numeroPedido}. ¿En cuánto tiempo llegas?';
    case 'entregado':
      return 'Hola, tengo una consulta sobre el pedido #${pedido.numeroPedido}.';
    default:
      return 'Hola, necesito información sobre mi pedido #${pedido.numeroPedido}.';
  }
}

// Uso
OpcionesContacto(
  telefono: pedido.repartidor!.telefono!,
  nombreContacto: pedido.repartidor!.nombre,
  mensajeWhatsApp: _generarMensaje(pedido),
)
```

---

## Validación de Teléfono

Los widgets ya incluyen validación automática:

- ✅ Limpia caracteres especiales del número
- ✅ Agrega código de país (+593) si falta
- ✅ Maneja números que empiezan con 0
- ✅ Muestra error si WhatsApp no está instalado
- ✅ No muestra nada si el teléfono es null o vacío

---

## Estados Recomendados para Mostrar Contacto

Se recomienda mostrar las opciones de contacto cuando:

- ✅ El pedido está en estado `confirmado`
- ✅ El pedido está en estado `en_preparacion`
- ✅ El pedido está en estado `en_ruta`
- ❌ NO mostrar si está `pendiente` (aún no hay repartidor)
- ❌ NO mostrar si está `entregado` o `cancelado` (pedido terminado)

```dart
bool _puedeContactarRepartidor(Pedido pedido) {
  return pedido.repartidor != null &&
         pedido.repartidor!.telefono != null &&
         pedido.repartidor!.telefono!.isNotEmpty &&
         ['confirmado', 'en_preparacion', 'en_ruta'].contains(pedido.estado);
}
```

---

## Estilos y Colores

Los widgets usan los colores del tema de la aplicación (`JPColors`), pero puedes personalizar:

```dart
BotonContactoWhatsApp(
  telefono: '0999999999',
  mensaje: 'Hola',
  color: Colors.green, // Color personalizado
  icono: Icons.phone, // Icono personalizado
)
```

---

## Troubleshooting

### WhatsApp no se abre
- Verificar que el paquete `url_launcher` esté en `pubspec.yaml`
- Verificar permisos en Android (`AndroidManifest.xml`)
- Verificar que WhatsApp esté instalado en el dispositivo

### El número no es válido
- Los números deben tener 10 dígitos para Ecuador
- El widget agrega automáticamente +593
- Si el número tiene código de país diferente, debe incluirse con +

### El widget no se muestra
- Verificar que `pedido.repartidor?.telefono` no sea null
- Verificar que el estado del pedido sea uno de los permitidos
- Revisar la consola para errores de rendering

---

## Ejemplo de Implementación Completa

Ver archivo de ejemplo: `/lib/screens/user/pedidos/pedido_detalle_screen.dart`

```dart
// Importaciones
import '../../../widgets/card_contacto_repartidor.dart';
import '../../../models/pedido_model.dart';

class PedidoDetalleScreen extends StatelessWidget {
  final int pedidoId;

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoProvider>(
      builder: (context, provider, child) {
        final pedido = provider.pedidoDetalle;

        if (pedido == null) return CircularProgressIndicator();

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Información básica del pedido
              _buildInfoCard(pedido),
              SizedBox(height: 16),

              // Items del pedido
              _buildItemsCard(pedido),
              SizedBox(height: 16),

              // ✨ Contacto con repartidor
              if (_puedeContactarRepartidor(pedido))
                CardContactoRepartidor(
                  nombreRepartidor: pedido.repartidor!.nombre,
                  telefonoRepartidor: pedido.repartidor!.telefono,
                  numeroPedido: pedido.numeroPedido,
                ),
            ],
          ),
        );
      },
    );
  }

  bool _puedeContactarRepartidor(Pedido pedido) {
    return pedido.repartidor != null &&
           pedido.repartidor!.telefono != null &&
           pedido.repartidor!.telefono!.isNotEmpty &&
           ['confirmado', 'en_preparacion', 'en_ruta'].contains(pedido.estado);
  }
}
```

---

## Testing

Para probar la funcionalidad:

1. Crear un pedido de prueba con un repartidor asignado
2. Asegurarse de que el repartidor tenga teléfono configurado
3. Verificar que el pedido esté en uno de los estados permitidos
4. Navegar a la pantalla de detalles del pedido
5. El widget de contacto debe aparecer
6. Al presionar WhatsApp, debe abrir la app con el mensaje predefinido

---

## Notas Adicionales

- Los mensajes de WhatsApp se codifican automáticamente (URL encoding)
- El widget es totalmente responsive
- Funciona tanto en Android como iOS
- No requiere configuración adicional más allá de `url_launcher`
- Los errores se manejan con snackbars informativos
