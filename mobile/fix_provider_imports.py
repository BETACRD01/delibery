import os
import re

# Mapping of file names to their new relative path from 'lib/providers'
MOVED_PROVIDERS = {
    'proveedor_roles.dart': 'auth/proveedor_roles.dart',
    'proveedor_pedido.dart': 'orders/proveedor_pedido.dart',
    'proveedor_carrito.dart': 'cart/proveedor_carrito.dart',
    'productos_provider.dart': 'products/productos_provider.dart',
    'theme_provider.dart': 'core/theme_provider.dart',
    'locale_provider.dart': 'core/locale_provider.dart',
    'preferencias_provider.dart': 'core/preferencias_provider.dart',
    'notificaciones_provider.dart': 'core/notificaciones_provider.dart',
}

ROOT_DIR = '/Users/willian/Desktop/Proyecto/delibery/mobile/lib'

def fix_imports():
    count = 0
    for root, dirs, files in os.walk(ROOT_DIR):
        for file in files:
            if not file.endswith('.dart'):
                continue
            
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            modified = False
            
            for filename, new_rel_path in MOVED_PROVIDERS.items():
                # 1. Fix package imports:
                #    import 'package:delibery/providers/proveedor_roles.dart'; 
                # -> import 'package:delibery/providers/auth/proveedor_roles.dart';
                
                pattern_pkg = re.compile(r'package:delibery/providers/' + re.escape(filename))
                replacement_pkg = f'package:delibery/providers/{new_rel_path}'
                
                if pattern_pkg.search(new_content):
                    new_content = pattern_pkg.sub(replacement_pkg, new_content)
                    modified = True

                # 2. Fix relative imports
                # e.g. import '../providers/proveedor_roles.dart';
                # -> import '../providers/auth/proveedor_roles.dart';
                
                subdir = new_rel_path.split('/')[0] # e.g. auth
                
                # Match /filename NOT preceded by /subdir/
                
                # Capture group 1: path prefix ending in providers/ or / or ../
                pattern_rel = re.compile(r'((?:\.\./)+|providers/|/)' + re.escape(filename) + r"(['\";])")
                
                def replace_rel(match):
                    prefix = match.group(1)
                    closing = match.group(2)
                    if prefix.endswith(f'/{subdir}/'):
                            return match.group(0)
                    return f'{prefix}{subdir}/{filename}{closing}'

                if pattern_rel.search(new_content):
                    new_content = pattern_rel.sub(replace_rel, new_content)
                    modified = True

            if modified:
                print(f"Fixing imports in {file}")
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += 1
                
    print(f"Finished. Modified {count} files.")

if __name__ == '__main__':
    fix_imports()
