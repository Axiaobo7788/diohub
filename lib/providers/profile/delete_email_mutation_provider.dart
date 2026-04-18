/// Mutation to delete an email. Call [onSuccess] to patch the list (e.g. applyPatch).
/// List is paginated in the sheet via [PaginationController]; no list provider.
library;

import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for the delete mutation family: (userRef, email).
typedef DeleteEmailKey = ({UserRef user, String email});

class DeleteEmailMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  DeleteEmailMutationNotifier(this._key);

  final DeleteEmailKey _key;

  String get _email => _key.email;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  /// [onSuccess] Called after delete (e.g. to apply PatchDeleted). The list
  /// is driven by [PaginationController] in the sheet; no list provider.
  Future<void> delete({void Function()? onSuccess}) => runMutation(() async {
        await ref.read(viewerSettingsServiceProvider).deleteEmails([_email]);
        onSuccess?.call();
      });
}

final deleteEmailMutationProvider = NotifierProvider.family<
    DeleteEmailMutationNotifier,
    MutationState<void>,
    DeleteEmailKey>(DeleteEmailMutationNotifier.new);

/// Mutation to add an email. Call [onSuccess] to refresh the list (e.g. PaginationController refresh).
class AddEmailMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  AddEmailMutationNotifier(this._userRef);

  final UserRef _userRef;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> add(final String email, {void Function()? onSuccess}) async {
    await runMutation(() async {
      await ref.read(viewerSettingsServiceProvider).addEmails([email]);
      onSuccess?.call();
    });
  }
}

final addEmailMutationProvider = NotifierProvider.family<
    AddEmailMutationNotifier,
    MutationState<void>,
    UserRef>(AddEmailMutationNotifier.new);
