from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("pedidos", "0008_remove_pedido_pedidos_pedido__f7f4f0_idx_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="pedido",
            name="tarifa_servicio",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=6),
        ),
    ]

