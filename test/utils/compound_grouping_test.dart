import 'package:diohub/utils/compound_grouping.dart';
import 'package:test/test.dart';

/// Minimal strategy for testing. Items are `_Evt` records.
class _TestStrategy extends GroupingStrategy<_Evt, String, String> {
  @override
  Object? actorKeyOf(final _Evt e) => e.actor;

  @override
  String actorDataOf(final _Evt e) => e.actor;

  @override
  Object targetOf(final _Evt e) => e.target;

  @override
  String actionOf(final _Evt e) => e.action;

  @override
  CompoundRole roleOf(final String action) => switch (action) {
        'primary' || 'opened' || 'closed' || 'push' => CompoundRole.primary,
        'label' || 'assign' || 'comment' => CompoundRole.supporting,
        _ => CompoundRole.isolated,
      };

  @override
  bool canMergeItems(final _Evt a, final _Evt b, final String action) {
    if (action == 'push') return a.branch == b.branch;
    return true;
  }
}

class _Evt {

  _Evt(
    this.id, {
    required this.actor,
    required this.target,
    required this.action,
    this.branch,
  });
  final String actor;
  final String target;
  final String action;
  final String? branch;
  final String id;

  @override
  String toString() => id;
}

void main() {
  late CompoundGrouper<_Evt, String, String> grouper;

  setUp(() {
    grouper = CompoundGrouper(_TestStrategy());
  });

  group('identity grouping', () {
    test('same actor groups into one section', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        _Evt('e2', actor: 'alice', target: 'repo2', action: 'star'),
      ],);
      expect(result.sections, hasLength(1));
      expect(result.sections.first.actor, 'alice');
    });

    test('different actors split into separate sections', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        _Evt('e2', actor: 'bob', target: 'repo1', action: 'star'),
      ],);
      expect(result.sections, hasLength(2));
      expect(result.sections[0].actor, 'alice');
      expect(result.sections[1].actor, 'bob');
    });

    test('actor switches back create a new section', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        _Evt('e2', actor: 'bob', target: 'repo1', action: 'star'),
        _Evt('e3', actor: 'alice', target: 'repo1', action: 'star'),
      ],);
      expect(result.sections, hasLength(3));
    });
  });

  group('target enforcement', () {
    test('same action on different targets produces separate compounds', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        _Evt('e2', actor: 'alice', target: 'repo2', action: 'star'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(2));
    });

    test('same action on same target merges into one cluster', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        _Evt('e2', actor: 'alice', target: 'repo1', action: 'star'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      // star is isolated, so each goes to its own compound...
      // BUT Step 1 fires first: same target + same action → merge into cluster.
      expect(section.compounds, hasLength(1));
      expect(section.compounds.first.parts.first.events, hasLength(2));
    });

    test('supporting action on different target creates new compound', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'issue/1', action: 'opened'),
        _Evt('e2', actor: 'alice', target: 'issue/2', action: 'label'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(2));
    });
  });

  group('role behavior', () {
    test('isolated role blocks cross-action compounding', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        _Evt('e2', actor: 'alice', target: 'repo1', action: 'fork'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(2));
    });

    test('supporting attaches to primary on same target', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'issue/1', action: 'opened'),
        _Evt('e2', actor: 'alice', target: 'issue/1', action: 'label'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(1));
      expect(section.compounds.first.parts, hasLength(2));
    });

    test('two primaries on same target produce separate compounds', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'issue/1', action: 'opened'),
        _Evt('e2', actor: 'alice', target: 'issue/1', action: 'closed'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(2));
    });

    test('supporting without prior primary still creates compound', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'issue/1', action: 'label'),
        _Evt('e2', actor: 'alice', target: 'issue/1', action: 'assign'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      // label → new compound, assign → same target, supporting, no primary conflict → joins.
      expect(section.compounds, hasLength(1));
      expect(section.compounds.first.parts, hasLength(2));
    });
  });

  group('canMergeItems refinement', () {
    test('push on same branch merges into one cluster', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1',
            actor: 'alice', target: 'repo1', action: 'push', branch: 'main',),
        _Evt('e2',
            actor: 'alice', target: 'repo1', action: 'push', branch: 'main',),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(1));
      expect(section.compounds.first.parts.first.events, hasLength(2));
    });

    test('push on different branches creates separate compounds', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1',
            actor: 'alice', target: 'repo1', action: 'push', branch: 'main',),
        _Evt('e2',
            actor: 'alice', target: 'repo1', action: 'push', branch: 'dev',),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      // Step 1: same target+action but canMergeItems returns false → falls through.
      // Step 2: primary + existing primary → primary conflict → new compound.
      expect(section.compounds, hasLength(2));
    });
  });

  group('inline dedup (map-based builder)', () {
    test('interleaved actions consolidate into one cluster per action', () {
      // label → assign → label  should produce 2 clusters (label, assign)
      // with the second label merging into the existing label cluster.
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt('e1', actor: 'alice', target: 'issue/1', action: 'label'),
        _Evt('e2', actor: 'alice', target: 'issue/1', action: 'assign'),
        _Evt('e3', actor: 'alice', target: 'issue/1', action: 'label'),
      ],);
      final ActorSection<String, String, _Evt> section = result.sections.first;
      expect(section.compounds, hasLength(1));
      final Compound<String, _Evt> compound = section.compounds.first;
      expect(compound.parts, hasLength(2)); // label, assign
      expect(compound.parts[0].action, 'label');
      expect(compound.parts[0].events, hasLength(2)); // e1 + e3
      expect(compound.parts[1].action, 'assign');
      expect(compound.parts[1].events, hasLength(1)); // e2
    });
  });

  group('boundary merging', () {
    test('tryMergeBoundary merges same-actor sections', () {
      final ActorSection<String, String, _Evt> prev = ActorSection<String, String, _Evt>(
        actor: 'alice',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'star', events: <_Evt>[
              _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
            ],),
          ],),
        ],
      );
      final ActorSection<String, String, _Evt> next = ActorSection<String, String, _Evt>(
        actor: 'alice',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'star', events: <_Evt>[
              _Evt('e2', actor: 'alice', target: 'repo1', action: 'star'),
            ],),
          ],),
        ],
      );

      final ActorSection<String, String, _Evt>? merged = grouper.tryMergeBoundary(prev, next);
      expect(merged, isNotNull);
      // star events on same target merge into one cluster.
      expect(merged!.compounds.first.parts.first.events, hasLength(2));
    });

    test('tryMergeBoundary returns null for different actors', () {
      final ActorSection<String, String, _Evt> prev = ActorSection<String, String, _Evt>(
        actor: 'alice',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'star', events: <_Evt>[
              _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
            ],),
          ],),
        ],
      );
      final ActorSection<String, String, _Evt> next = ActorSection<String, String, _Evt>(
        actor: 'bob',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'star', events: <_Evt>[
              _Evt('e2', actor: 'bob', target: 'repo1', action: 'star'),
            ],),
          ],),
        ],
      );

      expect(grouper.tryMergeBoundary(prev, next), isNull);
    });

    test('tryMergeBoundary replays all events from next first compound', () {
      final ActorSection<String, String, _Evt> prev = ActorSection<String, String, _Evt>(
        actor: 'alice',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'opened', events: <_Evt>[
              _Evt('e1', actor: 'alice', target: 'issue/1', action: 'opened'),
            ],),
          ],),
        ],
      );
      final ActorSection<String, String, _Evt> next = ActorSection<String, String, _Evt>(
        actor: 'alice',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'label', events: <_Evt>[
              _Evt('e2', actor: 'alice', target: 'issue/1', action: 'label'),
              _Evt('e3', actor: 'alice', target: 'issue/1', action: 'label'),
            ],),
          ],),
        ],
      );

      final ActorSection<String, String, _Evt>? merged = grouper.tryMergeBoundary(prev, next);
      expect(merged, isNotNull);
      // opened + label should compound (same target, supporting role).
      expect(merged!.compounds.first.parts, hasLength(2));
      expect(merged.compounds.first.parts[1].events, hasLength(2));
    });
  });

  group('carry merging', () {
    test('carry from previous page continues the section', () {
      final ActorSection<String, String, _Evt> carry = ActorSection<String, String, _Evt>(
        actor: 'alice',
        compounds: <Compound<String, _Evt>>[
          Compound<String, _Evt>(parts: <ActionCluster<String, _Evt>>[
            ActionCluster<String, _Evt>(action: 'star', events: <_Evt>[
              _Evt('e0', actor: 'alice', target: 'repo1', action: 'star'),
            ],),
          ],),
        ],
      );

      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(
        events: <_Evt>[
          _Evt('e1', actor: 'alice', target: 'repo1', action: 'star'),
        ],
        carry: carry,
      );

      expect(result.mergedWithCarry, isTrue);
      expect(result.sections.first.compounds.first.parts.first.events,
          hasLength(2),);
    });
  });

  group('edge cases', () {
    test('empty input returns empty sections', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[]);
      expect(result.sections, isEmpty);
      expect(result.mergedWithCarry, isFalse);
    });

    test('single item produces one section with one compound', () {
      final GroupingResult<ActorSection<String, String, _Evt>> result = grouper.group(events: <_Evt>[
        _Evt(
          'e1',
          actor: 'alice',
          target: 'repo1',
          action: 'star',
        ),
      ],);
      expect(result.sections, hasLength(1));
      expect(result.sections.first.compounds, hasLength(1));
      expect(result.sections.first.compounds.first.parts, hasLength(1));
    });
  });
}
