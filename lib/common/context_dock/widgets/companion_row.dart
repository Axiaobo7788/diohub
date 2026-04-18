import 'package:diohub/common/animations/staggered_entrance.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/widgets/dock_pill_widget.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Horizontal row of companion pills shown when a pill is active.
///
/// Each companion is a [DockPill] instance (typically [BasicDockPill])
/// rendered as a small [DockPillWidget].
///
/// Uses [StaggeredEntrance] for sequential appearance (50ms delay per pill).
///
/// Layout: Row, right-aligned, wrapped in Padding above the main dock row.
class CompanionRow extends StatelessWidget {
  const CompanionRow({required this.companions, super.key});

  /// Companion pills from [ActivePhase.companions]. Cast from List<Object>.
  final List<DockPill> companions;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.tightSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, companion) in companions.indexed)
            StaggeredEntrance(
              index: i,
              staggerDelay: const Duration(milliseconds: 50),
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : spacing.tightSpacing,
                ),
                child: GlassPill(
                  style: GlassPillStyle.dockPill(context),
                  isFloating: true,
                  child: DockPillWidget(pill: companion),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
