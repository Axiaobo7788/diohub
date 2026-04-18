import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_phase.freezed.dart';

enum FetchDirection { forward, backward }

@freezed
sealed class PaginationPhase with _$PaginationPhase {
  const PaginationPhase._();

  const factory PaginationPhase.idle() = Idle;
  const factory PaginationPhase.loadingForward() = LoadingForward;
  const factory PaginationPhase.loadingBackward() = LoadingBackward;
  const factory PaginationPhase.refreshing() = Refreshing;
  const factory PaginationPhase.failed(Object error, FetchDirection direction) =
      Failed;
}
