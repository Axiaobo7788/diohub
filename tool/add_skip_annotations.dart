// Script to add @Skip() annotations to parameters that shouldn't be exposed to LLM

import 'dart:io';

void main() {
  // List of files and their params to skip
  final filesToProcess = {
    'lib/services/repositories/repo_branch_service.dart': [
      {'param': 'GRefOrder? orderBy', 'skip': '@Skip(\'null\')'},
      {'param': 'bool refresh', 'skip': '@Skip(\'false\')'},
    ],
    'lib/services/repositories/repo_release_service.dart': [
      {'param': 'GReleaseOrder? orderBy', 'skip': '@Skip(\'null\')'},
      {'param': 'bool refresh', 'skip': '@Skip(\'false\')'},
    ],
    'lib/services/repositories/repo_stats_service.dart': [
      {'param': 'bool refresh', 'skip': '@Skip(\'false\')'},
    ],
    'lib/services/repositories/repo_deployment_service.dart': [
      {'param': 'bool refresh', 'skip': '@Skip(\'false\')'},
    ],
    'lib/services/repositories/repo_label_milestone_service.dart': [
      {'param': 'List<GMilestoneState>? states', 'skip': '@Skip(\'null\')'},
    ],
    'lib/services/users/user_info_service.dart': [
      {'param': 'bool refresh', 'skip': '@Skip(\'false\')'},
      {'param': 'GRepositoryOrder? orderBy', 'skip': '@Skip(\'null\')'},
      {'param': 'RepositoryVisibility? visibility', 'skip': '@Skip(\'null\')'},
    ],
    'lib/services/users/user_activity_service.dart': [
      {'param': 'bool refreshCache', 'skip': '@Skip(\'false\')'},
    ],
    'lib/services/git_database/git_database_service.dart': [
      {'param': 'List<({String path, String content})> additions', 'skip': '@Skip(\'const []\')'},
    ],
  };

  for (final entry in filesToProcess.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) {
      print('File not found: ${entry.key}');
      continue;
    }

    var content = file.readAsStringSync();
    var modified = false;

    for (final paramInfo in entry.value) {
      final param = paramInfo['param']!;
      final skip = paramInfo['skip']!;
      
      // Pattern to find the parameter (handle both 'final type name' and 'type name')
      final patterns = [
        'final $param',
        '  $param',
      ];

      for (final pattern in patterns) {
        if (content.contains(pattern) && !content.contains('$skip $pattern')) {
          content = content.replaceAll(pattern, '$skip $pattern');
          modified = true;
          print('Added $skip to $param in ${entry.key}');
        }
      }
    }

    if (modified) {
      file.writeAsStringSync(content);
      print('Updated ${entry.key}');
    }
  }

  print('Done!');
}
