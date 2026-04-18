import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Status flag variants for repos, issues, PRs, users, and commits.
enum StatusFlag {
  archived,
  disabled,
  fork,
  mirror,
  template,
  private,
  locked,
  pinned,
  verified,
  unverified,
  hireable,
  busy,
  draft,
  conflicts,
}

extension StatusFlagExt on StatusFlag {
  IconData get icon {
    switch (this) {
      case StatusFlag.archived:
        return Octicons.archive;
      case StatusFlag.disabled:
        return Icons.block;
      case StatusFlag.fork:
        return Octicons.repo_forked;
      case StatusFlag.mirror:
        return Octicons.repo;
      case StatusFlag.template:
        return Octicons.file;
      case StatusFlag.private:
        return Octicons.lock;
      case StatusFlag.locked:
        return Octicons.lock;
      case StatusFlag.pinned:
        return Octicons.pin;
      case StatusFlag.verified:
        return Octicons.verified;
      case StatusFlag.unverified:
        return Octicons.unverified;
      case StatusFlag.hireable:
        return Icons.work_outline_rounded;
      case StatusFlag.busy:
        return Icons.do_not_disturb;
      case StatusFlag.draft:
        return Octicons.git_pull_request_draft;
      case StatusFlag.conflicts:
        return Icons.warning_amber_rounded;
    }
  }

  String get label {
    switch (this) {
      case StatusFlag.archived:
        return 'Archived';
      case StatusFlag.disabled:
        return 'Disabled';
      case StatusFlag.fork:
        return 'Fork';
      case StatusFlag.mirror:
        return 'Mirror';
      case StatusFlag.template:
        return 'Template';
      case StatusFlag.private:
        return 'Private';
      case StatusFlag.locked:
        return 'Locked';
      case StatusFlag.pinned:
        return 'Pinned';
      case StatusFlag.verified:
        return 'Verified';
      case StatusFlag.unverified:
        return 'Unverified';
      case StatusFlag.hireable:
        return 'Hireable';
      case StatusFlag.busy:
        return 'Busy';
      case StatusFlag.draft:
        return 'Draft';
      case StatusFlag.conflicts:
        return 'Conflicts';
    }
  }

  Color color(ColorScheme colorScheme) {
    switch (this) {
      case StatusFlag.archived:
      case StatusFlag.disabled:
      case StatusFlag.private:
        return colorScheme.error;
      case StatusFlag.fork:
        return colorScheme.tertiary;
      case StatusFlag.mirror:
      case StatusFlag.template:
        return colorScheme.secondary;
      case StatusFlag.locked:
        return Colors.orange;
      case StatusFlag.pinned:
        return colorScheme.primary;
      case StatusFlag.verified:
      case StatusFlag.hireable:
        return Colors.green;
      case StatusFlag.unverified:
      case StatusFlag.busy:
        return Colors.amber;
      case StatusFlag.draft:
        return colorScheme.onSurfaceVariant;
      case StatusFlag.conflicts:
        return colorScheme.error;
    }
  }
}

/// A row of micro status chips (e.g. Archived, Fork, Locked) for collapsed bars.
class StatusFlagRow extends StatelessWidget {
  const StatusFlagRow({
    required this.flags,
    this.compact = true,
    super.key,
  });

  final List<StatusFlag> flags;
  final bool compact;

  @override
  Widget build(final BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    if (compact) {
      final List<MetadataBadgeChip> badges = flags.map((final StatusFlag flag) {
        final bool isCritical = flag == StatusFlag.private ||
            flag == StatusFlag.archived ||
            flag == StatusFlag.disabled ||
            flag == StatusFlag.locked ||
            flag == StatusFlag.draft ||
            flag == StatusFlag.conflicts;
        return MetadataBadgeChip(
          label: flag.label,
          color: flag.color(colorScheme),
          icon: flag.icon,
          priority: isCritical ? 0 : 50,
        );
      }).toList();
      return MetadataBadgeFlow(
        badges: badges,
        compact: true,
      );
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppSpacing spacing = context.spacing;

    return Wrap(
      spacing: spacing.tightSpacing,
      runSpacing: spacing.tightSpacing,
      children: flags.map((final StatusFlag flag) {
        final Color color = flag.color(colorScheme);
        return TintedChip(
          color: color,
          icon: flag.icon,
          label: flag.label,
          iconSize: 10,
          padding: spacing.badgePadding,
          size: RadiusSize.small,
          border: true,
          labelStyle: textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

/// Single horizontal row for app bar status: optional leading widget (e.g.
/// [UserStatusPill]) plus [StatusFlagRow]. Use for profile/entity bars to avoid
/// vertical stacking that clips when collapsed.
class StatusIndicatorRow extends StatelessWidget {
  const StatusIndicatorRow({
    this.leading,
    this.flags = const <StatusFlag>[],
    super.key,
  });

  final Widget? leading;
  final List<StatusFlag> flags;

  @override
  Widget build(final BuildContext context) {
    final bool hasLeading = leading != null;
    final bool hasFlags = flags.isNotEmpty;
    if (!hasLeading && !hasFlags) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasLeading) leading!,
        if (hasLeading && hasFlags) SizedBox(width: spacing.tightSpacing),
        if (hasFlags) StatusFlagRow(flags: flags, compact: true),
      ],
    );
  }
}
