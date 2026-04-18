import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// A generic horizontally-scrolling single-select chip row.
///
/// Decoupled from the search/filter system, making it reusable for any
/// scenario requiring single-selection from a list of options.
///
/// Type parameter [T] represents the option type.
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.iconBuilder,
    super.key,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final IconData? Function(T)? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (index, option) in options.indexed) ...[
            if (index > 0) spacing.tightGap,
            ChoiceChip(
              label: Text(labelBuilder(option)),
              avatar: iconBuilder != null
                  ? Icon(
                      iconBuilder!(option),
                      size: 16,
                    )
                  : null,
              selected: option == selected,
              onSelected: (_) => onSelected(option),
            ),
          ],
        ],
      ),
    );
  }
}
