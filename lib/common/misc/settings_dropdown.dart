import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Data for a single option in [SettingsDropdown].
class SettingsDropdownOption<T> {
  const SettingsDropdownOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Settings row: icon + title + current value; tap expands inline to show options.
/// Uses bodyMedium for title, bodySmall + w500 + primary for current value.
/// Options: bodyMedium (w400 normal, w600 selected), bodySmall for subtitle.
class SettingsDropdown<T> extends StatefulWidget {
  const SettingsDropdown({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.icon,
    this.optionSubtitleBuilder,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;
  final List<SettingsDropdownOption<T>> options;
  final ValueChanged<T> onChanged;

  /// If provided, builds subtitle for the selected option when collapsed.
  final String Function(T)? optionSubtitleBuilder;

  @override
  State<SettingsDropdown<T>> createState() => _SettingsDropdownState<T>();
}

class _SettingsDropdownState<T> extends State<SettingsDropdown<T>> {
  bool _expanded = false;

  SettingsDropdownOption<T>? get _selectedOption {
    for (final SettingsDropdownOption<T> o in widget.options) {
      if (o.value == widget.value) return o;
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final SettingsDropdownOption<T>? selected = _selectedOption;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: spacing.cardContentPadding,
              child: Row(
                children: <Widget>[
                  if (widget.icon != null) ...<Widget>[
                    Icon(
                      widget.icon,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: spacing.compactSpacing),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          widget.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (widget.subtitle != null) ...<Widget>[
                          SizedBox(height: spacing.tightSpacing),
                          Text(
                            widget.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (selected != null && !_expanded) ...<Widget>[
                          SizedBox(height: spacing.tightSpacing),
                          Text(
                            selected.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: kMicroDuration,
                    curve: kMicroCurve,
                    child: Icon(
                      Icons.expand_more,
                      size: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(
              left: spacing.cardContentPadding.left +
                  (widget.icon != null ? 22.0 + spacing.compactSpacing : 0),
              right: spacing.cardContentPadding.right,
              bottom: spacing.cardContentPadding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  widget.options.map((final SettingsDropdownOption<T> opt) {
                final bool isSelected = opt.value == widget.value;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onChanged(opt.value);
                      setState(() => _expanded = false);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: <Widget>[
                          if (opt.icon != null) ...<Widget>[
                            Icon(
                              opt.icon,
                              size: 20,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: spacing.compactSpacing),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  opt.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (opt.subtitle != null) ...<Widget>[
                                  SizedBox(height: spacing.tightSpacing),
                                  Text(
                                    opt.subtitle!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: kMicroDuration,
        ),
      ],
    );
  }
}
