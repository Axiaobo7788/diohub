import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/context_dock/content/branch_pill_content.dart';
import 'package:diohub/common/context_dock/descriptors/basic_pill_descriptor.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/dock/branch_pill_state_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/repository/code/widgets/create_branch_sheet.dart';

/// Descriptor for branch/tag ref selection pill with search and type toggle.
/// Active: search field + overlay list with [Branches | Tags] companions.
/// Hint: branch/tag name when non-default.
@immutable
final class BranchPillDescriptor extends DockPillDescriptor {
  const BranchPillDescriptor({
    required this.repo,
    required this.defaultBranch,
    this.repositoryId,
  }) : super(icon: Octicons.git_branch);

  final RepoRef repo;
  final String defaultBranch;

  /// When set, a "New branch" companion is shown to open [CreateBranchSheet].
  final String? repositoryId;

  @override
  List<Object?> get props => [
    ...super.props,
    repo,
    defaultBranch,
    repositoryId,
  ];

  @override
  DockPillKind get kind => DockPillKind.activate;

  @override
  List<DockPillDescriptor> get companions {
    final base = [
      BasicPillDescriptor(
        icon: Octicons.git_branch,
        label: 'Branches',
        onTapAction: (ref) {
          ref
              .read(branchPillStateProvider(this).notifier)
              .setRefKind(RefKind.branch);
        },
      ),
      BasicPillDescriptor(
        icon: Octicons.tag,
        label: 'Tags',
        onTapAction: (ref) {
          ref
              .read(branchPillStateProvider(this).notifier)
              .setRefKind(RefKind.tag);
        },
      ),
    ];

    if (repositoryId != null) {
      base.add(
        BasicPillDescriptor(
          icon: Octicons.plus,
          label: 'New branch',
          onTapAction: (ref) {
            // Note: This requires context. For now, we'll defer to the widget layer to handle.
            // This is a limitation of the current descriptor pattern.
          },
        ),
      );
    }

    return base;
  }

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => BranchPillContent(
        repo: repo,
        descriptor: this,
        defaultBranch: defaultBranch,
      ),
      PillPhase.hint => BranchPillHint(
        repo: repo,
        defaultBranch: defaultBranch,
      ),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) {
    if (phase != PillPhase.active) return null;
    return BranchPillOverlay(
      repo: repo,
      descriptor: this,
      defaultBranch: defaultBranch,
    );
  }
}
