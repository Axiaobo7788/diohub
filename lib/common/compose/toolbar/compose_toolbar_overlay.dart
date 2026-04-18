import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub/common/compose/saved_replies_sheet.dart';
import 'package:diohub/common/compose/toolbar/save_draft_button.dart';
import 'package:diohub/common/misc/glass_pill_surface.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/issues_pulls/widgets/image_upload_button.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/repository/issues/widgets/template_picker_sheet.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inserts [text] at the current selection in [controller]; places cursor after it.
void insertAtCursor(TextEditingController controller, String text) {
  final int start = controller.selection.start;
  final int end = controller.selection.end;
  final String current = controller.text;
  final String newText = current.replaceRange(start, end, text);
  controller.text = newText;
  controller.selection = TextSelection.collapsed(offset: start + text.length);
}

void _wrapOrInsert({
  required TextEditingController controller,
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
    const String placeholder = 'text';
    newText = text.replaceRange(start, end, '$prefix$placeholder$suffix');
    newCursorStart = start + prefix.length;
    newCursorEnd = newCursorStart + placeholder.length;
  }

  controller.text = newText;
  controller.selection =
      TextSelection(baseOffset: newCursorStart, extentOffset: newCursorEnd);
}

/// Floating glass pill toolbar above the keyboard. Shown when body field is focused.
class ComposeToolbarOverlay extends ConsumerWidget {
  const ComposeToolbarOverlay({
    required this.controller,
    required this.focusNode,
    required this.config,
    this.titleController,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ComposeConfig config;
  final TextEditingController? titleController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (BuildContext context, Widget? child) {
        if (!focusNode.hasFocus) return const SizedBox.shrink();
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: GlassPillSurface(
            borderRadius: BorderRadius.circular(24),
            glassReveal: 0.8,
            animate: false,
            innerPadding: context.spacing.chipPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.format_bold, size: 20),
                  tooltip: 'Bold',
                  onPressed: () => _wrapOrInsert(
                      controller: controller, prefix: '**', suffix: '**'),
                ),
                IconButton(
                  icon: const Icon(Icons.format_italic, size: 20),
                  tooltip: 'Italic',
                  onPressed: () => _wrapOrInsert(
                      controller: controller, prefix: '_', suffix: '_'),
                ),
                IconButton(
                  icon: const Icon(Icons.code, size: 20),
                  tooltip: 'Code',
                  onPressed: () => _wrapOrInsert(
                      controller: controller, prefix: '`', suffix: '`'),
                ),
                IconButton(
                  icon: const Icon(Icons.link, size: 20),
                  tooltip: 'Link',
                  onPressed: () => _wrapOrInsert(
                      controller: controller, prefix: '[', suffix: '](url)'),
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted, size: 20),
                  tooltip: 'List',
                  onPressed: () =>
                      _wrapOrInsert(controller: controller, linePrefix: '- '),
                ),
                IconButton(
                  icon: const Icon(Icons.title, size: 20),
                  tooltip: 'Heading',
                  onPressed: () =>
                      _wrapOrInsert(controller: controller, linePrefix: '## '),
                ),
                IconButton(
                  icon: const Icon(Icons.format_quote, size: 20),
                  tooltip: 'Quote',
                  onPressed: () =>
                      _wrapOrInsert(controller: controller, linePrefix: '> '),
                ),
                IconButton(
                  icon: const Icon(Icons.check_box_outline_blank, size: 20),
                  tooltip: 'Task',
                  onPressed: () => _wrapOrInsert(
                      controller: controller, linePrefix: '- [ ] '),
                ),
                context.spacing.itemGap,
                ImageUploadButton(
                  onInsertMarkdown: (String md) =>
                      insertAtCursor(controller, md),
                ),
                if (_showSavedReplies(config)) ...[
                  IconButton(
                    icon: const Icon(Icons.quickreply_outlined, size: 20),
                    tooltip: 'Saved Replies',
                    onPressed: () async {
                      final String? body =
                          await SavedRepliesSheet.show(context);
                      if (body != null) insertAtCursor(controller, body);
                    },
                  ),
                ],
                if (_showTemplatePicker(config, ref)) ...[
                  _TemplatePickerButton(
                    config: config,
                    controller: controller,
                  ),
                ],
                if (config.hasDraft) ...[
                  SaveDraftButton(config: config, controller: controller),
                ],
                // TODO: Implement AiComposeButton
                // AiComposeButton(
                //   controller: controller,
                //   config: config,
                //   titleController: titleController,
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  static bool _showSavedReplies(ComposeConfig config) {
    final mode = config.mode;
    return mode is NewIssueMode ||
        mode is CommentMode ||
        mode is EditCommentMode;
  }

  static bool _showTemplatePicker(ComposeConfig config, WidgetRef ref) {
    if (config.mode is! NewIssueMode) return false;
    final repo =
        ref.watch(repositoryProvider(config.repoRef)).value?.repository;
    final templates = repo?.issueTemplates?.toList() ?? <RepoIssueTemplate>[];
    return templates.isNotEmpty || (repo?.isBlankIssuesEnabled ?? false);
  }
}

/// Template picker button for New Issue compose. Replaces body with template body; confirms if body non-empty.
class _TemplatePickerButton extends ConsumerWidget {
  const _TemplatePickerButton({
    required this.config,
    required this.controller,
  });

  final ComposeConfig config;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.description_outlined, size: 20),
      tooltip: 'Choose template',
      onPressed: () async {
        final repo =
            ref.read(repositoryProvider(config.repoRef)).value?.repository;
        final templates =
            repo?.issueTemplates?.toList() ?? <RepoIssueTemplate>[];
        final selected = await TemplatePickerSheet.show(
          context,
          templates: templates,
          showBlankOption: repo?.isBlankIssuesEnabled ?? true,
        );
        if (!context.mounted || selected == null) return;
        final String newBody = selected.body ?? '';
        final String current = controller.text;
        if (current.trim().isNotEmpty) {
          final bool? replace = await showConfirmAction(
            context,
            title: 'Replace content?',
            explanation:
                'Current content will be replaced with the template. Continue?',
            confirmLabel: 'Replace',
            isDestructive: false,
          );
          if (replace != true || !context.mounted) return;
        }
        controller.text = newBody;
      },
    );
  }
}
