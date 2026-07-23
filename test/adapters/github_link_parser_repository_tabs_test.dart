import 'package:diohub/adapters/github_link_parser.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final ({String path, Type locationType}) expectation
      in <({String path, Type locationType})>[
        (path: 'actions', locationType: RepoLocationActions),
        (path: 'projects', locationType: RepoLocationProjects),
        (path: 'security', locationType: RepoLocationSecurity),
        (path: 'pulse', locationType: RepoLocationInsights),
      ]) {
    test('parses repository ${expectation.path} as a typed tab location', () {
      final parsed = GitHubLinkParser.parse(
        Uri.parse('https://github.com/octocat/hello-world/${expectation.path}'),
      );

      expect(parsed, isA<RepoRef>());
      final RepoRef repo = parsed! as RepoRef;
      expect(repo.location.runtimeType, expectation.locationType);
    });
  }

  test('new repository tab locations survive JSON persistence', () {
    const List<RepoLocation> locations = <RepoLocation>[
      RepoLocation.actions(),
      RepoLocation.security(),
      RepoLocation.insights(),
    ];

    for (final RepoLocation location in locations) {
      final RepoRef source = RepoRef(
        owner: 'octocat',
        name: 'hello-world',
        location: location,
      );
      final RepoRef restored = EntityRef.fromJson(source.toJson()) as RepoRef;
      expect(restored.location.runtimeType, location.runtimeType);
    }
  });
}
