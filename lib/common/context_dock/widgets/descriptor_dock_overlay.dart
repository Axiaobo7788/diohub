import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/context_dock/providers/dock_pill_phase_provider.dart';
import 'package:diohub/common/context_dock/widgets/descriptor_pill_widget.dart';
import 'package:diohub/common/context_dock/widgets/pill_entrance.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/style/app_spacing.dart';

/// Descriptor-based dock overlay. Replaces old DockOverlay.
/// Uses [DockPillDescriptor] (pure data) + [dockPillPhaseProvider] (state).
class DescriptorDockOverlay extends ConsumerWidget {
  const DescriptorDockOverlay({
    required this.descriptors,
    this.tabIndex,
    super.key,
  });

  final List<DockPillDescriptor> descriptors;

  /// When non-null, used as key for [AnimatedSwitcher] so pill row crossfades
  /// when tab changes.
  final int? tabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (descriptors.isEmpty) return const SizedBox.shrink();

    // Find active pill
    DockPillDescriptor? activePill;
    for (final descriptor in descriptors) {
      final phase = ref.watch(dockPillPhaseProvider(descriptor));
      if (phase == PillPhase.active) {
        activePill = descriptor;
        break;
      }
    }

    final spacing = context.spacing;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = spacing.screenPadding.bottom + safeBottom;
    final right = spacing.screenPadding.right;
    final left = spacing.screenPadding.left;

    final pillRow = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, descriptor) in descriptors.indexed)
          if (descriptor == activePill)
            Expanded(
              child: PillEntrance(
                key: ValueKey<DockPillDescriptor>(descriptor),
                visible: true,
                animateEntrance: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : spacing.tightSpacing,
                  ),
                  child: GlassPill(
                    style: GlassPillStyle.dockPill(context),
                    isFloating: true,
                    child: DescriptorPillWidget(
                      descriptor: descriptor,
                      allDescriptors: descriptors,
                    ),
                  ),
                ),
              ),
            )
          else
            PillEntrance(
              key: ValueKey<DockPillDescriptor>(descriptor),
              visible: activePill == null,
              animateEntrance: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : spacing.tightSpacing,
                ),
                child: GlassPill(
                  style: GlassPillStyle.dockPill(context),
                  isFloating: true,
                  child: DescriptorPillWidget(
                    descriptor: descriptor,
                    allDescriptors: descriptors,
                  ),
                ),
              ),
            ),
      ],
    );

    final content = tabIndex != null
        ? AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<int>(tabIndex!),
              child: pillRow,
            ),
          )
        : pillRow;

    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: content,
    );
  }
}
