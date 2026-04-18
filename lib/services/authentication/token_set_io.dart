import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub/services/authentication/token_store.dart';

/// Key name constants for token storage schema.
const _accessTokenPrefix = 'accessToken_';
const _refreshTokenPrefix = 'refreshToken_';
const _tokenExpiryPrefix = 'tokenExpiry_';
const _refreshTokenExpiryPrefix = 'refreshTokenExpiry_';

/// Extension on [TokenStore] providing token-set I/O operations.
///
/// Centralizes the 4-key token schema (accessToken, refreshToken, tokenExpiry,
/// refreshTokenExpiry) so all callsites use the same pattern. The [TokenStore]
/// itself remains a pure key-value primitive.
extension TokenSetIO on TokenStore {
  /// Read a full token set from secure storage.
  ///
  /// Reads all four keys and assembles them into an [AccessTokenModel].
  /// Returns null if the access token is missing.
  Future<AccessTokenModel?> readTokenSet(String storageKey) async {
    final accessToken = await read('$_accessTokenPrefix$storageKey');
    if (accessToken == null || accessToken.isEmpty) return null;

    final refreshToken = await read('$_refreshTokenPrefix$storageKey');
    final expiryStr = await read('$_tokenExpiryPrefix$storageKey');
    final refreshExpiryStr = await read('$_refreshTokenExpiryPrefix$storageKey');

    return AccessTokenModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt:
          expiryStr != null ? DateTime.tryParse(expiryStr) : null,
      refreshTokenExpiresAt: refreshExpiryStr != null
          ? DateTime.tryParse(refreshExpiryStr)
          : null,
    );
  }

  /// Write a full token set (access token, refresh token, expiry dates) to secure storage.
  ///
  /// Stores four separate keys:
  /// - `accessToken_{storageKey}` — the access token
  /// - `refreshToken_{storageKey}` — the refresh token (optional)
  /// - `tokenExpiry_{storageKey}` — access token expiry ISO8601 string (optional)
  /// - `refreshTokenExpiry_{storageKey}` — refresh token expiry ISO8601 string (optional)
  ///
  /// This mirrors the MCP OAuth service pattern and allows updating just the
  /// access token on refresh without rewriting the refresh token.
  Future<void> writeTokenSet(String storageKey, AccessTokenModel model) async {
    if (model.accessToken != null) {
      await write('$_accessTokenPrefix$storageKey', model.accessToken!);
    }
    if (model.refreshToken != null) {
      await write('$_refreshTokenPrefix$storageKey', model.refreshToken!);
    } else {
      await delete('$_refreshTokenPrefix$storageKey');
    }
    if (model.accessTokenExpiresAt != null) {
      await write('$_tokenExpiryPrefix$storageKey',
          model.accessTokenExpiresAt!.toIso8601String());
    } else {
      await delete('$_tokenExpiryPrefix$storageKey');
    }
    if (model.refreshTokenExpiresAt != null) {
      await write('$_refreshTokenExpiryPrefix$storageKey',
          model.refreshTokenExpiresAt!.toIso8601String());
    } else {
      await delete('$_refreshTokenExpiryPrefix$storageKey');
    }
  }

  /// Delete all token set keys for a given storage key.
  ///
  /// Removes all four keys to prevent orphaned keychain entries.
  Future<void> deleteTokenSet(String storageKey) async {
    await delete('$_accessTokenPrefix$storageKey');
    await delete('$_refreshTokenPrefix$storageKey');
    await delete('$_tokenExpiryPrefix$storageKey');
    await delete('$_refreshTokenExpiryPrefix$storageKey');
  }
}
