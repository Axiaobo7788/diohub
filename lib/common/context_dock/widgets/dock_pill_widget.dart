import 'package:diohub/common/animations/animated_content_switcher.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/animations/pressable_scale.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/models/pill_tap_behaviour.dart';
import 'package:diohub/common/context_dock/widgets/companion_row.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/popup/popup_menu.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Animated pill that renders icon + subclass content.
///
/// Owns its entire vertical stack when active: Column(overlay, companions, pill row).
/// When idle/hint, renders just the pill row.
///
/// Content only; parent wraps in [GlassPillSurface], [ScrollUnderGlass], or
/// [GlassPill] as needed.
class DockPillWidget extends ConsumerWidget {
  const DockPillWidget({required this.pill, super.key});

  final DockPill pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DockPillMountScope(
      pill: pill,
      child: ValueListenableBuilder<DockPillPhase>(
        valueListenable: pill,
        builder: (context, phase, _) {
          final content = pill.buildContent(context);
          final isActive = phase is ActivePhase;
          final hasContent = content != null;
          final colorScheme = Theme.of(context).colorScheme;
          // Stadium radius (999) for all phases — never card radius.
          final borderRadius = BorderRadius.circular(999);

          final pillRowInner = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: hasContent ? 12 : 8,
              vertical: 8,
            ),
            child: AnimatedContentSwitcher(
              transition: AnimationTransition.fade,
              duration: kStateDuration,
              child: Row(
                key: ValueKey(phase.runtimeType),
                mainAxisSize: isActive ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(
                    pill.icon,
                    size: isActive ? 16 : 20,
                    color: colorScheme.onSurface,
                  ),
                  if (hasContent) ...[
                    SizedBox(width: isActive ? 8 : 4),
                    if (isActive)
                      Expanded(child: content)
                    else
                      Flexible(child: content),
                  ],
                ],
              ),
            ),
          );

          Widget buildPillRow(VoidCallback? onTap) {
            return GestureDetector(
              onTap: isActive ? null : onTap,
              child: PressableScale(
                child: AnimatedContainer(
                  duration: kStateDuration,
                  curve: kStateCurve,
                  child: pillRowInner,
                ),
              ),
            );
          }

          switch (pill.tapBehaviour) {
            case PopupPill():
              return PopupButton(
                buttonBuilder: (_, showMenu) => buildPillRow(showMenu),
                popupBuilder: (_, close) {
                  final actions = pill.buildActions(ref, close);
                  if (actions != null && actions.isNotEmpty) {
                    return PopupMenu(actions: actions, onDismiss: close);
                  }
                  return pill.buildPopupContent(close) ??
                      const SizedBox.shrink();
                },
              );
            case FireAndForget():
              final pillRow = buildPillRow(() {
                pill.onTap(context, ref);
              });
              return pillRow;
            case ActivatePill():
              break;
          }

          final pillRow = buildPillRow(() {
            pill.onTap(context, ref);
          });

          if (!isActive) return pillRow;

          final overlay = pill.buildOverlay(context);
          final companions = (phase as ActivePhase).companions.cast<DockPill>();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (overlay != null)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: context.spacing.tightSpacing,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Theme.of(context).surface.radius(RadiusSize.large),
                      ),
                      child: ColoredBox(
                        color: colorScheme.surfaceContainerLow,
                        child: overlay,
                      ),
                    ),
                  ),
                ),
              if (companions.isNotEmpty) CompanionRow(companions: companions),
              pillRow,
            ],
          );
        },
      ),
    );
  }
}

/// Calls [DockPill.onMount] once after first frame.
class _DockPillMountScope extends ConsumerStatefulWidget {
  const _DockPillMountScope({required this.pill, required this.child});

  final DockPill pill;
  final Widget child;

  @override
  ConsumerState<_DockPillMountScope> createState() =>
      _DockPillMountScopeState();
}

class _DockPillMountScopeState extends ConsumerState<_DockPillMountScope> {
  @override
  void initState() {
    super.initState();
    widget.pill.onMount(ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
