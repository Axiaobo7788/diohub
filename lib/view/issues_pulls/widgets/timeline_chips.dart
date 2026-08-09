import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Green "Closes this issue" badge for cross-references.
class ClosesTargetBadge extends StatelessWidget {
  const ClosesTargetBadge({super.key});

  @override
  Widget build(final BuildContext context) {
    return TintedChip(
      label: 'Closes this',
      icon: Octicons.issue_closed,
      color: DiffColors.addition,
      iconSize: 12,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Colored badge for issue close state reason (Completed, Not Planned).
class StateReasonBadge extends StatelessWidget {
  const StateReasonBadge({required this.reason, super.key});

  final IssueStateReason reason;

  @override
  Widget build(final BuildContext context) {
    final (String label, Color color) = switch (reason) {
      IssueStateReason.COMPLETED => ('Completed', const Color(0xFF8B5CF6)),
      IssueStateReason.NOT_PLANNED => ('Not planned', const Color(0xFF656D76)),
      _ => (reason.name, Theme.of(context).colorScheme.onSurfaceVariant),
    };

    return TintedChip(
      label: label,
      color: color,
      iconSize: 12,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Monospace chip showing a commit abbreviated OID.
class CommitOidChip extends StatelessWidget {
  const CommitOidChip({
    required this.abbreviatedOid,
    required this.commitUrl,
    super.key,
  });

  final String abbreviatedOid;
  final String commitUrl;

  @override
  Widget build(final BuildContext context) {
    return MetadataChip(
      leading: Icon(
        Octicons.git_commit,
        size: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: abbreviatedOid,
      accentColor: null,
      textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A tappable [CommitOidChip] that navigates and shows a contextual popup.
/// Tap → navigate to commit detail screen.
/// Long-press → popup with View / Browse files / Compare with parent / Copy SHA.
class InteractiveCommitChip extends ConsumerWidget {
  const InteractiveCommitChip({
    required this.abbreviatedOid,
    required this.fullOid,
    required this.repoRef,
    this.onCompareWithParent,
    super.key,
  });

  final String abbreviatedOid;
  final String fullOid;
  final RepoRef repoRef;
  final VoidCallback? onCompareWithParent;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return PopupButton(
      placement: Placement.bottom,
      buttonBuilder: (final BuildContext c, final VoidCallback showPopup) =>
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey<String>('interactive-commit-chip-$fullOid'),
              onTap: () =>
                  CommitRef(repo: repoRef, oid: fullOid).navigate(context, ref),
              onLongPress: showPopup,
              borderRadius: BorderRadius.circular(6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: CommitOidChip(
                    abbreviatedOid: abbreviatedOid,
                    commitUrl: '',
                  ),
                ),
              ),
            ),
          ),
      popupBuilder: (final BuildContext c, final VoidCallback onDismiss) =>
          buildCommitPopupContent(
            context,
            onDismiss: onDismiss,
            abbreviatedOid: abbreviatedOid,
            fullOid: fullOid,
            repoRef: repoRef,
            onViewCommit: () =>
                CommitRef(repo: repoRef, oid: fullOid).navigate(context, ref),
            onBrowseFiles: () => RepoRef(
              owner: repoRef.owner,
              name: repoRef.name,
              location: RepoLocationTree(branch: fullOid),
            ).navigate(context, ref),
            onCompareWithParent: onCompareWithParent,
            onCopySha: () => ref.read(clipboardServiceProvider).copy(fullOid),
          ),
    );
  }
}

/// Compact green/red "+X / -Y" additions/deletions text.
class AdditionsDeletionsText extends StatelessWidget {
  const AdditionsDeletionsText({
    required this.additions,
    required this.deletions,
    super.key,
  });

  final int additions;
  final int deletions;

  @override
  Widget build(final BuildContext context) {
    if (additions == 0 && deletions == 0) return const SizedBox.shrink();

    final TextStyle? textStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurface);
    return Text.rich(
      TextSpan(
        style: textStyle,
        children: <InlineSpan>[
          if (additions > 0) TextSpan(text: '+$additions'),
          if (additions > 0 && deletions > 0) const TextSpan(text: ' / '),
          if (deletions > 0) TextSpan(text: '-$deletions'),
        ],
      ),
    );
  }
}

/// Badge showing a review state label (e.g. "Approved", "Changes requested").
class ReviewStateLabelBadge extends StatelessWidget {
  const ReviewStateLabelBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(final BuildContext context) {
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant;
    return TintedChip(label: label, color: color, iconSize: 12);
  }
}

/// Styled chip for lock reason.
class LockReasonChip extends StatelessWidget {
  const LockReasonChip({required this.reason, super.key});

  final LockReason reason;

  @override
  Widget build(final BuildContext context) {
    final String label = switch (reason) {
      LockReason.OFF_TOPIC => 'Off-topic',
      LockReason.TOO_HEATED => 'Too heated',
      LockReason.RESOLVED => 'Resolved',
      LockReason.SPAM => 'Spam',
      _ => reason.name,
    };

    final Color color = Theme.of(context).colorScheme.onSurfaceVariant;
    return TintedChip(
      label: label,
      icon: Octicons.lock,
      color: color,
      iconSize: 12,
    );
  }
}
