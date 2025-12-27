from django.core.management.base import BaseCommand
from legal.models import DocumentoLegal


class Command(BaseCommand):
    help = 'Crea documentos legales de prueba (Términos y Condiciones, Política de Privacidad)'

    def handle(self, *args, **kwargs):
        self.stdout.write('Creando documentos legales de prueba...')

        # Términos y Condiciones
        terminos_contenido = """
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; padding: 20px; line-height: 1.6; color: #333;">
    <h1 style="color: #0cb7f2; font-size: 28px; margin-bottom: 20px;">Términos y Condiciones de Uso</h1>
    <p style="color: #666; font-size: 14px; margin-bottom: 30px;">Última actualización: Diciembre 2024 | Versión 1.0</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">1. Aceptación de los Términos</h2>
    <p>Al acceder y utilizar la plataforma JP Express, usted acepta estar sujeto a estos Términos y Condiciones de Uso. Si no está de acuerdo con alguno de estos términos, no debe utilizar nuestros servicios.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">2. Descripción del Servicio</h2>
    <p>JP Express es una plataforma digital que conecta usuarios con proveedores locales y repartidores para facilitar la entrega de productos y servicios. Actuamos como intermediarios entre las partes y no somos responsables de la calidad, seguridad o legalidad de los productos ofrecidos.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">3. Registro y Cuenta de Usuario</h2>
    <p><strong>3.1 Requisitos:</strong> Debes tener al menos 18 años para crear una cuenta. Al registrarte, garantizas que toda la información proporcionada es veraz, precisa y actualizada.</p>
    <p><strong>3.2 Seguridad:</strong> Eres responsable de mantener la confidencialidad de tu contraseña y de todas las actividades realizadas desde tu cuenta.</p>
    <p><strong>3.3 Suspensión:</strong> Nos reservamos el derecho de suspender o cancelar cuentas que violen estos términos o realicen actividades fraudulentas.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">4. Uso de la Plataforma</h2>
    <p><strong>4.1 Conducta del Usuario:</strong> Te comprometes a utilizar la plataforma de manera responsable y legal. Está prohibido:</p>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li>Realizar pedidos fraudulentos o con información falsa</li>
        <li>Utilizar la plataforma para actividades ilegales</li>
        <li>Intentar acceder de manera no autorizada a sistemas o cuentas</li>
        <li>Acosar, intimidar o amenazar a otros usuarios, proveedores o repartidores</li>
    </ul>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">5. Pedidos y Pagos</h2>
    <p><strong>5.1 Realización de Pedidos:</strong> Al realizar un pedido, confirmas que tienes autorización para usar el método de pago proporcionado.</p>
    <p><strong>5.2 Precios:</strong> Los precios mostrados incluyen impuestos aplicables. Los costos de envío se calculan según la distancia y tipo de servicio.</p>
    <p><strong>5.3 Métodos de Pago:</strong> Aceptamos pagos mediante tarjeta de crédito/débito, transferencias bancarias y efectivo (cuando esté disponible).</p>
    <p><strong>5.4 Cancelaciones:</strong> Puedes cancelar pedidos antes de que sean aceptados por el proveedor. Una vez aceptados, las políticas de cancelación del proveedor aplican.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">6. Entregas</h2>
    <p><strong>6.1 Tiempos de Entrega:</strong> Los tiempos estimados son aproximados y pueden variar según condiciones del tráfico, clima u otros factores.</p>
    <p><strong>6.2 Responsabilidad:</strong> El repartidor es responsable de entregar el pedido en la dirección proporcionada. Debes estar disponible para recibir el pedido.</p>
    <p><strong>6.3 Problemas con la Entrega:</strong> Si hay problemas con tu pedido (productos incorrectos, faltantes o dañados), contacta a soporte dentro de las 24 horas.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">7. Devoluciones y Reembolsos</h2>
    <p>Las políticas de devolución varían según el proveedor. Los reembolsos se procesarán según el método de pago original y pueden tardar entre 5-10 días hábiles en reflejarse.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">8. Propiedad Intelectual</h2>
    <p>Todos los contenidos de la plataforma (logos, diseños, textos, imágenes) son propiedad de JP Express o sus licenciantes y están protegidos por leyes de propiedad intelectual.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">9. Limitación de Responsabilidad</h2>
    <p>JP Express no se hace responsable por daños indirectos, incidentales o consecuentes derivados del uso de la plataforma. Nuestra responsabilidad total no excederá el monto del pedido en cuestión.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">10. Modificaciones</h2>
    <p>Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios serán notificados a través de la plataforma y entrarán en vigor inmediatamente.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">11. Ley Aplicable</h2>
    <p>Estos términos se rigen por las leyes de Ecuador. Cualquier disputa será resuelta en los tribunales competentes de Ecuador.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">12. Contacto</h2>
    <p>Para consultas sobre estos términos, contacta a:</p>
    <p style="margin-left: 20px;">
        <strong>JP Express</strong><br>
        Email: soporte@jpexpress.com<br>
        Teléfono: +593-XXX-XXXX
    </p>

    <div style="margin-top: 40px; padding: 20px; background-color: #f0f9ff; border-left: 4px solid #0cb7f2; border-radius: 4px;">
        <p style="margin: 0; font-size: 14px; color: #0369a1;">
            <strong>Nota:</strong> Este es un documento legal de prueba. El administrador debe personalizar estos términos según las necesidades específicas del negocio y consultar con un abogado para asegurar el cumplimiento legal completo.
        </p>
    </div>
</div>
        """

        # Política de Privacidad
        privacidad_contenido = """
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; padding: 20px; line-height: 1.6; color: #333;">
    <h1 style="color: #0cb7f2; font-size: 28px; margin-bottom: 20px;">Política de Privacidad</h1>
    <p style="color: #666; font-size: 14px; margin-bottom: 30px;">Última actualización: Diciembre 2024 | Versión 1.0</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">1. Introducción</h2>
    <p>En JP Express valoramos tu privacidad y nos comprometemos a proteger tus datos personales. Esta Política de Privacidad explica cómo recopilamos, usamos, compartimos y protegemos tu información personal cuando utilizas nuestros servicios.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">2. Información que Recopilamos</h2>

    <h3 style="color: #555; font-size: 18px; margin-top: 20px; margin-bottom: 10px;">2.1 Información que Proporcionas</h3>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li><strong>Datos de Cuenta:</strong> Nombre, apellido, correo electrónico, número de teléfono, contraseña</li>
        <li><strong>Información de Entrega:</strong> Direcciones de entrega, instrucciones especiales</li>
        <li><strong>Información de Pago:</strong> Datos de tarjetas de crédito/débito, información bancaria (procesada de forma segura)</li>
        <li><strong>Preferencias:</strong> Categorías favoritas, proveedores preferidos, historial de pedidos</li>
    </ul>

    <h3 style="color: #555; font-size: 18px; margin-top: 20px; margin-bottom: 10px;">2.2 Información Recopilada Automáticamente</h3>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li><strong>Datos de Ubicación:</strong> Ubicación GPS para facilitar entregas y mostrar proveedores cercanos</li>
        <li><strong>Información del Dispositivo:</strong> Modelo del dispositivo, sistema operativo, identificadores únicos</li>
        <li><strong>Datos de Uso:</strong> Páginas visitadas, productos vistos, tiempo de uso, interacciones en la app</li>
        <li><strong>Cookies y Tecnologías Similares:</strong> Para mejorar tu experiencia y analizar el uso de la plataforma</li>
    </ul>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">3. Cómo Usamos tu Información</h2>
    <p>Utilizamos tu información personal para:</p>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li>Procesar y entregar tus pedidos</li>
        <li>Gestionar tu cuenta y preferencias</li>
        <li>Procesar pagos y prevenir fraudes</li>
        <li>Enviarte notificaciones sobre el estado de tus pedidos</li>
        <li>Mejorar nuestros servicios y desarrollar nuevas funcionalidades</li>
        <li>Personalizar tu experiencia en la plataforma</li>
        <li>Cumplir con obligaciones legales y regulatorias</li>
        <li>Enviar comunicaciones promocionales (con tu consentimiento)</li>
    </ul>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">4. Compartir Información</h2>

    <h3 style="color: #555; font-size: 18px; margin-top: 20px; margin-bottom: 10px;">Compartimos tu información con:</h3>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li><strong>Proveedores y Repartidores:</strong> Información necesaria para completar tu pedido (nombre, dirección, teléfono)</li>
        <li><strong>Procesadores de Pago:</strong> Información de pago para procesar transacciones de forma segura</li>
        <li><strong>Proveedores de Servicios:</strong> Empresas que nos ayudan a operar (hosting, análisis, soporte al cliente)</li>
        <li><strong>Autoridades Legales:</strong> Cuando sea requerido por ley o para proteger nuestros derechos</li>
    </ul>

    <p style="margin-top: 15px;"><strong>No vendemos</strong> tu información personal a terceros para fines de marketing.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">5. Seguridad de los Datos</h2>
    <p>Implementamos medidas de seguridad técnicas, administrativas y físicas para proteger tu información:</p>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li>Encriptación SSL/TLS para transmisión de datos</li>
        <li>Almacenamiento seguro de contraseñas (hash y salt)</li>
        <li>Acceso restringido a información personal</li>
        <li>Monitoreo continuo de seguridad</li>
        <li>Cumplimiento con estándares de seguridad PCI DSS para pagos</li>
    </ul>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">6. Tus Derechos</h2>
    <p>Tienes derecho a:</p>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li><strong>Acceder:</strong> Solicitar una copia de tus datos personales</li>
        <li><strong>Rectificar:</strong> Corregir información inexacta o incompleta</li>
        <li><strong>Eliminar:</strong> Solicitar la eliminación de tus datos (sujeto a obligaciones legales)</li>
        <li><strong>Limitar:</strong> Restringir el procesamiento de tus datos</li>
        <li><strong>Portabilidad:</strong> Recibir tus datos en formato estructurado</li>
        <li><strong>Oposición:</strong> Oponerte al procesamiento de tus datos para ciertos fines</li>
        <li><strong>Retirar Consentimiento:</strong> Retirar el consentimiento previamente otorgado</li>
    </ul>

    <p style="margin-top: 15px;">Para ejercer estos derechos, contacta a: <strong>privacidad@jpexpress.com</strong></p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">7. Retención de Datos</h2>
    <p>Conservamos tu información personal mientras tu cuenta esté activa o según sea necesario para proporcionar servicios. Tras la eliminación de tu cuenta, retendremos cierta información durante el tiempo requerido por obligaciones legales, contables o de auditoría.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">8. Menores de Edad</h2>
    <p>Nuestros servicios no están dirigidos a menores de 18 años. No recopilamos intencionalmente información de menores. Si detectamos que hemos recopilado datos de un menor, procederemos a eliminarlos inmediatamente.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">9. Transferencias Internacionales</h2>
    <p>Tus datos pueden ser transferidos y procesados en servidores ubicados fuera de Ecuador. Implementamos salvaguardas adecuadas para proteger tu información en estas transferencias.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">10. Cookies y Tecnologías de Seguimiento</h2>
    <p>Utilizamos cookies y tecnologías similares para:</p>
    <ul style="margin-left: 20px; margin-top: 10px;">
        <li>Mantener tu sesión iniciada</li>
        <li>Recordar tus preferencias</li>
        <li>Analizar el uso de la plataforma</li>
        <li>Personalizar contenido y anuncios</li>
    </ul>
    <p style="margin-top: 15px;">Puedes gestionar las cookies desde la configuración de tu navegador o dispositivo.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">11. Cambios a esta Política</h2>
    <p>Podemos actualizar esta Política de Privacidad periódicamente. Te notificaremos sobre cambios significativos a través de la plataforma o por correo electrónico. La fecha de "última actualización" al inicio del documento indica cuándo se realizó el cambio más reciente.</p>

    <h2 style="color: #333; font-size: 22px; margin-top: 30px; margin-bottom: 15px;">12. Contacto</h2>
    <p>Si tienes preguntas o inquietudes sobre esta política o nuestras prácticas de privacidad, contacta a:</p>
    <p style="margin-left: 20px;">
        <strong>JP Express - Departamento de Privacidad</strong><br>
        Email: privacidad@jpexpress.com<br>
        Teléfono: +593-XXX-XXXX<br>
        Dirección: [Dirección física en Ecuador]
    </p>

    <div style="margin-top: 40px; padding: 20px; background-color: #f0f9ff; border-left: 4px solid #0cb7f2; border-radius: 4px;">
        <p style="margin: 0; font-size: 14px; color: #0369a1;">
            <strong>Nota:</strong> Esta es una política de privacidad de prueba. El administrador debe personalizarla según las prácticas reales de manejo de datos y consultar con un especialista en privacidad para asegurar el cumplimiento con regulaciones aplicables (GDPR, CCPA, leyes locales de Ecuador, etc.).
        </p>
    </div>
</div>
        """

        # Crear o actualizar Términos y Condiciones
        terminos, created = DocumentoLegal.objects.update_or_create(
            tipo='terminos',
            defaults={
                'contenido': terminos_contenido.strip(),
                'version': '1.0',
                'activo': True,
                'modificado_por': 'Sistema'
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('✓ Términos y Condiciones creados'))
        else:
            self.stdout.write(self.style.WARNING('⚠ Términos y Condiciones actualizados'))

        # Crear o actualizar Política de Privacidad
        privacidad, created = DocumentoLegal.objects.update_or_create(
            tipo='privacidad',
            defaults={
                'contenido': privacidad_contenido.strip(),
                'version': '1.0',
                'activo': True,
                'modificado_por': 'Sistema'
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('✓ Política de Privacidad creada'))
        else:
            self.stdout.write(self.style.WARNING('⚠ Política de Privacidad actualizada'))

        self.stdout.write(self.style.SUCCESS('\n¡Documentos legales inicializados correctamente!'))
        self.stdout.write(self.style.SUCCESS('Los administradores pueden editarlos desde el panel de admin Django.'))
