import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:flutter/material.dart';

/// Groups actions by category, preserving order.
/// Returns a map where keys are categories (null for uncategorized)
/// and values are lists of actions.
Map<String?, List<ActionButtonData>> groupActionsByCategory(
  final List<ActionButtonData> actions,
) {
  final Map<String?, List<ActionButtonData>> grouped =
      <String?, List<ActionButtonData>>{};
  String? currentCategory;

  for (final ActionButtonData action in actions) {
    final String? category = action.category;

    // If category changed, start a new group
    if (category != currentCategory) {
      currentCategory = category;
    }

    // Always ensure the category exists in the map before accessing it
    grouped.putIfAbsent(category, () => <ActionButtonData>[]).add(action);
  }

  return grouped;
}

/// Builds a section header widget for a category
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    required this.category,
    super.key,
  });

  final String category;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: 4,
          top: 12,
          bottom: 8,
        ),
        child: Text(
          category.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
