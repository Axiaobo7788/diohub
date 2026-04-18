import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/copy_select_action.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/popup/animated_menu_icon.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart'
    show Actor;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/providers/issue_pulls/reactions_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class BaseComment extends ConsumerStatefulWidget {
  const BaseComment({
    required this.onQuote,
    required this.isMinimized,
    required this.reactions,
    required this.viewerCanDelete,
    required this.viewerCanMinimize,
    required this.viewerCannotUpdateReasons,
    required this.viewerCanReact,
    required this.viewerCanUpdate,
    required this.viewerDidAuthor,
    required this.createdAt,
    required this.author,
    required this.body,
    required this.lastEditedAt,
    required this.bodyHTML,
    required this.authorAssociation,
    required this.resourceUri,
    required this.commentDraftKey,
    super.key,
    this.minimizedReason,
    this.leading,
    this.description,
    this.footer,
    this.footerPadding = const EdgeInsets.only(top: 8, left: 8, right: 8),
    this.onEdit,
    this.onDelete,
    this.onMinimize,
    this.onUnminimize,
    this.repoRef,
    this.commentDatabaseId,
    this.commentNodeId,
    this.pinActionBuilder,
  });

  final Actor? author;
  final CommentAuthorAssociation authorAssociation;
  final String body;
  final IconData? leading;
  final String? bodyHTML;
  final List<ReactionGroupData> reactions;
  final DateTime? lastEditedAt;
  final DateTime createdAt;
  final bool isMinimized;
  final String? minimizedReason;
  final bool viewerCanMinimize;
  final bool viewerCanDelete;
  final bool viewerCanUpdate;
  final bool viewerDidAuthor;

  // Note: Nullable until API is final.
  final List<CommentCannotUpdateReason>? viewerCannotUpdateReasons;
  final bool viewerCanReact;
  final Widget? footer;
  final String? description;

  final VoidCallback onQuote;

  final EdgeInsets footerPadding;
  final Uri resourceUri;

  /// Draft key for [composeDraftProvider]. Used for add-quote and reply sheet draft.
  final DraftKey commentDraftKey;

  /// Called when user saves an edit. If non-null, Edit action is shown (when [viewerCanUpdate]).
  final Future<void> Function(String newBody)? onEdit;

  /// Called when user confirms delete. If non-null, Delete action is shown (when [viewerCanDelete]).
  final Future<void> Function()? onDelete;

  /// Called when user selects a minimize reason. If non-null, Minimize action is shown (when [viewerCanMinimize]).
  final Future<void> Function(ReportedContentClassifiers classifier)?
  onMinimize;

  /// Called after unminimizing. If non-null and [isMinimized], Unminimize action is shown. Parent should invalidate detail provider.
  final VoidCallback? onUnminimize;

  /// When set with [commentDatabaseId], enables Pin/Unpin action (gated by repo [viewerCanAdminister]).
  final RepoRef? repoRef;

  /// Database ID of this comment for REST pin/unpin API. Requires [repoRef].
  final BigInt? commentDatabaseId;

  /// Node ID of this comment (e.g. for edit history sheet). When set with [lastEditedAt], "Edited" is tappable.
  final String? commentNodeId;

  /// When set and [repoRef] + [commentDatabaseId] are non-null, the premium side
  /// provides a Pin/Unpin action button. Injected by premium; null in OSS.
  final ActionButtonData Function(BuildContext, WidgetRef)? pinActionBuilder;

  @override
  ConsumerState<BaseComment> createState() => BaseCommentState();
}

class BaseCommentState extends ConsumerState<BaseComment> {
  void addQuote(final String data) {
    final key = widget.commentDraftKey;
    final current = ref
        .read(composeDraftProvider(key))
        .when(data: (v) => v, loading: () => '', error: (_, __) => '');
    final quoted = '\n> ${widget.body.replaceAll(RegExp('\n'), '\n> ')}\n\n';
    ref.read(composeDraftProvider(key).notifier).updateBody(current + quoted);
  }

  @override
  Widget build(final BuildContext context) {
    final PopupButton menuButton = PopupButton(
      animatedButtonBuilder: (context, showMenu, isOpen) => TapFeedback(
        onTap: showMenu,
        child: AnimatedMenuIcon.compact(isOpen: isOpen),
      ),
      buttonBuilder: (context, showMenu) => const SizedBox.shrink(),
      actions: buildCommentActions(
        context,
        ref,
        widget,
        addQuote,
        (ctx) => showEditCommentDialog(ctx, ref, widget.body, widget.onEdit),
        (ctx) => confirmDeleteComment(ctx, widget.onDelete),
        (ctx) => showMinimizePicker(ctx, ref, widget.onMinimize),
        pinAction:
            widget.repoRef != null &&
                widget.commentDatabaseId != null &&
                viewerCanAdminister(ref, widget.repoRef!)
            ? widget.pinActionBuilder?.call(context, ref)
            : null,
      ),
    );

    return NestedCardWithHeader(
      header: CommentHeader(
        author: widget.author,
        leading: widget.leading,
        createdAt: widget.createdAt,
        authorAssociation: widget.authorAssociation,
        lastEditedAt: widget.lastEditedAt,
        commentNodeId: widget.commentNodeId,
      ),
      trailing: menuButton,
      headerPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      childPadding: context.spacing.chipPadding,
      spacing: 0,
      footer: _reactionsNotEmpty()
          ? Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.itemSpacing,
                vertical: 6,
              ),
              child: ReactionBar(
                widget.reactions,
                viewerCanReact: widget.viewerCanReact,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.description!,
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          if (widget.bodyHTML?.isNotEmpty ?? false)
            MarkdownBody(widget.bodyHTML!, buildAsync: false),
          if (widget.footer != null)
            Padding(
              padding: widget.footerPadding.copyWith(top: 8),
              child: widget.footer,
            ),
        ],
      ),
    );
  }

  bool _reactionsNotEmpty() => widget.reactions
      .where(
        (final ReactionGroupData element) => element.reactors.totalCount > 0,
      )
      .isNotEmpty;
}

Future<void> showEditCommentDialog(
  final BuildContext context,
  final WidgetRef ref,
  final String body,
  final Future<void> Function(String newBody)? onEdit,
) async {
  if (onEdit == null) return;
  final controller = TextEditingController(text: body);
  final saved = await showDialog<bool>(
    context: context,
    builder: (final BuildContext ctx) => AlertDialog(
      title: const Text('Edit comment'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Comment body',
        ),
        maxLines: 8,
        minLines: 3,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    await onEdit(controller.text.trim());
  }
  controller.dispose();
}

bool viewerCanAdminister(final WidgetRef ref, final RepoRef repoRef) =>
    ref
        .watch(repositoryProvider(repoRef))
        .value
        ?.repository
        ?.viewerCanAdminister ??
    false;

Future<void> confirmDeleteComment(
  final BuildContext context,
  final Future<void> Function()? onDelete,
) async {
  if (onDelete == null) return;
  final confirmed = await showConfirmAction(
    context,
    title: 'Delete comment',
    explanation: 'This comment will be removed. This action cannot be undone.',
    confirmLabel: 'Delete',
    isDestructive: true,
  );
  if (confirmed == true && context.mounted) {
    await onDelete();
  }
}

String minimizeReasonLabel(final ReportedContentClassifiers c) {
  switch (c) {
    case ReportedContentClassifiers.SPAM:
      return 'Spam';
    case ReportedContentClassifiers.ABUSE:
      return 'Abuse';
    case ReportedContentClassifiers.OFF_TOPIC:
      return 'Off-topic';
    case ReportedContentClassifiers.OUTDATED:
      return 'Outdated';
    case ReportedContentClassifiers.DUPLICATE:
      return 'Duplicate';
    case ReportedContentClassifiers.RESOLVED:
      return 'Resolved';
    default:
      return c.name;
  }
}

Future<void> showMinimizePicker(
  final BuildContext context,
  final WidgetRef ref,
  final Future<void> Function(ReportedContentClassifiers classifier)?
  onMinimize,
) async {
  if (onMinimize == null) return;
  if (!context.mounted) return;
  final classifiers = ReportedContentClassifiers.values;
  final selected = await AppSheet.actions<ReportedContentClassifiers>(
    context,
    header: AppSheetHeader.text('Why are you minimizing this?'),
    actions: (final BuildContext ctx) => classifiers
        .map(
          (final ReportedContentClassifiers c) => SheetAction(
            title: Text(minimizeReasonLabel(c)),
            onPressed: () => Navigator.of(ctx).pop(c),
          ),
        )
        .toList(),
  );
  if (selected != null && context.mounted) {
    await onMinimize(selected);
  }
}

/// Builds the list of action buttons for a comment's popup menu.
List<ActionButtonData> buildCommentActions(
  final BuildContext context,
  final WidgetRef ref,
  final BaseComment widget,
  final void Function(String body) addQuote,
  final Future<void> Function(BuildContext) onEditTap,
  final Future<void> Function(BuildContext) onDeleteConfirm,
  final Future<void> Function(BuildContext) onMinimizePicker, {
  final ActionButtonData? pinAction,
}) {
  return <ActionButtonData>[
    MinorActionButton(
      label: 'React',
      icon: Icons.add_reaction_outlined,
      leading: AppReactionButton(
        reactionGroups: widget.reactions,
        loading: false,
        onReactionChanged: widget.commentNodeId != null && widget.viewerCanReact
            ? (final ReactionInfo info) async {
                await ref
                    .read(reactionsProvider(widget.commentNodeId!).notifier)
                    .addReaction(info.selectedReaction.content);
              }
            : null,
      ),
    ),
    MinorActionButton(
      label: 'Share',
      icon: Icons.adaptive.share_rounded,
      onTap: () async {
        await Share.share(widget.resourceUri.toString());
      },
    ),
    MinorActionButton(
      label: 'Quote',
      icon: Icons.format_quote_rounded,
      onTap: () {
        addQuote(widget.body);
        widget.onQuote();
      },
    ),
    if (widget.repoRef != null)
      MinorActionButton(
        label: 'Open issue from this',
        icon: Icons.launch_rounded,
        onTap: () {
          final quoted =
              '> ${widget.body.replaceAll(RegExp('\n'), '\n> ')}\n\n'
              '_From [comment](${widget.resourceUri})_';
          context.router.push(
            NewIssueRoute(
              repoRef: widget.repoRef!,
              initialBody: quoted,
              initialTitle: '',
            ),
          );
        },
      ),
    createCopySelectAction(
      text: widget.body,
      copy: ref.read(clipboardServiceProvider).copy,
      selectDialogBuilder: (final BuildContext context) => SelectAndCopy(
        widget.body,
        commentDraftKey: widget.commentDraftKey,
        onQuote: widget.onQuote,
        copy: ref.read(clipboardServiceProvider).copy,
      ),
    ),
    if (widget.viewerCanUpdate && widget.onEdit != null)
      MinorActionButton(
        label: 'Edit',
        icon: Icons.edit_outlined,
        onTap: () => onEditTap(context),
      ),
    if (widget.viewerCanDelete && widget.onDelete != null)
      MinorActionButton(
        label: 'Delete',
        icon: Icons.delete_outline,
        isDestructive: true,
        onTap: () => onDeleteConfirm(context),
      ),
    if (widget.isMinimized &&
        widget.commentNodeId != null &&
        widget.onUnminimize != null)
      MinorActionButton(
        label: 'Unminimize',
        icon: Icons.visibility_outlined,
        onTap: () {
          widget.onUnminimize?.call();
        },
      )
    else if (widget.viewerCanMinimize && widget.onMinimize != null)
      MinorActionButton(
        label: 'Minimize',
        icon: Icons.visibility_off_outlined,
        onTap: () => onMinimizePicker(context),
      ),
    if (widget.repoRef != null &&
        widget.commentDatabaseId != null &&
        pinAction != null)
      pinAction,
    MinorActionButton(
      label: widget.author!.login,
      subtitle: 'Go to profile',
      icon: Icons.person_rounded,
      leading: SizedBox(
        width: 24,
        height: 24,
        child: ClipRRect(
          borderRadius: context.radius(RadiusSize.medium),
          child: CachedNetworkImage(
            imageUrl: widget.author!.avatarUrl.toString(),
            width: 24,
            height: 24,
            memCacheWidth: (24 * MediaQuery.of(context).devicePixelRatio)
                .round()
                .clamp(1, 512),
            memCacheHeight: (24 * MediaQuery.of(context).devicePixelRatio)
                .round()
                .clamp(1, 512),
            fit: BoxFit.cover,
          ),
        ),
      ),
      onTap: () async {
        await context.router.push(
          UserProfileRoute(userRef: UserRef(login: widget.author!.login)),
        );
      },
    ),
  ];
}

/// Header row for a comment: avatar, author, badges, timestamp, edited link.
class CommentHeader extends ConsumerWidget {
  const CommentHeader({
    required this.author,
    required this.createdAt,
    required this.authorAssociation,
    super.key,
    this.leading,
    this.lastEditedAt,
    this.commentNodeId,
  });

  final Actor? author;
  final IconData? leading;
  final DateTime createdAt;
  final CommentAuthorAssociation authorAssociation;
  final DateTime? lastEditedAt;
  final String? commentNodeId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Row(
    children: <Widget>[
      if (leading != null)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            leading,
            size: 16,
            color: context.colorScheme.onSurface.muted,
          ),
        ),
      ProfileTile.avatar(
        avatarUrl: author?.avatarUrl.toString(),
        userLogin: author?.login,
        padding: EdgeInsets.zero,
        size: 32,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    author?.login ?? 'N/A',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (authorAssociation != CommentAuthorAssociation.MEMBER &&
                    authorAssociation != CommentAuthorAssociation.NONE)
                  Builder(
                    builder: (final BuildContext context) {
                      String? str;
                      Color? badgeColor;
                      if (authorAssociation ==
                          CommentAuthorAssociation.COLLABORATOR) {
                        str = 'Collaborator';
                        badgeColor = context.colorScheme.secondaryContainer;
                      } else if (authorAssociation ==
                          CommentAuthorAssociation.CONTRIBUTOR) {
                        str = 'Contributor';
                        badgeColor = context.colorScheme.tertiaryContainer;
                      } else if (authorAssociation ==
                          CommentAuthorAssociation.OWNER) {
                        str = 'Owner';
                        badgeColor = context.colorScheme.primaryContainer;
                      }
                      return Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor?.muted,
                          borderRadius: context.radius(RadiusSize.soft),
                        ),
                        child: Text(
                          str ?? '',
                          style: context.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateTime.parse(createdAt.toString()).toRelativeDate(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.muted,
                  ),
                ),
                if (lastEditedAt != null) ...[
                  Text(
                    ' • ',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface.muted,
                    ),
                  ),
                  Text(
                    'Edited ${DateTime.parse(lastEditedAt.toString()).toRelativeDate()}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface.hinted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class SelectAndCopy extends ConsumerStatefulWidget {
  const SelectAndCopy(
    this.data, {
    required this.copy,
    this.commentDraftKey,
    super.key,
    this.onQuote,
  });

  final String data;
  final VoidCallback? onQuote;
  final DraftKey? commentDraftKey;
  final Future<void> Function(String text) copy;

  @override
  ConsumerState<SelectAndCopy> createState() => _SelectAndCopyState();
}

class _SelectAndCopyState extends ConsumerState<SelectAndCopy> {
  String selectedText = '';

  @override
  Widget build(final BuildContext context) => AlertDialog(
    title: Text(
      'Select and copy',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    content: SingleChildScrollView(
      child: SelectableText(
        widget.data,
        style: Theme.of(context).textTheme.bodyMedium,
        onSelectionChanged:
            (
              final TextSelection selection,
              final SelectionChangedCause? cause,
            ) {
              setState(() {
                selectedText = selection.textInside(widget.data);
              });
            },
      ),
    ),
    actions: <Widget>[
      MaterialButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.all(context.spacing.itemSpacing),
          child: const Text('Cancel'),
        ),
      ),
      MaterialButton(
        onPressed: selectedText.isNotEmpty
            ? () async {
                await widget.copy(selectedText);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            : null,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.itemSpacing),
          child: const Text('Copy'),
        ),
      ),
      if (widget.onQuote != null && widget.commentDraftKey != null)
        MaterialButton(
          onPressed: selectedText.isNotEmpty
              ? () {
                  final key = widget.commentDraftKey!;
                  final current = ref
                      .read(composeDraftProvider(key))
                      .when(
                        data: (v) => v,
                        loading: () => '',
                        error: (_, __) => '',
                      );
                  final quoted =
                      '\n> ${selectedText.replaceAll(RegExp('\n'), '\n> ')}\n\n';
                  ref
                      .read(composeDraftProvider(key).notifier)
                      .updateBody(current + quoted);
                  Navigator.pop(context);

                  widget.onQuote!();
                }
              : null,
          child: Padding(
            padding: EdgeInsets.all(context.spacing.itemSpacing),
            child: const Text('Quote'),
          ),
        ),
    ],
  );
}
