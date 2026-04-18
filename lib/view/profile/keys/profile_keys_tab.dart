import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/gpg_key_item.dart';
import 'package:diohub_models/models/users/ssh_key_item.dart';
import 'package:diohub_models/models/users/ssh_signing_key_item.dart';
import 'package:diohub/providers/users/keys_refresh_trigger_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/profile/widgets/key_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _pageSize = 30;

/// Returns a [TabBody] for the viewer's SSH keys list (Keys position).
/// Uses [SliverListBody.page] with REST page/per_page.
TabBody createKeysBody(UserRef userRef) {
  return DelegatingTabBody(
    createBody: (ref) => SliverListBody<SSHKeyItem>.page(
      pageSize: _pageSize,
      refreshTrigger: ref.read(keysRefreshTriggerProvider(userRef)),
      fetch: ({required int page, required int perPage}) async {
        final result = await ref
            .read(viewerSettingsServiceProvider)
            .listSSHKeys(page: page, perPage: perPage);
        return result.items;
      },
      idOf: (SSHKeyItem item) => item.id.toString(),
      itemBuilder: (BuildContext context, SSHKeyItem item) => Consumer(
        builder: (_, WidgetRef r, __) =>
            buildSSHKeyCard(context, r, userRef, item),
      ),
    ),
  );
}

/// Returns a [TabBody] for the viewer's GPG keys list (Keys position).
TabBody createGpgKeysBody(UserRef userRef) {
  return DelegatingTabBody(
    createBody: (ref) => SliverListBody<GpgKeyItem>.page(
      pageSize: _pageSize,
      refreshTrigger: ref.read(keysRefreshTriggerProvider(userRef)),
      fetch: ({required int page, required int perPage}) async {
        final result = await ref
            .read(viewerSettingsServiceProvider)
            .listGPGKeys(page: page, perPage: perPage);
        return result.items;
      },
      idOf: (GpgKeyItem item) => item.id.toString(),
      itemBuilder: (BuildContext context, GpgKeyItem item) => Consumer(
        builder: (_, WidgetRef r, __) =>
            buildGpgKeyCard(context, r, userRef, item),
      ),
    ),
  );
}

/// Returns a [TabBody] for the viewer's SSH signing keys list (Keys position).
TabBody createSSHSigningKeysBody(UserRef userRef) {
  return DelegatingTabBody(
    createBody: (ref) => SliverListBody<SSHSigningKeyItem>.page(
      pageSize: _pageSize,
      refreshTrigger: ref.read(keysRefreshTriggerProvider(userRef)),
      fetch: ({required int page, required int perPage}) async {
        final result =
            await ref.read(viewerSettingsServiceProvider).listSSHSigningKeys(
                  page: page,
                  perPage: perPage,
                );
        return result.items;
      },
      idOf: (SSHSigningKeyItem item) => item.id.toString(),
      itemBuilder: (BuildContext context, SSHSigningKeyItem item) => Consumer(
        builder: (_, WidgetRef r, __) =>
            buildSSHSigningKeyCard(context, r, userRef, item),
      ),
    ),
  );
}

const int _publicKeysPageSize = 20;

/// Converts GQL PublicKey node to [SSHKeyItem] for [buildPublicSSHKeyCard].
SSHKeyItem publicKeyNodeToSSHKeyItem(
  UserPublicKeyNode? node,
) {
  if (node == null) {
    return SSHKeyItem(
      id: 0,
      title: '',
      key: '',
      fingerprint: '',
      createdAt: DateTime.now(),
      lastUsedAt: null,
      readOnly: false,
    );
  }
  return SSHKeyItem(
    id: int.tryParse(node.id) ?? 0,
    title: node.fingerprint,
    key: node.key,
    fingerprint: node.fingerprint,
    createdAt: node.createdAt ?? DateTime.now(),
    lastUsedAt: node.accessedAt,
    readOnly: node.isReadOnly ?? false,
  );
}

/// Returns a [TabBody] for another user's public SSH keys (GQL [User.publicKeys]).
/// Used in the Public Keys position when viewing a non-viewer profile.
TabBody createPublicKeysBody(WidgetRef ref, UserRef userRef) {
  return SliverListBody<UserPublicKeyNode?>(
    getCursor: (item) => item?.id,
    pageSize: _publicKeysPageSize,
    fetcher: ({
      String? after,
      int first = _publicKeysPageSize,
      bool refresh = false,
    }) async {
      return ref.read(userInfoServiceProvider).getUserPublicKeys(
            userRef.login,
            after: after,
            first: first,
            refresh: refresh,
          );
    },
    itemBuilder: (BuildContext context,
        UserPublicKeyNode? item) {
      return buildPublicSSHKeyCard(context, publicKeyNodeToSSHKeyItem(item));
    },
  );
}
