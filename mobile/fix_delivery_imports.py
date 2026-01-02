import os
import re

# Mapping of file names to their new relative path from 'lib/screens/delivery'
MOVED_SCREENS = {
    'pantalla_inicio_repartidor.dart': 'home/pantalla_inicio_repartidor.dart',
    'pantalla_datos_bancarios.dart': 'ganancias/pantalla_datos_bancarios.dart',
    'pantalla_ver_comprobante.dart': 'orders/pantalla_ver_comprobante.dart',
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
            
            for filename, new_rel_path in MOVED_SCREENS.items():
                # 1. Fix package imports:
                #    import 'package:delibery/screens/delivery/pantalla_inicio_repartidor.dart'; 
                # -> import 'package:delibery/screens/delivery/home/pantalla_inicio_repartidor.dart';
                
                pattern_pkg = re.compile(r'package:delibery/screens/delivery/' + re.escape(filename))
                replacement_pkg = f'package:delibery/screens/delivery/{new_rel_path}'
                
                if pattern_pkg.search(new_content):
                    new_content = pattern_pkg.sub(replacement_pkg, new_content)
                    modified = True

                # 2. Fix relative imports
                # e.g. import 'pantalla_inicio_repartidor.dart'; (if inside delivery/)
                # or import '../delivery/pantalla_inicio_repartidor.dart';
                
                subdir = new_rel_path.split('/')[0] # e.g. home
                
                # Match /filename NOT preceded by /subdir/
                
                # Capture group 1: path prefix ending in delivery/ or / or ../
                pattern_rel = re.compile(r'((?:\.\./)+|delivery/|/)' + re.escape(filename) + r"(['\";])")
                
                def replace_rel(match):
                    prefix = match.group(1)
                    closing = match.group(2)
                    if prefix.endswith(f'/{subdir}/'):
                            return match.group(0)
                    return f'{prefix}{subdir}/{filename}{closing}'

                if pattern_rel.search(new_content):
                    new_content = pattern_rel.sub(replace_rel, new_content)
                    modified = True
                    
                # Special case: direct import in same dir, now moved to subdir
                # Check if file is in delivery/ and imports just the filename
                # (handled by regex above if prefix is '/')

            if modified:
                print(f"Fixing imports in {file}")
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += 1
                
    print(f"Finished. Modified {count} files.")

if __name__ == '__main__':
    fix_imports()
