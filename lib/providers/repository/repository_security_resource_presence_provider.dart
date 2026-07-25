import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/notifier.dart';

final NotifierProviderFamily<
  RepositorySecurityResourcePresenceNotifier,
  ResourcePresence,
  RepoRef
>
repositorySecurityResourcePresenceProvider =
    NotifierProvider.family<
      RepositorySecurityResourcePresenceNotifier,
      ResourcePresence,
      RepoRef
    >(RepositorySecurityResourcePresenceNotifier.new);

/// Page-session visibility for resources owned by the Repository Security Tab.
class RepositorySecurityResourcePresenceNotifier
    extends Notifier<ResourcePresence> {
  RepositorySecurityResourcePresenceNotifier(final RepoRef _);

  @override
  ResourcePresence build() => ResourcePresence.visible;

  void setPresence(final ResourcePresence presence) {
    if (state != presence) {
      state = presence;
    }
  }
}
