import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/surface_style.dart' show RadiusSize;
import 'package:diohub/utils/hex_color.dart';
// TODO(phase-10): Premium editor sheets will be injected via callbacks
// import '../label_editor_sheet.dart';
// import '../milestone_editor_sheet.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

Widget buildLabelTile(
  BuildContext context,
  WidgetRef ref,
  RepoRef repoRef,
  RepoInfo repo,
  LabelNode? node,
) {
  if (node == null) return const SizedBox.shrink();
  final spacing = context.spacing;
  final theme = Theme.of(context);
  final canAdminister = repo.viewerCanAdminister;

  Future<void> onTap() async {
    // TODO(phase-10): Premium edit callback will be injected
    // if (!canAdminister) return;
    // await showLabelEditorSheet(...);
  }

  Future<void> onLongPress() async {
    // TODO(phase-10): Premium delete callback will be injected
    // if (!canAdminister) return;
    // final confirmed = await confirmDeleteLabel(context, node.name);
    // if (!confirmed) return;
    // await ref.read(deleteLabelMutationProvider(node.id).notifier).delete(repoRef: repoRef);
  }

  final content = Padding(
    padding: spacing.screenPadding,
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: tryParseHexColor(node.color, fallback: Colors.grey)!,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        spacing.itemGap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (node.description != null && node.description!.isNotEmpty)
                Text(
                  node.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (canAdminister)
          ref
                  .read(premiumActionsProvider)
                  .labelAdminMenuBuilder(
                    context: context,
                    ref: ref,
                    repoRef: repoRef,
                    repo: repo,
                    labelNode: node,
                  ) ??
              const SizedBox.shrink(),
      ],
    ),
  );

  return content;
}

Future<bool> confirmDeleteLabel(BuildContext context, String labelName) async {
  return await showConfirmAction(
        context,
        title: 'Delete Label',
        explanation:
            'Delete "$labelName"? This will remove it from all issues and PRs.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ) ??
      false;
}

Widget buildMilestoneTile(
  BuildContext context,
  WidgetRef ref,
  RepoRef repoRef,
  MilestoneEdge edge,
  bool canAdminister,
) {
  final node = edge.node;
  if (node == null) return const SizedBox.shrink();
  final spacing = context.spacing;
  final theme = Theme.of(context);
  final isOpen = node.state == MilestoneState.OPEN;
  return Padding(
    padding: spacing.screenPadding,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (node.description != null && node.description!.isNotEmpty)
            Text(
              node.description!,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (node.dueOn != null)
            Text('Due: ${node.dueOn}', style: theme.textTheme.bodySmall),
          TintedChip(
            icon: isOpen ? Icons.flag_outlined : Icons.check_circle_outline,
            color: isOpen
                ? theme.colorScheme.primary
                : theme.colorScheme.tertiary,
            label: node.state.name,
            size: RadiusSize.small,
          ),
        ],
      ),
      trailing: canAdminister
          ? ref
                .read(premiumActionsProvider)
                .milestoneAdminMenuBuilder(
                  context: context,
                  ref: ref,
                  repoRef: repoRef,
                  milestoneNode: node,
                  canAdminister: canAdminister,
                )
          : null,
      onTap: null,
    ),
  );
}
