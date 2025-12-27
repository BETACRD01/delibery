from django.db import models
from django.utils import timezone


class DocumentoLegal(models.Model):
    """
    Modelo para almacenar documentos legales como términos y condiciones
    y política de privacidad que pueden ser modificados por el administrador.
    """
    TIPO_CHOICES = [
        ('terminos', 'Términos y Condiciones'),
        ('privacidad', 'Política de Privacidad'),
    ]

    tipo = models.CharField(
        max_length=20,
        choices=TIPO_CHOICES,
        unique=True,
        verbose_name='Tipo de Documento'
    )
    contenido = models.TextField(
        verbose_name='Contenido',
        help_text='Contenido del documento legal (puede usar HTML)'
    )
    version = models.CharField(
        max_length=20,
        default='1.0',
        verbose_name='Versión'
    )
    activo = models.BooleanField(
        default=True,
        verbose_name='Activo',
        help_text='Indica si este documento está actualmente vigente'
    )
    fecha_creacion = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Fecha de Creación'
    )
    fecha_modificacion = models.DateTimeField(
        auto_now=True,
        verbose_name='Fecha de Modificación'
    )
    modificado_por = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name='Modificado por',
        help_text='Usuario que realizó la última modificación'
    )

    class Meta:
        verbose_name = 'Documento Legal'
        verbose_name_plural = 'Documentos Legales'
        ordering = ['tipo']

    def __str__(self):
        return f"{self.get_tipo_display()} - v{self.version}"

    def save(self, *args, **kwargs):
        # Actualizar fecha de modificación
        if self.pk:
            self.fecha_modificacion = timezone.now()
        super().save(*args, **kwargs)
