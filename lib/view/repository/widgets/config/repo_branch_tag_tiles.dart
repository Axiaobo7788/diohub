import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/common/misc/ref_list_item.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/permission_utils.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

// TODO(phase-11): Move to premium - admin mutation
// Future<void> confirmDeleteRef(...) async { ... }

// TODO(phase-11): Move to premium - admin mutation
// String? validateBranchName(String value) { ... }

// TODO(phase-11): Move to premium - admin mutation
// Future<void> showRenameBranchDialog(...) async { ... }
// class _RenameBranchDialog extends ConsumerStatefulWidget { ... }
// class _RenameBranchDialogState extends ConsumerState<_RenameBranchDialog> { ... }

Widget buildBranchTile(
  BuildContext context,
  BranchEdge edge,
  RepoRef repoRef,
  RepositoryPermission? permission,
) {
  final spacing = context.spacing;
  final theme = Theme.of(context);
  final node = edge.node;
  if (node == null) return const SizedBox.shrink();
  final name = node.name;

  // Extract rich data from the GQL commit target.
  DateTime? committedDate;
  String? messageHeadline;
  String? authorAvatarUrl;
  String? authorLogin;
  String? ciState;
  bool? signatureVerified;
  node.target?.maybeWhen(
    commit: (c) {
      committedDate = c.committedDate;
      messageHeadline = c.messageHeadline;
      ciState = c.statusCheckRollup?.state.name;
      signatureVerified = c.signature?.isValid;
      final a = c.author;
      if (a != null) {
        authorAvatarUrl = a.avatarUrl.toString();
        authorLogin = a.user?.login;
      }
    },
    orElse: () {},
  );
  final openPrCount = node.associatedPullRequests.totalCount;

  final branchData = RefListItemBranchData(
    name: name,
    committedDate: committedDate,
    messageHeadline: messageHeadline,
    authorAvatarUrl: authorAvatarUrl,
    authorLogin: authorLogin,
    hasProtection: node.branchProtectionRule != null,
    ciState: ciState,
    openPullRequestCount: openPrCount,
    signatureVerified: signatureVerified,
  );

  final bool canWrite = isAtLeast(permission, RepositoryPermission.WRITE);

  return Consumer(
    builder: (context, ref, _) => Padding(
      padding: spacing.screenPadding,
      child: RefListItem(
        variant: RefListItemVariant.branch,
        branchData: branchData,
        trailing: ref
            .read(premiumActionsProvider)
            .branchAdminMenuBuilder(
              context: context,
              ref: ref,
              repoRef: repoRef,
              branchNode: node,
              permission: permission,
            ),
        onTap: () => RepoRef(
          owner: repoRef.owner,
          name: repoRef.name,
          location: RepoLocationTree(branch: name),
        ).navigate(context, ref),
      ),
    ),
  );
}

Widget buildTagTile(
  BuildContext context,
  WidgetRef ref,
  TagEdge edge,
  RepoRef repoRef,
  RepositoryPermission? permission,
) {
  final spacing = context.spacing;
  final theme = Theme.of(context);
  final node = edge.node;
  if (node == null) return const SizedBox.shrink();
  final name = node.name;
  final target = node.target;

  // Extract rich data from the GQL tag/commit target.
  bool isAnnotated = false;
  String? message;
  String? taggerName;
  String? taggerAvatarUrl;
  DateTime? committedDate;
  if (target != null) {
    target.maybeWhen(
      tag: (t) {
        isAnnotated = t.message != null && t.message!.isNotEmpty;
        message = t.message;
        taggerName = t.tagger?.name;
        taggerAvatarUrl = t.tagger?.avatarUrl.toString();
        committedDate =
            t.tagger?.date ??
            t.target.maybeWhen(
              commit: (c) => c.committedDate,
              orElse: () => null,
            );
      },
      commit: (c) {
        committedDate = c.committedDate;
      },
      orElse: () {},
    );
  }

  final tagData = RefListItemTagData(
    name: name,
    isAnnotated: isAnnotated,
    message: message,
    taggerName: taggerName,
    taggerAvatarUrl: taggerAvatarUrl,
    committedDate: committedDate,
  );

  return Padding(
    padding: spacing.screenPadding,
    child: RefListItem(
      variant: RefListItemVariant.tag,
      tagData: tagData,
      trailing: ref
          .read(premiumActionsProvider)
          .tagDeleteButtonBuilder(
            context: context,
            ref: ref,
            repoRef: repoRef,
            tagNode: node,
            permission: permission,
          ),
      onTap: () => RepoRef(
        owner: repoRef.owner,
        name: repoRef.name,
        location: RepoLocationTree(branch: name),
      ).navigate(context, ref),
    ),
  );
}
