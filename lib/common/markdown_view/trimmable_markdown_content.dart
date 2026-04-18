import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/utils/markdown_to_html.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class TrimmableMarkdownContent extends ConsumerWidget {
  const TrimmableMarkdownContent({
    this.text,
    this.textHtml,
    this.repo,
    this.branch,
    this.maxLengthForIndicator = 200,
    super.key,
  });

  final String? text;
  final String? textHtml;
  final String? repo;
  final String? branch;
  final int maxLengthForIndicator;

  /// Strips HTML comments and other invisible markdown content
  /// to calculate truncation based on visible content length
  static String _stripInvisibleContent(final String markdown) {
    // Remove HTML comments (<!-- ... -->)
    String cleaned = markdown.replaceAll(
      RegExp(r'<!--[\s\S]*?-->', multiLine: true),
      '',
    );

    // Remove HTML directives like [//]: # (comment)
    cleaned = cleaned.replaceAll(
      RegExp(r'\[//\]:\s*#\s*\([^)]*\)', multiLine: true),
      '',
    );

    return cleaned;
  }

  List<MarkdownImgSrcModifiers>? _imgSrcModifiers(WidgetRef ref) {
    if (repo == null) return null;
    final server = ref.read(activeServerConfigProvider);
    return createRepoMarkdownImgSrcModifiers(repo, branch, server);
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bool useHtml = textHtml != null && textHtml!.trim().isNotEmpty;
    final bool useText = text != null;

    if (!useHtml && !useText) {
      return const SizedBox.shrink();
    }

    String? content;
    if (useHtml) {
      // Prefer server-rendered HTML from GitHub
      content = textHtml!.trim();
    } else {
      // Fallback: client-side markdown to HTML
      final String cleanedText = _stripInvisibleContent(text!);
      final bool shouldTruncate = cleanedText.length > maxLengthForIndicator;
      if (shouldTruncate) {
        String textToConvert = cleanedText.substring(0, maxLengthForIndicator);
        textToConvert = '${textToConvert.trim()}...';
        content = mdToHtml(
          textToConvert,
          repo: repo,
          serverConfig: ref.read(activeServerConfigProvider),
        );
      } else {
        content = mdToHtml(
          text!,
          repo: repo,
          serverConfig: ref.read(activeServerConfigProvider),
        );
      }
    }

    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MarkdownBody(
          content,
          buildAsync: false,
          imgSrcModifiers: _imgSrcModifiers(ref),
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.strong,
                height: 1.35,
                fontSize: 13,
              ),
          ),
      ],
    );
  }
}
