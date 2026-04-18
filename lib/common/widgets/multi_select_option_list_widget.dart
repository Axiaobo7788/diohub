import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/widgets/expandable_option_list_widget.dart'
    show ExpandableOptionListWidget;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A single item for [MultiSelectOptionListWidget].
class MultiSelectItem {
  const MultiSelectItem({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
}

/// A reusable multi-select list for expandable UIs (e.g. toolbar filter).
///
/// Same visual style as [ExpandableOptionListWidget]: padding, borders,
/// TapFeedback, selected background, check icon. Tap toggles selection
/// without collapsing so the user can select several items.
///
/// Example:
/// ```dart
/// MultiSelectOptionListWidget(
///   items: reasonItems,
///   selectedIds: filtersState.showOnlyReasons.toSet(),
///   onSelectionChanged: (ids) => notifier.setShowOnlyReasons(ids.toList()),
///   onCollapse: onCollapse,
/// )
/// ```
class MultiSelectOptionListWidget extends StatelessWidget {
  const MultiSelectOptionListWidget({
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onCollapse,
    super.key,
  });

  final List<MultiSelectItem> items;
  final Set<String> selectedIds;
  final void Function(Set<String>) onSelectionChanged;
  final VoidCallback onCollapse;

  void _onItemTap(final String id) {
    final Set<String> next = Set<String>.from(selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onSelectionChanged(next);
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...items.map((final MultiSelectItem item) {
              final bool isSelected = selectedIds.contains(item.id);
              final bool isLast = item.id == items.last.id;
              return DecoratedBox(
                decoration: BoxDecoration(
                  border: isLast || isSelected
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.subtle,
                            width: 0.5,
                          ),
                        ),
                ),
                child: _buildTile(
                  context: context,
                  theme: theme,
                  colorScheme: colorScheme,
                  item: item,
                  isSelected: isSelected,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required final BuildContext context,
    required final ThemeData theme,
    required final ColorScheme colorScheme,
    required final MultiSelectItem item,
    required final bool isSelected,
  }) {
    final Color mutedTextColor = colorScheme.onSurfaceVariant;
    final Color resolvedTextColor =
        isSelected ? colorScheme.primary : colorScheme.onSurface;
    final Color resolvedIconColor =
        isSelected ? colorScheme.primary : mutedTextColor;

    return TapFeedback(
      onTap: () => _onItemTap(item.id),
      child: Container(
        padding: context.spacing.inputPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.borderO
              : Colors.transparent,
          borderRadius: context.radius(RadiusSize.medium),
        ),
        child: Row(
          children: <Widget>[
            if (item.icon != null) ...<Widget>[
              Icon(
                item.icon,
                size: 20,
                color: resolvedIconColor,
              ),
              context.spacing.contentGap,
            ],
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: resolvedTextColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected) ...<Widget>[
              context.spacing.itemGap,
              Icon(
                Icons.check_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
