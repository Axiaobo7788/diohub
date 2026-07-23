import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/events/compound_data.dart';
import 'package:diohub/utils/events/event_target.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';
import 'package:diohub_models/models/commits/commit_card_data_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:test/test.dart';

Map<String, dynamic> _redactedForkEventJson({
  final String id = '12155816494',
}) => <String, dynamic>{
  'id': id,
  'type': 'ForkEvent',
  'actor': <String, dynamic>{'id': 7, 'login': 'octocat'},
  'repo': <String, dynamic>{},
  'payload': <String, dynamic>{
    'forkee': <String, dynamic>{
      'name': 'diohub',
      'full_name': 'octocat/diohub',
      'url': 'https://api.github.com/repos/octocat/diohub',
      'html_url': 'https://github.com/octocat/diohub',
    },
  },
  'public': true,
  'created_at': '2026-07-23T00:00:00Z',
};

void main() {
  group('redacted event repository', () {
    test('parses repo: {} without discarding the ForkEvent payload', () {
      final EventsModel event = EventsModel.fromJson(_redactedForkEventJson());

      expect(event.repo.id, isNull);
      expect(event.repo.name, isNull);
      expect(event.repo.url, isNull);
      expect(event.payload.forkee?.fullName, 'octocat/diohub');
      expect(
        event.payload.forkee?.url,
        'https://api.github.com/repos/octocat/diohub',
      );
    });

    test('extracts the visible fork as the compound display repository', () {
      final EventsModel event = EventsModel.fromJson(_redactedForkEventJson());
      final EventCompound compound = Compound<SemanticAction, EventsModel>(
        parts: <EventCluster>[
          ActionCluster<SemanticAction, EventsModel>(
            action: SemanticAction.fork,
            events: <EventsModel>[event],
          ),
        ],
      );

      final EventCompoundData data = compound.toCompoundData();

      expect(data.repoName, isNull);
      expect(data.repoUrl, isNull);
      expect(data.forkRepoName, 'octocat/diohub');
      expect(data.forkRepoUrl, 'https://api.github.com/repos/octocat/diohub');
    });

    test('uses id, then name, then event id as the grouping identity', () {
      final EventsModel redacted = EventsModel.fromJson(
        _redactedForkEventJson(),
      );
      final EventsModel withName = redacted.copyWith(
        repo: const EventRepo(name: 'Owner/Repository'),
      );
      final EventsModel withId = redacted.copyWith(
        repo: const EventRepo(id: 42, name: 'Owner/Repository'),
      );
      final EventsModel anotherRedacted = EventsModel.fromJson(
        _redactedForkEventJson(id: 'another-event'),
      );

      expect(EventTarget.from(withId).repositoryKey, 'id:42');
      expect(EventTarget.from(withName).repositoryKey, 'name:owner/repository');
      expect(EventTarget.from(redacted).repositoryKey, 'event:12155816494');
      expect(
        EventTarget.from(anotherRedacted),
        isNot(EventTarget.from(redacted)),
      );
    });

    test('repository-only consumers reject a redacted source explicitly', () {
      final EventsModel event = EventsModel.fromJson(_redactedForkEventJson());

      expect(() => RepoRef.fromEventRepo(event.repo), throwsArgumentError);
      expect(() => CommitCardDataModel.fromPushEvent(event), throwsStateError);
    });
  });
}
