import 'package:drift/drift.dart';

/// Persistent log entries. Replaces the in-memory Talker ring buffer for
/// persistence while keeping Talker as the in-process sink.
/// Composite indexes for filtered queries (level+time, entity+time, etc.).
@TableIndex(name: 'idx_log_level_created', columns: {#level, #createdAt})
@TableIndex(name: 'idx_log_entity_created', columns: {#entityPath, #createdAt})
@TableIndex(name: 'idx_log_tag_created', columns: {#tag, #createdAt})
@TableIndex(name: 'idx_log_type_created', columns: {#entityType, #createdAt})
@TableIndex(name: 'idx_log_parent_created', columns: {#parentPath, #createdAt})
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Optional nodeId for bookmark correlation (populated when available post-API).
  TextColumn get nodeId => text().nullable()();

  /// Log level: 'error', 'warning', 'info', 'verbose'.
  TextColumn get level => text()();

  /// Primary log message text.
  TextColumn get message => text()();

  /// Optional tag prefix: 'Dio', 'GraphQL', 'Auth', service name, etc.
  TextColumn get tag => text().nullable()();

  // ── Entity key contract (shared with all other tables) ──
  /// EntityRef.apiPath — nullable because not all logs are entity-scoped.
  TextColumn get entityPath => text().nullable()();

  /// EntityRef.dbType — filter discriminator.
  TextColumn get entityType => text().nullable()();

  /// EntityRef.parentPath — scope key for hierarchical queries.
  TextColumn get parentPath => text().nullable()();

  // ── HTTP-specific columns (populated for API logs) ──
  /// HTTP method: GET, POST, PUT, DELETE, PATCH.
  TextColumn get httpMethod => text().nullable()();

  /// Request URL path (without host).
  TextColumn get httpPath => text().nullable()();

  /// HTTP status code (200, 404, 500, etc.).
  IntColumn get httpStatusCode => integer().nullable()();

  /// Response time in milliseconds.
  IntColumn get responseTimeMs => integer().nullable()();

  // ── Detail columns ──
  /// Serialized error/exception message.
  TextColumn get errorMessage => text().nullable()();

  /// Serialized stack trace.
  TextColumn get stackTrace => text().nullable()();

  /// Full request/response detail JSON (optional, only for verbose).
  TextColumn get detailJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
