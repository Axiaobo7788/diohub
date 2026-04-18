import 'package:diohub_database/database/enums/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_filter.freezed.dart';

/// Filter state for the global log viewer.
@immutable
@freezed
abstract class LogFilter with _$LogFilter {
  const LogFilter._();

  const factory LogFilter({
    LogLevel? level,
    String? tag,
    String? entityPath,
    EntityTypeFilter? entityType,
    int? httpStatusCode,
    String? searchQuery,
    LogTimeRange? timeRange,
    @Default(false) bool errorsOnly,
    @Default(false) bool bookmarkedOnly,
  }) = _LogFilter;

  /// Effective level: errorsOnly overrides level.
  LogLevel? get effectiveLevel => errorsOnly ? LogLevel.error : level;
}
