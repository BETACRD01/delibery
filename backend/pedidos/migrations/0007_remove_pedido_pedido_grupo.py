# Generated manually to remove pedido_grupo field

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('pedidos', '0006_pedido_pedido_grupo_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='pedido',
            name='pedido_grupo',
        ),
    ]