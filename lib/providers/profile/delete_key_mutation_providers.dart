/// Delete GPG/SSH/SSH signing key mutations. On success bump
/// [keysRefreshTriggerProvider].
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/keys_refresh_trigger_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DeleteGpgKeyKey = ({UserRef user, int keyId});

class DeleteGpgKeyMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DeleteGpgKeyMutationNotifier(this._key);

  final DeleteGpgKeyKey _key;

  UserRef get _userRef => _key.user;
  int get _keyId => _key.keyId;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> delete() => runMutation(() async {
        await ref.read(viewerSettingsServiceProvider).deleteGPGKey(_keyId);
        ref.read(keysRefreshTriggerProvider(_userRef)).value++;
      });
}

final deleteGpgKeyMutationProvider = NotifierProvider.autoDispose
    .family<DeleteGpgKeyMutationNotifier, MutationState<void>, DeleteGpgKeyKey>(
        DeleteGpgKeyMutationNotifier.new);

typedef DeleteSSHKeyKey = ({UserRef user, int keyId});

class DeleteSSHKeyMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DeleteSSHKeyMutationNotifier(this._key);

  final DeleteSSHKeyKey _key;

  UserRef get _userRef => _key.user;
  int get _keyId => _key.keyId;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> delete() => runMutation(() async {
        await ref.read(viewerSettingsServiceProvider).deleteSSHKey(_keyId);
        ref.read(keysRefreshTriggerProvider(_userRef)).value++;
      });
}

final deleteSSHKeyMutationProvider = NotifierProvider.family<
    DeleteSSHKeyMutationNotifier,
    MutationState<void>,
    DeleteSSHKeyKey>(DeleteSSHKeyMutationNotifier.new);

typedef DeleteSSHSigningKeyKey = ({UserRef user, int keyId});

class DeleteSSHSigningKeyMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DeleteSSHSigningKeyMutationNotifier(this._key);

  final DeleteSSHSigningKeyKey _key;

  UserRef get _userRef => _key.user;
  int get _keyId => _key.keyId;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> delete() => runMutation(() async {
        await ref.read(viewerSettingsServiceProvider).deleteSSHSigningKey(_keyId);
        ref.read(keysRefreshTriggerProvider(_userRef)).value++;
      });
}

final deleteSSHSigningKeyMutationProvider = NotifierProvider.autoDispose.family<
    DeleteSSHSigningKeyMutationNotifier,
    MutationState<void>,
    DeleteSSHSigningKeyKey>(DeleteSSHSigningKeyMutationNotifier.new);
