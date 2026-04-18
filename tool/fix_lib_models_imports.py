#!/usr/bin/env python3
import os
import re

# Files that stayed in lib/models/ (should use package:diohub/models)
lib_models_files = {
    'entity_ref.dart',
    'entity_ref_lens_extensions.dart',
    'server_config.dart',
    'home_destination.dart',
}

# Directory of the workspace
workspace = '/Users/namanshergill/Desktop/dev/diohub'

def fix_imports_in_lib_models():
    """Fix imports in lib/models/ files to use diohub_models package for moved files"""
    
    lib_models_dir = os.path.join(workspace, 'lib', 'models')
    
    for root, dirs, files in os.walk(lib_models_dir):
        for file in files:
            if not file.endswith('.dart'):
                continue
                
            filepath = os.path.join(root, file)
            
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original = content
                
                # Replace imports of files that were moved to the package
                # But NOT files that stayed in lib/models/
                lines = content.split('\n')
                new_lines = []
                
                for line in lines:
                    # Match import statements
                    match = re.match(r"import 'package:diohub/models/(.+?)';", line)
                    if match:
                        imported_file = match.group(1)
                        # Check if this is a file that stayed in lib/models
                        is_lib_file = any(imported_file == f or imported_file.startswith(f'{f[:-5]}.') 
                                        for f in lib_models_files)
                        
                        if not is_lib_file:
                            # This file was moved to the package
                            line = f"import 'package:diohub_models/models/{imported_file}';"
                    
                    new_lines.append(line)
                
                content = '\n'.join(new_lines)
                
                if content != original:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Fixed: {filepath}")
                    
            except Exception as e:
                print(f"Error processing {filepath}: {e}")

if __name__ == '__main__':
    fix_imports_in_lib_models()
    print("Done!")
