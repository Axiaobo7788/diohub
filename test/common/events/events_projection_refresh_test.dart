import 'dart:async';

import 'package:diohub/app/settings/events.dart';
import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/app/settings/settings_descriptors.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/events_provider.dart'
    as settings_events;
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class _TestEventsSettingsNotifier
    extends GenericPersistedNotifier<EventsSettings> {
  _TestEventsSettingsNotifier() : super(eventsDescriptor);

  void setCompoundActions(final bool value) {
    state = state.copyWith(compoundActions: value);
  }
}

EventsModel _event({required final String id, required final String type}) =>
    EventsModel.fromJson(<String, dynamic>{
      'id': id,
      'type': type,
      'actor': <String, dynamic>{
        'id': 7,
        'login': 'octocat',
        'avatar_url': 'https://avatars.githubusercontent.com/u/7?v=4',
      },
      'repo': <String, dynamic>{
        'id': 42,
        'name': 'octocat/hello-world',
        'url': 'https://api.github.com/repos/octocat/hello-world',
      },
      'payload': type == 'PushEvent'
          ? <String, dynamic>{
              'ref': 'refs/heads/main',
              'head': 'abc123',
              'before': 'def456',
              'size': 1,
              'distinct_size': 1,
              'commits': <Map<String, dynamic>>[],
            }
          : <String, dynamic>{
              'ref': 'feature',
              'ref_type': 'branch',
              'master_branch': 'main',
              'pusher_type': 'user',
            },
      'public': true,
      'created_at': '2026-08-11T00:00:00Z',
    });

void main() {
  testWidgets('compound setting rebuilds the feed projection', (
    final WidgetTester tester,
  ) async {
    late _TestEventsSettingsNotifier settingsNotifier;
    final Completer<RepoCardData> repoCard = Completer<RepoCardData>();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        settings_events.eventsProvider.overrideWith(
          () => settingsNotifier = _TestEventsSettingsNotifier(),
        ),
        repoCardProvider.overrideWith(
          (final Ref ref, final RepoRef arg) => repoCard.future,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          home: CustomScrollView(
            slivers: <Widget>[
              Events.mock(<EventsModel>[
                _event(id: 'push', type: 'PushEvent'),
                _event(id: 'create', type: 'CreateEvent'),
              ]),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(UnifiedTimelineItem), findsOneWidget);

    settingsNotifier.setCompoundActions(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(UnifiedTimelineItem), findsNWidgets(2));
  });
}
