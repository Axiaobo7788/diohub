import 'dart:io';

void main() async {
  print('Starting import fix...\n');
  
  // Phase 0b: Revert features/ imports back to common/
  final featuresReplacements = {
    'package:diohub/features/navigation/nav_center/': 'package:diohub/common/nav_center/',
    'package:diohub/features/context_dock/context_dock/': 'package:diohub/common/context_dock/',
    'package:diohub/features/insights/charts/': 'package:diohub/common/charts/',
    'package:diohub/features/compose/compose/': 'package:diohub/common/compose/',
    'package:diohub/features/lens/lens/': 'package:diohub/common/lens/',
    'package:diohub/features/search/search_overlay/': 'package:diohub/common/search_overlay/',
    'package:diohub/features/code_viewer/code/': 'package:diohub/common/code/',
    'package:diohub/features/activity/events/': 'package:diohub/common/events/',
    'package:diohub/features/activity/timeline_content/': 'package:diohub/common/timeline_content/',
    'package:diohub/features/terminal/terminal/': 'package:diohub/common/terminal/',
  };
  
  // Phase 0c: Fix schema import
  final schemaFix = {
    'package:diohub_graphql/__generated__/schema.schema.gql.dart': 'package:diohub_graphql/schema.graphql.dart',
  };
  
  int totalFiles = 0;
  int modifiedFiles = 0;
  
  // Process all .dart files in lib/
  final libDir = Directory('lib');
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      totalFiles++;
      
      String content = await file.readAsString();
      String originalContent = content;
      
      // Apply features reversions
      for (final entry in featuresReplacements.entries) {
        content = content.replaceAll(entry.key, entry.value);
      }
      
      // Apply schema fix
      for (final entry in schemaFix.entries) {
        content = content.replaceAll(entry.key, entry.value);
      }
      
      // Only write if something changed
      if (content != originalContent) {
        await file.writeAsString(content);
        modifiedFiles++;
        print('Fixed: ${file.path}');
      }
    }
  }
  
  print('\n✓ Phase 0b & 0c complete: $modifiedFiles files modified out of $totalFiles');
}
