import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/widgets/tinted_icon.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart'
    show LabelFragment;
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart'
    show Actor;
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class BasicEventCard extends StatelessWidget {
  const BasicEventCard({
    required this.user,
    required this.content,
    required this.date,
    required this.leading,
    required this.headerText,
    this.iconColor,
    super.key,
  });
  final Actor? user;
  final IconData leading;
  final Color? iconColor;
  final DateTime date;
  final Widget content;
  final List<TextSpan> headerText;
  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveIconColor =
        iconColor ?? context.colorScheme.onSurfaceVariant;

    final Widget headerRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Icon in colored container like BaseEventCard
        TintedIcon(
          icon: leading,
          color: effectiveIconColor,
          iconSize: 12,
          boxSize: 22,
        ),
        context.spacing.compactGap,
        // Actor avatar
        if (user?.avatarUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: user!.avatarUrl.toString(),
              width: 18,
              height: 18,
              memCacheWidth: (18 * MediaQuery.of(context).devicePixelRatio)
                  .round()
                  .clamp(1, 512),
              memCacheHeight: (18 * MediaQuery.of(context).devicePixelRatio)
                  .round()
                  .clamp(1, 512),
              fit: BoxFit.cover,
              placeholder: (final BuildContext context, final String url) =>
                  const ShimmerScope(
                child: ShimmerBone.avatar(size: 18),
              ),
              errorWidget: (final BuildContext context, final String url,
                      final Object error) =>
                  Container(
                width: 18,
                height: 18,
                color: context.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 10,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (user?.avatarUrl != null) context.spacing.tightGap,
        // Actor name and action text
        Flexible(
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.onSurface.secondary,
              ),
              children: <TextSpan>[
                if (user?.login != null)
                  TextSpan(
                    text: user!.login,
                  ),
                if (user?.login != null) const TextSpan(text: ' '),
                ...headerText,
              ],
            ),
          ),
        ),
      ],
    );

    return NestedCardWithHeader(
      header: headerRow,
      trailing: Text(
        DateTime.parse(date.toString()).toRelativeDate(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant.secondary,
        ),
      ),
      headerPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      childPadding: EdgeInsets.all(context.spacing.itemSpacing),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!.asMuted(),
        child: content,
      ),
    );
  }
}

class BasicEventTextCard extends StatelessWidget {
  const BasicEventTextCard({
    required this.user,
    required this.textContent,
    required this.date,
    required this.leading,
    this.footer,
    this.iconColor,
    super.key,
  });
  final Actor? user;
  final IconData leading;
  final Color? iconColor;
  final DateTime date;
  final Widget? footer;
  final String textContent;
  @override
  Widget build(final BuildContext context) => BasicEventCard(
        iconColor: iconColor,
        headerText: <TextSpan>[
          TextSpan(text: textContent),
        ],
        content: footer != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: footer,
              )
            : const SizedBox.shrink(),
        date: date,
        user: user,
        leading: leading,
      );
}

class BasicEventAssignedCard extends StatelessWidget {
  const BasicEventAssignedCard({
    required this.actor,
    required this.assignee,
    required this.createdAt,
    required this.isAssigned,
    super.key,
  });
  final Actor? actor;
  final Actor? assignee;
  final DateTime createdAt;
  final bool isAssigned;
  @override
  Widget build(final BuildContext context) => BasicEventCard(
        headerText: <TextSpan>[
          TextSpan(text: isAssigned ? 'Assigned' : 'Unassigned'),
          if (actor?.login != null &&
              actor?.login != assignee?.login) ...<TextSpan>[
            const TextSpan(text: ' '),
            TextSpan(
              text: assignee?.login ?? 'themselves',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ] else
            const TextSpan(text: ' themselves'),
          TextSpan(text: ' ${isAssigned ? 'to' : 'from'} the issue.'),
        ],
        content: const SizedBox.shrink(),
        date: createdAt,
        user: actor,
        leading: MdiIcons.account,
      );
}

class BasicEventLabeledCard extends StatelessWidget {
  const BasicEventLabeledCard({
    required this.actor,
    required this.content,
    required this.added,
    required this.date,
    // this.iconColor,
    super.key,
  });
  final Actor? actor;
  final DateTime date;
  final LabelFragment content;
  final bool added;
  @override
  Widget build(final BuildContext context) => BasicEventCard(
        headerText: <TextSpan>[
          TextSpan(text: '${added ? 'Added' : 'Removed'} the '),
          TextSpan(text: 'label ${added ? 'to' : 'from'} this.'),
        ],
        content: IssueLabel.gql(content),
        user: actor,
        date: date,
        leading: added ? Icons.label_rounded : Icons.label_off_rounded,
      );
}
