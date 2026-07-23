import 'package:diohub/common/nav_center/models/preset.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RepoRef repo = RepoRef(owner: 'octocat', name: 'hello-world');

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: <Override>[
        currentUserProvider.overrideWithBuild((_, __) async => null),
      ],
    );
  }

  test('initializes the default preset exactly once', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final notifier = container.read(
      searchStateNotifierProvider(scope).notifier,
    );

    notifier.initializeDefaultPreset(NavigationPresets.issues);
    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'is:open',
    );

    notifier.setRawFreeText('renderer regression');
    notifier.initializeDefaultPreset(NavigationPresets.issues);
    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'is:open renderer regression',
    );
  });

  test(
    'repository scopes own their default Open state before widgets mount',
    () {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      const SearchScope scope = SearchScope.repoPulls(repo: repo);
      final notifier = container.read(
        searchStateNotifierProvider(scope).notifier,
      );

      notifier.setRawFreeText('fix startup');
      notifier.initializeDefaultPreset(NavigationPresets.pulls);

      expect(
        container.read(searchStateNotifierProvider(scope)).displayQuery,
        'is:open fix startup',
      );
    },
  );

  test(
    'every Issue and Pull search scope starts Open at provider creation',
    () {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      const UserRef user = UserRef(login: 'octocat');
      const List<SearchScope> scopes = <SearchScope>[
        SearchScope.homeIssues(),
        SearchScope.homePulls(),
        SearchScope.repoIssues(repo: repo),
        SearchScope.repoPulls(repo: repo),
        SearchScope.profileIssues(user: user),
        SearchScope.profilePulls(user: user),
      ];

      for (final SearchScope scope in scopes) {
        expect(
          container.read(searchStateNotifierProvider(scope)).displayQuery,
          'is:open',
          reason: '$scope must not need a widget lifecycle write',
        );
      }
    },
  );

  test('parses every qualifier in a multi-token preset', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final notifier = container.read(
      searchStateNotifierProvider(scope).notifier,
    );

    notifier.applyPreset(
      const NavigationPreset(
        label: 'Open bugs',
        qualifier: 'is:open label:bug',
      ),
    );

    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'is:open label:bug',
    );
  });

  test('viewer provider rebuild does not reset the current query', () async {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final notifier = container.read(
      searchStateNotifierProvider(scope).notifier,
    );
    notifier.initializeDefaultPreset(NavigationPresets.issues);
    notifier.setRawFreeText('keep me');

    container.invalidate(currentUserProvider);
    await container.read(currentUserProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'is:open keep me',
    );
  });

  test('committed status qualifier replaces the default status only', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final notifier = container.read(
      searchStateNotifierProvider(scope).notifier,
    );

    notifier.applyPreset(
      const NavigationPreset(
        label: 'Open bugs',
        qualifier: 'is:open label:bug',
      ),
    );
    notifier
      ..setRawFreeText('is:closed renderer regression')
      ..commitFreeText();

    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'label:bug is:closed renderer regression',
    );
  });

  test('committing ordinary text preserves every active qualifier', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);
    const SearchScope scope = SearchScope.repoPulls(repo: repo);
    final notifier = container.read(
      searchStateNotifierProvider(scope).notifier,
    );

    notifier.applyPreset(
      const NavigationPreset(
        label: 'Merged regressions',
        qualifier: 'is:merged label:regression',
      ),
    );
    notifier
      ..setRawFreeText('startup crash')
      ..commitFreeText();

    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'is:merged label:regression startup crash',
    );
  });

  test('committed multi-value qualifier replaces only its existing key', () {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final notifier = container.read(
      searchStateNotifierProvider(scope).notifier,
    );

    notifier.applyPreset(
      const NavigationPreset(
        label: 'Open existing label',
        qualifier: 'is:open label:existing author:octocat',
      ),
    );
    notifier
      ..setRawFreeText('label:bug label:regression pagination')
      ..commitFreeText();

    expect(
      container.read(searchStateNotifierProvider(scope)).displayQuery,
      'is:open author:octocat label:bug label:regression pagination',
    );
  });
}
