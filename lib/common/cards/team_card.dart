import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub_graphql/schema_typedefs.dart' show TeamPrivacy;
import 'package:diohub_graphql/queries/common/common_typedefs.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card for an organization team in the Teams tab.
/// Tapping opens the team page on GitHub (orgs/{org}/teams/{slug}).
/// Caller MUST wrap in BorderedContainer if needed.
class TeamCard extends ConsumerWidget {
  const TeamCard({
    required this.team,
    required this.orgLogin,
    super.key,
  });

  final OrgTeamNode team;
  final String orgLogin;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final spacing = context.spacing;
    final teamUrl = ref.webUrl('/orgs/$orgLogin/teams/${team.slug}');

    // Build titlePrefix: avatar
    final Widget titlePrefix = UserAvatar(
      avatarUrl: team.avatarUrl?.toString(),
      size: 48,
    );

    // Build title: team name + lock icon if SECRET
    final Widget title = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            team.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (team.privacy == TeamPrivacy.SECRET) ...[
          SizedBox(width: spacing.tightSpacing),
          Icon(
            Octicons.lock,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );

    // Build chips: parent + members + repos
    final List<PrioritizedChip> allChips = [];
    if (team.parentTeam != null) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: MetadataChip(
            leading: const Icon(Octicons.organization, size: 12),
            label: 'Parent: ${team.parentTeam!.name}',
          ),
        ),
      );
    }
    allChips.add(
      PrioritizedChip(
        priority: ChipPriority.medium,
        widget: MetadataChip(
          leading: const Icon(Octicons.people, size: 12),
          label: _shortCount(team.members.totalCount),
        ),
      ),
    );
    allChips.add(
      PrioritizedChip(
        priority: ChipPriority.medium,
        widget: MetadataChip(
          leading: const Icon(Octicons.repo, size: 12),
          label: _shortCount(team.repositories.totalCount),
        ),
      ),
    );

    final chips = buildChipSection(
      chips: allChips,
      maxVisible: 3,
    );

    // Build supplementary: description
    Widget? supplementary;
    if (team.description != null && team.description!.trim().isNotEmpty) {
      supplementary = Text(
        team.description!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return GestureDetector(
      onTap: () => launchUrl(teamUrl),
      child: EntityCardLayout(
        titlePrefix: titlePrefix,
        title: title,
        chips: chips.isNotEmpty ? chips : null,
        supplementary: supplementary,
      ),
    );
  }

  static String _shortCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
