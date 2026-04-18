import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/widgets/expandable_option_list_widget.dart'
    as option_list;
import 'package:flutter/material.dart';

/// Reusable sort row: shows current option and opens [ExpandableOptionListWidget]
/// in a small bottom sheet on tap. Use for ref lists (branches/tags) or releases.
class SortOptionRow<T> extends StatelessWidget {
  const SortOptionRow({
    required this.icon,
    required this.current,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final T current;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(labelBuilder(current)),
      trailing: const Icon(Icons.arrow_drop_down_rounded),
      onTap: () {
        AppSheet.simple<void>(
          context,
          bodyBuilder: (final BuildContext ctx, StateSetter setState) =>
              option_list.ExpandableOptionListWidget(
            options: options
                .map(
                  (final T v) => option_list.ExpandableOption(
                    label: labelBuilder(v),
                    isSelected: v == current,
                    onTap: () {
                      onChanged(v);
                      Navigator.pop(ctx);
                    },
                  ),
                )
                .toList(),
            onCollapse: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }
}
