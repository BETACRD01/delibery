#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys


def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings.settings")

    try:
        import django
        django.setup()
    except Exception as exc:
        raise SystemExit(f"No se pudo inicializar Django: {exc}")

    from proveedores.models import Proveedor
    from calificaciones.models import _recalcular_rating_proveedor

    proveedores = Proveedor.objects.all()
    total = proveedores.count()
    if total == 0:
        print("No hay proveedores para recalcular.")
        return

    print(f"Recalculando rating para {total} proveedores...")
    for index, proveedor in enumerate(proveedores, start=1):
        _recalcular_rating_proveedor(proveedor)
        if index % 25 == 0:
            print(f"Procesados {index}/{total}")

    print("Listo.")


if __name__ == "__main__":
    sys.exit(main())
