import 'package:diohub/common/compose/editor/markdown_syntax_span_builder.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

/// Live-formatting markdown text field for compose body.
/// Renders inline syntax (bold, italic, code, links, mentions) as styled spans.
/// Raw markdown is preserved in [controller].text for submit/save.
class MarkdownLiveTextField extends StatelessWidget {
  const MarkdownLiveTextField({
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.placeholder,
    this.maxLines,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ExtendedTextField(
      controller: controller,
      focusNode: focusNode,
      specialTextSpanBuilder: MarkdownSyntaxSpanBuilder(context: context),
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: placeholder,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}
