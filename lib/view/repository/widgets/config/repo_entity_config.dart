import 'package:diohub/common/misc/entity_header.dart';
import 'package:diohub/common/nav_center/models/entity_config.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub/common/popup/popup_sections_repo.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/view/repository/widgets/config/repo_metadata_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds [EntityConfig] for the repo screen with header, status flags, and metadata.
EntityConfig buildEntityConfigWithActions(
  BuildContext context,
  WidgetRef ref,
  RepoRef repoRef,
  RepoInfo repo,
  List<PopupMenuSection> actionSections,
  List<MetadataSectionData> metadataSections,
) {
  final ownerLogin = repo.owner.maybeWhen(
    user: (final u) => u.login,
    organization: (final o) => o.login,
    orElse: () => null,
  );
  final ownerAvatarUrl = repo.owner.maybeWhen(
    user: (final u) => u.avatarUrl.toString(),
    organization: (final o) => o.avatarUrl.toString(),
    orElse: () => null,
  );
  return EntityConfig(
    leading: null,
    title: EntityHeader(
      avatarUrl: ownerAvatarUrl,
      title: repo.name,
      subtitle: ownerLogin,
      avatarSize: 24,
      onTap: ownerLogin != null
          ? () => UserRef(login: ownerLogin).navigate(context, ref)
          : null,
    ),
    subtitle: null,
    statusIndicators: StatusFlagRow(
      flags: repo.statusFlags,
    ),
    metadataSections: metadataSections,
    actionSections: actionSections,
  );
}

/// Status flags for repository (private, archived, fork, etc.).
List<StatusFlag> repositoryStatusFlags(RepoInfo repo) => <StatusFlag>[
      if (repo.isPrivate) StatusFlag.private,
      if (repo.isArchived) StatusFlag.archived,
      if (repo.isDisabled) StatusFlag.disabled,
      if (repo.isFork) StatusFlag.fork,
      if (repo.isMirror) StatusFlag.mirror,
      if (repo.isTemplate) StatusFlag.template,
    ];

extension RepoInfoStatusFlags on RepoInfo {
  List<StatusFlag> get statusFlags => repositoryStatusFlags(this);
}

extension RepoInfoEntityConfig on RepoInfo {
  EntityConfig entityConfig(BuildContext context, WidgetRef ref) {
    final actions = popupSections(context, ref);
    final metadata = metadataSections(context, ref);
    return buildEntityConfigWithActions(
      context,
      ref,
      toRef,
      this,
      actions,
      metadata,
    );
  }
}
