import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub_graphql/queries/users/user_status.graphql.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub_models/models/users/gist_mutation_models.dart';
import 'package:diohub_models/models/users/gpg_key_item.dart';
import 'package:diohub_models/models/users/ssh_key_item.dart';
import 'package:diohub_models/models/users/ssh_signing_key_item.dart';
import 'package:diohub/services/base/base_service.dart';

/// Viewer-only settings and mutations: profile, status, blocks, SSH/GPG/SSH signing keys.
/// Use [viewerSettingsServiceProvider] to obtain an instance.
class ViewerSettingsService extends BaseService {
  ViewerSettingsService(super.apiClient);

  /// Updates the authenticated user's profile. REST only; no GQL equivalent.
  /// Ref: https://docs.github.com/en/rest/reference/users#update-the-authenticated-user
  /// Accepts: name, email, blog, twitter_username, company, location, bio, hireable.
  Future<void> updateProfile(final Map<String, dynamic> fields) async {
    await rest.patch<void>('/user', data: fields);
  }

  /// Sets or clears the viewer's status. Returns the new status from the response, or null if cleared.
  Future<Mutation$changeUserStatus$changeUserStatus$status?> changeStatus({
    final String? emoji,
    final String? message,
    final bool? limitedAvailability,
    final DateTime? expiresAt,
  }) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationchangeUserStatus,
      Variables$Mutation$changeUserStatus(
        emoji: emoji,
        message: message,
        limitedAvailability: limitedAvailability,
        expiresAt: expiresAt,
      ).toJson(),
    );
    final Mutation$changeUserStatus data = Mutation$changeUserStatus.fromJson(
      res.data!,
    );
    return data.changeUserStatus?.status;
  }

  /// Clears the viewer's status (calls changeUserStatus with all null).
  Future<void> clearStatus() async {
    await this.changeStatus(
      emoji: null,
      message: null,
      limitedAvailability: null,
      expiresAt: null,
    );
  }

  /// Blocks a user. GitHub does not expose this via GraphQL, only REST.
  Future<void> blockUser(final String username) async {
    await rest.put<void>('/user/blocks/$username');
  }

  /// Unblocks a user. DELETE /user/blocks/:username; 204 on success.
  Future<void> unblockUser(final String username) async {
    await rest.delete<void>('/user/blocks/$username');
  }

  /// Returns true if the given user is blocked by the viewer.
  Future<bool> isUserBlocked(final String username) async {
    try {
      await rest.get<void>('/user/blocks/$username');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  /// Lists the authenticated user's SSH public keys. GET /user/keys.
  Future<PaginatedResult<SSHKeyItem>> listSSHKeys({
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await rest.get<dynamic>(
      '/user/keys',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => SSHKeyItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse<SSHKeyItem>(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  /// Adds an SSH public key. POST /user/keys.
  Future<SSHKeyItem> createSSHKey({
    required String title,
    required String key,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '/user/keys',
      data: <String, dynamic>{'title': title, 'key': key},
    );
    return SSHKeyItem.fromJson(response.data!);
  }

  /// Deletes an SSH key. DELETE /user/keys/:keyId.
  Future<void> deleteSSHKey(int keyId) async {
    await rest.delete<void>('/user/keys/$keyId');
  }

  /// Lists the authenticated user's GPG keys. GET /user/gpg_keys.
  Future<PaginatedResult<GpgKeyItem>> listGPGKeys({
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await rest.get<dynamic>(
      '/user/gpg_keys',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => GpgKeyItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse<GpgKeyItem>(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  /// Adds a GPG key. POST /user/gpg_keys. [armoredPublicKey] is ASCII-armored.
  Future<GpgKeyItem> createGPGKey({
    required String armoredPublicKey,
    String? name,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '/user/gpg_keys',
      data: <String, dynamic>{
        'armored_public_key': armoredPublicKey,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return GpgKeyItem.fromJson(response.data!);
  }

  /// Deletes a GPG key. DELETE /user/gpg_keys/:keyId.
  Future<void> deleteGPGKey(int keyId) async {
    await rest.delete<void>('/user/gpg_keys/$keyId');
  }

  /// Lists the authenticated user's SSH signing keys. GET /user/ssh_signing_keys.
  Future<PaginatedResult<SSHSigningKeyItem>> listSSHSigningKeys({
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await rest.get<dynamic>(
      '/user/ssh_signing_keys',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => SSHSigningKeyItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse<SSHSigningKeyItem>(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  /// Adds an SSH signing key. POST /user/ssh_signing_keys.
  Future<SSHSigningKeyItem> createSSHSigningKey({
    required String title,
    required String key,
  }) async {
    final response = await rest.post<Map<String, dynamic>>(
      '/user/ssh_signing_keys',
      data: <String, dynamic>{'title': title, 'key': key},
    );
    return SSHSigningKeyItem.fromJson(response.data!);
  }

  /// Deletes an SSH signing key. DELETE /user/ssh_signing_keys/:keyId.
  Future<void> deleteSSHSigningKey(int keyId) async {
    await rest.delete<void>('/user/ssh_signing_keys/$keyId');
  }

  // ─── Email addresses (GET/POST/DELETE /user/emails, PATCH /user/email/visibility) ───

  /// Lists the authenticated user's email addresses. GET /user/emails.
  Future<PaginatedResult<EmailItem>> listEmails({
    int page = 1,
    int perPage = 30,
  }) async {
    final response = await rest.get<dynamic>(
      '/user/emails',
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
    final List<Object?> list = extractListFromResponse<Object?>(response);
    final items = list
        .map(
          (e) => EmailItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
    return parsePaginatedRestResponse<EmailItem>(
      response: response,
      items: items,
      currentPage: page,
    );
  }

  /// Adds email addresses. POST /user/emails. [emails] is a list of email strings.
  Future<List<EmailItem>> addEmails(List<String> emails) async {
    final response = await rest.post<List<dynamic>>(
      '/user/emails',
      data: <String, dynamic>{'emails': emails},
    );
    final list = response.data ?? <dynamic>[];
    return list
        .map(
          (e) => EmailItem.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  /// Deletes email addresses. DELETE /user/emails. [emails] is a list of email strings to remove.
  Future<void> deleteEmails(List<String> emails) async {
    await rest.delete<void>(
      '/user/emails',
      data: <String, dynamic>{'emails': emails},
    );
  }

  /// Whether the primary email visibility is public. Derived from GET /user/emails (primary item's visibility).
  Future<bool> getEmailVisibility() async {
    final result = await listEmails(page: 1, perPage: 30);
    try {
      final primary = result.items.firstWhere((EmailItem e) => e.primary);
      return primary.visibility == 'public';
    } on StateError catch (e) {
      AppLogger.error('No primary email found', error: e, tag: 'UserSettings');
      return false;
    }
  }

  /// Sets the primary email visibility. PATCH /user/email/visibility.
  Future<void> setEmailVisibility(String visibility) async {
    await rest.patch<void>(
      '/user/email/visibility',
      data: <String, dynamic>{'visibility': visibility},
    );
  }

  // ─── Gists (REST: create/update/delete/star) ───

  /// Creates a gist. POST /gists.
  Future<GistResponse> createGist({
    required String description,
    required List<GistFileInput> files,
    bool public = false,
  }) async {
    final Map<String, dynamic> filesMap = <String, dynamic>{};
    for (final f in files) {
      filesMap[f.filename] = <String, dynamic>{'content': f.content};
    }
    final Response<Map<String, dynamic>> res = await rest
        .post<Map<String, dynamic>>(
          '/gists',
          data: <String, dynamic>{
            'description': description,
            'public': public,
            'files': filesMap,
          },
        );
    return GistResponse.fromJson(res.data! as Map<String, dynamic>);
  }

  /// Updates a gist. PATCH /gists/:gist_id.
  Future<GistResponse> updateGist({
    required String gistId,
    String? description,
    List<GistFileInput>? files,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (description != null) data['description'] = description;
    if (files != null) {
      final Map<String, dynamic> filesMap = <String, dynamic>{};
      for (final f in files) {
        filesMap[f.filename] = <String, dynamic>{'content': f.content};
      }
      data['files'] = filesMap;
    }
    final Response<Map<String, dynamic>> res = await rest
        .patch<Map<String, dynamic>>('/gists/$gistId', data: data);
    return GistResponse.fromJson(res.data! as Map<String, dynamic>);
  }

  /// Deletes a gist. DELETE /gists/:gist_id.
  Future<void> deleteGist(String gistId) async {
    await rest.delete<void>('/gists/$gistId');
  }

  /// Stars a gist. PUT /gists/:gist_id/star.
  Future<void> starGist(String gistId) async {
    await rest.put<void>('/gists/$gistId/star');
  }

  /// Unstars a gist. DELETE /gists/:gist_id/star.
  Future<void> unstarGist(String gistId) async {
    await rest.delete<void>('/gists/$gistId/star');
  }

  /// Returns true if the gist is starred by the viewer (204), false if not (404).
  Future<bool> isGistStarred(String gistId) async {
    try {
      await rest.get<void>('/gists/$gistId/star');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }
}
