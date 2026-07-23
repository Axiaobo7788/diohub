import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/providers/code_browser/directory_last_commit_provider.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/repository_document_provider.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/view/repository/md3/repository_code_md3.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'keeps the repository code shell visible while branch resolution loads',
    (final WidgetTester tester) async {
      const RepoRef repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
      final Completer<RepoCardData> cardCompleter = Completer<RepoCardData>();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          repositoryProvider.overrideWith2(_PendingRepositoryNotifier.new),
          repoCardProvider.overrideWith(
            (final Ref ref, final RepoRef arg) => cardCompleter.future,
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        if (!cardCompleter.isCompleted) {
          cardCompleter.completeError(StateError('test disposed'));
        }
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              body: RepositoryCodeMd3(
                repoRef: repoRef,
                repo: null,
                details: null,
                detailsLoading: true,
                detailsError: null,
                onRetryDetails: () async {},
                header: const Text('octocat / hello-world'),
                inlineAbout: const Text('About preview'),
                aside: const Text('About aside'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        container.read(branchProvider(repoRef)),
        isA<BranchStateLoading>(),
      );
      expect(find.text('octocat / hello-world'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsNWidgets(9));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byKey(
          const PageStorageKey<String>(
            'repository-code-octocat/hello-world-loading',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final double width in <double>[360, 800, 1440]) {
    testWidgets(
      'keeps the root Code layout honest and overflow-free at ${width}px',
      (final WidgetTester tester) async {
        const RepoRef repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
        final Completer<RepoInfoData> repositoryCompleter =
            Completer<RepoInfoData>();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            repositoryProvider.overrideWith2(
              (final RepoRef arg) =>
                  _PendingRepositoryNotifier(arg, repositoryCompleter),
            ),
            settingsCacheProvider.overrideWithValue(
              SettingsCache(<String, String>{}),
            ),
            directoryProvider.overrideWith2(_TestDirectoryNotifier.new),
            directoryLastCommitProvider.overrideWith(
              (final Ref ref, final LastCommitKey key) async =>
                  DirectoryLastCommit(
                    oid: '0123456789abcdef',
                    abbreviatedOid: '0123456',
                    message: 'Keep the repository layout compact',
                    committedDate: DateTime.utc(2026, 7, 23, 8),
                    authorName: 'octocat',
                  ),
            ),
            repositoryDocumentProvider.overrideWith(
              (final Ref ref, final RepositoryDocumentKey key) async => null,
            ),
          ],
        );
        addTearDown(() {
          container.dispose();
          if (!repositoryCompleter.isCompleted) {
            repositoryCompleter.completeError(StateError('test disposed'));
          }
        });
        container
            .read(repositoryPreviewProvider(repoRef).notifier)
            .seed(
              const RepositoryPreview(
                fullName: 'octocat/hello-world',
                name: 'hello-world',
                owner: 'octocat',
                ownerAvatarUrl: null,
                isPrivate: false,
                defaultBranch: 'main',
              ),
            );
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(useMaterial3: true),
              home: Scaffold(
                body: RepositoryCodeMd3(
                  repoRef: repoRef,
                  repo: null,
                  details: null,
                  detailsLoading: false,
                  detailsError: null,
                  onRetryDetails: () async {},
                  header: const Text('Repository identity'),
                  inlineAbout: const Text('About summary'),
                  aside: const Text('About aside'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('repository-file-table')),
          findsOneWidget,
        );
        expect(find.text('Keep the repository layout compact'), findsOneWidget);
        expect(find.text('lib'), findsOneWidget);
        expect(find.text('README.md'), findsOneWidget);
        expect(
          find.text('hello-world'),
          findsNothing,
          reason: 'The root directory must not repeat the repository name.',
        );
        expect(
          find.text('Directory'),
          findsNothing,
          reason: 'A directory type is not a last-commit message.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

final class _PendingRepositoryNotifier extends RepositoryNotifier {
  _PendingRepositoryNotifier(super.arg, [Completer<RepoInfoData>? completer])
    : _completer = completer ?? Completer<RepoInfoData>();

  final Completer<RepoInfoData> _completer;

  @override
  Future<RepoInfoData> build() => _completer.future;
}

final class _TestDirectoryNotifier extends DirectoryNotifier {
  _TestDirectoryNotifier(final DirectoryKey key) : super(key);

  @override
  Future<List<CodeTreeNode>> build() async => const <CodeTreeNode>[
    CodeTreeNode(
      name: 'lib',
      path: 'lib',
      oid: 'tree',
      kind: CodeEntryKind.directory,
      mode: 16384,
      size: 0,
    ),
    CodeTreeNode(
      name: 'README.md',
      path: 'README.md',
      oid: 'blob',
      kind: CodeEntryKind.file,
      mode: 33188,
      size: 1024,
      extension: 'md',
      byteSize: 1024,
    ),
  ];
}
