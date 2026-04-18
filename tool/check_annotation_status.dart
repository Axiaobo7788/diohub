#!/usr/bin/env dart
// Script to bulk-annotate services based on their tool files

import 'dart:io';

// Map of service file → tool file
final serviceToolMapping = {
  'lib/services/search/search_service.dart': 'lib/services/search/search_tools.dart',
  'lib/services/repositories/repo_stats_service.dart': 'lib/services/repositories/repo_stats_tools.dart',
  'lib/services/repositories/repo_branch_service.dart': 'lib/services/repositories/repo_branch_tools.dart',
  'lib/services/repositories/repo_deployment_service.dart': 'lib/services/repositories/repo_deployment_tools.dart',
  'lib/services/repositories/repo_release_service.dart': 'lib/services/repositories/repo_release_tools.dart',
  'lib/services/repositories/repo_label_milestone_service.dart': 'lib/services/repositories/repo_label_milestone_tools.dart',
  'lib/services/repositories/repo_collaborator_service.dart': 'lib/services/repositories/repo_collaborator_tools.dart',
  'lib/services/users/user_info_service.dart': 'lib/services/users/user_info_tools.dart',
  'lib/services/users/user_activity_service.dart': 'lib/services/users/user_activity_tools.dart',
  'lib/services/users/user_contributions_service.dart': 'lib/services/users/user_contributions_tools.dart',
  'lib/services/users/viewer_info_service.dart': 'lib/services/users/viewer_info_tools.dart',
  'lib/services/issues/issue_creation_service.dart': 'lib/services/issues/issue_creation_tools.dart',
  'lib/services/pulls/pull_creation_service.dart': 'lib/services/pulls/pull_creation_tools.dart',
  'lib/services/git_database/git_database_service.dart': 'lib/services/git_database/git_database_tools.dart',
};

void main() async {
  print('DioLens Service Annotation Summary');
  print('===================================\n');
  
  final completed = <String>[];
  final pending = <String>[];
  
  for (final entry in serviceToolMapping.entries) {
    final serviceFile = File(entry.key);
    final content = await serviceFile.readAsString();
    
    if (content.contains('@LensService')) {
      completed.add(entry.key);
    } else {
      pending.add(entry.key);
    }
  }
  
  print('✓ Annotated: ${completed.length}');
  for (final file in completed) {
    print('  - ${file.split('/').last}');
  }
  
  print('\n✗ Pending: ${pending.length}');
  for (final file in pending) {
    print('  - ${file.split('/').last}');
  }
  
  print('\nNext: Run build_runner to generate ${serviceToolMapping.length} service tool files');
  print('  fvm dart run build_runner build --delete-conflicting-outputs');
}
