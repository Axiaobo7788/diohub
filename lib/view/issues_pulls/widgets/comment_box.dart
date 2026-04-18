import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/common/compose/saved_replies_sheet.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/common/compose/editor/markdown_live_text_field.dart';
import 'package:diohub/providers/markdown/markdown_preview_provider.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/view/issues_pulls/widgets/image_upload_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef LoadingFuture = Future<void> Function();

Future<void> showCommentSheet(
  final BuildContext context, {
  required final LoadingFuture onSubmit,
  required final String? initialData,
  required final ValueChanged<String> onChanged,
  required final RepoRef repo,
  final String type = 'Comment',

  /// When non-null, identifies the review thread (e.g. for "Reply to thread").
  final String? threadId,

  /// When true and [onResolveOnSubmitChanged] is set, sheet shows "Resolve thread" checkbox.
  final bool initialResolveOnSubmit = false,

  /// Called when user toggles "Resolve thread"; caller may use this in [onSubmit].
  final ValueChanged<bool>? onResolveOnSubmitChanged,
}) async {
  final GlobalKey<CommentBoxState> commentBoxKey = GlobalKey<CommentBoxState>();
  bool markdownView = false;
  bool loading = false;
  bool resolveOnSubmit = initialResolveOnSubmit;
  await AppSheet.form(
    context,
    headerBuilder: (final BuildContext context, final StateSetter setState) =>
        Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          onPressed: () {
            setState(
              () {
                markdownView = !markdownView;
              },
            );
          },
          icon: const Icon(Icons.remove_red_eye_rounded),
        ),
        IconButton(
          onPressed: () async {
            final body = await SavedRepliesSheet.show(context);
            if (body != null && context.mounted) {
              commentBoxKey.currentState?.insertText(body);
            }
          },
          icon: const Icon(Icons.bookmark_outline_rounded),
          tooltip: 'Saved replies',
        ),
        Expanded(
          child: TapFeedback(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding: EdgeInsets.all(context.spacing.itemSpacing),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      type,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: loading
              ? null
              : () async {
                  setState(() {
                    loading = true;
                  });
                  // ignore: prefer_async_await
                  await onSubmit().then((final _) {
                    setState(
                      () {
                        loading = false;
                      },
                    );
                    Navigator.pop(context);
                  });
                },
          icon: loading
              ? const LoadingIndicator()
              : const Icon(
                  Icons.reply,
                ),
        ),
      ],
    ),
    bodyBuilder: (
      final BuildContext context,
      final StateSetter setState,
    ) =>
        Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CommentBox(
          key: commentBoxKey,
          repo: repo,
          markdownView: markdownView,
          initialData: initialData,
          onChanged: loading ? null : onChanged,
        ),
        if (threadId != null && onResolveOnSubmitChanged != null)
          CheckboxListTile(
            value: resolveOnSubmit,
            onChanged: (final bool? value) {
              if (value != null) {
                setState(() => resolveOnSubmit = value);
                onResolveOnSubmitChanged(value);
              }
            },
            title: const Text('Resolve thread when replying'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    ),
  );
}

class CommentBox extends StatefulWidget {
  const CommentBox({
    required this.repo,
    required this.initialData,
    required this.onChanged,
    required this.markdownView,
    super.key,
    this.scrollController,
  });

  final RepoRef repo;
  final String? initialData;
  final ValueChanged<String>? onChanged;
  final bool markdownView;
  final ScrollController? scrollController;

  @override
  CommentBoxState createState() => CommentBoxState();
}

class CommentBoxState extends State<CommentBox> {
  bool loading = false;
  late String data;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    data = widget.initialData ?? '';
    _controller = TextEditingController(text: data);
    _focusNode = FocusNode();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CommentBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData &&
        widget.initialData != null &&
        widget.initialData != _controller.text) {
      data = widget.initialData!;
      _controller.text = data;
    }
  }

  void _onControllerChanged() {
    if (data != _controller.text) {
      setState(() => data = _controller.text);
      widget.onChanged?.call(data);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Inserts [text] at the end of the current comment body and notifies [onChanged].
  void insertText(final String text) {
    data = data + text;
    _controller.text = data;
    widget.onChanged?.call(data);
  }

  @override
  Widget build(final BuildContext context) {
    Widget textBox() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.onChanged != null)
              Row(
                children: <Widget>[
                  ImageUploadButton(
                    onInsertMarkdown: (final String markdown) {
                      insertText(markdown);
                    },
                  ),
                ],
              ),
            MarkdownLiveTextField(
              controller: _controller,
              focusNode: _focusNode,
              placeholder: 'Leave a comment',
              maxLines: 8,
            ),
          ],
        );

    return widget.markdownView
        ? Consumer(
            builder:
                (final BuildContext context, final WidgetRef ref, final _) {
              final previewAsync = ref.watch(
                markdownPreviewProvider((
                  markdown: data,
                  context: widget.repo.fullName,
                )),
              );
              return AsyncValueBuilder<String>(
                value: previewAsync,
                loading: (_) => const Center(child: LoadingIndicator()),
                data: (final String renderedHtml) => MarkdownBody(
                  renderedHtml,
                  imgSrcModifiers: widget.repo.markdownImgModifiers(
                    null,
                    ref.read(activeServerConfigProvider),
                  ),
                ),
              );
            },
          )
        : textBox();
  }
}

