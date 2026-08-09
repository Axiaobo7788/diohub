import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/notifications/notification_page_resource.dart';
import 'package:diohub/providers/notifications/notifications_filters_provider.dart';
import 'package:diohub/providers/notifications/notifications_inbox_session_provider.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/notifications/notifications_md3_screen.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'widget-account',
);

void main() {
  for (final Size viewport in <Size>[
    const Size(360, 800),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'notifications inbox is responsive at ${viewport.width.toInt()}px',
      (final WidgetTester tester) async {
        final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
        final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
        final ProviderContainer container = _container(
          runtime: runtime,
          backend: backend,
        );
        addTearDown(() {
          container.dispose();
          runtime.dispose();
        });
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = viewport;
        addTearDown(() {
          tester.view
            ..resetDevicePixelRatio()
            ..resetPhysicalSize();
        });

        await _pumpPage(tester, container);
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('notifications-all-unread-control'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>('notifications-select-all-checkbox'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('notifications-query-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('notifications-sort-menu')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('notifications-group-menu')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('notifications-cleanup-prompt')),
          findsOneWidget,
        );
        if (viewport.width == 360) {
          for (final String key in <String>[
            'notifications-query-target',
            'notifications-sort-menu',
            'notifications-group-menu',
            'notifications-compact-navigation-button',
            'notifications-more-menu',
          ]) {
            expect(
              tester.getSize(find.byKey(ValueKey<String>(key))).height,
              greaterThanOrEqualTo(48),
              reason: '$key must keep a touch-safe target at 360px',
            );
          }
        }
        expect(find.text('Please review the runtime page'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('notifications-inbox-list')),
            matching: find.text('octocat/hello-world'),
          ),
          findsAtLeastNWidgets(1),
          reason:
              'every built date-grouped row keeps its repository identity visible',
        );
        expect(
          find.byKey(const ValueKey<String>('notifications-sidebar')),
          viewport.width >= 1040 ? findsOneWidget : findsNothing,
        );
        final bool expanded = viewport.width >= 1040;
        expect(
          find.byKey(
            const ValueKey<String>('notifications-compact-navigation-button'),
          ),
          expanded ? findsNothing : findsOneWidget,
        );
        final Finder navigation = expanded
            ? find.byKey(const ValueKey<String>('notifications-sidebar'))
            : find.byKey(
                const ValueKey<String>(
                  'notifications-compact-navigation-sheet',
                ),
              );
        if (!expanded) {
          await tester.tap(
            find.byKey(
              const ValueKey<String>('notifications-compact-navigation-button'),
            ),
          );
          await tester.pumpAndSettle();
          expect(navigation, findsOneWidget);
        }
        for (final String label in <String>[
          'Inbox',
          'Saved',
          'Done',
          'Filters',
          'Assigned',
          'Needs review',
        ]) {
          expect(
            find.descendant(of: navigation, matching: find.text(label)),
            findsWidgets,
            reason: '$label must remain reachable at ${viewport.width}px',
          );
        }
        final Finder inboxTile = find.ancestor(
          of: find.descendant(of: navigation, matching: find.text('Inbox')),
          matching: find.byType(ListTile),
        );
        expect(
          tester.getSize(inboxTile).height,
          greaterThanOrEqualTo(48),
          reason: 'sidebar items keep a 48px hit target at ${viewport.width}px',
        );
        expect(
          find.descendant(
            of: navigation,
            matching: find.byKey(
              const ValueKey<String>('notifications-saved-unavailable'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: navigation,
            matching: find.byKey(
              const ValueKey<String>('notifications-done-unavailable'),
            ),
          ),
          findsOneWidget,
        );
        if (!expanded) {
          final Finder sidebarScrollable = find.descendant(
            of: navigation,
            matching: find.byType(Scrollable),
          );
          await tester.scrollUntilVisible(
            find.descendant(
              of: navigation,
              matching: find.text('Repositories'),
            ),
            200,
            scrollable: sidebarScrollable,
          );
          await tester.pumpAndSettle();
        }
        for (final String label in <String>[
          'Repositories',
          'octocat/hello-world',
        ]) {
          expect(
            find.descendant(of: navigation, matching: find.text(label)),
            findsWidgets,
            reason: '$label must remain reachable at ${viewport.width}px',
          );
        }
        expect(
          find.text('All'),
          findsOneWidget,
          reason: 'All/Unread belongs to the main toolbar, not the sidebar',
        );
        expect(
          find.byKey(
            const ValueKey<String>('notifications-subject-icon-unread'),
          ),
          findsOneWidget,
        );
        expect(backend.calls, <String>['all:1']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('scope and sidebar expose selection with 48 pixel hit targets', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final ProviderContainer container = _container(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await _pumpPage(
      tester,
      container,
      visualDensity: VisualDensity.comfortable,
    );
    await tester.pumpAndSettle();

    final Finder scope = find.byKey(
      const ValueKey<String>('notifications-all-unread-control'),
    );
    final Finder all = find.descendant(
      of: scope,
      matching: find.bySemanticsLabel('All'),
    );
    final Finder unread = find.descendant(
      of: scope,
      matching: find.bySemanticsLabel('Unread'),
    );
    expect(tester.getSize(all).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(unread).height, greaterThanOrEqualTo(48));
    expect(tester.getSemantics(all).hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(
      tester.getSemantics(unread).hasFlag(SemanticsFlag.isSelected),
      isFalse,
    );

    final Finder sidebar = find.byKey(
      const ValueKey<String>('notifications-sidebar'),
    );
    final Finder inbox = find.descendant(
      of: sidebar,
      matching: find.bySemanticsLabel('Inbox'),
    );
    expect(tester.getSize(inbox).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(inbox).hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(
              const ValueKey<String>('notifications-sidebar-indicator-Inbox'),
            ),
          )
          .duration,
      kContentTransitionDuration,
    );

    final Finder assigned = find.ancestor(
      of: find.descendant(of: sidebar, matching: find.text('Assigned')),
      matching: find.byType(ListTile),
    );
    await tester.tap(assigned);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('notifications-sidebar-clear-filters'),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(unread);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: scope,
              matching: find.bySemanticsLabel('Unread'),
            ),
          )
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final ({Size viewport, double textScale}) scenario
      in <({Size viewport, double textScale})>[
        (viewport: const Size(360, 800), textScale: 2),
        (viewport: const Size(800, 900), textScale: 1.3),
      ]) {
    testWidgets('notifications inbox supports ${scenario.textScale}x text at '
        '${scenario.viewport.width.toInt()}px', (
      final WidgetTester tester,
    ) async {
      final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ProviderContainer container = _container(
        runtime: runtime,
        backend: backend,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = scenario.viewport;
      addTearDown(() {
        tester.view
          ..resetDevicePixelRatio()
          ..resetPhysicalSize();
      });

      await _pumpPage(
        tester,
        container,
        textScaler: TextScaler.linear(scenario.textScale),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('notifications-all-unread-control')),
        findsOneWidget,
      );
      if (find.text('Please review the runtime page').evaluate().isEmpty) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
      }
      expect(find.text('Please review the runtime page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('notification toolbar becomes static for Reduced Motion', (
    final WidgetTester tester,
  ) async {
    final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final ProviderContainer container = _container(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await _pumpPage(tester, container, disableAnimations: true);
    await tester.pumpAndSettle();

    final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey<String>('notifications-toolbar-switcher')),
    );
    expect(switcher.duration, Duration.zero);
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(
              const ValueKey<String>('notifications-sidebar-indicator-Inbox'),
            ),
          )
          .duration,
      Duration.zero,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('notifications-row-checkbox-unread')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('notifications-selection-toolbar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('outgoing notification toolbar cannot be tapped or announced', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final ProviderContainer container = _container(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await _pumpPage(tester, container);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('notifications-row-checkbox-unread')),
    );
    await tester.pump();

    final Finder outgoingToolbar = find.byKey(
      const ValueKey<String>('notifications-filter-toolbar'),
    );
    expect(outgoingToolbar, findsOneWidget);
    expect(
      find.ancestor(of: outgoingToolbar, matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
    expect(find.bySemanticsLabel('All'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('notifications-selection-toolbar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'All and Unread restore their loaded controller without skeleton',
    (final WidgetTester tester) async {
      final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ProviderContainer container = _container(
        runtime: runtime,
        backend: backend,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 900);
      addTearDown(() {
        tester.view
          ..resetDevicePixelRatio()
          ..resetPhysicalSize();
      });

      await _pumpPage(tester, container);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      expect(backend.calls, <String>['all:1', 'unread:1']);
      expect(find.text('Please review the runtime page'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pump();
      expect(backend.calls.length, 2);
      expect(
        find.byKey(const ValueKey<String>('notifications-loading')),
        findsNothing,
        reason: 'returning to a retained query must not restore first-load UI',
      );
      expect(find.text('An already read issue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'query sort grouping and prompt controls project loaded data locally',
    (final WidgetTester tester) async {
      final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final ProviderContainer container = _container(
        runtime: runtime,
        backend: backend,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(1440, 900);
      addTearDown(() {
        tester.view
          ..resetDevicePixelRatio()
          ..resetPhysicalSize();
      });

      await _pumpPage(tester, container);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('notifications-query-field')),
        'reason:review-requested',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('notifications-query-clear')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('notifications-query-field')),
          matching: find.byIcon(Icons.cancel),
        ),
        findsNothing,
      );
      expect(find.text('Please review the runtime page'), findsOneWidget);
      expect(find.text('An already read issue'), findsNothing);
      expect(backend.calls, <String>['all:1']);

      await tester.enterText(
        find.byKey(const ValueKey<String>('notifications-query-field')),
        '',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('notifications-sort-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest to newest').last);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('An already read issue')).dy,
        lessThan(
          tester.getTopLeft(find.text('Please review the runtime page')).dy,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('notifications-group-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Repository').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('notifications-group-octocat/hello-world'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('notifications-inbox-list')),
          matching: find.text('octocat/hello-world'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byKey(const ValueKey<String>('notifications-sidebar')),
              matching: find.text('octocat/hello-world'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(backend.calls, <String>['all:1']);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('notifications-cleanup-prompt')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading and empty states use stable multi-row page structure', (
    final WidgetTester tester,
  ) async {
    final _WidgetNotificationBackend backend = _WidgetNotificationBackend(
      holdFirstRequest: true,
    );
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final ProviderContainer container = _container(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await _pumpPage(tester, container);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('notifications-loading')),
      findsOneWidget,
    );

    backend.completeHeld(<Thread>[]);
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed first page exposes retry and recovers in place', (
    final WidgetTester tester,
  ) async {
    final _WidgetNotificationBackend backend = _WidgetNotificationBackend(
      failFirstRequest: true,
    );
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final ProviderContainer container = _container(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 900);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await _pumpPage(tester, container);
    await tester.pumpAndSettle();
    expect(find.text('Notifications could not be loaded.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Please review the runtime page'), findsOneWidget);
    expect(backend.calls, <String>['all:1', 'all:1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cold account loading keeps AppChrome and never paints sign-in', (
    final WidgetTester tester,
  ) async {
    final _ScreenHarness harness = await _pumpProductionScreen(
      tester,
      size: const Size(360, 800),
      accountOverride: accountProvider.overrideWith(
        _PendingAccountNotifier.new,
      ),
    );
    addTearDown(harness.dispose);

    expect(find.byKey(const ValueKey<String>('global-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('notifications-account-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('notifications-account-sidebar-placeholder'),
      ),
      findsNothing,
    );
    expect(find.text('Sign in to view notifications'), findsNothing);
    expect(harness.backend.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account loading preserves the desktop inbox column geometry', (
    final WidgetTester tester,
  ) async {
    final _ScreenHarness harness = await _pumpProductionScreen(
      tester,
      size: const Size(1440, 900),
      accountOverride: accountProvider.overrideWith(
        _PendingAccountNotifier.new,
      ),
    );
    addTearDown(harness.dispose);

    expect(
      find.byKey(
        const ValueKey<String>('notifications-account-sidebar-placeholder'),
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in to view notifications'), findsNothing);
    expect(harness.backend.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'account load error is retryable and is never painted as signed out',
    (final WidgetTester tester) async {
      _RetryableErrorAccountNotifier.builds = 0;
      final _ScreenHarness harness = await _pumpProductionScreen(
        tester,
        size: const Size(800, 900),
        accountOverride: accountProvider.overrideWith(
          _RetryableErrorAccountNotifier.new,
        ),
      );
      addTearDown(harness.dispose);

      expect(
        find.byKey(const ValueKey<String>('global-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('notifications-account-error')),
        findsOneWidget,
      );
      expect(
        find.text('Could not read the local account state.'),
        findsOneWidget,
      );
      expect(find.text('Notifications could not be loaded.'), findsNothing);
      expect(find.text('Sign in to view notifications'), findsNothing);
      expect(harness.backend.calls, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('notifications-account-retry')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to view notifications'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('notifications-account-error')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('only confirmed AsyncData(null) paints the signed-out state', (
    final WidgetTester tester,
  ) async {
    final _ScreenHarness harness = await _pumpProductionScreen(
      tester,
      size: const Size(1440, 900),
      accountOverride: accountProvider.overrideWith(
        _SignedOutAccountNotifier.new,
      ),
    );
    addTearDown(harness.dispose);

    expect(find.text('Sign in to view notifications'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('notifications-account-loading')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('notifications-account-error')),
      findsNothing,
    );
    expect(harness.backend.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolved signed-in account reaches the real inbox page', (
    final WidgetTester tester,
  ) async {
    final _ScreenHarness harness = await _pumpProductionScreen(
      tester,
      size: const Size(800, 900),
      accountOverride: accountProvider.overrideWith(
        _SignedInAccountNotifier.new,
      ),
    );
    addTearDown(harness.dispose);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('notifications-inbox-list')),
      findsOneWidget,
    );
    expect(find.text('Sign in to view notifications'), findsNothing);
    expect(harness.backend.calls, <String>['all:1']);
    expect(tester.takeException(), isNull);
  });
}

ProviderContainer _container({
  required final InMemoryResourceRuntime runtime,
  required final _WidgetNotificationBackend backend,
}) => ProviderContainer(
  overrides: <Override>[
    settingsCacheProvider.overrideWithValue(SettingsCache(<String, String>{})),
    resourceRuntimeProvider.overrideWithValue(runtime),
    notificationPageResourceSpecFactoryProvider.overrideWithValue(
      backend.specFactory,
    ),
    notificationsInboxActionsProvider.overrideWith(
      (final Ref ref, final ResourceScope scope) =>
          const _FakeNotificationActions(),
    ),
    notificationSavedFiltersProvider.overrideWithValue(
      const AsyncData<List<NotificationSavedFilter>>(<NotificationSavedFilter>[
        (
          label: 'Needs review',
          query: 'reason:review-requested',
          storedQuery: 'notifications::reason:review-requested',
        ),
      ]),
    ),
  ],
);

final class _ScreenHarness {
  const _ScreenHarness({
    required this.container,
    required this.runtime,
    required this.backend,
  });

  final ProviderContainer container;
  final InMemoryResourceRuntime runtime;
  final _WidgetNotificationBackend backend;

  void dispose() {
    container.dispose();
    runtime.dispose();
  }
}

Future<_ScreenHarness> _pumpProductionScreen(
  final WidgetTester tester, {
  required final Size size,
  required final Override accountOverride,
}) async {
  final _WidgetNotificationBackend backend = _WidgetNotificationBackend();
  final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      settingsCacheProvider.overrideWithValue(
        SettingsCache(<String, String>{}),
      ),
      resourceRuntimeProvider.overrideWithValue(runtime),
      notificationPageResourceSpecFactoryProvider.overrideWithValue(
        backend.specFactory,
      ),
      notificationsInboxActionsProvider.overrideWith(
        (final Ref ref, final ResourceScope scope) =>
            const _FakeNotificationActions(),
      ),
      notificationSavedFiltersProvider.overrideWithValue(
        const AsyncData<List<NotificationSavedFilter>>(
          <NotificationSavedFilter>[],
        ),
      ),
      accountOverride,
      currentUserProvider.overrideWithBuild((final _, final _) async => null),
      homeTopRepositoriesProvider.overrideWith(
        (final Ref ref, final HomeTopRepositoriesKey key) async =>
            <HomeRepositoryItem>[],
      ),
    ],
  );
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: const NotificationsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return _ScreenHarness(
    container: container,
    runtime: runtime,
    backend: backend,
  );
}

final class _PendingAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() => Completer<AccountSession?>().future;
}

final class _SignedOutAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async => null;
}

final class _SignedInAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async {
    final AccountModel account = AccountModel(
      nodeId: 'widget-account',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    return AccountSession(
      accounts: <AccountModel>[account],
      activeAccount: account.username,
    );
  }
}

final class _RetryableErrorAccountNotifier extends AccountNotifier {
  static int builds = 0;

  @override
  Future<AccountSession?> build() async {
    builds++;
    if (builds == 1) {
      throw StateError('Could not read local account state');
    }
    return null;
  }
}

Future<void> _pumpPage(
  final WidgetTester tester,
  final ProviderContainer container, {
  final TextScaler textScaler = TextScaler.noScaling,
  final bool disableAnimations = false,
  final VisualDensity visualDensity = VisualDensity.standard,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true, visualDensity: visualDensity),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: const Scaffold(body: NotificationsMd3Page(scope: _scope)),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _FakeNotificationActions
    implements NotificationsInboxActionHandler {
  const _FakeNotificationActions();

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markDone(final Thread thread) async {}

  @override
  Future<void> markRead(final Thread thread) async {}

  @override
  Future<NotificationsBulkActionResult> markSelectedDone(
    final Iterable<Thread> threads,
  ) async =>
      NotificationsBulkActionResult(succeeded: threads.length, failed: 0);
}

final class _WidgetNotificationBackend {
  _WidgetNotificationBackend({
    this.holdFirstRequest = false,
    this.failFirstRequest = false,
  });

  final bool holdFirstRequest;
  final bool failFirstRequest;
  final List<String> calls = <String>[];
  Completer<List<Thread>>? _held;

  ResourceSpec<PaginatedResourcePage<Thread, NotificationPageKey>> specFactory({
    required final ResourceScope scope,
    required final bool showAll,
    required final NotificationPageKey pageKey,
    required final int pageSize,
  }) => ResourceSpec<PaginatedResourcePage<Thread, NotificationPageKey>>(
    id: ResourceId<PaginatedResourcePage<Thread, NotificationPageKey>>(
      kind: 'notifications-inbox-page',
      version: 1,
      scope: scope,
      key: '${showAll ? 'all' : 'unread'}/page:${pageKey.page}/size:$pageSize',
    ),
    policy: notificationPageResourcePolicy,
    tags: <ResourceTag>{
      notificationsInboxTag,
      notificationQueryTag(showAll: showAll),
    },
    contract: 'test-widget-notifications-page-v1',
    load: (final ResourceLoadContext _) async {
      calls.add('${showAll ? 'all' : 'unread'}:${pageKey.page}');
      if (failFirstRequest && calls.length == 1) {
        throw StateError('simulated notifications failure');
      }
      final List<Thread> items;
      if (holdFirstRequest && _held == null) {
        _held = Completer<List<Thread>>();
        items = await _held!.future;
      } else {
        items = showAll ? <Thread>[_unread, _read] : <Thread>[_unread];
      }
      return ResourceLoadResult<
        PaginatedResourcePage<Thread, NotificationPageKey>
      >(
        data: PaginatedResourcePage<Thread, NotificationPageKey>(
          items: items,
          hasNextPage: false,
        ),
      );
    },
  );

  void completeHeld(final List<Thread> items) {
    _held?.complete(items);
  }
}

const MinimalRepository _repository = MinimalRepository(
  fullName: 'octocat/hello-world',
  owner: MinimalOwner(login: 'octocat'),
);

final Thread _unread = Thread(
  id: 'unread',
  subject: const ThreadSubject(
    title: 'Please review the runtime page',
    type: NotificationSubjectType.pullRequest,
  ),
  reason: 'review_requested',
  repository: _repository,
  unread: true,
  updatedAt: DateTime(2026, 7, 25, 12),
);

final Thread _read = Thread(
  id: 'read',
  subject: const ThreadSubject(
    title: 'An already read issue',
    type: NotificationSubjectType.issue,
  ),
  reason: 'author',
  repository: _repository,
  updatedAt: DateTime(2026, 7, 24, 12),
);
