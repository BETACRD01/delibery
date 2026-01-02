import os
import re

# Mapping of file names to their new relative path from 'lib/widgets'
MOVED_WIDGETS = {
    'boton_contacto_whatsapp.dart': 'contact/boton_contacto_whatsapp.dart',
    'card_contacto_repartidor.dart': 'cards/card_contacto_repartidor.dart',
    'jp_snackbar.dart': 'common/jp_snackbar.dart',
    'notificacion_in_app.dart': 'common/notificacion_in_app.dart',
    'mapa_pedidos_widget.dart': 'maps/mapa_pedidos_widget.dart',
    'role_switcher_ios.dart': 'role/role_switcher_ios.dart',
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
            
            for filename, new_rel_path in MOVED_WIDGETS.items():
                # 1. Fix package imports:
                #    import 'package:delibery/widgets/boton_contacto_whatsapp.dart'; 
                # -> import 'package:delibery/widgets/contact/boton_contacto_whatsapp.dart';
                
                pattern_pkg = re.compile(r'package:delibery/widgets/' + re.escape(filename))
                replacement_pkg = f'package:delibery/widgets/{new_rel_path}'
                
                if pattern_pkg.search(new_content):
                    new_content = pattern_pkg.sub(replacement_pkg, new_content)
                    modified = True

                # 2. Fix relative imports
                # e.g. import '../widgets/boton_contacto_whatsapp.dart';
                # -> import '../widgets/contact/boton_contacto_whatsapp.dart';
                
                subdir = new_rel_path.split('/')[0] # e.g. contact
                
                # Match /filename NOT preceded by /subdir/
                regex_str = r'(?<!/)' + re.escape(subdir) + r'/' + re.escape(filename)
                
                # Capture group 1: path prefix ending in widgets/ or / or ../
                # We assume imports to widgets usually have 'widgets/' in them if relative from screens
                # But could be direct if inside widgets.
                
                pattern_rel = re.compile(r'((?:\.\./)+|widgets/|/)' + re.escape(filename) + r"(['\";])")
                
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
