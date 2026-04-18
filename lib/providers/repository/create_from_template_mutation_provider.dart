/// Create repository from template (GQL cloneTemplateRepository).
/// Single notifier (not keyed by repo); use for "Use this template" flow.
library;

import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

class CreateFromTemplateMutationNotifier
    extends Notifier<MutationState<CloneTemplateResult?>>
    with MutationNotifierMixin<CloneTemplateResult?> {
  @override
  MutationState<CloneTemplateResult?> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<CloneTemplateResult?> create({
    required String templateRepoId,
    required String name,
    required String ownerId,
    required RepositoryVisibility visibility,
    String? description,
    bool includeAllBranches = false,
  }) => runMutation(() async {
      final templateRef = RepoRef(
        owner: '.',
        name: '.',
        nodeId: templateRepoId,
      );
      return await templateRef.services(ref.read(apiClientProvider)).cloneTemplateRepository(
        name: name,
        ownerId: ownerId,
        visibility: visibility,
        description: description,
        includeAllBranches: includeAllBranches,
      );
    });
}

final createFromTemplateMutationProvider = NotifierProvider<
    CreateFromTemplateMutationNotifier,
    MutationState<CloneTemplateResult?>>(
  CreateFromTemplateMutationNotifier.new,
);
