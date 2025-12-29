# -*- coding: utf-8 -*-
# authentication/views.py

from django.contrib.auth import authenticate
from django.contrib.auth.hashers import make_password, check_password
from django.conf import settings
from django.utils import timezone
from django.db import models
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User
from .serializers import (
    RegistroSerializer,
    LoginSerializer,
    CambiarPasswordSerializer,
    SolicitarCodigoRecuperacionSerializer,
    VerificarCodigoRecuperacionSerializer,
    ResetPasswordConCodigoSerializer,
    ActualizarPerfilSerializer,
    PreferenciasNotificacionesSerializer,
    DesactivarCuentaSerializer,
    UserSerializer,
)
from .throttles import (
    LoginRateThrottle,
    RegisterRateThrottle,
    PasswordResetRateThrottle,
)
import logging
import random
from datetime import timedelta

logger = logging.getLogger("authentication")


# ==========================================
# CONSTANTES
# ==========================================
CODIGO_EXPIRACION_MINUTOS = 15
MAX_INTENTOS_CODIGO = 5


# ==========================================
# HELPER FUNCTIONS
# ==========================================


ROLE_MAP = {
    'cliente': 'USUARIO',
    'usuario': 'USUARIO',
    'proveedor': 'PROVEEDOR',
    'repartidor': 'REPARTIDOR',
    'admin': 'ADMINISTRADOR',
    'administrador': 'ADMINISTRADOR',
}


def _obtener_rol_estandarizado(user):
    """
    Devuelve un rol en mayúsculas según el rol activo/tipo del usuario.
    """
    valor = (user.rol_activo or user.tipo_usuario or '').lower()

    # FIX: Prioridad Admin para staff/superusers
    # Si tiene rol 'cliente' pero es admin, devolvemos ADMINISTRADOR
    if (user.is_staff or user.is_superuser) and (not valor or valor == 'cliente'):
        return 'ADMINISTRADOR'

    if valor in ROLE_MAP:
        return ROLE_MAP[valor]
    return 'USUARIO'


def get_tokens_for_user(user):
    """
    Genera tokens JWT con claims personalizados
    """
    rol = _obtener_rol_estandarizado(user)
    refresh = RefreshToken.for_user(user)

    # Agregar claims personalizados al token
    refresh["user_id"] = user.id
    refresh["email"] = user.email
    refresh["rol"] = rol

    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
        "user_id": user.id,
        "email": user.email,
        "rol": rol,
    }


def get_client_ip(request):
    """Obtiene la IP real del cliente"""
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        ip = x_forwarded_for.split(",")[0].strip()
    else:
        ip = request.META.get("REMOTE_ADDR")
    return ip


def generar_codigo_recuperacion():
    """
    Genera un código de 6 dígitos aleatorio
    """
    return "".join([str(random.randint(0, 9)) for _ in range(6)])


def serializar_usuario_basico(user):
    """
    Serializa datos básicos del usuario
    """
    return {
        "id": user.id,
        "email": user.email,
        "nombre": user.first_name,
        "apellido": user.last_name,
        "celular": user.celular,
        "username": user.username,
    }


# ==========================================
# AUTENTICACIÓN BÁSICA
# ==========================================


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([RegisterRateThrottle])
def registro(request):
    """
    Registra un nuevo usuario con creación garantizada de Perfil
     CORREGIDO: Copia fecha_nacimiento al Perfil
    """
    try:
        serializer = RegistroSerializer(data=request.data, context={"request": request})

        if serializer.is_valid():
            user = serializer.save()
            logger.info(f"👤 Usuario creado: {user.email}")

            try:
                from usuarios.models import Perfil

                # CORREGIDO: Copiar fecha_nacimiento al Perfil
                perfil, created = Perfil.objects.get_or_create(
                    user=user,
                    defaults={
                        'fecha_nacimiento': user.fecha_nacimiento,  # Copiar aquí
                    }
                )

                if created:
                    logger.info(f"Perfil creado para usuario: {user.email} con fecha_nacimiento: {user.fecha_nacimiento}")
                else:
                    # Si ya existía, actualizar fecha_nacimiento
                    if user.fecha_nacimiento and not perfil.fecha_nacimiento:
                        perfil.fecha_nacimiento = user.fecha_nacimiento
                        perfil.save(update_fields=['fecha_nacimiento'])
                    logger.info(f"👁️ Perfil ya existía para: {user.email}")

            except Exception as perfil_error:
                logger.error(
                    f"Error creando perfil para {user.email}: {perfil_error}",
                    exc_info=True,
                )

            tokens = get_tokens_for_user(user)
            usuario_data = UserSerializer(user).data

            try:
                from .email_utils import enviar_email_bienvenida

                enviar_email_bienvenida(user)
                logger.info(f"Email de bienvenida enviado a: {user.email}")
            except Exception as email_error:
                logger.error(f"Error enviando email: {email_error}")

            logger.info(f"[OK] Registro exitoso: {user.email}")

            return Response(
                {
                    "mensaje": "Usuario registrado exitosamente",
                    "usuario": usuario_data,
                    "tokens": tokens,
                },
                status=status.HTTP_201_CREATED,
            )

        logger.warning(f"Validación fallida en registro: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error en registro: {e}", exc_info=True)
        return Response(
            {
                "error": "Error al registrar usuario",
                "detalle": str(e) if settings.DEBUG else None,
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([LoginRateThrottle])
def login(request):
    """
    Inicia sesión de usuario

    Request body:
        {
            "identificador": "juan@ejemplo.com",  // email o username
            "password": "SecurePass123"
        }
    """
    try:
        serializer = LoginSerializer(data=request.data, context={"request": request})

        if serializer.is_valid():
            user = serializer.validated_data["user"]
            ip_address = get_client_ip(request)
            user.registrar_login_exitoso(ip_address)

            tokens = get_tokens_for_user(user)
            usuario_data = UserSerializer(user).data

            # FIX: Asegurar que el frontend reciba el rol correcto en el objeto usuario
            if (user.is_staff or user.is_superuser) and (not user.rol_activo or user.rol_activo == 'cliente'):
                 usuario_data['rol_activo'] = 'ADMINISTRADOR'

            logger.info(f"[OK] Login exitoso: {user.email} desde IP {ip_address}")

            return Response(
                {"mensaje": "Login exitoso", "usuario": usuario_data, "tokens": tokens},
                status=status.HTTP_200_OK,
            )

        return Response(serializer.errors, status=status.HTTP_401_UNAUTHORIZED)

    except Exception as e:
        logger.error(f"[ERROR] Error en login: {e}")
        return Response(
            {
                "error": "Error al iniciar sesión",
                "detalle": str(e) if settings.DEBUG else None,
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    Cierra sesión del usuario

    Request body:
        {
            "refresh_token": "token_aqui"
        }
    """
    try:
        refresh_token = request.data.get("refresh_token")

        if refresh_token:
            try:
                token = RefreshToken(refresh_token)
                token.blacklist()
            except Exception as e:
                logger.warning(f"[!] Error al blacklistear token: {e}")

        logger.info(f"[OK] Logout exitoso: {request.user.email}")

        return Response({"mensaje": "Logout exitoso"}, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"[ERROR] Error en logout: {e}")
        return Response(
            {"error": "Error al cerrar sesión"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# ==========================================
# PERFIL Y CONFIGURACIÓN
# ==========================================


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def perfil(request):
    """
    Obtiene el perfil completo del usuario autenticado
    """
    try:
        usuario_data = UserSerializer(request.user).data

        return Response(
            {"mensaje": "Perfil obtenido", "usuario": usuario_data},
            status=status.HTTP_200_OK,
        )

    except Exception as e:
        logger.error(f"Error obteniendo perfil: {e}")
        return Response(
            {"error": "Error al obtener perfil"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["PATCH", "PUT"])
@permission_classes([IsAuthenticated])
def actualizar_perfil(request):
    """
    Actualiza información del perfil del usuario
    """
    try:
        serializer = ActualizarPerfilSerializer(
            request.user, data=request.data, partial=True
        )

        if serializer.is_valid():
            serializer.save()
            usuario_data = UserSerializer(request.user).data

            logger.info(f"Perfil actualizado: {request.user.email}")

            return Response(
                {"mensaje": "Perfil actualizado", "usuario": usuario_data},
                status=status.HTTP_200_OK,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error actualizando perfil: {e}")
        return Response(
            {"error": "Error al actualizar perfil"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def verificar_token(request):
    """
    Verifica si el token es válido
    """
    return Response(
        {
            "mensaje": "Token válido",
            "usuario": {"id": request.user.id, "email": request.user.email},
        },
        status=status.HTTP_200_OK,
    )


# ==========================================
# GESTIÓN DE CONTRASEÑA
# ==========================================


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cambiar_password(request):
    """
    Cambia la contraseña del usuario autenticado
    """
    try:
        serializer = CambiarPasswordSerializer(
            data=request.data, context={"request": request}
        )

        if serializer.is_valid():
            serializer.save()

            # Enviar email de confirmación
            try:
                from .email_utils import enviar_confirmacion_cambio_password

                enviar_confirmacion_cambio_password(request.user)
            except Exception as e:
                logger.error(f"Error enviando email de confirmación: {e}")

            logger.info(f"Contraseña cambiada: {request.user.email}")

            return Response(
                {"mensaje": "Contraseña actualizada exitosamente"},
                status=status.HTTP_200_OK,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error cambiando contraseña: {e}")
        return Response(
            {"error": "Error al cambiar contraseña"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([PasswordResetRateThrottle])
def solicitar_codigo_recuperacion(request):
    """
    Solicita un código de 6 dígitos para recuperación de contraseña
    """
    try:
        serializer = SolicitarCodigoRecuperacionSerializer(data=request.data)

        if serializer.is_valid():
            email = serializer.validated_data["email"]

            try:
                user = User.objects.get(email=email)

                # Generar código
                codigo = user.generar_codigo_recuperacion()

                # Enviar email
                from .email_utils import enviar_codigo_recuperacion_password

                enviar_codigo_recuperacion_password(user, codigo)

                logger.info(f"Código de recuperación enviado a: {email}")

                return Response(
                    {
                        "mensaje": "Código enviado a tu email",
                        "email": email,
                        "expira_en_minutos": CODIGO_EXPIRACION_MINUTOS,
                    },
                    status=status.HTTP_200_OK,
                )

            except User.DoesNotExist:
                # Por seguridad, no revelar si el email existe
                return Response(
                    {
                        "mensaje": "Si el email existe, recibirás un código",
                        "expira_en_minutos": CODIGO_EXPIRACION_MINUTOS,
                    },
                    status=status.HTTP_200_OK,
                )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error solicitando código: {e}")
        return Response(
            {"error": "Error al solicitar código"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
def verificar_codigo_recuperacion(request):
    """
    Verifica el código de 6 dígitos
    """
    try:
        serializer = VerificarCodigoRecuperacionSerializer(data=request.data)

        if serializer.is_valid():
            email = serializer.validated_data["email"]
            codigo = serializer.validated_data["codigo"]

            try:
                user = User.objects.get(email=email)
                es_valido, mensaje = user.verificar_codigo_recuperacion(codigo)

                if es_valido:
                    return Response(
                        {"mensaje": "Código válido", "email": email},
                        status=status.HTTP_200_OK,
                    )
                else:
                    return Response(
                        {"error": mensaje}, status=status.HTTP_400_BAD_REQUEST
                    )

            except User.DoesNotExist:
                return Response(
                    {"error": "Email no encontrado"},
                    status=status.HTTP_404_NOT_FOUND,
                )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error verificando código: {e}")
        return Response(
            {"error": "Error al verificar código"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
def reset_password_con_codigo(request):
    """
    Resetea la contraseña usando el código de 6 dígitos
    """
    try:
        serializer = ResetPasswordConCodigoSerializer(data=request.data)

        if serializer.is_valid():
            email = serializer.validated_data["email"]
            codigo = serializer.validated_data["codigo"]
            password = serializer.validated_data["password"]

            try:
                user = User.objects.get(email=email)

                # Verificar código
                es_valido, mensaje = user.verificar_codigo_recuperacion(codigo)

                if not es_valido:
                    return Response(
                        {"error": mensaje}, status=status.HTTP_400_BAD_REQUEST
                    )

                # Cambiar contraseña
                user.set_password(password)
                user.limpiar_codigo_recuperacion()
                user.save()

                # Enviar email de confirmación
                try:
                    from .email_utils import enviar_confirmacion_cambio_password

                    enviar_confirmacion_cambio_password(user)
                except Exception as e:
                    logger.error(f"Error enviando email de confirmación: {e}")

                logger.info(f"Contraseña reseteada para: {email}")

                return Response(
                    {"mensaje": "Contraseña actualizada exitosamente"},
                    status=status.HTTP_200_OK,
                )

            except User.DoesNotExist:
                return Response(
                    {"error": "Email no encontrado"},
                    status=status.HTTP_404_NOT_FOUND,
                )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error reseteando contraseña: {e}")
        return Response(
            {"error": "Error al resetear contraseña"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# ==========================================
# PREFERENCIAS Y CUENTA
# ==========================================


@api_view(["GET", "PATCH", "PUT"])
@permission_classes([IsAuthenticated])
def preferencias_notificaciones(request):
    """
    Obtiene o actualiza preferencias de notificaciones
    """
    try:
        if request.method == "GET":
            serializer = PreferenciasNotificacionesSerializer(request.user)
            return Response(serializer.data, status=status.HTTP_200_OK)

        # PATCH/PUT
        serializer = PreferenciasNotificacionesSerializer(
            request.user, data=request.data, partial=True
        )

        if serializer.is_valid():
            serializer.save()

            logger.info(
                f"Preferencias de notificaciones actualizadas: {request.user.email}"
            )

            return Response(
                {"mensaje": "Preferencias actualizadas", "preferencias": serializer.data},
                status=status.HTTP_200_OK,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error en preferencias: {e}")
        return Response(
            {"error": "Error al actualizar preferencias"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def desactivar_cuenta(request):
    """
    Desactiva la cuenta del usuario
    """
    try:
        serializer = DesactivarCuentaSerializer(
            data=request.data, context={"request": request}
        )

        if serializer.is_valid():
            serializer.save()

            logger.info(f"Cuenta desactivada: {request.user.email}")

            return Response(
                {"mensaje": "Cuenta desactivada exitosamente"},
                status=status.HTTP_200_OK,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Error desactivando cuenta: {e}")
        return Response(
            {"error": "Error al desactivar cuenta"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# ==========================================
# UNSUBSCRIBE (DARSE DE BAJA)
# ==========================================


@api_view(["GET", "POST"])
@permission_classes([AllowAny])
def unsubscribe_emails(request, user_id, token):
    """
    Permite darse de baja de emails de marketing
    """
    try:
        from django.contrib.auth.tokens import default_token_generator

        user = User.objects.get(id=user_id)

        # Verificar token
        if not default_token_generator.check_token(user, token):
            return Response(
                {"error": "Link inválido o expirado"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Desactivar notificaciones
        user.notificaciones_email = False
        user.notificaciones_marketing = False
        user.save(
            update_fields=[
                "notificaciones_email",
                "notificaciones_marketing",
                "updated_at",
            ]
        )

        # Enviar confirmación
        try:
            from .email_utils import enviar_email_confirmacion_baja

            enviar_email_confirmacion_baja(user)
        except Exception as e:
            logger.error(f"Error enviando confirmación de baja: {e}")

        logger.info(f"Usuario dado de baja de emails: {user.email}")

        return Response(
            {"mensaje": "Te has dado de baja exitosamente de nuestros emails"},
            status=status.HTTP_200_OK,
        )

    except User.DoesNotExist:
        return Response(
            {"error": "Usuario no encontrado"}, status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        logger.error(f"Error en unsubscribe: {e}")
        return Response(
            {"error": "Error al procesar solicitud"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
    except Exception as e:
        logger.error(f"Error en unsubscribe: {e}")
        return Response(
            {"error": "Error al procesar solicitud"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# ==========================================
# DISPOSITIVOS CONECTADOS
# ==========================================

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def listar_dispositivos(request):
    """
    Lista las sesiones activas (Outstanding Tokens) del usuario.
    """
    try:
        from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
        
        # Obtener todos los tokens del usuario
        tokens = OutstandingToken.objects.filter(user=request.user).order_by('-created_at')
        
        # Filtrar los que ya están en blacklist
        # Nota: Esto podría optimizarse con una subquery o exclude, pero por simplicidad:
        blacklisted_ids = BlacklistedToken.objects.values_list('token_id', flat=True)
        
        activos = []
        for t in tokens:
            if t.id in blacklisted_ids:
                continue
            
            activos.append({
                "id": t.id,
                "creado": t.created_at,
                "dispositivo": "Sesión iniciada", # Placeholder ya que no guardamos UA todavía
                "ip": "No registrada" # Placeholder
            })
            
        return Response(activos, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error listando dispositivos: {e}")
        return Response(
            {"error": "Error al listar dispositivos"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cerrar_sesion_dispositivo(request, dispositivo_id):
    """
    Cierra sesión de un dispositivo específico (Blacklist token)
    """
    try:
        from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken

        try:
            token = OutstandingToken.objects.get(id=dispositivo_id, user=request.user)
        except OutstandingToken.DoesNotExist:
            return Response({"error": "Sesión no encontrada"}, status=status.HTTP_404_NOT_FOUND)

        # Blacklistear
        BlacklistedToken.objects.get_or_create(token=token)

        return Response({"mensaje": "Sesión cerrada exitosamente"}, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error cerrando sesión dispositivo: {e}")
        return Response(
            {"error": "Error al cerrar sesión"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
