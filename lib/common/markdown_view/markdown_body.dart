import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/markdown_view/builders/markdown_image_builder.dart';
import 'package:diohub/common/markdown_view/extensions/markdown_extensions.dart';
import 'package:diohub/common/markdown_view/markdown_render_artifact.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/common/misc/markdown_skeleton.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/widgets/section_toc_button.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:sliver_tools/sliver_tools.dart';

/// Typedef for image source modifiers
typedef MarkdownImgSrcModifiers = String Function(MarkdownImgSrcData srcData);

/// Data class for markdown image source information
class MarkdownImgSrcData {
  MarkdownImgSrcData(this.src);

  final String src;

  bool get isHttp => src.startsWith('https://') || src.startsWith('http://');

  bool isInRepoContext(final ServerConfig server, final String repoContext) =>
      src.startsWith('${server.webBaseUrl}/$repoContext/blob/');
}

/// Create image source modifiers for repository context.
/// [serverConfig] is used to build raw content URLs for the active server.
List<MarkdownImgSrcModifiers> createRepoMarkdownImgSrcModifiers(
  final String? repoContext,
  final String? branch,
  final ServerConfig serverConfig,
) {
  if (repoContext == null) return <MarkdownImgSrcModifiers>[];
  final List<String> parts = repoContext.split('/');
  final String owner = parts.isNotEmpty ? parts[0] : '';
  final String repo = parts.length > 1 ? parts[1] : '';
  return <MarkdownImgSrcModifiers>[
    (final MarkdownImgSrcData srcData) {
      String src = srcData.src;
      if (!srcData.isHttp &&
          branch != null &&
          owner.isNotEmpty &&
          repo.isNotEmpty) {
        src = serverConfig.rawUrl(owner, repo, branch, src).toString();
      } else if (srcData.isInRepoContext(serverConfig, repoContext)) {
        src = src.replaceFirst(
          '${serverConfig.webBaseUrl}/$repoContext/blob/',
          '${serverConfig.rawContentBaseUrl}/$repoContext/',
        );
      }
      return src;
    },
  ];
}

/// Create image source modifiers for wiki context.
/// [serverConfig] is used to build raw wiki image URLs.
List<MarkdownImgSrcModifiers> createWikiMarkdownImgSrcModifiers(
  final String repoFullName,
  final ServerConfig serverConfig,
) {
  final List<String> parts = repoFullName.split('/');
  final String owner = parts.isNotEmpty ? parts[0] : '';
  final String repo = parts.length > 1 ? parts[1] : '';
  return <MarkdownImgSrcModifiers>[
    (final MarkdownImgSrcData srcData) {
      String src = srcData.src;
      if (!srcData.isHttp && owner.isNotEmpty && repo.isNotEmpty) {
        src = serverConfig.wikiRawUrl(owner, repo, src).toString();
      } else if (src.contains(serverConfig.host) && src.contains('/wiki/')) {
        final Uri uri = Uri.parse(src);
        if (uri.pathSegments.contains('wiki') &&
            !src.contains(serverConfig.rawContentBaseUrl)) {
          final int wikiIdx = uri.pathSegments.indexOf('wiki');
          final List<String> rest = uri.pathSegments.sublist(wikiIdx + 1);
          if (rest.isNotEmpty) {
            src = serverConfig
                .wikiRawUrl(owner, repo, rest.join('/'))
                .toString();
          }
        }
      }
      return src;
    },
  ];
}

extension RepoRefMarkdownImg on RepoRef {
  List<MarkdownImgSrcModifiers> markdownImgModifiers(
    String? branch,
    ServerConfig server,
  ) => createRepoMarkdownImgSrcModifiers(fullName, branch, server);

  List<MarkdownImgSrcModifiers> wikiImgModifiers(ServerConfig server) =>
      createWikiMarkdownImgSrcModifiers(fullName, server);
}

/// Mixin for shared markdown parsing logic
mixin MarkdownParserMixin {
  /// Parse HTML document, inject heading IDs, and extract heading list
  ({dom.Document doc, List<({String text, String id, int level})> headings})
  parseMarkdownDoc(final String htmlContent) {
    final ParsedMarkdownDocument result = const MarkdownArtifactParser()
        .parseDocument(htmlContent);
    return (
      doc: result.document,
      headings: result.headings
          .map(
            (final MarkdownHeading heading) =>
                (text: heading.text, id: heading.id, level: heading.level),
          )
          .toList(growable: false),
    );
  }

  /// Shared custom styles builder for HtmlWidget
  Map<String, String>? markdownStylesBuilder(final dom.Element element) =>
      switch (element.localName) {
        'a' => <String, String>{'text-decoration': 'none'},
        'blockquote' => <String, String>{'margin': '0'},
        'ol' => <String, String>{'margin': '16'},
        'ul' => <String, String>{'margin': '16'},
        _ => null,
      };

  /// Shared custom widget builder for HtmlWidget
  Widget? markdownWidgetBuilder(
    final dom.Element element,
    final List<MarkdownImgSrcModifiers>? imgSrcModifiers,
  ) {
    if (element.children.isNotEmpty) {
      if (element.children.first.isTag('pre')) {
        return CodeView(
          element.text,
          language: element.attributes['class']
              ?.replaceAll('highlight highlight-source-', '')
              .split(' ')
              .first,
        );
      }
    }

    if (element.isTag('img')) {
      return buildImageTag(element, imgSrcModifiers: imgSrcModifiers);
    }
    return null;
  }
}

/// Internal data class for grouping nodes during recursive split
class _NodeGroup {
  const _NodeGroup({required this.heading, required this.contentNodes});

  /// The heading element (null for preamble)
  final dom.Element? heading;

  /// The content nodes under this heading
  final List<dom.Node> contentNodes;
}

class MarkdownBody extends StatefulWidget {
  const MarkdownBody(
    this.content, {
    super.key,
    this.imgSrcModifiers,
    this.buildAsync,
    this.textStyle,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
  });

  final bool? buildAsync;
  final String content;
  final List<MarkdownImgSrcModifiers>? imgSrcModifiers;
  final TextStyle? textStyle;
  final void Function(List<({String text, String id, int level})> headings)?
  onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;

  @override
  MarkdownBodyState createState() => MarkdownBodyState();
}

class MarkdownBodyState extends State<MarkdownBody> with MarkdownParserMixin {
  late dom.Document doc;

  @override
  void initState() {
    updateData(widget.content);
    _scrollCallback = widget.onScrollToAnchor;
    super.initState();
  }

  void updateData(final String data) {
    final ({
      dom.Document doc,
      List<({String id, int level, String text})> headings,
    })
    result = parseMarkdownDoc(data);
    doc = result.doc;

    if (widget.onHeadingsExtracted != null && result.headings.isNotEmpty) {
      widget.onHeadingsExtracted!(result.headings);
    }
  }

  @override
  void didUpdateWidget(covariant final MarkdownBody oldWidget) {
    if (oldWidget.content != widget.content) {
      updateData(widget.content);
    }
    if (oldWidget.onScrollToAnchor != widget.onScrollToAnchor) {
      _scrollCallback = widget.onScrollToAnchor;
    }
    super.didUpdateWidget(oldWidget);
  }

  void Function(String anchorId)? _scrollCallback;

  final GlobalKey<HtmlWidgetState> htmlWidgetKey = GlobalKey<HtmlWidgetState>();

  HtmlWidgetState? get currentMarkdownState => htmlWidgetKey.currentState;

  void scrollToAnchor(final String anchorId) {
    if (currentMarkdownState != null) {
      try {
        currentMarkdownState!.scrollToAnchor(anchorId);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Error scrolling to anchor: $anchorId',
          error: e,
          stackTrace: stackTrace,
          tag: 'Markdown',
        );
      }
    }
    if (_scrollCallback != null) {
      _scrollCallback!.call(anchorId);
    }
  }

  @override
  Widget build(final BuildContext context) => HtmlWidget(
    doc.outerHtml,
    key: htmlWidgetKey,
    buildAsync: widget.buildAsync,
    factoryBuilder: () =>
        MyWidgetFactory(fetchState: () => currentMarkdownState),
    textStyle: widget.textStyle,
    onLoadingBuilder:
        (
          final BuildContext context,
          final dom.Element element,
          final double? loadingProgress,
        ) => const ShimmerScope(child: MarkdownSkeleton()),
    customStylesBuilder: markdownStylesBuilder,
    customWidgetBuilder: (final dom.Element element) =>
        markdownWidgetBuilder(element, widget.imgSrcModifiers),
  );
}

/// Sliver-based markdown body with optional legacy sticky headings.
class SliverMarkdownBody extends StatefulWidget {
  const SliverMarkdownBody(
    this.content, {
    super.key,
    this.imgSrcModifiers,
    this.buildAsync,
    this.textStyle,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
    this.contentPadding,
    this.onTapLink,
    this.stickyHeadings = true,
    this.artifact,
  });

  final String content;
  final List<MarkdownImgSrcModifiers>? imgSrcModifiers;
  final bool? buildAsync;
  final TextStyle? textStyle;
  final void Function(List<({String text, String id, int level})> headings)?
  onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;
  final EdgeInsets? contentPadding;
  final MarkdownRenderArtifact? artifact;

  /// Whether headings use the legacy nested sticky-header renderer.
  ///
  /// Repository README pages disable this. A README can contain dozens of
  /// nested headings, and combining a [SliverStickyHeader] for every heading
  /// with nested [MultiSliver] children can leave the third-party sticky
  /// renderer without child geometry during layout.
  final bool stickyHeadings;

  /// When non-null and returns true for a given href, the link is handled
  /// in-app (e.g. wiki page navigation) and the default launch URL is skipped.
  final bool Function(String href)? onTapLink;

  @override
  SliverMarkdownBodyState createState() => SliverMarkdownBodyState();
}

class SliverMarkdownBodyState extends State<SliverMarkdownBody>
    with MarkdownParserMixin {
  late dom.Document doc;
  final Map<String, GlobalKey> _anchorKeys =
      <String, GlobalKey<State<StatefulWidget>>>{};
  List<({String text, String id, int level})> _headings =
      <({String id, int level, String text})>[];

  /// Pre-allocated GlobalKeys for HtmlWidget sections — created/resized in
  /// [_updateData] when content changes, reused by index in [build] so that
  /// Flutter's reconciliation keeps the Elements alive across parent rebuilds.
  final List<GlobalKey<HtmlWidgetState>> _sectionHtmlKeys =
      <GlobalKey<HtmlWidgetState>>[];

  /// Index counter reset at the start of each [build], incremented by
  /// [_buildHtmlContent] to pick the next pre-allocated key.
  int _nextSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateData(widget.content, defer: true);
  }

  @override
  void didUpdateWidget(covariant final SliverMarkdownBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        !identical(oldWidget.artifact, widget.artifact)) {
      _updateData(widget.content);
    }
  }

  void _updateData(final String data, {final bool defer = false}) {
    _anchorKeys.clear();
    final MarkdownRenderArtifact? artifact = widget.artifact;
    if (artifact == null) {
      final ({
        dom.Document doc,
        List<({String id, int level, String text})> headings,
      })
      result = parseMarkdownDoc(data);
      doc = result.doc;
      _headings = result.headings;
    } else {
      _headings = artifact.headings
          .map(
            (final MarkdownHeading heading) =>
                (text: heading.text, id: heading.id, level: heading.level),
          )
          .toList(growable: false);
    }

    // Create GlobalKeys for all headings
    for (final ({String id, int level, String text}) heading in _headings) {
      if (heading.id.isNotEmpty && !_anchorKeys.containsKey(heading.id)) {
        _anchorKeys[heading.id] = GlobalKey();
      }
    }

    // Pre-allocate GlobalKeys for HtmlWidget sections. The recursive layout
    // creates one HtmlWidget per leaf section (base case at level > 6), plus
    // one per heading group that has no sub-headings. We over-estimate slightly
    // (headings + 1 for preamble) — extra keys are harmless.
    final int sectionCount =
        artifact?.sections.length ?? (_headings.length + 1).clamp(1, 256);
    _resizeSectionKeys(sectionCount);

    if (widget.onHeadingsExtracted != null && _headings.isNotEmpty) {
      if (defer) {
        // Defer to avoid setState-during-build when called from initState.
        WidgetsBinding.instance.addPostFrameCallback((final _) {
          if (mounted) {
            widget.onHeadingsExtracted!(_headings);
          }
        });
      } else {
        widget.onHeadingsExtracted!(_headings);
      }
    }
  }

  /// Grow or shrink [_sectionHtmlKeys] to [count]. Existing keys are kept
  /// so their Elements survive content-unchanged rebuilds.
  void _resizeSectionKeys(final int count) {
    while (_sectionHtmlKeys.length < count) {
      _sectionHtmlKeys.add(GlobalKey<HtmlWidgetState>());
    }
    if (_sectionHtmlKeys.length > count) {
      _sectionHtmlKeys.removeRange(count, _sectionHtmlKeys.length);
    }
  }

  /// Try to extract a heading element of [tag] from a node.
  ///
  /// GitHub wraps headings in `<div class="markdown-heading"><h2>…</h2></div>`.
  /// This returns the inner heading element if [node] is such a wrapper,
  /// or [node] itself if it is directly a heading of [tag].
  dom.Element? _extractHeading(final dom.Node node, final String tag) {
    if (node is! dom.Element) return null;
    if (node.localName == tag) return node;
    // Check for wrapper div (e.g. <div class="markdown-heading">)
    if (node.localName == 'div' &&
        (node.classes.contains('markdown-heading') ||
            (node.attributes['class']?.contains('markdown-heading') ??
                false))) {
      // Look for the heading child inside the wrapper
      for (final dom.Element child in node.children) {
        if (child.localName == tag) return child;
      }
    }
    return null;
  }

  /// Split nodes at a specific heading tag, also detecting headings wrapped
  /// in `<div class="markdown-heading">` wrappers (GitHub's README format).
  List<_NodeGroup> _splitNodesAtTag(
    final List<dom.Node> nodes,
    final String tag,
  ) {
    final List<_NodeGroup> groups = <_NodeGroup>[];
    dom.Element? currentHeading;
    List<dom.Node> currentNodes = <dom.Node>[];

    for (final dom.Node node in nodes) {
      final dom.Element? heading = _extractHeading(node, tag);
      if (heading != null) {
        // Flush previous group
        groups.add(
          _NodeGroup(
            heading: currentHeading,
            contentNodes: List.from(currentNodes),
          ),
        );
        currentHeading = heading;
        currentNodes = <dom.Node>[];
      } else {
        currentNodes.add(node);
      }
    }

    // Flush last group
    groups.add(
      _NodeGroup(
        heading: currentHeading,
        contentNodes: List.from(currentNodes),
      ),
    );

    return groups;
  }

  /// Recursively build slivers from nodes, splitting at each heading level
  List<Widget> _buildSliversFromNodes(
    final List<dom.Node> nodes,
    final int currentLevel,
  ) {
    if (currentLevel > 6) {
      // Base case: no more heading levels to split at, render as HtmlWidget
      return <Widget>[SliverToBoxAdapter(child: _buildHtmlContent(nodes))];
    }

    // Split nodes at h{currentLevel} boundaries
    final List<_NodeGroup> groups = _splitNodesAtTag(nodes, 'h$currentLevel');

    // If no splits happened (no headings at this level), try next level
    if (groups.length == 1 && groups.first.heading == null) {
      return _buildSliversFromNodes(nodes, currentLevel + 1);
    }

    final List<Widget> slivers = <Widget>[];
    for (final _NodeGroup group in groups) {
      if (group.heading == null && group.contentNodes.isNotEmpty) {
        // Preamble content before first heading at this level
        // Recurse into it to find deeper headings
        slivers.addAll(
          _buildSliversFromNodes(group.contentNodes, currentLevel + 1),
        );
      } else if (group.heading != null) {
        // Recursively build child slivers for content under this heading
        final List<Widget> childSlivers = _buildSliversFromNodes(
          group.contentNodes,
          currentLevel + 1,
        );

        // Get anchor key for this heading
        final String headingId = group.heading!.attributes['id'] ?? '';
        final GlobalKey<State<StatefulWidget>>? anchorKey =
            headingId.isNotEmpty && _anchorKeys.containsKey(headingId)
            ? _anchorKeys[headingId]!
            : null;

        final bool isFirst = _nextHeadingIsFirst;
        if (isFirst) _nextHeadingIsFirst = false;
        final SectionTocButton? trailing = isFirst && _headings.isNotEmpty
            ? SectionTocButton(
                entries: _headings
                    .map(
                      (final ({String id, int level, String text}) h) =>
                          SectionTocEntry(
                            id: h.id,
                            title: h.text,
                            level: h.level,
                          ),
                    )
                    .toList(),
                onSelect: scrollToAnchor,
              )
            : null;

        slivers.add(
          PinnedGlassHeader(
            headerBuilder:
                (
                  final BuildContext context,
                  final SliverStickyHeaderState state,
                ) => _buildHeadingWidget(group, state, trailing: trailing),
            style: GlassPillStyle.section(
              context,
              restingColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            sliver: MultiSliver(
              children: <Widget>[
                // Place anchor key on SizedBox.shrink at start of content
                if (anchorKey != null)
                  SliverToBoxAdapter(child: SizedBox.shrink(key: anchorKey)),
                ...childSlivers,
              ],
            ),
          ),
        );
      }
    }
    return slivers;
  }

  /// Builds non-sticky documents lazily, one heading section at a time.
  ///
  /// A [MultiSliver] must visit every child to determine its combined scroll
  /// extent. Repository READMEs can contain dozens of expensive HTML/code
  /// sections, so use one [SliverList] and materialize only the viewport/cache
  /// range instead.
  Widget _buildLazyFlatSliverFromNodes(final List<dom.Node> nodes) {
    final List<List<dom.Node>> sections = <List<dom.Node>>[];
    List<dom.Node> current = <dom.Node>[];

    for (final dom.Node node in nodes) {
      dom.Element? heading;
      for (int level = 1; level <= 6 && heading == null; level++) {
        heading = _extractHeading(node, 'h$level');
      }
      if (heading != null && current.isNotEmpty) {
        sections.add(current);
        current = <dom.Node>[];
      }
      current.add(node);
    }
    if (current.isNotEmpty) {
      sections.add(current);
    }

    if (sections.isEmpty) {
      return SliverToBoxAdapter(child: _buildHtmlContent(nodes));
    }

    return SliverList.builder(
      itemCount: sections.length,
      itemBuilder: (final BuildContext context, final int index) =>
          _buildHtmlContent(sections[index], sectionIndex: index),
    );
  }

  /// Build HtmlWidget for a list of nodes, using a pre-allocated GlobalKey.
  Widget _buildHtmlContent(
    final List<dom.Node> nodes, {
    final int? sectionIndex,
  }) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    return _buildHtmlString(_nodesToHtml(nodes), sectionIndex: sectionIndex);
  }

  Widget _buildHtmlString(final String html, {final int? sectionIndex}) {
    if (html.isEmpty) return const SizedBox.shrink();

    // Use pre-allocated key by index — stable across parent rebuilds.
    // If we exceed pre-allocated count (edge case), create on the fly.
    final GlobalKey<HtmlWidgetState> sectionHtmlKey;
    final int keyIndex = sectionIndex ?? _nextSectionIndex++;
    if (keyIndex < _sectionHtmlKeys.length) {
      sectionHtmlKey = _sectionHtmlKeys[keyIndex];
    } else {
      sectionHtmlKey = GlobalKey<HtmlWidgetState>();
      _sectionHtmlKeys.add(sectionHtmlKey);
    }

    final HtmlWidget htmlWidget = HtmlWidget(
      '<div>$html</div>',
      key: sectionHtmlKey,
      buildAsync: widget.buildAsync,
      factoryBuilder: () => MyWidgetFactory(
        fetchState: () => sectionHtmlKey.currentState,
        onScrollToAnchor: scrollToAnchor,
        anchorKeys: _anchorKeys,
        onTapLink: widget.onTapLink,
      ),
      textStyle: widget.textStyle,
      onLoadingBuilder:
          (
            final BuildContext context,
            final dom.Element element,
            final double? loadingProgress,
          ) => const ShimmerScope(child: MarkdownSkeleton()),
      customStylesBuilder: markdownStylesBuilder,
      customWidgetBuilder: (final dom.Element element) =>
          markdownWidgetBuilder(element, widget.imgSrcModifiers),
    );

    if (widget.contentPadding != null) {
      return Padding(padding: widget.contentPadding!, child: htmlWidget);
    }

    return htmlWidget;
  }

  String _nodesToHtml(final List<dom.Node> nodes) {
    if (nodes.isEmpty) return '';

    // Create a temporary div to hold the nodes
    final dom.Element tempDiv = dom.Element.tag('div');
    for (final dom.Node node in nodes) {
      tempDiv.append(node.clone(true));
    }

    return tempDiv.innerHtml;
  }

  void scrollToAnchor(final String anchorId) {
    final GlobalKey<State<StatefulWidget>>? key = _anchorKeys[anchorId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Fallback: try each section's HtmlWidgetState for non-heading anchors
    for (final GlobalKey<HtmlWidgetState> sectionKey in _sectionHtmlKeys) {
      try {
        sectionKey.currentState?.scrollToAnchor(anchorId);
        return;
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Error scrolling to anchor in section',
          error: e,
          stackTrace: stackTrace,
          tag: 'Markdown',
        );
      }
    }
  }

  Widget _buildHeadingWidget(
    final _NodeGroup group,
    final SliverStickyHeaderState state, {
    final Widget? trailing,
  }) {
    final dom.Element heading = group.heading!;
    final int level = int.parse(heading.localName!.substring(1));
    final String headingText = heading.text.trim();

    final TextStyle expandedStyle = _headingTextStyle(context, level);
    final TextStyle pinnedStyle = switch (level) {
      1 => context.textTheme.titleMedium!,
      2 => context.textTheme.titleSmall!,
      3 => context.textTheme.bodyLarge!,
      4 => context.textTheme.bodyMedium!,
      5 => context.textTheme.bodySmall!,
      6 => context.textTheme.bodySmall!,
      _ => context.textTheme.bodyMedium!,
    }.copyWith(fontWeight: FontWeight.bold);

    final AnimatedDefaultTextStyle content = AnimatedDefaultTextStyle(
      style: state.isPinned ? pinnedStyle : expandedStyle,
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          headingText,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );

    if (trailing == null) return content;
    return Row(
      children: <Widget>[
        Expanded(child: content),
        context.spacing.itemGap,
        trailing,
      ],
    );
  }

  TextStyle _headingTextStyle(final BuildContext context, final int level) {
    final TextStyle baseStyle =
        context.textTheme.bodyMedium ?? const TextStyle();

    // Match HtmlWidget's default heading sizes
    return switch (level) {
      1 => baseStyle.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
      2 => baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
      3 => baseStyle.copyWith(fontSize: 18.72, fontWeight: FontWeight.bold),
      4 => baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
      5 => baseStyle.copyWith(fontSize: 13.28, fontWeight: FontWeight.bold),
      6 => baseStyle.copyWith(fontSize: 10.72, fontWeight: FontWeight.bold),
      _ => baseStyle,
    };
  }

  /// True until the first PinnedGlassHeader for a heading is built (markdown:
  /// pill only on highest available heading).
  bool _nextHeadingIsFirst = true;

  @override
  Widget build(final BuildContext context) {
    // Reset section index counter — _buildHtmlContent will increment it.
    _nextSectionIndex = 0;
    _nextHeadingIsFirst = true;

    final MarkdownRenderArtifact? artifact = widget.artifact;
    if (artifact != null) {
      if (artifact.sections.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverList.builder(
        itemCount: artifact.sections.length,
        itemBuilder: (final BuildContext context, final int index) =>
            _buildHtmlString(artifact.sections[index], sectionIndex: index),
      );
    }

    final List<dom.Node> bodyNodes = doc.body?.nodes.toList() ?? <dom.Node>[];

    // GitHub (and some parsers) nest the README in multiple wrapper elements
    // (e.g. <body><div id="readme"><article class="markdown-body">...</article></div></body>).
    // Recursively unwrap single-child wrappers so we can split at h1–h6.
    List<dom.Node> nodesToUse = bodyNodes;
    while (nodesToUse.length == 1 && nodesToUse.first is dom.Element) {
      final dom.Element wrapper = nodesToUse.first as dom.Element;
      if (wrapper.nodes.isEmpty) break;
      nodesToUse = wrapper.nodes.toList();
    }

    if (!widget.stickyHeadings) {
      return _buildLazyFlatSliverFromNodes(nodesToUse);
    }

    final List<Widget> slivers = _buildSliversFromNodes(nodesToUse, 1);

    if (slivers.isEmpty) {
      return SliverToBoxAdapter(child: _buildHtmlContent(nodesToUse));
    }

    return MultiSliver(children: slivers);
  }
}
