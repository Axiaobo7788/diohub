import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings row that opens a sheet when the trailing chevron is tapped.
///
/// Use for rows that navigate to a bottom sheet (e.g. Milestone, Projects).
/// [onTap] is invoked when the user taps the chevron; loading and error
/// handling are provided by the base class.
class SettingsSheetActionRow extends SettingsRowBase<void> {
  SettingsSheetActionRow({
    required super.label,
    required this.onTap,
    super.key,
    super.leadingIcon,
    super.subtitle,
  }) : super(
         onMutate: (void _) async {
           await onTap();
         },
       );

  /// Called when the trailing chevron is tapped. Typically opens a sheet.
  final Future<void> Function() onTap;

  @override
  ConsumerState<SettingsSheetActionRow> createState() =>
      _SettingsSheetActionRowState();
}

class _SettingsSheetActionRowState
    extends SettingsRowBaseState<void, SettingsSheetActionRow> {
  @override
  Widget buildTrailing(BuildContext context) {
    return GestureDetector(
      onTap: () => executeMutation(null),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
