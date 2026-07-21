import 'dart:io';

import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:test/test.dart';

void main() {
  test('repository references have stable value identity', () {
    const GitHubRepositoryRef first = GitHubRepositoryRef(
      owner: 'openai',
      name: 'codex',
    );
    const GitHubRepositoryRef second = GitHubRepositoryRef(
      owner: 'openai',
      name: 'codex',
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.slug, 'openai/codex');
    expect(first.toString(), 'github.com/openai/codex');
  });

  test('domain and application stay independent from UI and legacy layers', () {
    final Iterable<File> domainFiles =
        <String>['lib/workbench/domain', 'lib/workbench/application'].expand(
          (final String path) => Directory(path)
              .listSync()
              .whereType<File>()
              .where((final File file) => file.path.endsWith('.dart')),
        );

    for (final File file in domainFiles) {
      final String source = file.readAsStringSync();
      expect(source, isNot(contains('package:flutter/')), reason: file.path);
      expect(
        source,
        isNot(contains('package:flutter_riverpod/')),
        reason: file.path,
      );
      expect(source, isNot(contains('/services/')), reason: file.path);
      expect(source, isNot(contains('/providers/')), reason: file.path);
      expect(source, isNot(contains('diohub_graphql')), reason: file.path);
      expect(source, isNot(contains('diohub_models')), reason: file.path);
      expect(source, isNot(contains("import 'dart:io'")), reason: file.path);
      expect(source, isNot(contains('Process.run')), reason: file.path);
      expect(source, isNot(contains('Process.start')), reason: file.path);
      expect(source, isNot(contains("'bash', ['-c'")), reason: file.path);
      expect(source, isNot(contains("'sh', ['-c'")), reason: file.path);
    }
  });
}
