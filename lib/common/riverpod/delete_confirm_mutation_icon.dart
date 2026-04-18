import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Reusable delete icon button with confirmation sheet and mutation feedback.
///
/// Wraps [MutationState<void>] + [AppSheet.actions] confirmation.
/// Replaces inline implementations across key cards, label tiles,
/// milestone tiles, and ref tiles.
class DeleteConfirmMutationIcon extends ConsumerWidget {
  const DeleteConfirmMutationIcon({
    required this.mutation,
    required this.onDelete,
    this.confirmTitle = 'Delete',
    this.confirmExplanation,
    this.icon = Octicons.trash,
    this.iconSize = 18,
    super.key,
  });

  /// The mutation state to watch (e.g. [ref.watch(deleteXMutationProvider(...))]).
  final MutationState<void> mutation;

  /// Called when user confirms deletion.
  final VoidCallback onDelete;

  /// Title for the confirmation sheet.
  final String confirmTitle;

  /// Optional explanation text shown in the confirmation sheet.
  final String? confirmExplanation;

  /// Icon to show in idle state. Defaults to [Octicons.trash].
  final IconData icon;

  /// Icon size. Defaults to 18.
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = mutation.isLoading;

    return IconButton(
      icon: mutation.when(
        idle: () => Icon(icon, size: iconSize),
        loading: () => ButtonSpinner(size: iconSize),
        success: (_) => Icon(Icons.check_rounded, size: iconSize),
        error: (_, __) => Icon(Icons.error_outline, size: iconSize),
      ),
      onPressed: isLoading
          ? null
          : () async {
              final confirm = await AppSheet.actions<bool>(
                context,
                header: AppSheetHeader.text(
                  confirmTitle,
                  subtitle: confirmExplanation != null
                      ? Text(confirmExplanation!)
                      : null,
                ),
                actions: (ctx) => [
                  SheetAction(
                    title: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  SheetAction(
                    title: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              );
              if (confirm == true && context.mounted) {
                onDelete();
              }
            },
    );
  }
}
