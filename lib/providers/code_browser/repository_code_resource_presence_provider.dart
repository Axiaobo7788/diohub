import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/notifier.dart';

final NotifierProviderFamily<
  RepositoryCodeResourcePresenceNotifier,
  ResourcePresence,
  RepoRef
>
repositoryCodeResourcePresenceProvider =
    NotifierProvider.family<
      RepositoryCodeResourcePresenceNotifier,
      ResourcePresence,
      RepoRef
    >(RepositoryCodeResourcePresenceNotifier.new);

/// Page-session visibility shared by Code resources without coupling the
/// ResourceRuntime to Flutter widgets or lifecycle callbacks.
class RepositoryCodeResourcePresenceNotifier
    extends Notifier<ResourcePresence> {
  RepositoryCodeResourcePresenceNotifier(final RepoRef _);

  @override
  ResourcePresence build() => ResourcePresence.visible;

  void setPresence(final ResourcePresence presence) {
    if (state != presence) {
      state = presence;
    }
  }
}
