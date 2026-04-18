import 'dart:io';

/// Fixes imports for server_config and entity_ref that moved to the package.
void main() async {
  int totalFilesScanned = 0;
  int totalReplacements = 0;

  // Find all Dart files in lib/
  final dir = Directory('lib');
  
  if (!await dir.exists()) {
    print('Error: lib/ directory not found');
    return;
  }

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFilesScanned++;
      
      String content = await entity.readAsString();
      String originalContent = content;
      
      // Replace server_config imports
      content = content.replaceAll(
        'package:diohub/models/server_config',
        'package:diohub_models/models/server_config',
      );
      
      // Replace entity_ref imports
      content = content.replaceAll(
        'package:diohub/models/entity_ref',
        'package:diohub_models/models/entity_ref',
      );
      
      // Write back if changed
      if (content != originalContent) {
        await entity.writeAsString(content);
        totalReplacements++;
        print('  Fixed: ${entity.path}');
      }
    }
  }

  print('\n✓ Scanned $totalFilesScanned files');
  print('✓ Fixed $totalReplacements files with incorrect imports');
}
