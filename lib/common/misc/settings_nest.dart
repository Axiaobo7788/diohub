import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:flutter/material.dart';

/// Recursive nested settings: a [SettingsDropdown] selector plus a child
/// widget that depends on the selected value. When the value changes, the
/// child is swapped with [AnimatedSwitcher] (kStateDuration / kStateCurve).
///
/// Use [children] to provide one widget per option value; the widget for
/// [value] is shown below the dropdown. Children can be nested [SettingsNest]
/// for multi-level options (e.g. style → surface override → glass sliders).
class SettingsNest<T> extends StatelessWidget {
  const SettingsNest({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.children,
    super.key,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;
  final List<SettingsDropdownOption<T>> options;
  final ValueChanged<T> onChanged;

  /// Widget to show for each option value. The widget for current [value] is
  /// displayed; use [SizedBox.shrink] for values that have no nested content.
  final Map<T, Widget> children;

  @override
  Widget build(final BuildContext context) {
    final Widget child = children[value] ?? const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsDropdown<T>(
          title: title,
          subtitle: subtitle,
          icon: icon,
          value: value,
          options: options,
          onChanged: onChanged,
        ),
        AnimatedSwitcher(
          duration: kStateDuration,
          switchInCurve: kStateCurve,
          switchOutCurve: kStateCurve,
          layoutBuilder: (final Widget? current, final List<Widget> previous) {
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...previous,
                if (current != null) current,
              ],
            );
          },
          transitionBuilder:
              (final Widget child, final Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(key: ValueKey<T>(value), child: child),
        ),
      ],
    );
  }
}
