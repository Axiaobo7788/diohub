import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/context_dock/providers/dock_pill_phase_provider.dart';
import 'package:diohub/style/app_spacing.dart';

/// Renders a dock pill from a [DockPillDescriptor].
/// Manages phase via [dockPillPhaseProvider].
class DescriptorPillWidget extends ConsumerWidget {
  const DescriptorPillWidget({
    required this.descriptor,
    this.allDescriptors,
    super.key,
  });

  final DockPillDescriptor descriptor;

  /// All descriptors in the dock (for mutual exclusion).
  final List<DockPillDescriptor>? allDescriptors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(dockPillPhaseProvider(descriptor));

    return GestureDetector(
      onTap: () => _handleTap(context, ref, phase),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(descriptor.icon, size: 20),
          if (phase != PillPhase.idle) ...[
            SizedBox(width: context.spacing.tightSpacing),
            Flexible(
              child:
                  descriptor.buildContent(phase, context) ??
                  const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, PillPhase currentPhase) {
    switch (descriptor.kind) {
      case DockPillKind.activate:
        // Enforce mutual exclusion: deactivate all others before toggling this one
        if (currentPhase != PillPhase.active && allDescriptors != null) {
          for (final other in allDescriptors!) {
            if (other != descriptor) {
              ref.read(dockPillPhaseProvider(other).notifier).deactivate();
            }
          }
        }
        // Toggle between idle and active
        ref.read(dockPillPhaseProvider(descriptor).notifier).toggle();
        break;
      case DockPillKind.popup:
        // Enforce mutual exclusion before activating
        if (allDescriptors != null) {
          for (final other in allDescriptors!) {
            if (other != descriptor) {
              ref.read(dockPillPhaseProvider(other).notifier).deactivate();
            }
          }
        }
        // Show popup (implementation depends on pill type)
        // For now, just activate
        ref.read(dockPillPhaseProvider(descriptor).notifier).activate();
        break;
      case DockPillKind.fireAndForget:
        // Fire action without changing phase
        descriptor.fireAction(ref);
        break;
    }
  }
}
