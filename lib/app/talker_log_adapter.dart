import 'dart:convert';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/scoped_talker_log.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_database/database/enums/log_level.dart' as app_log;
import 'package:drift/drift.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:talker/talker.dart' as talker;
import 'package:talker_dio_logger/dio_logs.dart';

/// Single point of contact with Talker internal types.
/// If `talker`/`talker_dio_logger` change their API, only this file breaks.
abstract final class TalkerLogAdapter {
  /// Map a raw TalkerData to a Drift companion, extracting all fields.
  static LogEntriesCompanion toCompanion(talker.TalkerData data) {
    final ref = _extractRef(data);
    final http = _extractHttp(data);
    final level = _mapLevel(data);

    return LogEntriesCompanion(
      level: Value(level.dbValue),
      message: Value(data.message ?? ''),
      tag: Value(_extractTag(data)),
      entityPath: Value(ref?.apiPath),
      entityType: Value(ref?.dbType),
      parentPath: Value(ref?.parentPath),
      httpMethod: Value(http.method),
      httpPath: Value(http.path),
      httpStatusCode: Value(http.statusCode),
      responseTimeMs: Value(http.responseTimeMs),
      errorMessage: Value(data.exception?.toString() ?? data.error?.toString()),
      stackTrace: Value(data.stackTrace?.toString()),
      detailJson: Value(http.detailJson),
      createdAt: Value(data.time),
    );
  }

  static EntityRef? _extractRef(talker.TalkerData data) =>
      data is ScopedTalkerLog ? data.entityRef : null;

  static app_log.LogLevel _mapLevel(talker.TalkerData data) {
    final talkerLevel = data.logLevel;
    if (talkerLevel == null) return app_log.LogLevel.info;
    return switch (talkerLevel) {
      talker.LogLevel.error => app_log.LogLevel.error,
      talker.LogLevel.warning => app_log.LogLevel.warning,
      talker.LogLevel.info => app_log.LogLevel.info,
      talker.LogLevel.debug => app_log.LogLevel.verbose,
      talker.LogLevel.verbose => app_log.LogLevel.verbose,
      _ => app_log.LogLevel.info,
    };
  }

  static ({
    String? method,
    String? path,
    int? statusCode,
    int? responseTimeMs,
    String? detailJson,
  }) _extractHttp(talker.TalkerData data) {
    if (data is DioResponseLog) {
      return (
        method: data.response.requestOptions.method,
        path: data.response.requestOptions.path,
        statusCode: data.response.statusCode,
        responseTimeMs: data.responseTime,
        detailJson: _safeSerializeDetail(data),
      );
    }
    if (data is DioErrorLog) {
      return (
        method: data.dioException.requestOptions.method,
        path: data.dioException.requestOptions.path,
        statusCode: data.dioException.response?.statusCode,
        responseTimeMs: data.responseTime,
        detailJson: _safeSerializeDetail(data),
      );
    }
    if (data is DioRequestLog) {
      return (
        method: data.requestOptions.method,
        path: data.requestOptions.path,
        statusCode: null,
        responseTimeMs: null,
        detailJson: null,
      );
    }
    return (
      method: null,
      path: null,
      statusCode: null,
      responseTimeMs: null,
      detailJson: null,
    );
  }

  /// Use Talker's structured key when available; do not parse message content.
  static String? _extractTag(talker.TalkerData data) {
    if (data is talker.TalkerLog) {
      final key = data.key;
      if (key != null && key != 'log') return key;
    }
    return null;
  }

  static const int _maxDetailBytes = 4096;

  static String? _safeSerializeDetail(talker.TalkerData data) {
    try {
      final Map<String, dynamic> detail = {};
      if (data is DioResponseLog) {
        final req = data.response.requestOptions;
        final res = data.response;
        detail['request'] = {
          'method': req.method,
          'path': req.path,
          'headers': req.headers,
        };
        detail['response'] = {
          'statusCode': res.statusCode,
          'statusMessage': res.statusMessage,
          'headers': res.headers.map,
        };
        final body = res.data;
        if (body != null) {
          final bodyStr = body is String ? body : jsonEncode(body);
          if (bodyStr.length <= _maxDetailBytes ~/ 2) {
            detail['responseBody'] = body;
          } else {
            detail['responseBody'] = '[truncated: ${bodyStr.length} chars]';
          }
        }
      } else if (data is DioErrorLog) {
        final req = data.dioException.requestOptions;
        detail['request'] = {
          'method': req.method,
          'path': req.path,
        };
        detail['error'] = {
          'type': data.dioException.type.name,
          'message': data.dioException.message,
        };
        final res = data.dioException.response;
        if (res != null) {
          detail['response'] = {
            'statusCode': res.statusCode,
            'statusMessage': res.statusMessage,
          };
        }
      }
      if (detail.isEmpty) return null;
      final json = jsonEncode(detail);
      return json.length <= _maxDetailBytes ? json : null;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to encode log detail',
        error: e,
        stackTrace: st,
        tag: 'TalkerLogAdapter',
      );
      return null;
    }
  }
}
