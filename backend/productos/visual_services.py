# backend/productos/visual_services.py

class CategoriaVisualizer:
    """
    Servicio dedicado a la lógica visual de las categorías.
    Decide si se muestra una FOTO (URL) o un ICONO (String) + COLOR.
    """

    # 1. ICONOS (Nombre Categoría -> Icono Flutter)
    ICON_DEFAULTS = {
        'comida': 'fastfood',
        'hamburguesas': 'lunch_dining',
        'pizza': 'local_pizza',
        'bebidas': 'local_drink',
        'postres': 'cake',
        'helados': 'icecream',
        'farmacia': 'medical_services',
        'licores': 'liquor',
        'cafe': 'local_cafe',
        'desayunos': 'breakfast_dining',
        'default': 'category'
    }

    # 2. COLORES (Nombre Categoría -> Color Hexadecimal)
    # Estos colores generan el fondo suave que querías
    COLOR_DEFAULTS = {
        'comida': '#E53935',    # Rojo (Fondo Rosado)
        'hamburguesas': '#E53935',
        'bebidas': '#1E88E5',   # Azul (Fondo Celeste)
        'postres': '#FB8C00',   # Naranja
        'pizza': '#D84315',     # Marrón/Naranja Oscuro
        'helados': '#00ACC1',   # Cian
        'farmacia': '#43A047',  # Verde
        'default': '#1E88E5'    # Azul por defecto
    }

    @staticmethod
    def procesar_visualizacion(categoria, request=None):
        """
        Analiza la categoría y retorna la configuración visual exacta.
        """
        
        # CASO 1: Hay foto real
        if categoria.imagen:
            url_imagen = categoria.imagen.url
            if request:
                url_imagen = request.build_absolute_uri(url_imagen)
                
            return {
                "tipo": "IMAGEN",
                "contenido": url_imagen,
                "color_hex": "#FFFFFF" 
            }

        # CASO 2: No hay foto -> Usar Icono y Color Específico
        nombre_normalizado = categoria.nombre.lower().strip()
        
        # Buscar icono
        nombre_icono = CategoriaVisualizer.ICON_DEFAULTS.get(
            nombre_normalizado, 
            CategoriaVisualizer.ICON_DEFAULTS['default']
        )

        # Buscar color (AQUÍ ESTÁ LA MAGIA VISUAL)
        color_hex = CategoriaVisualizer.COLOR_DEFAULTS.get(
            nombre_normalizado,
            CategoriaVisualizer.COLOR_DEFAULTS['default']
        )

        return {
            "tipo": "ICONO",
            "contenido": nombre_icono, 
            "color_hex": color_hex  # Ahora enviamos el color correcto para cada uno
        }