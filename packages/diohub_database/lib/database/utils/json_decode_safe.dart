import 'dart:convert';

/// Optional error logging callback type.
typedef ErrorLogger = void Function(String message, Object? error);

/// Decodes [source] as a JSON map. Returns null and logs a warning
/// if [source] is null, empty, or not a Map.
Map<String, dynamic>? tryDecodeMap(
  String? source, {
  String? tag,
  ErrorLogger? onError,
}) {
  if (source == null || source.isEmpty) return null;
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    final msg = '[${tag ?? 'JsonDecode'}] Expected Map but got ${decoded.runtimeType}';
    if (onError != null) {
      onError(msg, null);
    } else {
      print(msg);
    }
    return null;
  } on FormatException catch (e) {
    final msg = '[${tag ?? 'JsonDecode'}] Invalid JSON';
    if (onError != null) {
      onError(msg, e);
    } else {
      print('$msg: $e');
    }
    return null;
  }
}

/// Decodes [source] as a JSON list. Returns null if not a List.
List<dynamic>? tryDecodeList(
  String? source, {
  String? tag,
  ErrorLogger? onError,
}) {
  if (source == null || source.isEmpty) return null;
  try {
    final decoded = jsonDecode(source);
    if (decoded is List<dynamic>) return decoded;
    final msg = '[${tag ?? 'JsonDecode'}] Expected List but got ${decoded.runtimeType}';
    if (onError != null) {
      onError(msg, null);
    } else {
      print(msg);
    }
    return null;
  } on FormatException catch (e) {
    final msg = '[${tag ?? 'JsonDecode'}] Invalid JSON';
    if (onError != null) {
      onError(msg, e);
    } else {
      print('$msg: $e');
    }
    return null;
  }
}

/// Safely casts each element to String, discarding non-strings.
List<String> castStringList(List<dynamic> list) =>
    list.whereType<String>().toList();
