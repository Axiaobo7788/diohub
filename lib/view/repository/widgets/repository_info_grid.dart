import 'package:diohub/common/widgets/expandable_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:flutter/material.dart';

/// Grid-based repository info display for better visual hierarchy
/// Uses ExpandableSectionPrimary for prominence
class ExpandableRepositoryInfoGrid extends StatelessWidget {
  const ExpandableRepositoryInfoGrid({
    required this.onCollapse,
    required this.repo,
    super.key,
  });

  final VoidCallback onCollapse;
  final GrepositoryInfoData_repository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> infoCards = [];

    // Language card
    if (repo.primaryLanguage != null) {
      infoCards.add(_buildInfoCard(
        context,
        icon: Icons.code_rounded,
        label: 'Language',
        value: repo.primaryLanguage!.name,
        color: repo.primaryLanguage!.color != null
            ? Color(int.parse(
                repo.primaryLanguage!.color!.replaceFirst('#', '0xFF')))
            : colorScheme.primary,
        onTap: () {
          // TODO: Navigate to Code tab
        },
      ));
    }

    // License card
    if (repo.licenseInfo != null) {
      infoCards.add(_buildInfoCard(
        context,
        icon: Icons.balance_rounded,
        label: 'License',
        value: repo.licenseInfo!.name,
        color: colorScheme.secondary,
      ));
    }

    // Size card
    if (repo.diskUsage != null) {
      infoCards.add(_buildInfoCard(
        context,
        icon: Icons.storage_rounded,
        label: 'Size',
        value: _formatSize(repo.diskUsage!),
        color: colorScheme.tertiary,
      ));
    }

    // Visibility card
    infoCards.add(_buildInfoCard(
      context,
      icon: repo.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
      label: 'Visibility',
      value: repo.isPrivate ? 'Private' : 'Public',
      color: repo.isPrivate ? colorScheme.error : colorScheme.primary,
    ));

    // Archived status card
    if (repo.isArchived) {
      infoCards.add(_buildInfoCard(
        context,
        icon: Icons.archive_rounded,
        label: 'Status',
        value: 'Archived',
        color: colorScheme.onSurfaceVariant,
      ));
    }

    // Features card
    final List<String> enabledFeatures = [];
    if (repo.hasIssuesEnabled) enabledFeatures.add('Issues');
    if (repo.hasProjectsEnabled) enabledFeatures.add('Projects');
    if (repo.hasWikiEnabled) enabledFeatures.add('Wiki');
    if (repo.hasDiscussionsEnabled) enabledFeatures.add('Discussions');

    if (enabledFeatures.isNotEmpty) {
      infoCards.add(_buildInfoCard(
        context,
        icon: Icons.settings_rounded,
        label: 'Features',
        value: enabledFeatures.join(', '),
        color: colorScheme.primary,
        isWide: true,
      ));
    }

    if (infoCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpandableSectionPrimary(
      title: 'Repository Info',
      onCollapse: onCollapse,
      headerColor: colorScheme.secondary,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: infoCards.length,
                itemBuilder: (context, index) => infoCards[index],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
    bool isWide = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int diskUsageKB) {
    if (diskUsageKB >= 1024 * 1024) {
      return '${(diskUsageKB / (1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (diskUsageKB >= 1024) {
      return '${(diskUsageKB / 1024).toStringAsFixed(1)} MB';
    }
    return '$diskUsageKB KB';
  }
}

