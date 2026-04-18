import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart' show Thread;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'selection_state.freezed.dart';

/// State for multi-select mode in a list tab (e.g. issues/PRs).
@freezed
abstract class SelectionState with _$SelectionState {
  const SelectionState._();

  const factory SelectionState({
    @Default(false) bool isActive,
    @Default({}) Set<String> selectedIds,
    @Default({}) Map<String, Object> idToRef,
  }) = _SelectionState;

  int get count => selectedIds.length;

  List<IssueRef> get issueRefs => idToRef.values.whereType<IssueRef>().toList();

  List<PullRequestRef> get pullRefs =>
      idToRef.values.whereType<PullRequestRef>().toList();

  List<Thread> get threads => idToRef.values.whereType<Thread>().toList();
}

/// Manages selection state per tab (key = positionKey, e.g. 'issues', 'pulls').
class SelectionNotifier extends Notifier<SelectionState> {
  SelectionNotifier(this.arg);
  final String arg;

  @override
  SelectionState build() => const SelectionState();

  void toggle(String id, Object ref) {
    final nextIds = Set<String>.from(state.selectedIds);
    final nextMap = Map<String, Object>.from(state.idToRef);
    if (nextIds.contains(id)) {
      nextIds.remove(id);
      nextMap.remove(id);
    } else {
      nextIds.add(id);
      nextMap[id] = ref;
    }
    state = state.copyWith(
      isActive: nextIds.isNotEmpty,
      selectedIds: nextIds,
      idToRef: nextMap,
    );
  }

  void selectAll(Iterable<String> ids, Map<String, Object> idToRef) {
    state = state.copyWith(
      isActive: true,
      selectedIds: ids.toSet(),
      idToRef: Map.from(idToRef),
    );
  }

  void clear() {
    state = const SelectionState();
  }

  /// Enters selection mode (list shows checkboxes). Call when user taps the
  /// selection pill in idle. Does not select any items.
  void activate() {
    state = state.copyWith(isActive: true);
  }
}

final selectionModeProvider = NotifierProvider.autoDispose
    .family<SelectionNotifier, SelectionState, String>(
  SelectionNotifier.new,
);
