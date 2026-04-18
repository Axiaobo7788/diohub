/// Generic compound grouping engine.
///
/// Groups a stream of items into a three-level hierarchy:
///   1. [ActorSection] — items from one actor (identity)
///   2. [Compound]     — related action clusters on the same target
///   3. [ActionCluster] — items with the same semantic action
///
/// The engine is configured via a [GroupingStrategy] that answers
/// six questions about each item (who, what target, which action, etc.).
///
/// Two built-in strategies:
///   - `EventGroupingStrategy`  — GitHub events feed (mixed roles, real targets)
///   - `TimelineGroupingStrategy` — issue/PR timeline (all isolated, constant target)
library;

import 'package:diohub/utils/timeline/timeline_node_id.dart';

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------

/// How an action type participates in compounding.
enum CompoundRole {
  /// Anchor of a compound. At most one primary per compound.
  /// Examples: opened issue, closed PR, pushed commits.
  primary,

  /// Attaches to a primary (or other supporting) if on the same target.
  /// Examples: labeled, assigned, commented.
  supporting,

  /// Always renders as its own card. Never joins another compound.
  /// Examples: reviewed; and ALL timeline actions.
  isolated,

  /// Like [isolated] (never joins other action types), but consecutive events
  /// with the same action merge into one compound across different targets.
  /// Examples: starred 3 repos, forked 2 repos, made 2 repos public.
  crossTarget,
}

// ---------------------------------------------------------------------------
// Output data types (immutable)
// ---------------------------------------------------------------------------

/// Innermost: a cluster of items with the same action on the same target.
class ActionCluster<A, E> {
  const ActionCluster({required this.action, required this.events});
  final A action;
  final List<E> events;

  E get first => events.first;
  E get last => events.last;
  int get length => events.length;

  @override
  String toString() => 'ActionCluster($action, ${events.length} events)';
}

/// Middle: one timeline card — related action clusters on the same target.
class Compound<A, E> {
  const Compound({required this.parts});
  final List<ActionCluster<A, E>> parts;

  /// Whether this contains multiple action clusters (true compound).
  bool get isMultiAction => parts.length > 1;

  /// First action cluster.
  ActionCluster<A, E> get firstPart => parts.first;

  /// All items across all parts, flattened.
  List<E> get allEvents =>
      parts.expand((final ActionCluster<A, E> p) => p.events).toList();

  @override
  String toString() =>
      'Compound(${parts.length} parts, isMultiAction: $isMultiAction)';
}

/// Outermost: a section under one actor's sticky header.
class ActorSection<D, A, E> {
  const ActorSection({required this.actor, required this.compounds});
  final D actor;
  final List<Compound<A, E>> compounds;

  /// Last event across all compounds (used for boundary checks).
  E get lastEvent => compounds.last.parts.last.last;

  /// Stable unique identifier for this section (e.g. first event's node ID).
  String get itemId {
    final firstEvent = compounds.first.firstPart.events.first;
    return timelineNodeIdOf(firstEvent) ?? identityHashCode(this).toString();
  }

  /// IDs of sub-items (e.g. comment IDs inside this section).
  Set<String> get containedIds => const {};

  @override
  String toString() =>
      'ActorSection(actor: $actor, ${compounds.length} compounds)';
}

// ---------------------------------------------------------------------------
// Strategy interface
// ---------------------------------------------------------------------------

/// Defines how items are grouped into actor sections, compounds, and clusters.
///
/// Each method answers exactly one question:
///   [actorKeyOf]    → "Who did this?"
///   [actorDataOf]   → "What do we display in the header?"
///   [targetOf]      → "What is this item acting on?"
///   [actionOf]      → "What kind of action is this?"
///   [roleOf]        → "How does this action compound?"
///   [canMergeItems] → "Within the same action+target, are these the same cluster?"
abstract class GroupingStrategy<E, D, A> {
  /// Identity key. Consecutive items with the same key stay in one section.
  Object? actorKeyOf(final E event);

  /// Data for the section header (avatar, login, etc.).
  D actorDataOf(final E event);

  /// Target key. Only items with equal targets can share a compound.
  /// This is ALWAYS checked by the engine — no callback can bypass it.
  Object targetOf(final E event);

  /// Classifies the item into a semantic action.
  A actionOf(final E event);

  /// Determines how this action participates in compounding.
  CompoundRole roleOf(final A action);

  /// Optional refinement: can [incoming] merge into the same cluster as
  /// [existing]? Both already have the same action AND the same target.
  /// Override for sub-action splits (e.g., push events must be on the same
  /// branch). Default: always merge.
  bool canMergeItems(final E existing, final E incoming, final A action) =>
      true;
}

// ---------------------------------------------------------------------------
// Grouping result
// ---------------------------------------------------------------------------

/// Output of [CompoundGrouper.group].
class GroupingResult<G> {
  const GroupingResult({
    required this.sections,
    required this.mergedWithCarry,
  });
  final List<G> sections;
  final bool mergedWithCarry;
}

// ---------------------------------------------------------------------------
// Mutable builders (private)
// ---------------------------------------------------------------------------

class _SectionBuilder<D, A, E> {
  _SectionBuilder(this.actor);
  final D actor;
  final List<_CompoundBuilder<A, E>> compounds = <_CompoundBuilder<A, E>>[];

  _CompoundBuilder<A, E> get lastCompound => compounds.last;

  ActorSection<D, A, E> build() => ActorSection(
        actor: actor,
        compounds: compounds
            .map((final _CompoundBuilder<A, E> c) => c.build())
            .toList(),
      );
}

class _CompoundBuilder<A, E> {
  _CompoundBuilder(this.target);
  final Object target;

  /// Keyed by action — automatically deduplicates.
  final Map<A, List<E>> _clusters = <A, List<E>>{};
  final List<A> _insertionOrder = <A>[];

  /// Add event to existing cluster, or start a new one.
  void add(final A action, final E event) {
    if (_clusters.containsKey(action)) {
      _clusters[action]!.add(event);
    } else {
      _clusters[action] = <E>[event];
      _insertionOrder.add(action);
    }
  }

  /// Does a cluster for this action already exist?
  bool hasAction(final A action) => _clusters.containsKey(action);

  /// Last event in the cluster for this action (for canMergeItems check).
  E? lastEventFor(final A action) => _clusters[action]?.last;

  /// All action types present in this compound.
  Iterable<A> get actions => _insertionOrder;

  /// All events across all clusters, flattened.
  List<E> get allEvents =>
      _insertionOrder.expand((final a) => _clusters[a]!).toList();

  Compound<A, E> build() => Compound(
        parts: _insertionOrder
            .map((final a) => ActionCluster(action: a, events: _clusters[a]!))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

/// Groups items into [ActorSection]s using a [GroupingStrategy].
///
/// Usage:
/// ```dart
/// final grouper = CompoundGrouper(EventGroupingStrategy());
/// final result = grouper.group(events: myEvents);
/// for (final section in result.sections) { ... }
/// ```
class CompoundGrouper<E, D, A> {
  CompoundGrouper(this.strategy);
  final GroupingStrategy<E, D, A> strategy;

  /// Groups [events] into actor sections.
  /// Optionally accepts a [carry] from the previous page for boundary merging.
  GroupingResult<ActorSection<D, A, E>> group({
    required final Iterable<E> events,
    final ActorSection<D, A, E>? carry,
  }) {
    final List<ActorSection<D, A, E>> result = <ActorSection<D, A, E>>[];
    bool mergedWithCarry = false;

    _SectionBuilder<D, A, E>? active;
    bool activeIsFromCarry = false;

    // If carry is provided, convert it to a mutable builder to continue from.
    if (carry != null) {
      active = _builderFrom(carry);
      activeIsFromCarry = true;
    }

    for (final E event in events) {
      final Object? actorKey = strategy.actorKeyOf(event);

      if (active == null) {
        // First event, no carry.
        active = _SectionBuilder(strategy.actorDataOf(event));
        _seedCompound(active, event);
        result.add(active.build());
        activeIsFromCarry = false;
        continue;
      }

      // Check actor boundary.
      final E lastEvent = active.compounds.last.allEvents.last;
      final Object? lastActorKey = strategy.actorKeyOf(lastEvent);

      if (actorKey != lastActorKey) {
        // Actor changed — finalize active, start new section.
        if (activeIsFromCarry && result.isEmpty) {
          // Carry merged but never added to result yet — shouldn't happen
          // because we add immediately below. But guard anyway.
          mergedWithCarry = true;
          result.add(active.build());
        }
        active = _SectionBuilder(strategy.actorDataOf(event));
        _seedCompound(active, event);
        activeIsFromCarry = false;
        result.add(active.build());
        continue;
      }

      // Same actor — add event to the active section.
      _addEvent(active, event);

      // Update result list.
      if (activeIsFromCarry && result.isEmpty) {
        mergedWithCarry = true;
        result.add(active.build());
        activeIsFromCarry = false;
      } else if (result.isNotEmpty) {
        result[result.length - 1] = active.build();
      } else {
        result.add(active.build());
      }
    }

    return GroupingResult(
      sections: result,
      mergedWithCarry: mergedWithCarry,
    );
  }

  /// Tries to merge adjacent sections at a page boundary.
  /// Replays ALL events from [next]'s first compound into [prev].
  /// Returns the merged section if successful, null otherwise.
  ActorSection<D, A, E>? tryMergeBoundary(
    final ActorSection<D, A, E> prev,
    final ActorSection<D, A, E> next,
  ) {
    if (next.compounds.isEmpty) return null;

    // Can only merge if same actor.
    final E prevLastEvent = prev.lastEvent;
    final E nextFirstEvent = next.compounds.first.allEvents.first;
    if (strategy.actorKeyOf(prevLastEvent) !=
        strategy.actorKeyOf(nextFirstEvent)) {
      return null;
    }

    // Rebuild prev as a mutable builder, replay next's first compound.
    final _SectionBuilder<D, A, E> builder = _builderFrom(prev);
    for (final E event in next.compounds.first.allEvents) {
      _addEvent(builder, event);
    }
    return builder.build();
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// Start a new compound in [section] with [event] as its first item.
  void _seedCompound(final _SectionBuilder<D, A, E> section, final E event) {
    final A action = strategy.actionOf(event);
    final Object target = strategy.targetOf(event);
    final _CompoundBuilder<A, E> compound = _CompoundBuilder<A, E>(target);
    compound.add(action, event);
    section.compounds.add(compound);
  }

  /// Core decision tree: add [event] to the appropriate place in [section].
  void _addEvent(final _SectionBuilder<D, A, E> section, final E event) {
    final A action = strategy.actionOf(event);
    final CompoundRole role = strategy.roleOf(action);
    final Object target = strategy.targetOf(event);

    final _CompoundBuilder<A, E> lastCompound = section.lastCompound;

    // Merge into existing cluster?
    // Requires: same target + cluster exists for this action + refinement passes.
    if (lastCompound.target == target && lastCompound.hasAction(action)) {
      final E? lastInClusterNullable = lastCompound.lastEventFor(action);
      if (lastInClusterNullable == null) {
        throw StateError('Expected event for action $action but got null');
      }
      if (lastInClusterNullable is! E) {
        throw StateError('Expected event type $E but got ${lastInClusterNullable.runtimeType}');
      }
      final E lastInCluster = lastInClusterNullable;
      if (strategy.canMergeItems(lastInCluster, event, action)) {
        lastCompound.add(action, event);
        return;
      }
    }

    // New cluster in existing compound?
    // Requires: not isolated/crossTarget + same target + no primary conflict.
    if (role != CompoundRole.isolated &&
        role != CompoundRole.crossTarget &&
        lastCompound.target == target &&
        !_hasPrimaryConflict(lastCompound, role)) {
      lastCompound.add(action, event);
      return;
    }

    // Cross-target merge?
    // Same action across different targets, compound must be pure (single action).
    if (role == CompoundRole.crossTarget &&
        lastCompound.actions.length == 1 &&
        lastCompound.hasAction(action)) {
      final E? lastInClusterNullable = lastCompound.lastEventFor(action);
      if (lastInClusterNullable == null) {
        throw StateError('Expected event for action $action but got null');
      }
      if (lastInClusterNullable is! E) {
        throw StateError('Expected event type $E but got ${lastInClusterNullable.runtimeType}');
      }
      final E lastInCluster = lastInClusterNullable;
      if (strategy.canMergeItems(lastInCluster, event, action)) {
        lastCompound.add(action, event);
        return;
      }
    }

    // Start a new compound.
    _seedCompound(section, event);
  }

  /// Check if adding a primary action to [compound] would conflict.
  bool _hasPrimaryConflict(
      final _CompoundBuilder<A, E> compound, final CompoundRole role) {
    if (role != CompoundRole.primary) return false;
    return compound.actions.any(
      (final a) => strategy.roleOf(a) == CompoundRole.primary,
    );
  }

  /// Convert an immutable [ActorSection] back to a mutable builder.
  _SectionBuilder<D, A, E> _builderFrom(final ActorSection<D, A, E> section) {
    final _SectionBuilder<D, A, E> builder =
        _SectionBuilder<D, A, E>(section.actor);
    for (final Compound<A, E> compound in section.compounds) {
      final Object target = _targetFromCompound(compound);
      final _CompoundBuilder<A, E> cb = _CompoundBuilder<A, E>(target);
      for (final ActionCluster<A, E> cluster in compound.parts) {
        for (final E event in cluster.events) {
          cb.add(cluster.action, event);
        }
      }
      builder.compounds.add(cb);
    }
    return builder;
  }

  /// Extract the target from the first event in a compound.
  Object _targetFromCompound(final Compound<A, E> compound) =>
      strategy.targetOf(compound.parts.first.first);
}
