import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

final RegExp _unsafeHeadingId = RegExp(r'[^0-9a-zA-Z-]+');

/// Sendable top-level entry used by [ResourceLoadContext.runInWorker].
MarkdownRenderArtifact parseMarkdownRenderArtifact(final String htmlContent) =>
    const MarkdownArtifactParser().parse(htmlContent);

/// Heading metadata extracted from rendered Markdown HTML.
final class MarkdownHeading {
  const MarkdownHeading({
    required this.text,
    required this.id,
    required this.level,
  });

  final String text;
  final String id;
  final int level;
}

/// Parsed HTML plus its headings. This is intentionally pure Dart so parsing
/// can run on the ResourceRuntime worker isolate.
final class ParsedMarkdownDocument {
  const ParsedMarkdownDocument({
    required this.document,
    required this.headings,
  });

  final dom.Document document;
  final List<MarkdownHeading> headings;
}

/// Immutable rendering input retained by ResourceRuntime.
///
/// Sections preserve the existing lazy README behavior: Flutter builds only
/// the HTML sections intersecting the viewport/cache range.
final class MarkdownRenderArtifact {
  const MarkdownRenderArtifact({
    required this.sections,
    required this.headings,
    required this.estimatedWeight,
  });

  final List<String> sections;
  final List<MarkdownHeading> headings;
  final int estimatedWeight;
}

/// Converts GitHub-rendered Markdown HTML into reusable, UI-independent data.
final class MarkdownArtifactParser {
  const MarkdownArtifactParser();

  ParsedMarkdownDocument parseDocument(final String htmlContent) {
    final dom.Document document = html_parser.parse(htmlContent);
    for (final dom.Element heading in document.querySelectorAll(
      'h1, h2, h3, h4, h5, h6',
    )) {
      heading.attributes['id'] = heading.text
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(_unsafeHeadingId, '');
    }

    final List<MarkdownHeading> headings = document
        .querySelectorAll('h1, h2, h3, h4, h5, h6')
        .map((final dom.Element element) {
          final String text = element.text.trim();
          return MarkdownHeading(
            text: text,
            id: element.attributes['id'] ?? '',
            level: int.parse(element.localName!.substring(1)),
          );
        })
        .where((final MarkdownHeading heading) => heading.text.isNotEmpty)
        .toList(growable: false);
    return ParsedMarkdownDocument(document: document, headings: headings);
  }

  MarkdownRenderArtifact parse(final String htmlContent) {
    final ParsedMarkdownDocument parsed = parseDocument(htmlContent);
    List<dom.Node> nodes = _meaningfulNodes(
      parsed.document.body?.nodes ?? const <dom.Node>[],
    );

    // GitHub commonly wraps README content in #readme and .markdown-body.
    // Unwrap only single-child containers, matching the existing renderer.
    while (nodes.length == 1 && nodes.first is dom.Element) {
      final dom.Element wrapper = nodes.first as dom.Element;
      if (wrapper.nodes.isEmpty) break;
      nodes = _meaningfulNodes(wrapper.nodes);
    }

    final List<List<dom.Node>> groups = <List<dom.Node>>[];
    List<dom.Node> current = <dom.Node>[];
    for (final dom.Node node in nodes) {
      if (_containsHeading(node) && current.isNotEmpty) {
        groups.add(current);
        current = <dom.Node>[];
      }
      current.add(node);
    }
    if (current.isNotEmpty) groups.add(current);

    final List<String> sections = groups
        .map(_nodesToHtml)
        .where((final String section) => section.isNotEmpty)
        .toList(growable: false);
    final int serializedLength = sections.fold<int>(
      0,
      (final int total, final String section) => total + section.length,
    );
    return MarkdownRenderArtifact(
      sections: sections,
      headings: parsed.headings,
      estimatedWeight: resourceWeightForBytes(serializedLength).clamp(1, 256),
    );
  }

  bool _containsHeading(final dom.Node node) {
    if (node is! dom.Element) return false;
    final String? name = node.localName;
    final int? headingLevel = name != null && name.length == 2
        ? int.tryParse(name.substring(1))
        : null;
    if (name != null &&
        name.startsWith('h') &&
        headingLevel != null &&
        headingLevel >= 1 &&
        headingLevel <= 6) {
      return true;
    }
    return node.localName == 'div' &&
        node.classes.contains('markdown-heading') &&
        node.querySelector('h1, h2, h3, h4, h5, h6') != null;
  }

  List<dom.Node> _meaningfulNodes(final Iterable<dom.Node> nodes) => nodes
      .where(
        (final dom.Node node) =>
            node is! dom.Text || node.data.trim().isNotEmpty,
      )
      .toList(growable: false);

  String _nodesToHtml(final List<dom.Node> nodes) {
    final dom.Element container = dom.Element.tag('div');
    for (final dom.Node node in nodes) {
      container.append(node.clone(true));
    }
    return container.innerHtml;
  }
}
