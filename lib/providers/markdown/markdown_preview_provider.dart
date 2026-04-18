import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/services/markdown/markdown_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for markdown preview caching.
typedef MarkdownPreviewKey = ({String markdown, String? context});

final markdownPreviewProvider =
    FutureProvider.autoDispose.family<String, MarkdownPreviewKey>(
  (final Ref ref, final MarkdownPreviewKey key) =>
      MarkdownService(ref.read(apiClientProvider)).renderMarkdown(
    key.markdown,
    context: key.context,
  ),
);
