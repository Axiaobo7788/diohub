import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/code_search_result.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

ColorScheme _colorScheme(BuildContext context) => Theme.of(context).colorScheme;

/// Infer language label from file path extension (e.g. .dart → Dart).
String? _inferredLanguage(String path) {
  final int dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return null;
  final String ext = path.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'dart' => 'Dart',
    'py' => 'Python',
    'js' || 'jsx' => 'JavaScript',
    'ts' || 'tsx' => 'TypeScript',
    'go' => 'Go',
    'rs' => 'Rust',
    'rb' => 'Ruby',
    'java' => 'Java',
    'kt' || 'kts' => 'Kotlin',
    'swift' => 'Swift',
    'c' => 'C',
    'cpp' || 'cc' || 'cxx' => 'C++',
    'md' => 'Markdown',
    'json' => 'JSON',
    'yaml' || 'yml' => 'YAML',
    'sh' || 'bash' => 'Shell',
    'html' || 'htm' => 'HTML',
    'css' => 'CSS',
    _ => null,
  };
}

/// Card for a code search result.
class CodeResultCard extends StatelessWidget {
  const CodeResultCard(this.data, {super.key});
  final CodeSearchResult data;

  @override
  Widget build(final BuildContext context) {
    final spacing = context.spacing;
    final RepoRef repo = RepoRef.fromFullName(data.repository.fullName);
    final String? language = _inferredLanguage(data.path);

    // Build titlePrefix: file icon
    final Widget titlePrefix = Icon(
      Octicons.file_code,
      size: 16,
      color: _colorScheme(context).primary,
    );

    // Build title: file path + language chip
    final Widget title = Row(
      children: [
        Expanded(
          child: Text(
            data.path,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (language != null) ...[
          spacing.tightGap,
          MetadataChip(label: language),
        ],
      ],
    );

    // Build metadataLine: RepoNameLabel widget
    final Widget metadataLine = RepoNameLabel(repo: repo);

    // Build supplementary: code snippet
    Widget? supplementary;
    final String snippet = data.textMatches.isNotEmpty ? data.textMatches.first.fragment : '';
    if (snippet.isNotEmpty) {
      supplementary = Container(
        padding: spacing.chipPadding,
        decoration: BoxDecoration(
          color: _colorScheme(context).surfaceContainerHighest,
          borderRadius: context.radius(RadiusSize.medium),
        ),
        child: Text(
          snippet,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: _colorScheme(context).onSurfaceVariant,
              ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: title,
      metadataLine: metadataLine,
      supplementary: supplementary,
    );
  }
}

/// Skeleton for [CodeResultCard].
class CodeResultCardSkeleton extends StatelessWidget {
  const CodeResultCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showPrefix: true,
      showMetadataLine: true,
      showTrailing: false,
      showChips: 0,
      showSupplementary: true,
    );
  }
}
