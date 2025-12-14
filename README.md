
# 🚀 Delibery v1.0

**Sistema integral de delivery con gestión multi-rol** - Backend Django REST + Frontend React + Mobile Flutter

[![Django](https://img.shields.io/badge/Django-4.2-green.svg)](https://www.djangoproject.com/)
[![React](https://img.shields.io/badge/React-18-blue.svg)](https://reactjs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📋 Tabla de Contenidos

- [Descripción](#descripción)
- [Características](#características)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos Previos](#requisitos-previos)
- [Instalación](#instalación)
  - [Backend Django](#1-backend-django)
  - [Frontend React](#2-frontend-react)
  - [Mobile Flutter](#3-mobile-flutter)
- [Variables de Entorno](#variables-de-entorno)
- [Comandos de Ejecución](#comandos-de-ejecución)
- [API Documentation](#api-documentation)
- [Tecnologías](#tecnologías)
- [Contribución](#contribución)

---

## 📖 Descripción

Delibery es una plataforma completa de delivery que conecta usuarios, proveedores y repartidores en un ecosistema integrado. El sistema incluye:

- **Backend API REST** con Django para gestión centralizada
- **Panel Web Administrativo** con React para administradores
- **App Mobile** con Flutter para usuarios finales, proveedores y repartidores

---

## ✨ Características

### 👤 Usuario
- Registro y autenticación con JWT
- Búsqueda de productos y restaurantes
- Carrito de compras con múltiples proveedores
- Seguimiento en tiempo real de pedidos
- Sistema de calificaciones
- Gestión de direcciones favoritas
- Notificaciones push
- Sistema de rifas

### 🏪 Proveedor
- Dashboard de gestión de negocio
- Gestión de productos y categorías
- Control de pedidos en tiempo real
- Sistema de promociones
- Estadísticas de ventas
- Chat con clientes

### 🚴 Repartidor
- Panel de entregas disponibles
- Navegación GPS integrada
- Gestión de ganancias
- Historial de entregas
- Datos bancarios para pagos
- Sistema de calificaciones

### 👨‍💼 Administrador
- Dashboard completo con métricas
- Gestión de usuarios, proveedores y repartidores
- Sistema de solicitudes de cambio de rol
- Gestión de rifas
- Reportes y estadísticas
- Acciones administrativas

---

## 📁 Estructura del Proyecto

```
delibery/
├── backend/                    # API Django REST Framework
│   ├── administradores/       # App de administración
│   ├── authentication/        # Sistema de autenticación
│   ├── calificaciones/        # Sistema de ratings
│   ├── chat/                  # Sistema de mensajería
│   ├── envios/                # Gestión de envíos
│   ├── notificaciones/        # Push notifications
│   ├── pagos/                 # Sistema de pagos
│   ├── pedidos/               # Gestión de pedidos
│   ├── productos/             # Catálogo de productos
│   ├── proveedores/           # Gestión de proveedores
│   ├── repartidores/          # Gestión de repartidores
│   ├── reportes/              # Reportes y analytics
│   ├── rifas/                 # Sistema de rifas
│   ├── usuarios/              # Gestión de usuarios
│   ├── settings/              # Configuración Django
│   ├── manage.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend/                   # Panel Web Admin React
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── admin/         # Pantallas administrativas
│   │   │   └── auth/          # Login/Register
│   │   ├── services/          # API calls
│   │   ├── context/           # React Context
│   │   └── App.jsx
│   ├── package.json
│   └── vite.config.js
│
├── mobile/                     # App Mobile Flutter
│   ├── lib/
│   │   ├── screens/           # Pantallas
│   │   │   ├── admin/         # Pantallas admin
│   │   │   ├── delivery/      # Pantallas repartidor
│   │   │   ├── supplier/      # Pantallas proveedor
│   │   │   └── user/          # Pantallas usuario
│   │   ├── services/          # Servicios API
│   │   ├── controllers/       # Lógica de negocio
│   │   ├── models/            # Modelos de datos
│   │   ├── providers/         # State management
│   │   ├── widgets/           # Widgets reutilizables
│   │   ├── config/            # Configuración
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   ├── pubspec.yaml
│   └── firebase.json
│
├── documentacion/              # Documentación técnica
├── docker-compose.yml          # Docker setup
├── .gitignore
└── README.md
```

---

## 🔧 Requisitos Previos

### General
- Git
- Docker & Docker Compose (opcional pero recomendado)

### Backend
- Python 3.10+
- PostgreSQL 14+
- Redis (para Celery)

### Frontend
- Node.js 18+
- npm o yarn

### Mobile
- Flutter SDK 3.x
- Android Studio (para Android)
- Xcode (para iOS, solo macOS)

---

## 🚀 Instalación

### 1. Backend Django

```bash
# Clonar el repositorio
git clone https://github.com/BETACRD01/delibery.git
cd delibery/backend

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Copiar archivo de variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Configurar Firebase
# 1. Descargar firebase-credentials.json desde Firebase Console
# 2. Colocar en backend/firebase-credentials.json

# Ejecutar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Recolectar archivos estáticos
python manage.py collectstatic --noinput

# Correr servidor de desarrollo
python manage.py runserver 0.0.0.0:8000
```

**El backend estará disponible en:** `http://localhost:8000`

---

### 2. Frontend React

```bash
cd frontend

# Instalar dependencias
npm install
# o
yarn install

# Copiar variables de entorno
cp .env.example .env.local
# Editar .env.local con la URL de tu backend

# Correr servidor de desarrollo
npm run dev
# o
yarn dev
```

**El frontend estará disponible en:** `http://localhost:5173`

---

### 3. Mobile Flutter

```bash
cd mobile

# Instalar dependencias
flutter pub get

# Configurar Firebase
# 1. Android: Colocar google-services.json en mobile/android/app/
# 2. iOS: Colocar GoogleService-Info.plist en mobile/ios/Runner/

# Configurar API endpoint
# Editar mobile/lib/config/api_config.dart
# Cambiar BASE_URL a tu IP local o servidor

# Verificar dispositivos conectados
flutter devices

# Correr en modo debug
flutter run

# O construir APK para Android
flutter build apk --release

# O construir para iOS (solo macOS)
flutter build ios --release
```

---

## 🔐 Variables de Entorno

### Backend (.env)

```env
# Django
SECRET_KEY=tu-secret-key-super-segura-aqui
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,tu-dominio.com

# Base de datos
DB_ENGINE=django.db.backends.postgresql
DB_NAME=delibery_db
DB_USER=postgres
DB_PASSWORD=tu-password-seguro
DB_HOST=localhost
DB_PORT=5432

# Redis (Celery)
REDIS_URL=redis://localhost:6379/0

# Email
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=tu-email@gmail.com
EMAIL_HOST_PASSWORD=tu-app-password

# Firebase
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000

# JWT
JWT_SECRET_KEY=otra-key-diferente-para-jwt
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7
```

### Frontend (.env.local)

```env
VITE_API_URL=http://localhost:8000/api
VITE_WS_URL=ws://localhost:8000/ws
```

### Mobile (lib/config/api_config.dart)

```dart
class ApiConfig {
  // Para emulador Android
  static const String BASE_URL = 'http://10.0.2.2:8000/api';
  
  // Para dispositivo físico (usar IP de tu PC)
  // static const String BASE_URL = 'http://192.168.1.100:8000/api';
  
  // Para producción
  // static const String BASE_URL = 'https://tu-dominio.com/api';
}
```

---

## ⚡ Comandos de Ejecución

### Con Docker Compose (Recomendado)

```bash
# Construir y levantar todos los servicios
docker-compose up --build

# Levantar en modo detached
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar servicios
docker-compose down

# Parar y eliminar volúmenes
docker-compose down -v
```

### Backend Manual

```bash
# Desarrollo
python manage.py runserver 0.0.0.0:8000

# Con Gunicorn (producción)
gunicorn settings.wsgi:application --bind 0.0.0.0:8000

# Celery worker
celery -A settings worker -l info

# Celery beat (tareas programadas)
celery -A settings beat -l info
```

### Frontend

```bash
# Desarrollo
npm run dev

# Build de producción
npm run build

# Preview del build
npm run preview
```

### Mobile

```bash
# Modo debug
flutter run

# Modo release
flutter run --release

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Limpiar cache
flutter clean && flutter pub get
```

---

## 📚 API Documentation

### Autenticación

#### Registro
```http
POST /api/auth/register/
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "password123",
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+593987654321"
}
```

#### Login
```http
POST /api/auth/login/
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "password123"
}

Response:
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "usuario@ejemplo.com",
    "rol_activo": "usuario"
  }
}
```

### Productos

#### Listar Productos
```http
GET /api/productos/
Authorization: Bearer {token}

Query params:
- categoria: ID de categoría
- proveedor: ID de proveedor
- search: Búsqueda por nombre
- ordering: precio, -precio, created_at
```

#### Detalle de Producto
```http
GET /api/productos/{id}/
Authorization: Bearer {token}
```

### Pedidos

#### Crear Pedido
```http
POST /api/pedidos/
Authorization: Bearer {token}
Content-Type: application/json

{
  "items": [
    {
      "producto": 1,
      "cantidad": 2
    }
  ],
  "direccion_entrega": "Calle Principal 123",
  "metodo_pago": "efectivo",
  "notas": "Sin cebolla"
}
```

#### Mis Pedidos
```http
GET /api/pedidos/mis-pedidos/
Authorization: Bearer {token}

Query params:
- estado: pendiente, confirmado, en_camino, entregado, cancelado
```

### Repartidores

#### Pedidos Disponibles
```http
GET /api/repartidores/pedidos-disponibles/
Authorization: Bearer {token}
```

#### Aceptar Pedido
```http
POST /api/repartidores/aceptar-pedido/{pedido_id}/
Authorization: Bearer {token}
```

#### Actualizar Ubicación
```http
POST /api/repartidores/actualizar-ubicacion/
Authorization: Bearer {token}
Content-Type: application/json

{
  "latitud": -1.2345678,
  "longitud": -78.1234567
}
```

### Admin

#### Dashboard
```http
GET /api/admin/dashboard/
Authorization: Bearer {token}

Response:
{
  "total_usuarios": 150,
  "total_proveedores": 45,
  "total_repartidores": 30,
  "pedidos_activos": 25,
  "ingresos_hoy": 1250.50
}
```

#### Solicitudes de Cambio de Rol
```http
GET /api/admin/solicitudes/
Authorization: Bearer {token}

Query params:
- estado: pendiente, aprobada, rechazada
- rol_solicitado: proveedor, repartidor
```

**Ver documentación completa de endpoints en:** `documentacion/`

---

## 🛠️ Tecnologías

### Backend
- **Django 4.2** - Framework web
- **Django REST Framework** - API REST
- **PostgreSQL** - Base de datos
- **Redis** - Cache y mensajería
- **Celery** - Tareas asíncronas
- **Firebase Admin** - Notificaciones push
- **JWT** - Autenticación

### Frontend
- **React 18** - UI Library
- **Vite** - Build tool
- **Tailwind CSS** - Estilos
- **Axios** - HTTP client
- **React Router** - Enrutamiento

### Mobile
- **Flutter 3.x** - Framework multiplataforma
- **Provider** - State management
- **HTTP** - Peticiones API
- **Firebase Messaging** - Push notifications
- **Google Maps Flutter** - Mapas
- **Image Picker** - Selector de imágenes

### DevOps
- **Docker** - Contenedores
- **Docker Compose** - Orquestación
- **GitHub Actions** - CI/CD
- **Nginx** - Servidor web (producción)

---

## 👥 Contribución

1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Convenciones de Commits

```
feat: Nueva característica
fix: Corrección de bug
docs: Cambios en documentación
style: Cambios de formato (no afectan el código)
refactor: Refactorización de código
test: Agregar o modificar tests
chore: Tareas de mantenimiento
```

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 📞 Contacto

**Proyecto Delibery** - [@BETACRD01](https://github.com/BETACRD01)

**Link del Proyecto:** [https://github.com/BETACRD01/delibery](https://github.com/BETACRD01/delibery)

---

## 🙏 Agradecimientos

- [Django Documentation](https://docs.djangoproject.com/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [React Documentation](https://react.dev/)
- [Firebase](https://firebase.google.com/)

---

**Desarrollado con ❤️ para revolucionar el delivery**
