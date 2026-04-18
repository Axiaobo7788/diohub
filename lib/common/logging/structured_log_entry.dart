import 'package:diohub_models/models/entity_ref.dart';

/// Typed wrapper around a log entry for provider/UI consumption.
/// Can be built from a Drift [LogEntry] row.
class StructuredLogEntry {
  const StructuredLogEntry({
    required this.id,
    required this.level,
    required this.message,
    this.tag,
    this.entityRef,
    this.entityPath,
    this.entityType,
    this.parentPath,
    this.httpMethod,
    this.httpPath,
    this.httpStatusCode,
    this.responseTimeMs,
    this.errorMessage,
    this.stackTrace,
    this.detailJson,
    required this.createdAt,
  });

  final int id;
  final String level;
  final String message;
  final String? tag;
  final EntityRef? entityRef;
  final String? entityPath;
  final String? entityType;
  final String? parentPath;
  final String? httpMethod;
  final String? httpPath;
  final int? httpStatusCode;
  final int? responseTimeMs;
  final String? errorMessage;
  final String? stackTrace;
  final String? detailJson;
  final DateTime createdAt;

  bool get isError => level == 'error';
  bool get isWarning => level == 'warning';
  bool get isApiLog => httpMethod != null;
  bool get isEntityScoped => entityPath != null;

  /// Hierarchical matching — same logic as ScopedTalkerLog.relatesTo().
  bool relatesTo(EntityRef scope) =>
      entityPath == scope.apiPath || parentPath == scope.apiPath;
}
