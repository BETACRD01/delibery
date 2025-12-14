from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()

class AdminResetPasswordSerializer(serializers.Serializer):
    nueva_password = serializers.CharField(write_only=True, min_length=8)
    confirmar_password = serializers.CharField(write_only=True, min_length=8)

    def validate(self, data):
        if data["nueva_password"] != data["confirmar_password"]:
            raise serializers.ValidationError("Las contraseñas no coinciden.")
        return data

    def save(self, user):
        user.set_password(self.validated_data["nueva_password"])
        user.reset_password_attempts = 0
        user.reset_password_code = None
        user.reset_password_expire = None
        user.save()
        return user
