import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/context_dock/content/commit_filter_pill_content.dart';
import 'package:diohub/common/context_dock/descriptors/basic_pill_descriptor.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/commits/commit_providers.dart';

/// Descriptor for commit filter pill (author/path).
/// Active: TextField for author or path filter with mode toggle companions.
/// Hint: displays active filter value.
@immutable
final class CommitFilterPillDescriptor extends DockPillDescriptor {
  const CommitFilterPillDescriptor({required this.repo})
    : super(icon: Icons.filter_list_rounded);

  final RepoRef repo;

  @override
  List<Object?> get props => [...super.props, repo];

  @override
  DockPillKind get kind => DockPillKind.activate;

  @override
  List<DockPillDescriptor> get companions => [
    BasicPillDescriptor(
      icon: Octicons.person,
      label: 'Author',
      onTapAction: (ref) {
        ref.read(commitFilterPillModeProvider(this).notifier).state =
            CommitFilterMode.author;
      },
    ),
    BasicPillDescriptor(
      icon: Octicons.file_code,
      label: 'Path',
      onTapAction: (ref) {
        ref.read(commitFilterPillModeProvider(this).notifier).state =
            CommitFilterMode.path;
      },
    ),
  ];

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    return switch (phase) {
      PillPhase.active => CommitFilterPillContent(repo: repo, descriptor: this),
      PillPhase.hint => CommitFilterPillHint(repo: repo),
      PillPhase.idle => null,
    };
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) =>
      null;
}
