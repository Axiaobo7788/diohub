import 'package:diohub/common/animations/animated_gradient_bar.dart';
import 'package:diohub/common/cards/chips/metadata_chips_issue_pr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Animated diff stats bar for commit cards: same visual as [DiffDistribution]
/// with grow-in entrance via [AnimatedGradientBar].
///
/// Gated by existing [showDiffDistribution]. Use on commit card.
class CommitFileCompositionBar extends ConsumerWidget {
  const CommitFileCompositionBar({
    required this.additions,
    required this.deletions,
    this.changedFiles,
    super.key,
  });

  final int additions;
  final int deletions;
  final int? changedFiles;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return AnimatedGradientBar(
      child: DiffDistribution(
        additions: additions,
        deletions: deletions,
        changedFiles: changedFiles,
      ),
    );
  }
}
