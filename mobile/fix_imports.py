import os
import re

# Mapping of file names to their new relative path from 'lib/models'
# Note: 'user/...' files are now in 'users/...'
# Old paths were flat in 'models/' or in 'models/user/'
MOVED_FILES = {
    # auth
    'usuario.dart': 'auth/usuario.dart',
    'solicitud_cambio_rol.dart': 'auth/solicitud_cambio_rol.dart',
    'user_info.dart': 'auth/user_info.dart',
    # users
    'address.dart': 'users/address.dart',
    'profile.dart': 'users/profile.dart',
    'payment_method.dart': 'users/payment_method.dart',
    # products
    'producto_model.dart': 'products/producto_model.dart',
    'categoria_model.dart': 'products/categoria_model.dart',
    'categoria_super_model.dart': 'products/categoria_super_model.dart',
    'promocion_model.dart': 'products/promocion_model.dart',
    # orders
    'pedido_model.dart': 'orders/pedido_model.dart',
    'pedido_grupo.dart': 'orders/pedido_grupo.dart',
    'pedido_repartidor.dart': 'orders/pedido_repartidor.dart',
    'entrega_historial.dart': 'orders/entrega_historial.dart',
    # payments
    'pago_model.dart': 'payments/pago_model.dart',
    'datos_bancarios.dart': 'payments/datos_bancarios.dart',
    # entities
    'proveedor.dart': 'entities/proveedor.dart',
    'repartidor.dart': 'entities/repartidor.dart',
    'documento_legal_model.dart': 'entities/documento_legal_model.dart',
    # social
    'resena_model.dart': 'social/resena_model.dart',
    # core
    'notificacion_model.dart': 'core/notificacion_model.dart',
    'paginated_response.dart': 'core/paginated_response.dart',
    # raffles
    'rifa_activa.dart': 'raffles/rifa_activa.dart',
    'rifa_mes_card.dart': 'raffles/rifa_mes_card.dart',
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
            
            for filename, new_rel_path in MOVED_FILES.items():
                # 1. Fix package imports:
                #    import 'package:delibery/models/usuario.dart'; 
                # -> import 'package:delibery/models/auth/usuario.dart';
                #    import 'package:delibery/models/user/profile.dart'; 
                # -> import 'package:delibery/models/users/profile.dart';
                
                # Regex for package import (handling single/double quotes)
                # Matches: package:delibery/models/(optional user/)filename
                pattern_pkg = re.compile(r'package:delibery/models/(?:user/)?' + re.escape(filename))
                replacement_pkg = f'package:delibery/models/{new_rel_path}'
                
                if pattern_pkg.search(new_content):
                    new_content = pattern_pkg.sub(replacement_pkg, new_content)
                    modified = True

                # 2. Fix relative imports
                # This is harder blindly, but valid relative imports usually end with the filename.
                # e.g. import '../models/usuario.dart';
                # e.g. import '../../models/user/profile.dart';
                
                # We look for any import string ending in /filename or just 'filename'
                # and try to inject the new subdirectory.
                # Logic: if path ends with "/usuario.dart", replace with "/auth/usuario.dart"
                # Logic: if path is "usuario.dart" (same dir), replace with "auth/usuario.dart" (if we were in models root)
                # But wait, if file is IN models/auth/ now, relative imports FROM it might break too.
                # Let's focus on fixing IMPORTS TO these files first.
                
                # Pattern: import '.../filename'; -> import '.../subdir/filename';
                # We match ends of strings inside quotes.
                
                # Special handling for user/ folder files which are now in users/
                if filename in ['address.dart', 'profile.dart', 'payment_method.dart']:
                     # Old: .../models/user/address.dart
                     # New: .../models/users/address.dart
                     # We replace /user/filename with /users/filename
                     pattern_rel_user = re.compile(r'/user/' + re.escape(filename) + r"(['\";])")
                     replacement_rel_user = f'/users/{filename}\\1'
                     if pattern_rel_user.search(new_content):
                        new_content = pattern_rel_user.sub(replacement_rel_user, new_content)
                        modified = True
                else:
                    # Generic case: .../filename -> .../subdir/filename
                    # Avoid accidentally double-replacing if script runs twice (check if subdir already there is hard with regex alone)
                    # We assume precise filenames reduce partial matches.
                    
                    # Look for "/filename" NOT preceded by the new subdir
                    subdir = new_rel_path.split('/')[0] # e.g. auth
                    
                    # Negative lookbehind is tricky in variable length, so we check simple suffix
                    # match /filename followed by quote/semicolon
                    # and ensure it's NOT /subdir/filename
                    
                    regex_str = r'(?<!/)' + re.escape(subdir) + r'/' + re.escape(filename)
                    # If it already matches new path, ignore.
                    
                    # We want to match: (anything)/filename
                    # capture group 1: (anything)/
                    pattern_rel = re.compile(r'((?:\.\./)+|models/|/)' + re.escape(filename) + r"(['\";])")
                    
                    # Replacement: group1 + new_rel_path + quote
                    # But wait, new_rel_path includes subdir.
                    # If group1 ended in /, perfect.
                    # e.g. ../models/usuario.dart -> ../models/ + auth/usuario.dart
                    
                    # We iterate to apply this safely.
                    def replace_rel(match):
                        prefix = match.group(1)
                        closing = match.group(2)
                        # if prefix already contains the subdir (e.g. models/auth/), don't double it.
                        # But we are matching 'filename' directly preceded by prefix.
                        if prefix.endswith(f'/{subdir}/'):
                             return match.group(0) # No change
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
