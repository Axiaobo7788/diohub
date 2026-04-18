import 'package:dio/dio.dart';

/// Pure Dart scrubbing logic for removing sensitive data from strings,
/// exceptions, and maps before they reach Sentry.
///
/// This class is stateless and has no Sentry SDK dependencies, making it
/// easy to test and reason about. All methods are static and fail-safe:
/// if scrubbing fails, they return a safe default rather than throwing.
abstract final class SentryScrubber {
  SentryScrubber._();

  // Token patterns (comprehensive coverage of GitHub and generic formats)
  static final RegExp _tokenRe = RegExp(
    r'(?:'
    r'gh[psoura]_[A-Za-z0-9_]{36,}|' // GitHub fine-grained, classic, OAuth, user-to-server, app
    r'gho_[A-Za-z0-9]{36,}|' // GitHub OAuth tokens
    r'ghu_[A-Za-z0-9]{36,}|' // GitHub user-to-server
    r'github_pat_[A-Za-z0-9_]{22,}|' // New PAT format
    r'Bearer\s+[A-Za-z0-9._~+/-]+=*|' // Bearer tokens
    r'token\s+[A-Za-z0-9._~+/-]+=*|' // token keyword
    r'v1\.[A-Za-z0-9._~+/-]+=*' // Legacy GitHub v1 tokens
    r')',
    caseSensitive: false,
  );

  // Email pattern
  static final RegExp _emailRe = RegExp(
    r'[\w.+-]+@[\w-]+\.[\w.-]+',
  );

  // GitHub API path patterns
  static final RegExp _repoPathRe = RegExp(r'/repos/([^/\s?#]+)/([^/\s?#]+)');
  static final RegExp _userPathRe = RegExp(r'/users/([^/\s?#]+)');
  static final RegExp _orgPathRe = RegExp(r'/orgs/([^/\s?#]+)');

  // Query string pattern
  static final RegExp _queryStringRe = RegExp(r'\?[^\s]*');

  /// Scrub a string: strip tokens, hash GitHub identifiers, strip query strings, remove emails.
  static String scrubString(String input) {
    if (input.isEmpty) return input;

    try {
      var result = input;

      // 1. Strip all token patterns
      result = result.replaceAll(_tokenRe, '[REDACTED_TOKEN]');

      // 2. Strip emails
      result = result.replaceAll(_emailRe, '[REDACTED_EMAIL]');

      // 3. Hash GitHub repo paths
      result = result.replaceAllMapped(
        _repoPathRe,
        (m) => '/repos/${hashId(m[1]!)}/${hashId(m[2]!)}',
      );

      // 4. Hash GitHub user paths
      result = result.replaceAllMapped(
        _userPathRe,
        (m) => '/users/${hashId(m[1]!)}',
      );

      // 5. Hash GitHub org paths
      result = result.replaceAllMapped(
        _orgPathRe,
        (m) => '/orgs/${hashId(m[1]!)}',
      );

      // 6. Strip query strings (may contain search terms, tokens, sensitive params)
      result = result.replaceAll(_queryStringRe, '?[STRIPPED]');

      return result;
    } catch (e) {
      // Fail-safe: if scrubbing fails, return a safe placeholder
      return '[SCRUB_ERROR]';
    }
  }

  /// Simple deterministic hash for anonymizing identifiers.
  /// Uses String.hashCode for speed (not cryptographically secure, just obfuscation).
  static String hashId(String value) {
    if (value.isEmpty) return 'empty';
    try {
      final hash = value.hashCode.toRadixString(16).toLowerCase();
      // Pad or truncate to 8 characters for consistency
      return hash.length >= 8 ? hash.substring(0, 8) : hash.padLeft(8, '0');
    } catch (e) {
      return 'hash_err';
    }
  }

  /// Scrub HTTP headers: remove sensitive headers entirely.
  ///
  /// Follows Sentry's sensitive denylist for auth-related headers.
  static Map<String, String> scrubHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return headers;

    try {
      final result = Map<String, String>.from(headers);
      final keysToRemove = <String>[];

      // Sentry's built-in denylist (case-insensitive partial match)
      const denylist = [
        'auth',
        'token',
        'secret',
        'password',
        'passwd',
        'pwd',
        'key',
        'jwt',
        'bearer',
        'sso',
        'saml',
        'csrf',
        'xsrf',
        'credentials',
        'session',
        'sid',
        'identity',
      ];

      for (final key in result.keys) {
        final lowerKey = key.toLowerCase();
        if (denylist.any((term) => lowerKey.contains(term))) {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        result.remove(key);
      }

      return result;
    } catch (e) {
      // Fail-safe: return empty map if scrubbing fails
      return {};
    }
  }

  /// Recursively scrub a map: scrub all string values and nested maps.
  static Map<String, dynamic> scrubMapDeep(Map<String, dynamic> map) {
    if (map.isEmpty) return map;

    try {
      final result = <String, dynamic>{};

      for (final entry in map.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          result[key] = scrubString(value);
        } else if (value is Map<String, dynamic>) {
          result[key] = scrubMapDeep(value);
        } else if (value is List) {
          result[key] = _scrubListDeep(value);
        } else {
          result[key] = value;
        }
      }

      return result;
    } catch (e) {
      // Fail-safe: return empty map if scrubbing fails
      return {};
    }
  }

  /// Recursively scrub a list: scrub all string values and nested structures.
  static List<dynamic> _scrubListDeep(List<dynamic> list) {
    try {
      return list.map((item) {
        if (item is String) {
          return scrubString(item);
        } else if (item is Map<String, dynamic>) {
          return scrubMapDeep(item);
        } else if (item is List) {
          return _scrubListDeep(item);
        } else {
          return item;
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Scrub an exception object: if it's a DioException, replace it with a
  /// safe summary that contains no sensitive data.
  ///
  /// This is critical for preventing DioEventProcessor from extracting
  /// the full URL and headers from DioException.requestOptions.
  static Object scrubException(Object exception) {
    try {
      if (exception is DioException) {
        return _ScrubDioSummary.from(exception);
      }
      // For other exception types, scrub their string representation
      if (exception is Exception || exception is Error) {
        final str = exception.toString();
        return Exception(scrubString(str));
      }
      return exception;
    } catch (e) {
      // Fail-safe: return a generic exception if scrubbing fails
      return Exception('[EXCEPTION_SCRUB_ERROR]');
    }
  }
}

/// A safe, sanitized summary of a DioException that contains no sensitive data.
///
/// This class replaces DioException objects before they reach Sentry, preventing
/// DioEventProcessor from extracting sensitive information from requestOptions.
class _ScrubDioSummary implements Exception {
  _ScrubDioSummary({
    required this.type,
    required this.method,
    required this.statusCode,
    required this.message,
  });

  factory _ScrubDioSummary.from(DioException error) {
    try {
      return _ScrubDioSummary(
        type: error.type.toString(),
        method: error.requestOptions.method,
        statusCode: error.response?.statusCode,
        message: SentryScrubber.scrubString(
          error.message ?? error.type.toString(),
        ),
      );
    } catch (e) {
      // Fail-safe: minimal safe summary
      return _ScrubDioSummary(
        type: 'DioException',
        method: 'UNKNOWN',
        statusCode: null,
        message: '[SCRUB_ERROR]',
      );
    }
  }

  final String type;
  final String method;
  final int? statusCode;
  final String message;

  @override
  String toString() {
    final parts = <String>[
      'HTTP Error',
      method,
      if (statusCode != null) 'Status $statusCode',
      type,
      if (message.isNotEmpty && message != type) message,
    ];
    return parts.join(' - ');
  }
}
