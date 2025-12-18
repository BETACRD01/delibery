# -*- coding: utf-8 -*-
# usuarios/signals.py

from django.db import IntegrityError
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import Group
from authentication.models import User

from .models import Perfil

__all__ = ["manage_user_profile"]


@receiver(post_save, sender=User)
def manage_user_profile(sender, instance, created, **kwargs):
    if not created:
        return

    try:
        Perfil.objects.get_or_create(user=instance)
    except IntegrityError:
        # Otro proceso ya creó el perfil en paralelo
        pass

    try:
        cliente_group, _ = Group.objects.get_or_create(name="Cliente")
        instance.groups.add(cliente_group)
    except Exception:
        # El grupo no existe o hay un problema con el ORM, se ignora para no bloquear el login
        pass
