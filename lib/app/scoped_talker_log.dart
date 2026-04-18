import 'package:diohub/app/talker.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Returns log entries from [appTalker] history that are [ScopedTalkerLog] and relate to [scope].
List<TalkerData> logsForScope(EntityRef scope) {
  return appTalker.history
      .whereType<ScopedTalkerLog>()
      .where((e) => e.relatesTo(scope))
      .toList();
}

/// A [TalkerLog] scoped to an [EntityRef] for filtering in repo/entity log viewers.
class ScopedTalkerLog extends TalkerLog {
  ScopedTalkerLog({
    required String message,
    required this.entityRef,
    LogLevel? logLevel,
    Object? exception,
    Object? error,
    StackTrace? stackTrace,
    super.key,
    super.time,
    super.pen,
  }) : super(
          message,
          title: '${entityRef.apiPath} | $message',
          logLevel: logLevel,
          exception: exception,
          error: error is Error ? error : null,
          stackTrace: stackTrace,
        );

  final EntityRef entityRef;

  @override
  String get title => '${entityRef.apiPath} | ${message ?? ''}';

  /// Whether this log relates to [scope] — either this ref equals [scope],
  /// or this ref is a child of [scope] in the EntityRef hierarchy (e.g. issue → repo).
  bool relatesTo(EntityRef scope) =>
      entityRef == scope || entityRef.parentPath == scope.apiPath;
}
