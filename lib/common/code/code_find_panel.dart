import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// Material 3 styled find (and optional replace) panel for re_editor's [CodeEditor.findBuilder].
///
/// Shows find field, match count, next/prev, case-sensitive toggle.
/// Replace controls are hidden when [readOnly] is true.
class CodeFindPanel extends StatelessWidget implements PreferredSizeWidget {
  const CodeFindPanel({
    required this.controller,
    required this.readOnly,
    super.key,
  });

  final CodeFindController controller;
  final bool readOnly;

  static const double _panelHeight = 48;
  static const double _replaceRowHeight = 48;

  @override
  Size get preferredSize {
    final CodeFindValue? value = controller.value;
    if (value == null) {
      return Size.zero;
    }
    final double h = value.replaceMode && !readOnly
        ? _panelHeight + _replaceRowHeight
        : _panelHeight;
    return Size(double.infinity, h);
  }

  @override
  Widget build(final BuildContext context) {
    final CodeFindValue? value = controller.value;
    if (value == null) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.itemSpacing,
          vertical: spacing.tightSpacing,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildFindRow(context, value, scheme, spacing),
            if (value.replaceMode && !readOnly) ...[
              SizedBox(height: spacing.tightSpacing),
              _buildReplaceRow(context, value, scheme, spacing),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFindRow(
    final BuildContext context,
    final CodeFindValue value,
    final ColorScheme scheme,
    final AppSpacing spacing,
  ) {
    final String countText = value.result == null
        ? '—'
        : '${value.result!.index + 1}/${value.result!.matches.length}';

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller.findInputController,
            focusNode: controller.findInputFocusNode,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: 'Find',
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        SizedBox(width: spacing.itemSpacing),
        SizedBox(
          width: 48,
          child: Text(
            countText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_upward, size: 20),
          onPressed: value.result == null ? null : () => controller.previousMatch(),
          tooltip: 'Previous match',
          style: IconButton.styleFrom(
            foregroundColor: scheme.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward, size: 20),
          onPressed: value.result == null ? null : () => controller.nextMatch(),
          tooltip: 'Next match',
          style: IconButton.styleFrom(
            foregroundColor: scheme.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => controller.close(),
          tooltip: 'Close',
        ),
        SizedBox(width: spacing.tightSpacing),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => controller.toggleCaseSensitive(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Aa',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: value.option.caseSensitive
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight:
                      value.option.caseSensitive ? FontWeight.w600 : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplaceRow(
    final BuildContext context,
    final CodeFindValue value,
    final ColorScheme scheme,
    final AppSpacing spacing,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller.replaceInputController,
            focusNode: controller.replaceInputFocusNode,
            maxLines: 1,
            decoration: const InputDecoration(
              hintText: 'Replace',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        SizedBox(width: spacing.itemSpacing),
        IconButton(
          icon: const Icon(Icons.check, size: 20),
          onPressed: value.result == null ? null : () => controller.replaceMatch(),
          tooltip: 'Replace',
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline, size: 20),
          onPressed: () => controller.replaceAllMatches(),
          tooltip: 'Replace all',
        ),
      ],
    );
  }

}
