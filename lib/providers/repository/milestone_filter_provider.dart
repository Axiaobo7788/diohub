/// Milestone list state filter and refresh trigger for the Repo Milestones position.
library;

import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

class _MilestoneStateFilterNotifier extends Notifier<MilestoneState?> {
  _MilestoneStateFilterNotifier(this._arg);
  final RepoRef _arg;
  @override
  MilestoneState? build() => MilestoneState.OPEN;
}

/// Current state filter for the milestones list. Null = all, OPEN = open only, CLOSED = closed only.
final milestoneStateFilterProvider =
    NotifierProvider.family<_MilestoneStateFilterNotifier, MilestoneState?,
        RepoRef>(_MilestoneStateFilterNotifier.new);

/// Increment to trigger the Milestones position list to refresh (e.g. when state filter changes).
final ProviderFamily<ValueNotifier<int>, RepoRef>
    milestoneRefreshTriggerProvider =
    Provider.family<ValueNotifier<int>, RepoRef>((ref, repoRef) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});
