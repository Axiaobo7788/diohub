import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/providers/repository/repository_providers.dart';

/// Per-pill state for branch/tag selector: refKind and search query.
class BranchPillState {
  const BranchPillState({
    this.refKind = RefKind.branch,
    this.searchQuery,
  });

  final RefKind refKind;
  final String? searchQuery;

  BranchPillState copyWith({RefKind? refKind, String? searchQuery}) =>
      BranchPillState(
        refKind: refKind ?? this.refKind,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

final branchPillStateProvider = NotifierProvider.autoDispose
    .family<BranchPillStateNotifier, BranchPillState, DockPillDescriptor>(
  BranchPillStateNotifier.new,
);

class BranchPillStateNotifier extends Notifier<BranchPillState> {
  BranchPillStateNotifier(this.descriptor);
  final DockPillDescriptor descriptor;

  @override
  BranchPillState build() => const BranchPillState();

  void setRefKind(RefKind kind) {
    state = state.copyWith(refKind: kind);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }
}
