import 'dart:async';

import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/view/repository/md3/repository_md3_screen.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RepoRef repoRef = RepoRef(owner: 'octocat', name: 'hello-world');

  for (final double width in <double>[360, 800, 1440]) {
    testWidgets('keeps real repository identity states at ${width.toInt()}px', (
      final WidgetTester tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            repositoryProvider.overrideWith2(_PendingRepositoryNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              body: RepositoryIdentityHeader(
                repoRef: repoRef,
                repo: _forkedArchivedRepository(),
                preview: null,
                ownerAvatarUrl: null,
                detailsReady: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('repository-identity-avatar')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('repository-identity-name')),
            )
            .data,
        width < 600 ? 'octocat/hello-world' : 'hello-world',
      );
      expect(
        find.byKey(const ValueKey<String>('repository-visibility-private')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('repository-archived-status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('repository-fork-origin')),
        findsOneWidget,
      );
      expect(find.text('Forked from upstream/hello-world'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

RepoCardData _forkedArchivedRepository() => Fragment$repoCardFields(
  id: 'R_hello_world',
  name: 'hello-world',
  nameWithOwner: 'octocat/hello-world',
  description: 'A repository fixture with real identity states.',
  url: Uri.parse('https://github.com/octocat/hello-world'),
  stargazerCount: 42,
  forkCount: 7,
  watchers: Fragment$repoCardFields$watchers(totalCount: 3),
  issues: Fragment$repoCardFields$issues(totalCount: 2),
  pullRequests: Fragment$repoCardFields$pullRequests(totalCount: 1),
  repositoryTopics: Fragment$repoCardFields$repositoryTopics(
    edges: const <Fragment$repoCardFields$repositoryTopics$edges?>[],
    totalCount: 0,
  ),
  createdAt: DateTime.utc(2026),
  owner: Fragment$repoCardFields$owner($__typename: 'Actor'),
  isPrivate: true,
  isFork: true,
  viewerHasStarred: false,
  viewerCanSubscribe: false,
  forkingAllowed: false,
  parent: Fragment$repoCardFields$parent(
    nameWithOwner: 'upstream/hello-world',
    owner: Fragment$repoCardFields$parent$owner(
      login: 'upstream',
      avatarUrl: Uri.parse('https://github.com/upstream.png'),
      $__typename: 'Actor',
    ),
    name: 'hello-world',
    url: Uri.parse('https://github.com/upstream/hello-world'),
    stargazerCount: 100,
  ),
  isArchived: true,
  isMirror: false,
  isTemplate: false,
);

final class _PendingRepositoryNotifier extends RepositoryNotifier {
  _PendingRepositoryNotifier(super.arg);

  @override
  Future<RepoInfoData> build() => Completer<RepoInfoData>().future;
}
