import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';

/// Fire-and-forget pill: tap runs [onTapAction], no phase change.
/// Optional [label] shown next to icon when non-idle.
@immutable
final class BasicPillDescriptor extends DockPillDescriptor {
  const BasicPillDescriptor({
    required IconData icon,
    required this.onTapAction,
    this.label,
  }) : super(icon: icon);

  /// Called by the dock when the pill is tapped (with [WidgetRef]).
  final void Function(WidgetRef ref) onTapAction;

  final String? label;

  @override
  List<Object?> get props => [...super.props, icon, label];

  @override
  DockPillKind get kind => DockPillKind.fireAndForget;

  @override
  Widget? buildContent(final PillPhase phase, final BuildContext context) {
    if (phase == PillPhase.idle || label == null) return null;
    return Text(
      label!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }

  @override
  Widget? buildOverlay(final PillPhase phase, final BuildContext context) =>
      null;

  @override
  void fireAction(WidgetRef ref) => onTapAction(ref);
}
