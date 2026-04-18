/// Scalar type conversion helpers for GraphQL codegen.
///
/// These functions convert between JSON primitives and Dart types
/// for custom GraphQL scalars (DateTime, Uri, etc.).

DateTime dateTimeFromJson(dynamic json) {
  if (json is DateTime) return json;
  if (json is String) return DateTime.parse(json);
  throw ArgumentError('Cannot convert $json to DateTime');
}

String dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();

Uri uriFromJson(dynamic json) {
  if (json is Uri) return json;
  if (json is String) return Uri.parse(json);
  throw ArgumentError('Cannot convert $json to Uri');
}

String uriToJson(Uri uri) => uri.toString();
