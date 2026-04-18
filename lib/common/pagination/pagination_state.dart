import 'package:diohub/common/pagination/pagination_phase.dart';

const _absent = _Absent();

class _Absent {
  const _Absent();
}

/// Immutable state for the unified pagination controller.
/// No cursor fields — the source owns those.
class PaginationState<R> {
  const PaginationState({
    this.items = const [],
    this.hasMoreForward = true,
    this.hasMoreBackward = false,
    this.anchorId,
    this.totalCount,
    this.phase = const Idle(),
    this.syntheticTailCount = 0,
  });

  final List<R> items;
  final bool hasMoreForward;
  final bool hasMoreBackward;
  final String? anchorId;
  final int? totalCount;
  final PaginationPhase phase;
  final int syntheticTailCount;

  /// True when paginated content hasn't reached the end but synthetic items exist at the tail.
  bool get hasGap => hasMoreForward && syntheticTailCount > 0;

  /// Estimated number of items in the gap (when totalCount is known).
  int? get gapEstimate => totalCount != null
      ? totalCount! - (items.length - syntheticTailCount)
      : null;

  bool get isEmpty => items.isEmpty && phase is Idle;

  PaginationState<R> copyWith({
    Object? items = _absent,
    Object? hasMoreForward = _absent,
    Object? hasMoreBackward = _absent,
    Object? anchorId = _absent,
    Object? totalCount = _absent,
    Object? phase = _absent,
    Object? syntheticTailCount = _absent,
  }) {
    return PaginationState<R>(
      items: items == _absent ? this.items : items as List<R>,
      hasMoreForward: hasMoreForward == _absent
          ? this.hasMoreForward
          : hasMoreForward as bool,
      hasMoreBackward: hasMoreBackward == _absent
          ? this.hasMoreBackward
          : hasMoreBackward as bool,
      anchorId: anchorId == _absent ? this.anchorId : anchorId as String?,
      totalCount: totalCount == _absent ? this.totalCount : totalCount as int?,
      phase: phase == _absent ? this.phase : phase as PaginationPhase,
      syntheticTailCount: syntheticTailCount == _absent
          ? this.syntheticTailCount
          : syntheticTailCount as int,
    );
  }
}
