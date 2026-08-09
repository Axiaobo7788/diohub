import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/providers/users/viewer_settings_page_resource.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/services/users/viewer_settings_service.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/users/gpg_key_item.dart';
import 'package:diohub_models/models/users/ssh_key_item.dart';
import 'package:diohub_models/models/users/ssh_signing_key_item.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

typedef ViewerSettingsSessionKey = ({ResourceScope scope, String login});

/// Provider-owned Settings query session.
///
/// Controllers are lazy and survive short navigation between Settings
/// destinations. Widgets only render controller state and invoke explicit user
/// actions; resource identity, cursors and invalidation remain here.
final class ViewerSettingsSession {
  ViewerSettingsSession({
    required this.runtime,
    required this.scope,
    required this.login,
    required this.viewerSettingsService,
    required this.userInfoService,
  });

  final ResourceRuntime runtime;
  final ResourceScope scope;
  final String login;
  final ViewerSettingsService viewerSettingsService;
  final UserInfoService userInfoService;

  PaginationController<EmailItem, EmailItem>? _emails;
  PaginationController<SSHKeyItem, SSHKeyItem>? _sshKeys;
  PaginationController<GpgKeyItem, GpgKeyItem>? _gpgKeys;
  PaginationController<SSHSigningKeyItem, SSHSigningKeyItem>? _sshSigningKeys;
  PaginationController<SimpleUser, SimpleUser>? _blockedUsers;
  PaginationController<UserOrgEdge, UserOrgEdge>? _organizations;
  PaginationController<UserRepoEdge, UserRepoEdge>? _repositories;
  bool _disposed = false;

  PaginationController<EmailItem, EmailItem> get emails =>
      _emails ??= _restController<EmailItem>(
        collection: 'emails',
        loadPage: viewerSettingsService.listEmails,
        idOf: (final EmailItem item) => item.email,
      );

  PaginationController<SSHKeyItem, SSHKeyItem> get sshKeys =>
      _sshKeys ??= _restController<SSHKeyItem>(
        collection: 'ssh-keys',
        loadPage: viewerSettingsService.listSSHKeys,
        idOf: (final SSHKeyItem item) => item.id.toString(),
      );

  PaginationController<GpgKeyItem, GpgKeyItem> get gpgKeys =>
      _gpgKeys ??= _restController<GpgKeyItem>(
        collection: 'gpg-keys',
        loadPage: viewerSettingsService.listGPGKeys,
        idOf: (final GpgKeyItem item) => item.id.toString(),
      );

  PaginationController<SSHSigningKeyItem, SSHSigningKeyItem>
  get sshSigningKeys => _sshSigningKeys ??= _restController<SSHSigningKeyItem>(
    collection: 'ssh-signing-keys',
    loadPage: viewerSettingsService.listSSHSigningKeys,
    idOf: (final SSHSigningKeyItem item) => item.id.toString(),
  );

  PaginationController<SimpleUser, SimpleUser> get blockedUsers =>
      _blockedUsers ??= _restController<SimpleUser>(
        collection: 'blocked-users',
        loadPage: viewerSettingsService.listBlockedUsers,
        idOf: (final SimpleUser item) => item.login,
      );

  PaginationController<UserOrgEdge, UserOrgEdge> get organizations =>
      _organizations ??= _cursorController<UserOrgEdge>(
        collection: 'organizations',
        loadPage:
            ({required final String? after, required final int first}) async {
              final PaginatedResult<UserOrgEdge?> result = await userInfoService
                  .getUserOrganizationsPage(login, after: after, first: first);
              return PaginatedResult<UserOrgEdge>(
                items: result.items.whereType<UserOrgEdge>().toList(
                  growable: false,
                ),
                hasNextPage: result.hasNextPage,
                endCursor: result.endCursor,
                totalCount: result.totalCount,
              );
            },
        idOf: (final UserOrgEdge item) => item.cursor,
      );

  PaginationController<UserRepoEdge, UserRepoEdge> get repositories =>
      _repositories ??= _cursorController<UserRepoEdge>(
        collection: 'repositories',
        loadPage:
            ({required final String? after, required final int first}) async {
              final UserRepositories result = await userInfoService
                  .getUserRepositories(login, first, after: after);
              return PaginatedResult<UserRepoEdge>(
                items:
                    result.edges?.whereType<UserRepoEdge>().toList(
                      growable: false,
                    ) ??
                    <UserRepoEdge>[],
                hasNextPage: result.pageInfo.hasNextPage,
                endCursor: result.pageInfo.endCursor,
              );
            },
        idOf: (final UserRepoEdge item) => item.cursor,
      );

  Future<void> addEmails(final List<String> emails) async {
    await viewerSettingsService.addEmails(emails);
    await _refreshAfterMutation('emails', _emails);
  }

  Future<void> deleteEmail(final String email) async {
    await viewerSettingsService.deleteEmails(<String>[email]);
    await _refreshAfterMutation('emails', _emails);
  }

  Future<void> setEmailVisibility({required final bool isPublic}) async {
    await viewerSettingsService.setEmailVisibility(
      isPublic ? 'public' : 'private',
    );
    await _refreshAfterMutation('emails', _emails);
  }

  Future<void> createSSHKey({
    required final String title,
    required final String key,
  }) async {
    await viewerSettingsService.createSSHKey(title: title, key: key);
    await _refreshAfterMutation('ssh-keys', _sshKeys);
  }

  Future<void> deleteSSHKey(final int id) async {
    await viewerSettingsService.deleteSSHKey(id);
    await _refreshAfterMutation('ssh-keys', _sshKeys);
  }

  Future<void> createGPGKey({
    required final String armoredPublicKey,
    final String? name,
  }) async {
    await viewerSettingsService.createGPGKey(
      armoredPublicKey: armoredPublicKey,
      name: name,
    );
    await _refreshAfterMutation('gpg-keys', _gpgKeys);
  }

  Future<void> deleteGPGKey(final int id) async {
    await viewerSettingsService.deleteGPGKey(id);
    await _refreshAfterMutation('gpg-keys', _gpgKeys);
  }

  Future<void> createSSHSigningKey({
    required final String title,
    required final String key,
  }) async {
    await viewerSettingsService.createSSHSigningKey(title: title, key: key);
    await _refreshAfterMutation('ssh-signing-keys', _sshSigningKeys);
  }

  Future<void> deleteSSHSigningKey(final int id) async {
    await viewerSettingsService.deleteSSHSigningKey(id);
    await _refreshAfterMutation('ssh-signing-keys', _sshSigningKeys);
  }

  Future<void> blockUser(final String username) async {
    await viewerSettingsService.blockUser(username);
    await _refreshAfterMutation('blocked-users', _blockedUsers);
  }

  Future<void> unblockUser(final String username) async {
    await viewerSettingsService.unblockUser(username);
    await _refreshAfterMutation('blocked-users', _blockedUsers);
  }

  PaginationController<T, T> _restController<T>({
    required final String collection,
    required final ViewerSettingsRestPageLoader<T> loadPage,
    required final String Function(T item) idOf,
  }) {
    _ensureActive();
    return PaginationController<T, T>(
      source: RuntimeForwardPageSource<T, ViewerSettingsRestPageKey>(
        runtime: runtime,
        firstPageKey: const ViewerSettingsRestPageKey(1),
        specFactory:
            ({
              required final ViewerSettingsRestPageKey pageKey,
              required final int pageSize,
            }) => viewerSettingsRestPageSpec<T>(
              scope: scope,
              collection: collection,
              pageKey: pageKey,
              pageSize: pageSize,
              loadPage: loadPage,
            ),
        refreshSelector: viewerSettingsCollectionSelector(
          scope: scope,
          collection: collection,
        ),
      ),
      idOf: idOf,
      pageSize: 30,
    );
  }

  PaginationController<T, T> _cursorController<T>({
    required final String collection,
    required final ViewerSettingsCursorPageLoader<T> loadPage,
    required final String Function(T item) idOf,
  }) {
    _ensureActive();
    return PaginationController<T, T>(
      source: RuntimeForwardPageSource<T, ViewerSettingsCursorPageKey>(
        runtime: runtime,
        firstPageKey: const ViewerSettingsCursorPageKey(null),
        specFactory:
            ({
              required final ViewerSettingsCursorPageKey pageKey,
              required final int pageSize,
            }) => viewerSettingsCursorPageSpec<T>(
              scope: scope,
              collection: collection,
              pageKey: pageKey,
              pageSize: pageSize,
              loadPage: loadPage,
            ),
        refreshSelector: viewerSettingsCollectionSelector(
          scope: scope,
          collection: collection,
        ),
      ),
      idOf: idOf,
    );
  }

  Future<void> _refreshAfterMutation<T>(
    final String collection,
    final PaginationController<T, T>? controller,
  ) async {
    if (controller != null) {
      await controller.refresh();
      return;
    }
    runtime.invalidate(
      viewerSettingsCollectionSelector(scope: scope, collection: collection),
    );
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('ViewerSettingsSession is disposed');
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _emails?.dispose();
    _sshKeys?.dispose();
    _gpgKeys?.dispose();
    _sshSigningKeys?.dispose();
    _blockedUsers?.dispose();
    _organizations?.dispose();
    _repositories?.dispose();
  }
}

final ProviderFamily<ViewerSettingsSession, ViewerSettingsSessionKey>
viewerSettingsSessionProvider = Provider.autoDispose
    .family<ViewerSettingsSession, ViewerSettingsSessionKey>((
      final Ref ref,
      final ViewerSettingsSessionKey key,
    ) {
      keepAliveFor(ref);
      final ViewerSettingsSession session = ViewerSettingsSession(
        runtime: ref.watch(resourceRuntimeProvider),
        scope: key.scope,
        login: key.login,
        viewerSettingsService: ref.watch(viewerSettingsServiceProvider),
        userInfoService: ref.watch(userInfoServiceProvider),
      );
      ref.onDispose(session.dispose);
      return session;
    });
