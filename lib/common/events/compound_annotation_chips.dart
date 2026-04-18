import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/events/expandable_body_text.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/event_discussion.dart';
import 'package:diohub_models/models/events/event_release.dart';
import 'package:diohub_models/models/events/gollum_page.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/issues/issue_model.dart' show Label;
import 'package:diohub_models/models/users/profile_card_input.dart'
    show FragmentUser, ProfileCardInput, ProfileCardInputUser;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub/providers/users/user_providers.dart'
    show userCardByLoginProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Inline `Wrap` of [IssueLabel] widgets.
/// Removed labels are shown with `isRemoved: true` (strikethrough + dimmed).
/// Returns [SizedBox.shrink] when [labels] is empty.
class InlineLabels extends StatelessWidget {
  const InlineLabels({
    required this.labels,
    this.removedLabelNames = const <String>{},
    super.key,
  });

  final List<Label> labels;
  final Set<String> removedLabelNames;

  @override
  Widget build(final BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;

    return Wrap(
      spacing: spacing.itemSpacing * 0.75,
      runSpacing: spacing.itemSpacing * 0.75,
      children: labels.map((final label) {
        final bool isRemoved = removedLabelNames.contains(label.name);
        return IssueLabel(label, isRemoved: isRemoved);
      }).toList(),
    );
  }
}

/// Inline comment preview clamped to ~3 lines with a "Show more" / "Show less"
/// expand toggle. Uses [TrimmableMarkdownContent] for rendering.
class InlineComment extends StatefulWidget {
  const InlineComment({required this.body, this.repoName, super.key});

  final String body;
  final String? repoName;

  @override
  State<InlineComment> createState() => _InlineCommentState();
}

class _InlineCommentState extends State<InlineComment> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final String trimmed = widget.body.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;

    return InlineContainer(
      padding: spacing.chipPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Clamp via maxLengthForIndicator when collapsed
          TrimmableMarkdownContent(
            text: trimmed,
            repo: widget.repoName,
            maxLengthForIndicator: _expanded ? trimmed.length : 150,
          ),
          if (trimmed.length > 150)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: EdgeInsets.only(top: spacing.itemSpacing / 2),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tappable chip that navigates to a user profile.
class AssigneeChip extends ConsumerWidget {
  const AssigneeChip({required this.login, super.key});

  final String login;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return TapFeedback(
      onTap: () => UserRef(login: login).navigate(context, ref),
      borderRadius: context.radius(RadiusSize.small),
      child: MetadataChip(
        leading: Icon(Octicons.person, size: 12),
        label: '@$login',
      ),
    );
  }
}

/// Inline release annotation showing tag, name, and body preview.
/// Renders inside a [BorderedContainer] below the repo card.
class InlineRelease extends StatelessWidget {
  const InlineRelease({required this.release, super.key});

  final EventRelease release;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return BorderedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Octicons.tag, size: 16),
              SizedBox(width: spacing.itemSpacing),
              if (release.tagName != null)
                Flexible(
                  child: Text(
                    release.tagName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (release.prerelease ?? false) ...<Widget>[
                SizedBox(width: spacing.itemSpacing),
                _releaseBadge(context, 'Pre-release', const Color(0xFFCF222E)),
              ],
              if (release.draft ?? false) ...<Widget>[
                SizedBox(width: spacing.itemSpacing),
                _releaseBadge(context, 'Draft', const Color(0xFF656D76)),
              ],
            ],
          ),
          if (release.name != null &&
              release.name != release.tagName) ...<Widget>[
            SizedBox(height: spacing.itemSpacing / 2),
            Text(
              release.name!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (release.body != null &&
              release.body!.trim().isNotEmpty) ...<Widget>[
            SizedBox(height: spacing.itemSpacing / 2),
            ExpandableBodyText(
              text: release.body!,
              title: 'Release Notes',
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _releaseBadge(
    final BuildContext context,
    final String text,
    final Color color,
  ) => TintedChip(color: color, icon: Octicons.tag, label: text, iconSize: 12);
}

/// Inline discussion annotation showing category, title, and body preview.
/// Renders inside a [BorderedContainer] below the repo card.
class InlineDiscussion extends StatelessWidget {
  const InlineDiscussion({required this.discussion, super.key});

  final EventDiscussion discussion;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return BorderedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Octicons.comment_discussion,
                size: 16,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(width: spacing.itemSpacing),
              if (discussion.category != null) ...<Widget>[
                if (discussion.category!.emoji != null)
                  Text(discussion.category!.emoji!),
                if (discussion.category!.name != null) ...<Widget>[
                  SizedBox(width: spacing.itemSpacing / 2),
                  Text(
                    discussion.category!.name!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ],
          ),
          if (discussion.title != null) ...<Widget>[
            SizedBox(height: spacing.itemSpacing / 2),
            Text(
              discussion.title!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (discussion.body != null &&
              discussion.body!.trim().isNotEmpty) ...<Widget>[
            SizedBox(height: spacing.itemSpacing / 2),
            ExpandableBodyText(
              text: discussion.body!,
              title: 'Discussion',
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline wiki pages annotation showing a list of changed pages.
/// Renders inside a [BorderedContainer] below the repo card.
/// When more than 5 pages, tap "N more pages" to expand inline (no popup).
class InlineWikiPages extends StatefulWidget {
  const InlineWikiPages({required this.pages, super.key});

  final List<GollumPage> pages;

  @override
  State<InlineWikiPages> createState() => _InlineWikiPagesState();
}

class _InlineWikiPagesState extends State<InlineWikiPages> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    if (widget.pages.isEmpty) return const SizedBox.shrink();
    final AppSpacing spacing = context.spacing;
    final List<GollumPage> pages = widget.pages;
    final int initialCount = pages.length > 5 ? 5 : pages.length;

    return BorderedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < initialCount; i++) ...<Widget>[
            _WikiPageRow(page: pages[i]),
            if (i < initialCount - 1) SizedBox(height: spacing.itemSpacing / 2),
          ],
          if (pages.length > 5) ...<Widget>[
            SizedBox(height: spacing.itemSpacing / 2),
            TapFeedback(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: context.radius(RadiusSize.small),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _expanded ? Octicons.fold : Octicons.unfold,
                    size: 12,
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(width: spacing.badgePadding.left),
                  Text(
                    _expanded
                        ? 'Show less'
                        : '+ ${pages.length - 5} more pages',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded) ...<Widget>[
              SizedBox(height: spacing.itemSpacing / 2),
              for (int i = 5; i < pages.length; i++) ...<Widget>[
                _WikiPageRow(page: pages[i]),
                if (i < pages.length - 1)
                  SizedBox(height: spacing.itemSpacing / 2),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _WikiPageRow extends StatelessWidget {
  const _WikiPageRow({required this.page});

  final GollumPage page;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Row(
      children: <Widget>[
        Icon(
          page.action == 'created' ? Octicons.plus : Octicons.pencil,
          size: 14,
          color: page.action == 'created'
              ? const Color(0xFF2DA44E)
              : const Color(0xFF656D76),
        ),
        SizedBox(width: spacing.itemSpacing),
        Expanded(
          child: Text(
            page.title ?? page.pageName ?? 'Untitled page',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Inline member annotation showing a tappable profile card.
/// Renders below the repo card for MemberEvent compounds.
/// Fetches user card fragment via [userCardByLoginProvider] and shows loading then [ProfileCard].
class InlineMember extends ConsumerWidget {
  const InlineMember({required this.login, super.key});

  final String login;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<gql.UserCardData?> asyncCard = ref.watch(
      userCardByLoginProvider(login),
    );
    return AsyncValueBuilder<gql.UserCardData?>(
      value: asyncCard,
      skeleton: (final _) => Padding(
        padding: context.spacing.pagePadding,
        child: const LoadingIndicator(),
      ),
      error: (final Object e, final StackTrace st) => Padding(
        padding: context.spacing.pagePadding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              context.spacing.itemGap,
              Text(e.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (final gql.UserCardData? data) {
        if (data == null) {
          return Padding(
            padding: context.spacing.pagePadding,
            child: Text(login),
          );
        }
        return BorderedContainer(
          ref: UserRef(login: login),
          child: ProfileCard(ProfileCardInputUser(FragmentUser(data))),
        );
      },
    );
  }
}
