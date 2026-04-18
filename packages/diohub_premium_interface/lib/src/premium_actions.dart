import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_models/models/entity_ref.dart' show RepoRef;
import 'package:diohub_models/models/download/download_item.dart'
    show DownloadItem;
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart'
    show RepoInfo, LabelNode, MilestoneNode, BranchNode, TagNode;
import 'package:diohub_graphql/schema_typedefs.dart' show RepositoryPermission;

class PremiumActionDefinition {
  const PremiumActionDefinition({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

abstract class PremiumActions {
  const PremiumActions();

  List<PremiumActionDefinition> issueActions(BuildContext context) => const [];

  List<PremiumActionDefinition> pullRequestActions(BuildContext context) =>
      const [];

  List<PremiumActionDefinition> commentActions(BuildContext context) =>
      const [];

  List<PremiumActionDefinition> repoActions(BuildContext context) => const [];

  List<PremiumActionDefinition> codeActions(BuildContext context) => const [];

  List<PremiumActionDefinition> entityPopupActions(
    BuildContext context,
    WidgetRef ref,
    String entityType,
  ) => const [];

  Future<void> enqueueDownload(
    BuildContext context,
    WidgetRef ref,
    DownloadItem target,
  ) async {}

  List<dynamic> downloadPopupItems(BuildContext context, WidgetRef ref) =>
      const [];

  /// Build admin menu for label tiles (edit/delete). Returns null in OSS.
  Widget? labelAdminMenuBuilder({
    required BuildContext context,
    required WidgetRef ref,
    required RepoRef repoRef,
    required RepoInfo repo,
    required LabelNode labelNode,
  }) => null;

  /// Build admin menu for milestone tiles (edit/toggle/delete). Returns null in OSS.
  Widget? milestoneAdminMenuBuilder({
    required BuildContext context,
    required WidgetRef ref,
    required RepoRef repoRef,
    required MilestoneNode milestoneNode,
    required bool canAdminister,
  }) => null;

  /// Build admin menu for branch tiles (rename/delete). Returns null in OSS.
  Widget? branchAdminMenuBuilder({
    required BuildContext context,
    required WidgetRef ref,
    required RepoRef repoRef,
    required BranchNode branchNode,
    required RepositoryPermission? permission,
  }) => null;

  /// Build delete button for tag tiles. Returns null in OSS.
  Widget? tagDeleteButtonBuilder({
    required BuildContext context,
    required WidgetRef ref,
    required RepoRef repoRef,
    required TagNode tagNode,
    required RepositoryPermission? permission,
  }) => null;
}

class DefaultPremiumActions extends PremiumActions {
  const DefaultPremiumActions();
}

final premiumActionsProvider = Provider<PremiumActions>((ref) {
  return const DefaultPremiumActions();
});
