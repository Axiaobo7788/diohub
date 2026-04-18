import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/widgets/dock_pill_widget.dart';
import 'package:diohub/common/context_dock/widgets/pill_entrance.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Bottom dock overlay: action pills only (no tab-switch FAB).
/// The context pill is shown in the top [ContextBarSliver] instead.
/// Holds [_activePill] and enforces mutual exclusion (e.g. search expansion).
class DockOverlay extends StatefulWidget {
  const DockOverlay({
    required this.pills,
    this.initialActivePillIndex,
    this.tabIndex,
    super.key,
  });

  final List<DockPill> pills;
  final int? initialActivePillIndex;

  /// When non-null, used as key for [AnimatedSwitcher] so pill row crossfades
  /// when tab changes (exit animation).
  final int? tabIndex;

  @override
  State<DockOverlay> createState() => _DockOverlayState();
}

class _DockOverlayState extends State<DockOverlay> {
  DockPill? _activePill;
  final Map<DockPill, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _attachListeners(widget.pills);
    final index = widget.initialActivePillIndex;
    if (index != null &&
        index >= 0 &&
        index < widget.pills.length &&
        widget.pills.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pill = widget.pills[index];
        if (pill.value is! ActivePhase) {
          pill.value = const ActivePhase();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DockOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pills != widget.pills) {
      _detachListeners(oldWidget.pills);
      _activePill = null;
      _attachListeners(widget.pills);
    }
  }

  void _attachListeners(List<DockPill> pills) {
    for (final pill in pills) {
      final callback = () => _onPillChanged(pill);
      _listeners[pill] = callback;
      pill.addListener(callback);
    }
  }

  void _detachListeners(List<DockPill> pills) {
    for (final pill in pills) {
      final callback = _listeners.remove(pill);
      if (callback != null) {
        pill.removeListener(callback);
      }
    }
  }

  void _onPillChanged(DockPill pill) {
    if (!mounted) return;
    final phase = pill.value;
    if (phase is ActivePhase) {
      final previous = _activePill;
      if (previous != null && previous != pill) {
        _activePill = null;
        previous.value = const IdlePhase();
      }
      if (mounted) setState(() => _activePill = pill);
    } else if (_activePill == pill) {
      setState(() => _activePill = null);
    }
  }

  @override
  void dispose() {
    _detachListeners(widget.pills);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _activePill != null;
    final spacing = context.spacing;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = spacing.screenPadding.bottom + safeBottom;
    final right = spacing.screenPadding.right;
    final left = spacing.screenPadding.left;

    if (widget.pills.isEmpty) return const SizedBox.shrink();

    final pillRow = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, pill) in widget.pills.indexed)
          if (pill == _activePill)
            Expanded(
              child: PillEntrance(
                key: ValueKey<DockPill>(pill),
                visible: true,
                animateEntrance: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : spacing.tightSpacing,
                  ),
                  child: GlassPill(
                    style: GlassPillStyle.dockPill(context),
                    isFloating: true,
                    child: DockPillWidget(pill: pill),
                  ),
                ),
              ),
            )
          else
            PillEntrance(
              key: ValueKey<DockPill>(pill),
              visible: !isActive,
              animateEntrance: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : spacing.tightSpacing,
                ),
                child: GlassPill(
                  style: GlassPillStyle.dockPill(context),
                  isFloating: true,
                  child: DockPillWidget(pill: pill),
                ),
              ),
            ),
      ],
    );

    final content = widget.tabIndex != null
        ? AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<int>(widget.tabIndex!),
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
