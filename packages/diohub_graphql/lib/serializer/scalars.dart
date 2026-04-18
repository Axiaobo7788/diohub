// Custom scalar serialization helpers for graphql_codegen
// 
// Note: graphql_codegen handles most scalar mappings via build.yaml configuration.
// These helpers are provided for any manual parsing needs.

/// Parses a Date scalar string to DateTime
DateTime parseDateScalar(String value) => DateTime.parse(value);

/// Serializes DateTime to Date scalar string
String serializeDateScalar(DateTime value) => value.toIso8601String();

/// Parses a DateTime scalar string to DateTime
DateTime parseDateTimeScalar(String value) => DateTime.parse(value);

/// Serializes DateTime to DateTime scalar string
String serializeDateTimeScalar(DateTime value) => value.toIso8601String();

/// Parses a URI scalar string to Uri
Uri parseUriScalar(String value) => Uri.parse(value);

/// Serializes Uri to URI scalar string
String serializeUriScalar(Uri value) => value.toString();
