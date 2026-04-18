#!/usr/bin/env python3
import os
import re
import sys

def migrate_graphql_imports(content):
    """
    Migrate old graphql imports to new graphql_codegen format.
    
    Old: package:diohub/graphql/queries/domain/__generated__/file.data.gql.dart
    New: package:diohub_graphql/queries/domain/file.graphql.dart
    
    Old: package:diohub/graphql/fragments/file
    New: package:diohub_graphql/fragments/file
    """
    original = content
    
    # Pattern 1: __generated__/*.data.gql.dart -> *.graphql.dart
    content = re.sub(
        r"package:diohub/graphql/queries/([^/]+)/__generated__/([^'\"]+)\.data\.gql\.dart",
        r"package:diohub_graphql/queries/\1/\2.graphql.dart",
        content
    )
    
    # Pattern 2: __generated__/*.req.gql.dart -> *.graphql.dart (merged into same file)
    content = re.sub(
        r"package:diohub/graphql/queries/([^/]+)/__generated__/([^'\"]+)\.req\.gql\.dart",
        r"package:diohub_graphql/queries/\1/\2.graphql.dart",
        content
    )
    
    # Pattern 3: __generated__/*.var.gql.dart -> *.graphql.dart (merged into same file)
    content = re.sub(
        r"package:diohub/graphql/queries/([^/]+)/__generated__/([^'\"]+)\.var\.gql\.dart",
        r"package:diohub_graphql/queries/\1/\2.graphql.dart",
        content
    )
    
    # Pattern 4: fragments (no __generated__)
    content = re.sub(
        r"package:diohub/graphql/fragments/",
        r"package:diohub_graphql/fragments/",
        content
    )
    
    # Pattern 5: schema_typedefs.dart
    content = re.sub(
        r"package:diohub/graphql/schema_typedefs\.dart",
        r"package:diohub_graphql/schema_typedefs.dart",
        content
    )
    
    # Pattern 6: serializer
    content = re.sub(
        r"package:diohub/graphql/serializer/",
        r"package:diohub_graphql/serializer/",
        content
    )
    
    # Pattern 7: queries without __generated__ (repo_typedefs.dart etc)
    content = re.sub(
        r"package:diohub/graphql/queries/",
        r"package:diohub_graphql/queries/",
        content
    )
    
    return content, original != content

def main():
    modified_count = 0
    total_count = 0
    
    lib_dir = "lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                total_count += 1
                
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content, changed = migrate_graphql_imports(content)
                    
                    if changed:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        modified_count += 1
                        print(f"Fixed: {filepath}")
                except Exception as e:
                    print(f"Error processing {filepath}: {e}", file=sys.stderr)
    
    print(f"\n✓ Phase 2: {modified_count} files modified out of {total_count}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
