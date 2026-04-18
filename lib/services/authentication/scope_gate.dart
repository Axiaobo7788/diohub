import 'package:diohub_models/models/server_config.dart';

/// Service for querying granted OAuth/PAT scopes for the active account.
///
/// Provides per-feature scope checks for graceful degradation.
class ScopeGate {
  ScopeGate(this._grantedScopes);

  /// Parse a space or comma-separated scope string into a set of scopes.
  ///
  /// Used by [fromScopeString] factory, and can be used standalone for parsing.
  static Set<String> parseScopes(String? scopeString) {
    if (scopeString == null || scopeString.isEmpty) return <String>{};
    return scopeString
        .split(RegExp(r'[,\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  /// Create a ScopeGate from a space or comma-separated scope string.
  factory ScopeGate.fromScopeString(String? scopeString) =>
      ScopeGate(parseScopes(scopeString));

  final Set<String> _grantedScopes;

  /// Check if a single scope is granted.
  bool hasScope(String scope) => _grantedScopes.contains(scope);

  /// Check if all of the given scopes are granted.
  bool hasAllScopes(List<String> scopes) =>
      scopes.every(_grantedScopes.contains);

  /// Get the set of optional scopes that are missing from granted scopes.
  Set<String> get missingOptionalScopes =>
      OAuthConfig.optionalScopes.toSet().difference(_grantedScopes);

  /// Get the set of required scopes that are missing from granted scopes.
  Set<String> get missingRequiredScopes =>
      OAuthConfig.requiredScopes.toSet().difference(_grantedScopes);

  /// Check if all required scopes are present.
  bool get hasAllRequiredScopes => missingRequiredScopes.isEmpty;

  /// Get the list of all granted scopes.
  Set<String> get grantedScopes => Set.unmodifiable(_grantedScopes);
}
