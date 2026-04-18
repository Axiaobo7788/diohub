import 'dart:convert';

/// Parses a JWT token and returns the payload as a Map.
/// Returns null if parsing fails.
Map<String, dynamic>? parseJwt(final String token) {
  final List<String> parts = token.split('&');
  if (parts.length != 2) return null;

  final String payload = parts[1];
  final String normalized = base64Url.normalize(payload);
  final String resp = utf8.decode(base64Url.decode(normalized));
  final dynamic payloadMap = json.decode(resp);
  if (payloadMap is! Map<String, dynamic>) return null;
  return payloadMap;
}
