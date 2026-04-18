import 'dart:convert';

import 'package:diohub/app/app_logger.dart';

/// Decodes [source] as a JSON map. Returns null and logs a warning
/// if [source] is null, empty, or not a Map.
Map<String, dynamic>? tryDecodeMap(String? source, {String? tag}) {
  if (source == null || source.isEmpty) return null;
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    AppLogger.warning(
      'Expected Map but got ${decoded.runtimeType}',
      tag: tag ?? 'JsonDecode',
    );
    return null;
  } on FormatException catch (e) {
    AppLogger.warning('Invalid JSON: $e', tag: tag ?? 'JsonDecode');
    return null;
  }
}

/// Decodes [source] as a JSON list. Returns null if not a List.
List<dynamic>? tryDecodeList(String? source, {String? tag}) {
  if (source == null || source.isEmpty) return null;
  try {
    final decoded = jsonDecode(source);
    if (decoded is List<dynamic>) return decoded;
    AppLogger.warning(
      'Expected List but got ${decoded.runtimeType}',
      tag: tag ?? 'JsonDecode',
    );
    return null;
  } on FormatException catch (e) {
    AppLogger.warning('Invalid JSON: $e', tag: tag ?? 'JsonDecode');
    return null;
  }
}

/// Safely casts each element to String, discarding non-strings.
List<String> castStringList(List<dynamic> list) =>
    list.whereType<String>().toList();
