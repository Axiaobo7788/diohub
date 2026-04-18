import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horizontal strip of markdown formatting buttons for the compose bar.
///
/// Each button wraps the current selection (or inserts at cursor) with the
/// corresponding markdown syntax. Shown above the text field when focused.
class ComposeMarkdownToolbar extends ConsumerWidget {
  const ComposeMarkdownToolbar({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  void _wrapOrInsert({
    String prefix = '',
    String suffix = '',
    String linePrefix = '',
  }) {
    final TextSelection selection = controller.selection;
    final int start = selection.start;
    final int end = selection.end;
    final String text = controller.text;
    final String selected = text.substring(start, end);

    String newText;
    int newCursorStart;
    int newCursorEnd;

    if (selected.isNotEmpty) {
      newText = text.replaceRange(start, end, '$prefix$selected$suffix');
      newCursorStart = start + prefix.length;
      newCursorEnd = newCursorStart + selected.length;
    } else if (linePrefix.isNotEmpty) {
      final int lineStart = text.lastIndexOf('\n', start - 1) + 1;
      newText = text.replaceRange(lineStart, lineStart, linePrefix);
      newCursorStart = start + linePrefix.length;
      newCursorEnd = newCursorStart;
    } else {
      final String placeholder = 'text';
      newText = text.replaceRange(start, end, '$prefix$placeholder$suffix');
      newCursorStart = start + prefix.length;
      newCursorEnd = newCursorStart + placeholder.length;
    }

    controller.text = newText;
    controller.selection =
        TextSelection(baseOffset: newCursorStart, extentOffset: newCursorEnd);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: spacing.tightSpacing),
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: () => _wrapOrInsert(prefix: '**', suffix: '**'),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: () => _wrapOrInsert(prefix: '_', suffix: '_'),
          ),
          _ToolbarButton(
            icon: Icons.code,
            tooltip: 'Code',
            onPressed: () => _wrapOrInsert(prefix: '`', suffix: '`'),
          ),
          _ToolbarButton(
            icon: Icons.link,
            tooltip: 'Link',
            onPressed: () => _wrapOrInsert(prefix: '[', suffix: '](url)'),
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'List',
            onPressed: () => _wrapOrInsert(linePrefix: '- '),
          ),
          _ToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading',
            onPressed: () => _wrapOrInsert(linePrefix: '## '),
          ),
          _ToolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: () => _wrapOrInsert(linePrefix: '> '),
          ),
          _ToolbarButton(
            icon: Icons.check_box_outline_blank,
            tooltip: 'Task',
            onPressed: () => _wrapOrInsert(linePrefix: '- [ ] '),
          ),
          if (ref.read(premiumAiProvider).buildComposeAiActions(context, ref, 
            controller: controller,
            onActionSelected: (action) {},
          ) != null)
            ref.read(premiumAiProvider).buildComposeAiActions(context, ref, 
              controller: controller,
              onActionSelected: (action) {},
            )!,
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
