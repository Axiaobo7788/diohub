import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/misc/code_block_view.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/copy_to_clipboard.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:pull_down_button/pull_down_button.dart';

extension Tag on dom.Element {
  bool isTag(final String tag) => localName == tag;
}

extension on BuildTree {
  bool isTag(final String tag) => element.localName == tag;

  void wrapTaggedWidget({
    required final String tag,
    required final Widget? Function(
      BuildContext context,
      Widget child,
      BuildTree tree,
    ) newWidgetBuilder,
  }) {
    if (isTag(tag)) {
      register(
        BuildOp.inline(
          onRenderInlineBlock: (
            final BuildTree tree,
            final Widget child,
          ) =>
              Builder(
            builder: (final BuildContext context) =>
                newWidgetBuilder.call(
                  context,
                  child,
                  tree,
                ) ??
                child,
          ),
        ),
      );
    }
  }
}

// extension BuildTreeCopyWith on BuildTree {
//   BuildTree copyWith({
//     dom.Element? element,
//     InheritanceResolvers? inheritanceResolvers,
//     List<BuildBit>? children,
//     List<dynamic>? nonInherited,
//     LockableList<css.Declaration>? styles,
//   }) {
//     return BuildTree(
//       element: element ?? this.element,
//       inheritanceResolvers: inheritanceResolvers ?? this.inheritanceResolvers,
//       _children: children ?? this._children,
//       _nonInherited: nonInherited ?? this._nonInherited,
//       styles: styles ?? this.styles,
//     );
//   }
// }

// extension on BuildTree {
//   // ... (rest of your class)
//
//   /// Creates a copy of the current BuildTree with optional parameter overrides.
//   BuildTree copyWith({
//     dom.Element? element,
//     InheritanceResolvers? inheritanceResolvers,
//     List<BuildBit>? children,
//     List<dynamic>? nonInherited,
//     LockableList<css.Declaration>? styles,
//   }) {
//     return BuildTree(
//       element: element ?? this.element,
//       inheritanceResolvers: inheritanceResolvers ?? this.inheritanceResolvers,
//       _children: children ?? this._children,
//       _nonInherited: nonInherited ?? this._nonInherited,
//       styles: styles ?? this.styles,
//     );
//   }
// }

class MyWidgetFactory extends WidgetFactory {
  MyWidgetFactory({
    required this.fetchState,
  });

  final HtmlWidgetState? Function() fetchState;

  @override
  void parse(final BuildTree meta) {
    meta
      ..wrapTaggedWidget(
        tag: 'code',
        newWidgetBuilder: (
          final BuildContext context,
          final Widget child,
          final BuildTree tree,
        ) {
          Future<void> onPress() async => showActionsMenu(
                <PullDownMenuEntry>[
                  PullDownMenuTitle(
                    title: Text(
                      tree.element.text,
                    ),
                  ),
                  PullDownMenuItem(
                    onTap: () => copyToClipboard(tree.element.text),
                    title: 'Copy',
                    icon: MdiIcons.contentCopy,
                  ),
                ],
                context,
              );
          return GestureDetector(
            onLongPress: onPress,
            onTap: onPress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceVariant,
                borderRadius:
                    Theme.of(context).surfaceStyle.borderRadiusMedium(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
      )
      ..wrapTaggedWidget(
        tag: 'a',
        newWidgetBuilder: (
          final BuildContext context,
          final Widget child,
          final BuildTree tree,
        ) {
          final String link = tree.element.attributes['href'] ?? '';
          if (link.startsWith('#')) {
            return InkPot(
              onTap: () async => fetchState()?.scrollToAnchor(
                link.replaceAll('#', ''),
              ),
              child: child,
            );
          }
          final URLActions urlActions = URLActions(
            uri: Uri.parse(link),
          );
          return InkPot(
            onTap: () async => urlActions.launchURL(),
            onLongPress: () async => urlActions.showMenu(context),
            child: child,
          );
        },
      )
      ..wrapTaggedWidget(
        tag: 'blockquote',
        newWidgetBuilder: (final BuildContext context, final Widget child,
                final BuildTree tree) =>
            DecoratedBox(
          decoration: BoxDecoration(
            // color: context.colorScheme.surface.,
            border: Border(
              left: BorderSide(
                color: context.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: child,
          ),
        ),
      );
    super.parse(meta);
  }
}

class CodeView extends StatefulWidget {
  const CodeView(
    this.data, {
    super.key,
    this.language,
  });

  final String data;
  final String? language;

  @override
  _CodeViewState createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  bool wrapText = false;

  @override
  Widget build(final BuildContext context) {
    final Widget child = Padding(
      padding: const EdgeInsets.all(8),
      child: CodeBlockView(
        widget.data,
        language: widget.language,
      ),
    );

    return MenuInfoCard(
      title: widget.language ?? 'Code',
      leading: Container(
        decoration: BoxDecoration(
          color: Color(
            getLangColor(widget.language),
          ),
          shape: BoxShape.circle,
        ),
        height: 10,
        width: 10,
      ),
      menuBuilder: (final BuildContext context) => <PullDownMenuEntry>[
        PullDownMenuItem.selectable(
          onTap: () {
            setState(() {
              wrapText = !wrapText;
            });
          },
          selected: wrapText,
          title: 'Wrap',
          icon: MdiIcons.wrap,
        ),
        PullDownMenuActionsRow.medium(
          items: <PullDownMenuItem>[
            PullDownMenuItem(
              onTap: () async {
                await copyToClipboard(widget.data);
              },
              title: 'Copy',
              icon: MdiIcons.contentCopy,
            ),
            PullDownMenuItem(
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (final BuildContext cxt) => SelectAndCopy(
                    widget.data,
                    // onQuote: widget.onQuote,
                  ),
                );
              },
              title: 'Select',
              icon: MdiIcons.cursorText,
            ),
          ],
        ),
      ],
      child: wrapText
          ? child
          : Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: child,
              ),
            ),
    );
  }
}
