import 'dart:io';

/// Fixes imports for files that stayed in lib/models/ but were incorrectly changed to package:diohub_models/models/.
/// This reverses the over-aggressive sed command from package extraction.
void main() async {
  // Map of file paths that stayed in lib/models/ to their correct import paths
  final Map<String, String> unmovedFiles = {
    // Cloud Sync
    'cloud_sync/sync_types': 'cloud_sync/sync_types',
    
    // Commits
    'commits/commit_list_item_model': 'commits/commit_list_item_model',
    
    // Contributions
    'contributions/contribution_query_models': 'contributions/contribution_query_models',
    'contributions/chip_detail_models': 'contributions/chip_detail_models',
    
    // Download
    'download/download_task': 'download/download_task',
    
    // Search
    'search/search_scope': 'search/search_scope',
    'search/qualifier_parser_registry': 'search/qualifier_parser_registry',
    'search/search_type_config': 'search/search_type_config',
    
    // Filters
    'filters/custom_filter': 'filters/custom_filter',
    
    // Events
    'events/thread_entity_ref_extension': 'events/thread_entity_ref_extension',
    
    // Repositories
    'repositories/repository_initial_state': 'repositories/repository_initial_state',
    
    // Lens
    'lens/lens_response_segment_json': 'lens/lens_response_segment_json',
    
    // Users
    'users/email_item': 'users/email_item',
    
    // Home
    'home_destination': 'home_destination',
  };

  int totalFilesScanned = 0;
  int totalReplacements = 0;

  // Find all Dart files in lib/ and packages/
  final directories = [
    Directory('lib'),
    Directory('packages'),
  ];

  for (final dir in directories) {
    if (!await dir.exists()) continue;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        totalFilesScanned++;
        
        String content = await entity.readAsString();
        String originalContent = content;
        
        // Replace each unmoved file's import
        for (final entry in unmovedFiles.entries) {
          final wrongImport = "package:diohub_models/models/${entry.key}";
          final correctImport = "package:diohub/models/${entry.value}";
          
          if (content.contains(wrongImport)) {
            content = content.replaceAll(wrongImport, correctImport);
            print('  Fixed: ${entity.path}');
            print('    $wrongImport -> $correctImport');
          }
        }
        
        // Write back if changed
        if (content != originalContent) {
          await entity.writeAsString(content);
          totalReplacements++;
        }
      }
    }
  }

  print('\n✓ Scanned $totalFilesScanned files');
  print('✓ Fixed $totalReplacements files with incorrect imports');
}
