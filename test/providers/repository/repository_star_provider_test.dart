import 'dart:async';

import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/star_mutation_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RepoRef repoRef = RepoRef(owner: 'octo', name: 'repo');
  const RepositoryStarFeedbackMessages feedbackMessages =
      RepositoryStarFeedbackMessages(
        starred: 'Repository starred',
        unstarred: 'Repository unstarred',
        updateFailed: 'Could not update repository star',
      );

  test(
    'star mutation uses the current state and shares optimistic result',
    () async {
      final Completer<StarMutationResult?> result =
          Completer<StarMutationResult?>();
      bool? receivedCurrentState;
      String? receivedNodeId;
      String? feedbackMessage;
      final List<RepositoryStarState> firstConsumerStates =
          <RepositoryStarState>[];
      final List<RepositoryStarState> secondConsumerStates =
          <RepositoryStarState>[];
      final ProviderContainer container = ProviderContainer(
        overrides: [
          repositoryStarAccountKeyProvider.overrideWithValue('account-a'),
          repositoryStarMutationProvider(repoRef).overrideWithValue(({
            required final bool isStarred,
            required final String repoNodeId,
          }) {
            receivedCurrentState = isStarred;
            receivedNodeId = repoNodeId;
            return result.future;
          }),
          repositoryStarFeedbackProvider.overrideWithValue(({
            required final bool success,
            required final String message,
          }) {
            feedbackMessage = message;
          }),
        ],
      );
      addTearDown(container.dispose);
      final firstSubscription = container.listen(
        repositoryStarProvider(repoRef),
        (_, final RepositoryStarState next) => firstConsumerStates.add(next),
        fireImmediately: true,
      );
      final secondSubscription = container.listen(
        repositoryStarProvider(repoRef),
        (_, final RepositoryStarState next) => secondConsumerStates.add(next),
        fireImmediately: true,
      );
      addTearDown(firstSubscription.close);
      addTearDown(secondSubscription.close);
      expect(container.exists(repositoryProvider(repoRef)), isFalse);

      final Future<void> pending = container
          .read(repositoryStarProvider(repoRef).notifier)
          .toggle(
            repoNodeId: 'R_node',
            currentIsStarred: false,
            currentCount: 4,
            feedbackMessages: feedbackMessages,
          );

      expect(receivedCurrentState, isFalse);
      expect(receivedNodeId, 'R_node');
      expect(
        container.read(repositoryStarProvider(repoRef)).result,
        isA<StarMutationResult>()
            .having((value) => value.viewerHasStarred, 'starred', isTrue)
            .having((value) => value.stargazerCount, 'count', 5),
      );
      expect(
        container.read(repositoryStarProvider(repoRef)).isMutating,
        isTrue,
      );
      expect(firstConsumerStates.last.result?.viewerHasStarred, isTrue);
      expect(secondConsumerStates.last.result?.viewerHasStarred, isTrue);
      expect(
        container.read(repositoryStarProvider(repoRef)).hasOptimisticOverlay,
        isTrue,
      );

      result.complete(
        const StarMutationResult(viewerHasStarred: true, stargazerCount: 6),
      );
      await pending;

      expect(
        container.read(repositoryStarProvider(repoRef)).result?.stargazerCount,
        6,
      );
      expect(
        container.read(repositoryStarProvider(repoRef)).isMutating,
        isFalse,
      );
      expect(
        container.read(repositoryStarProvider(repoRef)).hasOptimisticOverlay,
        isFalse,
      );
      expect(firstConsumerStates.last.result?.stargazerCount, 6);
      expect(secondConsumerStates.last.result?.stargazerCount, 6);
      expect(feedbackMessage, feedbackMessages.starred);
      expect(container.exists(repositoryProvider(repoRef)), isFalse);
    },
  );

  test(
    'authoritative seed replaces the confirmed value and stale widget seeds cannot revive it',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          repositoryStarAccountKeyProvider.overrideWithValue('account-a'),
          repositoryStarMutationProvider(repoRef).overrideWithValue(
            ({
              required final bool isStarred,
              required final String repoNodeId,
            }) async => const StarMutationResult(
              viewerHasStarred: true,
              stargazerCount: 6,
            ),
          ),
          repositoryStarFeedbackProvider.overrideWithValue(
            ({required final bool success, required final String message}) {},
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        repositoryStarProvider(repoRef),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final RepositoryStarNotifier notifier = container.read(
        repositoryStarProvider(repoRef).notifier,
      );

      await notifier.toggle(
        repoNodeId: 'R_node',
        currentIsStarred: false,
        currentCount: 4,
        feedbackMessages: feedbackMessages,
      );
      notifier.acceptAuthoritativeSeed(
        const StarMutationResult(viewerHasStarred: false, stargazerCount: 9),
      );

      final RepositoryStarState state = container.read(
        repositoryStarProvider(repoRef),
      );
      expect(state.hasOptimisticOverlay, isFalse);
      expect(state.result?.viewerHasStarred, isFalse);
      expect(state.result?.stargazerCount, 9);

      // A still-mounted card may retain the pre-mutation seed. Consumers use
      // the shared result first, so that old seed cannot revive the mutation.
      const StarMutationResult staleWidgetSeed = StarMutationResult(
        viewerHasStarred: false,
        stargazerCount: 4,
      );
      expect(state.result ?? staleWidgetSeed, same(state.result));
    },
  );

  testWidgets(
    'two mounted star consumers share optimistic and reconciled values',
    (final WidgetTester tester) async {
      final Completer<StarMutationResult?> result =
          Completer<StarMutationResult?>();
      String? feedbackMessage;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryStarAccountKeyProvider.overrideWithValue('account-a'),
            repositoryStarMutationProvider(repoRef).overrideWithValue(
              ({
                required final bool isStarred,
                required final String repoNodeId,
              }) => result.future,
            ),
            repositoryStarFeedbackProvider.overrideWithValue(({
              required final bool success,
              required final String message,
            }) {
              feedbackMessage = message;
            }),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Row(
                children: <Widget>[
                  RepoStarChipFromData(
                    key: Key('first-star-consumer'),
                    repoRef: repoRef,
                    repoNodeId: 'R_node',
                    initialStarCount: 4,
                    initialIsStarred: false,
                  ),
                  RepoStarChipFromData(
                    key: Key('second-star-consumer'),
                    repoRef: repoRef,
                    repoNodeId: 'R_node',
                    initialStarCount: 4,
                    initialIsStarred: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('4'), findsNWidgets(2));
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('first-star-consumer')),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pump();
      expect(find.text('5'), findsNWidgets(2));

      result.complete(
        const StarMutationResult(viewerHasStarred: true, stargazerCount: 6),
      );
      await tester.pump();
      expect(find.text('6'), findsNWidgets(2));
      expect(feedbackMessage, 'Repository starred');

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('first-star-consumer'))),
      );
      container
          .read(repositoryStarProvider(repoRef).notifier)
          .acceptAuthoritativeSeed(
            const StarMutationResult(
              viewerHasStarred: false,
              stargazerCount: 9,
            ),
          );
      await tester.pumpAndSettle();

      expect(find.text('9'), findsNWidgets(2));
      expect(find.text('4'), findsNothing);
    },
  );

  test('an in-flight optimistic value rejects an older server seed', () async {
    final Completer<StarMutationResult?> result =
        Completer<StarMutationResult?>();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        repositoryStarAccountKeyProvider.overrideWithValue('account-a'),
        repositoryStarMutationProvider(repoRef).overrideWithValue(
          ({required final bool isStarred, required final String repoNodeId}) =>
              result.future,
        ),
        repositoryStarFeedbackProvider.overrideWithValue(
          ({required final bool success, required final String message}) {},
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      repositoryStarProvider(repoRef),
      (_, __) {},
    );
    addTearDown(subscription.close);
    final RepositoryStarNotifier notifier = container.read(
      repositoryStarProvider(repoRef).notifier,
    );

    final Future<void> pending = notifier.toggle(
      repoNodeId: 'R_node',
      currentIsStarred: false,
      currentCount: 4,
      feedbackMessages: feedbackMessages,
    );
    notifier.acceptAuthoritativeSeed(
      const StarMutationResult(viewerHasStarred: false, stargazerCount: 4),
    );

    expect(
      container.read(repositoryStarProvider(repoRef)).result?.viewerHasStarred,
      isTrue,
    );
    result.complete(
      const StarMutationResult(viewerHasStarred: true, stargazerCount: 5),
    );
    await pending;
  });

  test(
    'failed star mutation rolls back to the previous shared state',
    () async {
      var shouldFail = false;
      String? feedbackMessage;
      final ProviderContainer container = ProviderContainer(
        overrides: [
          repositoryStarAccountKeyProvider.overrideWithValue('account-a'),
          repositoryStarMutationProvider(repoRef).overrideWithValue(({
            required final bool isStarred,
            required final String repoNodeId,
          }) async {
            if (shouldFail) throw StateError('network failed');
            return const StarMutationResult(
              viewerHasStarred: true,
              stargazerCount: 10,
            );
          }),
          repositoryStarFeedbackProvider.overrideWithValue(({
            required final bool success,
            required final String message,
          }) {
            feedbackMessage = message;
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        repositoryStarProvider(repoRef),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final RepositoryStarNotifier notifier = container.read(
        repositoryStarProvider(repoRef).notifier,
      );

      await notifier.toggle(
        repoNodeId: 'R_node',
        currentIsStarred: false,
        currentCount: 9,
        feedbackMessages: feedbackMessages,
      );
      shouldFail = true;
      await notifier.toggle(
        repoNodeId: 'R_node',
        currentIsStarred: true,
        currentCount: 10,
        feedbackMessages: feedbackMessages,
      );

      final RepositoryStarState state = container.read(
        repositoryStarProvider(repoRef),
      );
      expect(state.result?.viewerHasStarred, isTrue);
      expect(state.result?.stargazerCount, 10);
      expect(state.isMutating, isFalse);
      expect(feedbackMessage, feedbackMessages.updateFailed);
    },
  );

  test('switching account scope discards retained Star state', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        repositoryStarAccountKeyProvider.overrideWith(
          (final Ref ref) => ref.watch(_testStarAccountKeyProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      repositoryStarProvider(repoRef),
      (_, __) {},
    );
    addTearDown(subscription.close);

    container
        .read(repositoryStarProvider(repoRef).notifier)
        .acceptAuthoritativeSeed(
          const StarMutationResult(viewerHasStarred: true, stargazerCount: 12),
        );
    expect(
      container.read(repositoryStarProvider(repoRef)).result?.stargazerCount,
      12,
    );

    container
        .read(_testStarAccountKeyProvider.notifier)
        .setAccountKey('account-b');

    expect(container.read(repositoryStarProvider(repoRef)).result, isNull);
  });

  test('a mutation from the previous account cannot publish late', () async {
    final Completer<StarMutationResult?> result =
        Completer<StarMutationResult?>();
    var feedbackCount = 0;
    final ProviderContainer container = ProviderContainer(
      overrides: [
        repositoryStarAccountKeyProvider.overrideWith(
          (final Ref ref) => ref.watch(_testStarAccountKeyProvider),
        ),
        repositoryStarMutationProvider(repoRef).overrideWithValue(
          ({required final bool isStarred, required final String repoNodeId}) =>
              result.future,
        ),
        repositoryStarFeedbackProvider.overrideWithValue(({
          required final bool success,
          required final String message,
        }) {
          feedbackCount++;
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      repositoryStarProvider(repoRef),
      (_, __) {},
    );
    addTearDown(subscription.close);

    final Future<void> pending = container
        .read(repositoryStarProvider(repoRef).notifier)
        .toggle(
          repoNodeId: 'R_node',
          currentIsStarred: false,
          currentCount: 4,
          feedbackMessages: feedbackMessages,
        );
    container
        .read(_testStarAccountKeyProvider.notifier)
        .setAccountKey('account-b');
    result.complete(
      const StarMutationResult(viewerHasStarred: true, stargazerCount: 5),
    );
    await pending;

    expect(container.read(repositoryStarProvider(repoRef)).result, isNull);
    expect(feedbackCount, 0);
  });
}

final NotifierProvider<_TestStarAccountKeyNotifier, String?>
_testStarAccountKeyProvider =
    NotifierProvider<_TestStarAccountKeyNotifier, String?>(
      _TestStarAccountKeyNotifier.new,
    );

final class _TestStarAccountKeyNotifier extends Notifier<String?> {
  @override
  String? build() => 'account-a';

  void setAccountKey(final String value) => state = value;
}
