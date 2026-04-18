import 'package:diohub/common/nav_center/builders/common_metadata_builders.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub/common/widgets/metadata_language_bar.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/cards/release_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/format_bytes.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/view/repository/widgets/config/repo_entity_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

extension RepoInfoMetadata on RepoInfo {
  List<MetadataSectionData> metadataSections(
    BuildContext context,
    WidgetRef ref,
  ) => buildMetadataSections(context, ref, this);
}

/// Builds all metadata sections for the repository screen (overview, identity, code, features, topics, community, release, timeline).
List<MetadataSectionData> buildMetadataSections(
  BuildContext context,
  WidgetRef ref,
  RepoInfo repo,
) {
  final sections = <MetadataSectionData>[];

  final overviewChildren = _buildOverviewChildren(context, repo);
  if (overviewChildren.isNotEmpty) {
    sections.add(
      MetadataSectionData(
        title: 'Overview',
        icon: Icons.bar_chart_rounded,
        variant: MetadataSectionVariant.strong,
        children: overviewChildren,
      ),
    );
  }

  final identityChildren = _buildIdentityChildren(context, ref, repo);
  if (identityChildren.isNotEmpty) {
    sections.add(
      MetadataSectionData(
        title: 'Identity',
        icon: Icons.person_outline_rounded,
        variant: MetadataSectionVariant.strong,
        children: identityChildren,
      ),
    );
  }

  final codeChildren = _buildCodeChildren(context, repo);
  if (codeChildren.isNotEmpty) {
    sections.add(
      MetadataSectionData(
        title: 'Code',
        icon: Icons.code_rounded,
        variant: MetadataSectionVariant.strong,
        children: codeChildren,
      ),
    );
  }

  final featureFlags = _collectFeatureFlags(repo);
  if (featureFlags.isNotEmpty) {
    sections.add(
      MetadataSectionData(
        title: 'Features',
        icon: Icons.tune_rounded,
        variant: MetadataSectionVariant.muted,
        children: [
          Wrap(
            spacing: context.spacing.tightSpacing,
            runSpacing: context.spacing.compactSpacing,
            children: featureFlags,
          ),
        ],
      ),
    );
  }

  final topicsChildren = _buildTopicsChildren(context, repo);
  if (topicsChildren.isNotEmpty) {
    sections.add(
      MetadataSectionData(
        title: 'Topics',
        icon: Icons.label_outline_rounded,
        variant: MetadataSectionVariant.neutral,
        children: topicsChildren,
      ),
    );
  }

  final communityChildren = _buildCommunityChildren(context, repo);
  if (communityChildren.isNotEmpty) {
    sections.add(
      MetadataSectionData(
        title: 'Community',
        icon: Icons.people_outline_rounded,
        variant: MetadataSectionVariant.muted,
        children: communityChildren,
      ),
    );
  }

  if (repo.latestRelease != null) {
    sections.add(
      MetadataSectionData(
        title: 'Latest release',
        icon: Icons.local_offer_rounded,
        variant: MetadataSectionVariant.muted,
        children: _buildReleaseChildren(context, repo),
      ),
    );
  }

  sections.add(
    MetadataSectionData(
      title: 'Timeline',
      icon: Icons.schedule_rounded,
      variant: MetadataSectionVariant.muted,
      children: <Widget>[
        buildTimestampsGroup(
          createdAt: repo.createdAt,
          updatedAt: repo.updatedAt,
          pushedAt: repo.pushedAt,
          archivedAt: repo.isArchived && repo.archivedAt != null
              ? repo.archivedAt
              : null,
          title: '',
        ),
      ],
    ),
  );

  return sections;
}

List<Widget> _buildOverviewChildren(BuildContext context, RepoInfo repo) {
  final List<MetadataStat> stats = <MetadataStat>[
    MetadataStat(label: 'Stars', value: '${repo.stargazerCount}'),
    MetadataStat(label: 'Forks', value: '${repo.forkCount}'),
    MetadataStat(label: 'Watchers', value: '${repo.watchers.totalCount}'),
    MetadataStat(label: 'Issues', value: '${repo.issues.totalCount}'),
  ];
  return <Widget>[MetadataStatBar(stats: stats)];
}

List<Widget> _buildIdentityChildren(
  BuildContext context,
  WidgetRef ref,
  RepoInfo repo,
) {
  final spacing = context.spacing;
  final ownerRows = <Widget>[];
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
  if (ownerLogin != null) {
    ownerRows.add(
      MetadataUserRow(
        label: 'Owner',
        avatarUrl: ownerAvatarUrl ?? '',
        login: ownerLogin,
        onTap: () => UserRef(login: ownerLogin).navigate(context, ref),
      ),
    );
  }
  ownerRows.add(
    MetadataRow(
      icon: repo.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
      label: 'Visibility',
      child: Text(
        repo.isPrivate ? 'Private' : 'Public',
        style: TextStyle(
          color: repo.isPrivate
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
  );
  if (repo.isArchived || repo.isFork || repo.isMirror || repo.isTemplate) {
    ownerRows.add(StatusFlagRow(flags: repo.statusFlags, compact: false));
  }
  if (repo.diskUsage != null) {
    ownerRows.add(
      MetadataRow(
        icon: Icons.storage_rounded,
        label: 'Size',
        child: Text(formatBytes(repo.diskUsage! * 1024)),
      ),
    );
  }
  final plan = repo.planFeatures;
  final parts = <String>[
    if (plan.maximumAssignees > 0) 'Max ${plan.maximumAssignees} assignees',
    if (plan.maximumManualReviewRequests > 0)
      'Max ${plan.maximumManualReviewRequests} manual reviews',
  ];
  if (parts.isNotEmpty) {
    ownerRows.add(
      MetadataRow(
        icon: Icons.workspace_premium_outlined,
        label: 'Plan',
        child: Text(parts.join(' · ')),
      ),
    );
  }
  if (repo.homepageUrl != null) {
    ownerRows.add(
      MetadataRow(
        icon: Icons.link,
        label: 'Homepage',
        onTap: () => launchUrl(repo.homepageUrl!),
        child: Text(
          repo.homepageUrl.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  if (repo.templateRepository != null) {
    final template = repo.templateRepository!;
    ownerRows.add(
      MetadataRow(
        icon: Icons.description_outlined,
        label: 'Created from',
        onTap: () => launchUrl(template.url),
        child: Text(
          template.nameWithOwner,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  if (repo.mirrorUrl != null) {
    ownerRows.add(
      MetadataRow(
        icon: Icons.refresh_rounded,
        label: 'Mirror of',
        onTap: () => launchUrl(repo.mirrorUrl!),
        child: Text(
          repo.mirrorUrl.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
      ),
    );
  }
  List<Widget> identityChildren = ownerRows.isNotEmpty
      ? <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ownerRows,
          ),
        ]
      : <Widget>[];

  if (repo.isFork && repo.parent != null) {
    final parent = repo.parent!;
    identityChildren.add(spacing.itemGap);
    identityChildren.add(
      MetadataRow(
        icon: Icons.call_split_rounded,
        label: 'Forked from',
        onTap: () => RepoRef(
          owner: parent.owner.login,
          name: parent.name,
        ).navigate(context, ref),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                parent.nameWithOwner,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            spacing.tightGap,
            Icon(
              Icons.star_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant.muted,
            ),
            spacing.tightGap,
            Text(
              '${parent.stargazerCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  return identityChildren;
}

List<Widget> _buildCodeChildren(BuildContext context, RepoInfo repo) {
  final codeRows = <Widget>[];
  if (repo.primaryLanguage != null) {
    final langColor = repo.primaryLanguage!.color != null
        ? tryParseHexColor(
            repo.primaryLanguage!.color!,
            fallback: Theme.of(context).colorScheme.primary,
          )!
        : Theme.of(context).colorScheme.primary;
    codeRows.add(
      MetadataRow(
        icon: Icons.code_rounded,
        label: 'Language',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: langColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              repo.primaryLanguage!.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
  if (repo.licenseInfo != null) {
    codeRows.add(
      MetadataRow(
        icon: Icons.balance_rounded,
        label: 'License',
        child: Text(repo.licenseInfo!.name),
      ),
    );
  }
  if (repo.defaultBranchRef != null) {
    codeRows.add(
      MetadataRow(
        icon: Icons.fork_right_rounded,
        label: 'Default',
        child: Text(
          repo.defaultBranchRef!.name,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }
  if (repo.languages?.edges != null && repo.languages!.edges!.isNotEmpty) {
    final langEntries = repo.languages!.edges!
        .whereType<RepoLanguageEdge>()
        .map(
          (final e) => LanguageBarEntry(
            name: e.node.name,
            color: e.node.color ?? '#6e7681',
            size: e.size,
          ),
        )
        .toList();
    codeRows.add(MetadataLanguageBar(entries: langEntries));
  }
  return codeRows.isNotEmpty
      ? <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: codeRows,
          ),
        ]
      : <Widget>[];
}

List<Widget> _collectFeatureFlags(RepoInfo repo) {
  final list = <Widget>[];
  if (repo.hasDiscussionsEnabled == true) {
    list.add(
      TintedChip(
        color: Colors.purple,
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Discussions',
      ),
    );
  }
  if (repo.hasWikiEnabled == true) {
    list.add(
      TintedChip(
        color: Colors.blue,
        icon: Icons.menu_book_outlined,
        label: 'Wiki',
      ),
    );
  }
  if (repo.isSecurityPolicyEnabled == true) {
    list.add(
      TintedChip(
        color: Colors.orange,
        icon: Icons.security_rounded,
        label: 'Security policy',
      ),
    );
  }
  if (repo.hasVulnerabilityAlertsEnabled == true) {
    list.add(
      TintedChip(
        color: Colors.red,
        icon: Icons.warning_amber_rounded,
        label: 'Vulnerability alerts',
      ),
    );
  }
  return list;
}

List<Widget> _buildTopicsChildren(BuildContext context, RepoInfo repo) {
  if (repo.repositoryTopics.edges?.isEmpty ?? true) return <Widget>[];
  final topicChips = repo.repositoryTopics.edges!
      .whereType<RepoTopicEdge>()
      .where((final edge) => edge.node != null)
      .map((final edge) => MetadataChipData(label: edge.node!.topic.name))
      .toList();
  return topicChips.isEmpty
      ? <Widget>[]
      : <Widget>[MetadataChipWrap(chips: topicChips)];
}

List<Widget> _buildCommunityChildren(BuildContext context, RepoInfo repo) {
  final List<Widget> children = <Widget>[];
  for (final link in repo.fundingLinks) {
    children.add(
      MetadataRow(
        icon: Icons.volunteer_activism_rounded,
        label: link.platform.name.replaceAll('_', ' '),
        onTap: () => launchUrl(link.url),
        child: Icon(
          Icons.open_in_new_rounded,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  if (repo.codeOfConduct != null) {
    final coc = repo.codeOfConduct!;
    children.add(
      MetadataRow(
        icon: Icons.gavel_rounded,
        label: 'Code of Conduct',
        onTap: coc.url != null ? () => launchUrl(coc.url!) : null,
        child: Text(coc.name, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
  if (repo.contactLinks != null && repo.contactLinks!.isNotEmpty) {
    for (final link in repo.contactLinks!) {
      children.add(
        MetadataRow(
          icon: Icons.contact_mail_rounded,
          label: link.name,
          onTap: () => launchUrl(link.url),
          child: Text(
            link.about,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
        ),
      );
    }
  }
  return children;
}

List<Widget> _buildReleaseChildren(BuildContext context, RepoInfo repo) {
  if (repo.latestRelease == null) return <Widget>[];
  final release = repo.latestRelease!;
  final releaseName = release.name ?? release.tagName;
  if (releaseName.isEmpty) return <Widget>[];
  final ownerLogin = switch (repo.owner) {
    Fragment$actor actor => actor.login,
    _ => throw ArgumentError('Invalid owner type: ${repo.owner.runtimeType}'),
  };
  final RepoRef repoRef = RepoRef(owner: ownerLogin, name: repo.name);
  return <Widget>[
    BorderedContainer(
      child: ReleaseCard(repoRef: repoRef, release: release),
    ),
  ];
}
