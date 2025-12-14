from django.db import migrations, models
import repartidores.models


class Migration(migrations.Migration):

    dependencies = [
        ('repartidores', '0002_repartidor_banco_cedula_titular_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='repartidor',
            name='vehiculo',
            field=models.CharField(
                choices=repartidores.models.TipoVehiculo.choices,
                default='motocicleta',
                help_text='Medio de transporte principal',
                max_length=20,
            ),
        ),
    ]
