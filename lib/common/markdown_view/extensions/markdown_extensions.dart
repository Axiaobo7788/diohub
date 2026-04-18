import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/providers/settings/links_provider.dart';
import 'package:diohub/common/misc/code_block_view.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/copy_select_action.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/popup/animated_menu_icon.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:diohub/utils/utils.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;

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

class MyWidgetFactory extends WidgetFactory {
  MyWidgetFactory({
    required this.fetchState,
    this.onScrollToAnchor,
    this.anchorKeys,
    this.onTapLink,
  });

  final HtmlWidgetState? Function() fetchState;
  final void Function(String anchorId)? onScrollToAnchor;
  final Map<String, GlobalKey>? anchorKeys;

  /// When non-null and returns true for a given href, the link is handled
  /// in-app and the default (launch URL) is skipped.
  final bool Function(String href)? onTapLink;

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
          Future<void> onPress() async {
            await ProviderScope.containerOf(context)
                .read(clipboardServiceProvider)
                .copy(tree.element.text);
          }

          return GestureDetector(
            onLongPress: onPress,
            onTap: onPress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: context.radius(RadiusSize.medium),
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
            return TapFeedback(
              onTap: () async {
                final String anchorId = link.replaceAll('#', '');
                if (onScrollToAnchor != null) {
                  onScrollToAnchor!(anchorId);
                } else {
                  fetchState()?.scrollToAnchor(anchorId);
                }
              },
              child: child,
            );
          }
          if (onTapLink != null && onTapLink!(link)) {
            return TapFeedback(
              onTap: () async {},
              child: child,
            );
          }
          final links = ProviderScope.containerOf(context).read(linksProvider);
          final URLActions urlActions = URLActions(
            uri: Uri.parse(link),
            clipboard: ProviderScope.containerOf(context)
                .read(clipboardServiceProvider),
            openGitHubInApp: links.openGitHubInApp,
            confirmBeforeBrowser: links.confirmBeforeBrowser,
          );
          return TapFeedback(
            onTap: () async => urlActions.launchURL(context),
            onLongPress: () async => urlActions.showMenu(context),
            child: child,
          );
        },
      )
      ..wrapTaggedWidget(
        tag: 'blockquote',
        newWidgetBuilder: (
          final BuildContext context,
          final Widget child,
          final BuildTree tree,
        ) =>
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
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: CodeBlockView(
        widget.data,
        language: widget.language,
      ),
    );

    final List<ActionButtonData> actions = <ActionButtonData>[
      CheckboxActionButton(
        label: 'Wrap',
        value: wrapText,
        onChanged: (final bool value) {
          setState(() {
            wrapText = value;
          });
        },
      ),
      createCopySelectAction(
        text: widget.data,
        copy: ProviderScope.containerOf(context)
            .read(clipboardServiceProvider)
            .copy,
        selectDialogBuilder: (final BuildContext context) => SelectAndCopy(
          widget.data,
          copy: ProviderScope.containerOf(context)
              .read(clipboardServiceProvider)
              .copy,
        ),
      ),
    ];
    return NestedCardWithHeader(
      headerPadding: const EdgeInsets.symmetric(horizontal: 4),
      header: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Color(
                getLangColor(widget.language),
              ),
              shape: BoxShape.circle,
            ),
            height: 10,
            width: 10,
          ),
          if ((widget.language ?? 'Code').isNotEmpty) ...[
            context.spacing.itemGap,
            Text(
              widget.language ?? 'Code',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ],
      ),
      trailing: PopupButton(
        animatedButtonBuilder: (context, showMenu, isOpen) => TapFeedback(
          onTap: showMenu,
          child: AnimatedMenuIcon.compact(isOpen: isOpen),
        ),
        buttonBuilder: (context, showMenu) => const SizedBox.shrink(),
        actions: actions,
      ),
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
