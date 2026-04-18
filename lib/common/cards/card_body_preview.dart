import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';

/// A consistent wrapper for displaying body/description preview in cards
/// Uses TrimmableMarkdownContent for rendering markdown (markdown only; no HTML path).
class CardBodyPreview extends StatelessWidget {
  const CardBodyPreview({
    this.body,
    this.repoName,
    super.key,
  });

  final String? body;
  final String? repoName;

  @override
  Widget build(final BuildContext context) {
    final String content = (body ?? '').trim();
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color textColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: Opacities.secondary);

    return DefaultTextStyle.merge(
      style: TextStyle(color: textColor),
      child: InlineContainer(
        child: TrimmableMarkdownContent(
          text: body,
          repo: repoName,
        ),
      ),
    );
  }
}
