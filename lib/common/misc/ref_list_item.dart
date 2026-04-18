import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Variant of ref shown in the unified branch/tag/release selector.
enum RefListItemVariant { branch, tag, release }

/// Data for a branch row in [RefListItem].
class RefListItemBranchData {
  const RefListItemBranchData({
    required this.name,
    this.isDefault = false,
    this.isCurrent = false,
    this.isDeleted = false,
    this.committedDate,
    this.messageHeadline,
    this.authorAvatarUrl,
    this.authorLogin,
    this.hasProtection = false,
    this.ciState,
    this.openPullRequestCount,
    this.signatureVerified,
    this.aheadBy,
    this.behindBy,
  });

  final String name;
  final bool isDefault;
  final bool isCurrent;

  /// When true, name is rendered with strikethrough and icon uses red tint (e.g. deleted refs).
  final bool isDeleted;
  final DateTime? committedDate;
  final String? messageHeadline;
  final String? authorAvatarUrl;
  final String? authorLogin;
  final bool hasProtection;

  /// Check suite / status rollup state: PENDING, SUCCESS, ERROR, FAILURE.
  final String? ciState;
  final int? openPullRequestCount;
  final bool? signatureVerified;
  final int? aheadBy;
  final int? behindBy;
}

/// Data for a tag row in [RefListItem].
class RefListItemTagData {
  const RefListItemTagData({
    required this.name,
    this.isAnnotated = false,
    this.message,
    this.taggerName,
    this.taggerAvatarUrl,
    this.committedDate,
    this.linkedReleaseName,
    this.isLatestRelease,
  });

  final String name;
  final bool isAnnotated;
  final String? message;
  final String? taggerName;
  final String? taggerAvatarUrl;
  final DateTime? committedDate;
  final String? linkedReleaseName;
  final bool? isLatestRelease;
}

/// Data for a release row in [RefListItem].
class RefListItemReleaseData {
  const RefListItemReleaseData({
    required this.name,
    required this.tagName,
    this.isDraft = false,
    this.isLatest = false,
    this.isPrerelease = false,
    this.publishedAt,
    this.authorLogin,
    this.authorAvatarUrl,
    this.shortDescriptionHtml,
    this.assetCount = 0,
    this.reactionCount,
    this.url,
  });

  final String name;
  final String tagName;
  final bool isDraft;
  final bool isLatest;
  final bool isPrerelease;
  final DateTime? publishedAt;
  final String? authorLogin;
  final String? authorAvatarUrl;
  final String? shortDescriptionHtml;
  final int assetCount;
  final int? reactionCount;
  final Uri? url;
}

/// Unified list item for branch, tag, or release in the ref selector.
class RefListItem extends StatelessWidget {
  const RefListItem({
    required this.variant,
    this.branchData,
    this.tagData,
    this.releaseData,
    this.onTap,
    this.isHighlighted = false,
    this.trailing,
    super.key,
  }) : assert(
          (variant == RefListItemVariant.branch && branchData != null) ||
              (variant == RefListItemVariant.tag && tagData != null) ||
              (variant == RefListItemVariant.release && releaseData != null),
          'Data must match variant',
        );

  final RefListItemVariant variant;
  final RefListItemBranchData? branchData;
  final RefListItemTagData? tagData;
  final RefListItemReleaseData? releaseData;
  final VoidCallback? onTap;
  final bool isHighlighted;

  /// Optional trailing widget (e.g. popup menu) rendered at the end of the row.
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final bool isCurrent = variant == RefListItemVariant.branch &&
        (branchData?.isCurrent ?? false);
    final Color? cardColor = isHighlighted || isCurrent
        ? colors.primary.withValues(alpha: 0.15)
        : null;

    return Material(
      color: cardColor ?? colors.surface,
      borderRadius: context.radius(RadiusSize.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radius(RadiusSize.medium),
        child: Padding(
          padding: context.spacing.pagePadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: switch (variant) {
                  RefListItemVariant.branch =>
                    _buildBranchContent(context, branchData!),
                  RefListItemVariant.tag => _buildTagContent(context, tagData!),
                  RefListItemVariant.release =>
                    _buildReleaseContent(context, releaseData!),
                },
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchContent(
    final BuildContext context,
    final RefListItemBranchData b,
  ) {
    final ColorScheme colors = context.colorScheme;
    final Color iconColor = b.isDeleted ? Colors.red : colors.primary;
    final List<Widget> leading = <Widget>[
      Icon(Octicons.git_branch, size: 20, color: iconColor),
      context.spacing.itemGap,
      Expanded(
        child: Opacity(
          opacity: b.isDeleted ? 0.85 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      b.name,
                      style: TextStyle(
                        fontWeight:
                            b.isCurrent ? FontWeight.bold : FontWeight.w500,
                        decoration:
                            b.isDeleted ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (b.isDefault) ...<Widget>[
                    context.spacing.itemGap,
                    Text(
                      'Default',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                  if (b.hasProtection) ...<Widget>[
                    context.spacing.tightGap,
                    Icon(
                      Octicons.lock,
                      size: 14,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ],
                  if (b.ciState != null) ...<Widget>[
                    context.spacing.tightGap,
                    _ciStatusDot(context, b.ciState!),
                  ],
                  if (b.signatureVerified == true) ...<Widget>[
                    context.spacing.tightGap,
                    Icon(
                      Octicons.verified,
                      size: 14,
                      color: context.colorScheme.primary,
                    ),
                  ],
                ],
              ),
              if (b.messageHeadline != null ||
                  b.committedDate != null ||
                  b.authorAvatarUrl != null) ...<Widget>[
                context.spacing.tightGap,
                Row(
                  children: <Widget>[
                    if (b.authorAvatarUrl != null)
                      CircleAvatar(
                        radius: 8,
                        backgroundImage: CachedNetworkImageProvider(
                          b.authorAvatarUrl!,
                        ),
                      ),
                    if (b.authorAvatarUrl != null) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.messageHeadline ??
                            (b.committedDate != null
                                ? b.committedDate!.toRelativeDate(shorten: true)
                                : ''),
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (b.aheadBy != null &&
                  b.behindBy != null &&
                  (b.aheadBy! > 0 || b.behindBy! > 0)) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  '↑${b.aheadBy} ↓${b.behindBy}',
                  style: context.textTheme.bodySmall,
                ),
              ],
              if (b.openPullRequestCount != null && b.openPullRequestCount! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${b.openPullRequestCount} open PR${b.openPullRequestCount == 1 ? '' : 's'}',
                    style: context.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: leading,
    );
  }

  static Widget _ciStatusDot(final BuildContext context, final String state) {
    Color color;
    switch (state) {
      case 'SUCCESS':
        color = const Color(0xFF2DA160);
        break;
      case 'ERROR':
      case 'FAILURE':
        color = const Color(0xFFCF222E);
        break;
      default:
        color = context.colorScheme.outline;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTagContent(
    final BuildContext context,
    final RefListItemTagData t,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Octicons.tag, size: 20, color: context.colorScheme.secondary),
        context.spacing.itemGap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      t.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (t.isAnnotated) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      'Annotated',
                      style: context.textTheme.bodySmall,
                    ),
                  ] else ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      'Lightweight',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                  if (t.linkedReleaseName != null) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      t.linkedReleaseName!,
                      style: context.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (t.isLatestRelease == true)
                      Text(
                        ' • Latest',
                        style: context.textTheme.bodySmall,
                      ),
                  ],
                ],
              ),
              if (t.message != null && t.message!.isNotEmpty) ...<Widget>[
                context.spacing.tightGap,
                Text(
                  t.message!,
                  style: context.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (t.taggerName != null || t.committedDate != null) ...<Widget>[
                context.spacing.tightGap,
                Row(
                  children: <Widget>[
                    if (t.taggerAvatarUrl != null)
                      CircleAvatar(
                        radius: 8,
                        backgroundImage: CachedNetworkImageProvider(
                          t.taggerAvatarUrl!,
                        ),
                      ),
                    if (t.taggerAvatarUrl != null) const SizedBox(width: 6),
                    Text(
                      [
                        if (t.taggerName != null) t.taggerName,
                        if (t.committedDate != null)
                          t.committedDate!.toRelativeDate(shorten: true),
                      ].join(' · '),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseContent(
    final BuildContext context,
    final RefListItemReleaseData r,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Octicons.package, size: 20, color: context.colorScheme.primary),
        context.spacing.itemGap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    ' ${r.tagName}',
                    style: context.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: <Widget>[
                  if (r.isLatest)
                    _badge(context, 'Latest', context.colorScheme.primary),
                  if (r.isPrerelease)
                    _badge(
                        context, 'Pre-release', context.colorScheme.secondary),
                  if (r.isDraft)
                    _badge(context, 'Draft', context.colorScheme.outline),
                ],
              ),
              if (r.publishedAt != null || r.authorLogin != null) ...<Widget>[
                context.spacing.tightGap,
                Row(
                  children: <Widget>[
                    if (r.authorAvatarUrl != null)
                      CircleAvatar(
                        radius: 8,
                        backgroundImage: CachedNetworkImageProvider(
                          r.authorAvatarUrl!,
                        ),
                      ),
                    if (r.authorAvatarUrl != null) const SizedBox(width: 6),
                    Text(
                      [
                        if (r.authorLogin != null) r.authorLogin,
                        if (r.publishedAt != null)
                          r.publishedAt!.toRelativeDate(shorten: true),
                      ].join(' · '),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (r.shortDescriptionHtml != null &&
                  r.shortDescriptionHtml!.isNotEmpty) ...<Widget>[
                context.spacing.tightGap,
                Text(
                  r.shortDescriptionHtml!
                      .replaceAll(RegExp(r'<[^>]*>'), '')
                      .trim(),
                  style: context.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (r.assetCount > 0 ||
                  (r.reactionCount != null && r.reactionCount! > 0))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: <Widget>[
                      if (r.assetCount > 0)
                        Text(
                          '${r.assetCount} asset${r.assetCount == 1 ? '' : 's'}',
                          style: context.textTheme.bodySmall,
                        ),
                      if (r.assetCount > 0 &&
                          r.reactionCount != null &&
                          r.reactionCount! > 0)
                        context.spacing.contentGap,
                      if (r.reactionCount != null && r.reactionCount! > 0)
                        Text(
                          '${r.reactionCount} reactions',
                          style: context.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge(
      final BuildContext context, final String label, final Color color) {
    return Container(
      padding: context.spacing.badgePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
