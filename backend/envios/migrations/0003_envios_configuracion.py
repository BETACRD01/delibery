from decimal import Decimal

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import migrations, models


def crear_datos_por_defecto(apps, schema_editor):
    ZonaTarifariaEnvio = apps.get_model("envios", "ZonaTarifariaEnvio")
    CiudadEnvio = apps.get_model("envios", "CiudadEnvio")
    ConfiguracionEnvios = apps.get_model("envios", "ConfiguracionEnvios")

    zonas = [
        {
            "codigo": "centro",
            "nombre_display": "Centro (Urbano)",
            "tarifa_base": Decimal("1.50"),
            "km_incluidos": Decimal("1.50"),
            "precio_km_extra": Decimal("0.50"),
            "max_distancia_km": Decimal("3.0"),
            "orden": 1,
        },
        {
            "codigo": "periferica",
            "nombre_display": "Periferia Cercana",
            "tarifa_base": Decimal("2.50"),
            "km_incluidos": Decimal("2.00"),
            "precio_km_extra": Decimal("0.70"),
            "max_distancia_km": Decimal("8.0"),
            "orden": 2,
        },
        {
            "codigo": "rural",
            "nombre_display": "Fuera de Ciudad / Rural",
            "tarifa_base": Decimal("4.00"),
            "km_incluidos": Decimal("3.00"),
            "precio_km_extra": Decimal("1.00"),
            "max_distancia_km": None,
            "orden": 3,
        },
    ]

    for zona in zonas:
        ZonaTarifariaEnvio.objects.create(**zona)

    ciudades = [
        {
            "codigo": "BANOS",
            "nombre": "Baños de Agua Santa",
            "lat": Decimal("-1.3964"),
            "lng": Decimal("-78.4247"),
            "radio_max_cobertura_km": Decimal("15.0"),
        },
        {
            "codigo": "TENA",
            "nombre": "Tena",
            "lat": Decimal("-0.9938"),
            "lng": Decimal("-77.8129"),
            "radio_max_cobertura_km": Decimal("20.0"),
        },
    ]

    for ciudad in ciudades:
        CiudadEnvio.objects.create(**ciudad)

    ConfiguracionEnvios.objects.get_or_create(
        pk=1,
        defaults={
            "recargo_nocturno": Decimal("1.00"),
            "hora_inicio_nocturno": 20,
            "hora_fin_nocturno": 6,
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ("envios", "0002_envio_ciudad_origen_envio_zona_destino"),
    ]

    operations = [
        migrations.CreateModel(
            name="CiudadEnvio",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("codigo", models.CharField(max_length=32, unique=True, verbose_name="Código de ciudad")),
                ("nombre", models.CharField(max_length=120, verbose_name="Nombre oficial")),
                ("lat", models.DecimalField(decimal_places=6, max_digits=9, verbose_name="Latitud")),
                ("lng", models.DecimalField(decimal_places=6, max_digits=9, verbose_name="Longitud")),
                ("radio_max_cobertura_km", models.DecimalField(decimal_places=2, max_digits=5, verbose_name="Radio máximo de cobertura (km)")),
                ("activo", models.BooleanField(default=True, help_text="Solo las ciudades activas son consideradas durante la cotización", verbose_name="Activo")),
            ],
            options={
                "verbose_name": "Ciudad de Envío",
                "verbose_name_plural": "Ciudades de Envío",
            },
        ),
        migrations.CreateModel(
            name="ConfiguracionEnvios",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("recargo_nocturno", models.DecimalField(decimal_places=2, default=Decimal("1.00"), max_digits=6, verbose_name="Recargo nocturno", help_text="Valor adicional que se suma durante la franja nocturna")),
                ("hora_inicio_nocturno", models.PositiveSmallIntegerField(default=20, validators=[MinValueValidator(0), MaxValueValidator(23)], verbose_name="Hora inicio nocturno", help_text="Hora en formato 24h en la que aplica el recargo (inclusive)")),
                ("hora_fin_nocturno", models.PositiveSmallIntegerField(default=6, validators=[MinValueValidator(0), MaxValueValidator(23)], verbose_name="Hora fin nocturno", help_text="Hora en formato 24h en la que termina el recargo")),
                ("actualizado_en", models.DateTimeField(auto_now=True, verbose_name="Actualizado en")),
            ],
            options={
                "verbose_name": "Configuración de Envíos",
                "verbose_name_plural": "Configuraciones de Envíos",
            },
        ),
        migrations.CreateModel(
            name="ZonaTarifariaEnvio",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("codigo", models.CharField(choices=[("centro", "Centro (Urbano)"), ("periferica", "Periferia Cercana"), ("rural", "Fuera de Ciudad / Rural")], max_length=32, unique=True, verbose_name="Código de Zona", help_text="Identificador interno de la zona tarifaria")),
                ("nombre_display", models.CharField(max_length=80, verbose_name="Nombre para mostrar", help_text="Texto que verá el usuario en el breakdown")),
                ("tarifa_base", models.DecimalField(decimal_places=2, max_digits=10, verbose_name="Tarifa base", help_text="Costo mínimo por la prestación del servicio dentro de esta zona")),
                ("km_incluidos", models.DecimalField(decimal_places=2, max_digits=10, verbose_name="Kilómetros incluidos", help_text="Distancia cubierta por la tarifa base")),
                ("precio_km_extra", models.DecimalField(decimal_places=2, max_digits=10, verbose_name="Precio por km extra", help_text="Costo por cada kilómetro adicional después del límite")),
                ("max_distancia_km", models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True, verbose_name="Distancia máxima (km)", help_text="Distancia máxima para pertenecer a esta zona (dejar vacío para zona abierta)")),
                ("orden", models.PositiveSmallIntegerField(default=0, verbose_name="Orden de evaluación", help_text="Determina la prioridad al clasificarse las zonas")),
            ],
            options={
                "ordering": ["orden"],
                "verbose_name": "Zona Tarifaria",
                "verbose_name_plural": "Zonas Tarifarias",
            },
        ),
        migrations.RunPython(crear_datos_por_defecto, migrations.RunPython.noop),
    ]
