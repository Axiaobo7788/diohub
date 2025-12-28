import 'package:diohub/common/markdown_view/builders/markdown_image_builder.dart';
import 'package:diohub/common/markdown_view/extensions/markdown_extensions.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/services/markdown/markdown_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';

/// Typedef for image source modifiers
typedef MarkdownImgSrcModifiers = String Function(MarkdownImgSrcData srcData);

/// Data class for markdown image source information
class MarkdownImgSrcData {
  MarkdownImgSrcData(this.src);

  final String src;

  bool get isHttp => src.startsWith('https://') || src.startsWith('http://');

  bool isInRepoContext(final String repoContext) =>
      src.startsWith('https://github.com/$repoContext/blob/');
}

class MarkdownRenderAPI extends StatelessWidget {
  const MarkdownRenderAPI(
    this.data, {
    super.key,
    this.repoContext,
    this.branch,
    this.buildAsync,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
    this.markdownBodyKey,
  });

  final String data;
  final String? repoContext;
  final String? branch;
  final bool? buildAsync;
  final void Function(List<({String text, String id, int level})> headings)?
      onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;
  final Key? markdownBodyKey;

  List<MarkdownImgSrcModifiers> get _repoMarkdownImgSrcModifiers =>
      <MarkdownImgSrcModifiers>[
        (final MarkdownImgSrcData srcData) {
          String src = srcData.src;
          if (!srcData.isHttp && branch != null) {
            src = 'https://raw.githubusercontent.com/$repoContext/$branch/$src';
          } else if (repoContext != null &&
              srcData.isInRepoContext(repoContext!)) {
            src = src.replaceFirst(
              'https://github.com/$repoContext/blob/',
              'https://raw.githubusercontent.com/$repoContext/',
            );
          }
          return src;
        },
      ];

  @override
  Widget build(final BuildContext context) => APIWrapper<String>.deferred(
        apiCall: ({
          required final bool refresh,
        }) async =>
            MarkdownService.renderMarkdown(data, context: repoContext),
        loadingBuilder: (final BuildContext context) => const Center(
          child: LoadingIndicator(),
        ),
        builder: (final BuildContext context, final String data) =>
            MarkdownBody(
          data,
          key: markdownBodyKey,
          buildAsync: buildAsync,
          imgSrcModifiers: _repoMarkdownImgSrcModifiers,
          onHeadingsExtracted: onHeadingsExtracted,
          onScrollToAnchor: onScrollToAnchor,
        ),
      );
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

class MarkdownBodyState extends State<MarkdownBody> {
  late dom.Document doc;

  @override
  void initState() {
    updateData(widget.content);
    _scrollCallback = widget.onScrollToAnchor;
    super.initState();
  }

  void updateData(final String data) {
    final dom.Document document = parse(data);
    final List<String> tags = <String>['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];

    for (final String element in tags) {
      final List<dom.Element> elements = document.getElementsByTagName(element);
      performModifications(elements);
    }

    final headings = <({String text, String id, int level})>[];
    final allHeadingElements =
        document.querySelectorAll('h1, h2, h3, h4, h5, h6');

    for (final dom.Element headingElement in allHeadingElements) {
      final text = headingElement.text.trim();
      if (text.isNotEmpty) {
        final id = headingElement.attributes['id'] ?? '';
        final level = int.parse(headingElement.localName!.substring(1));
        headings.add((text: text, id: id, level: level));
      }
    }

    doc = document;

    if (widget.onHeadingsExtracted != null && headings.isNotEmpty) {
      widget.onHeadingsExtracted!(headings);
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

  void performModifications(final List<dom.Element> elements) {
    for (final dom.Element node in elements) {
      node.attributes.addAll(
        <Object, String>{
          'id': node.text
              .toLowerCase()
              .replaceAll(' ', '-')
              .replaceAll(RegExp(r'[^0-9a-zA-Z-]+'), ''),
        },
      );
    }
  }

  final GlobalKey<HtmlWidgetState> htmlWidgetKey = GlobalKey<HtmlWidgetState>();

  HtmlWidgetState? get currentMarkdownState => htmlWidgetKey.currentState;

  void scrollToAnchor(String anchorId) {
    if (currentMarkdownState != null) {
      try {
        currentMarkdownState!.scrollToAnchor(anchorId);
      } catch (e) {
        // Error scrolling to anchor
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
        factoryBuilder: () => MyWidgetFactory(
          fetchState: () => currentMarkdownState,
        ),
        textStyle: widget.textStyle,
        onLoadingBuilder: (
          final BuildContext context,
          final dom.Element element,
          final double? loadingProgress,
        ) =>
            const LoadingIndicator(),
        customStylesBuilder: (final dom.Element element) {
          return switch (element.localName) {
            'a' => <String, String>{
                'text-decoration': 'none',
              },
            'blockquote' => <String, String>{
                'margin': '0',
              },
            'ol' => {
                'margin': '16',
              },
            'ul' => {
                'margin': '16',
              },
            _ => null,
          };
        },
        customWidgetBuilder: (final dom.Element element) {
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
            return buildImageTag(
              element,
              imgSrcModifiers: widget.imgSrcModifiers,
            );
          }
          return null;
        },
      );
}
