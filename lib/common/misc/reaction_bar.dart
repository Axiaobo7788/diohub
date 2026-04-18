import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/bottom_sheet/paginated_list_sheet.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart'
    show Actor;

import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/providers/issue_pulls/reactions_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension ReactionContentEmoji on ReactionContent {
  String get emoji => switch (this) {
        ReactionContent.THUMBS_UP => '👍',
        ReactionContent.THUMBS_DOWN => '👎',
        ReactionContent.LAUGH => '😄',
        ReactionContent.HOORAY => '🎉',
        ReactionContent.CONFUSED => '😕',
        ReactionContent.HEART => '❤️',
        ReactionContent.ROCKET => '🚀',
        ReactionContent.EYES => '👀',
        _ => '?',
      };
}

Widget _shimmer(final Widget child, final bool shimmer) =>
    shimmer ? ShimmerScope(child: child) : child;

class ReactionBar extends ConsumerStatefulWidget {
  const ReactionBar(
    this.reactionGroups, {
    required this.viewerCanReact,
    super.key,
  });

  final List<ReactionGroupData> reactionGroups;
  final bool viewerCanReact;

  @override
  ConsumerState<ReactionBar> createState() => _ReactionBarState();
}

class ReactionInfo {
  ReactionInfo({
    required this.selectedReaction,
  })  : reactorsCount = selectedReaction.reactors.totalCount,
        viewerHasReacted = selectedReaction.viewerHasReacted;

  final ReactionGroupData selectedReaction;
  int reactorsCount;
  bool viewerHasReacted;

  void unReact() {
    reactorsCount--;
    viewerHasReacted = false;
  }

  void react() {
    reactorsCount++;
    viewerHasReacted = true;
  }
}

class _ReactionBarState extends ConsumerState<ReactionBar> {
  MutationState<void> _mutationState = MutationState.idle();
  ReactionInfo? selectedReaction;
  late final List<ReactionInfo> reactionsInfo;

  String get _subjectId => widget.reactionGroups.first.subject.id;

  Future<ReactionInfo> _updateReaction(final ReactionInfo value) async {
    if (_mutationState.isLoading) return value;
    ref.read(hapticServiceProvider).lightImpact();
    setState(() => _mutationState = MutationState.loading());
    try {
      if (value.viewerHasReacted) {
        await ref
            .read(reactionsProvider(_subjectId).notifier)
            .removeReaction(value.selectedReaction.content);
        if (mounted) setState(() => selectedReaction = null);
        return value..unReact();
      } else {
        await ref
            .read(reactionsProvider(_subjectId).notifier)
            .addReaction(value.selectedReaction.content);
        if (mounted) setState(() => selectedReaction = value);
        return value..react();
      }
    } catch (e, st) {
      AppLogger.warning(
        'Reaction update failed',
        error: e,
        stackTrace: st,
        tag: 'ReactionBar',
      );
      ref.read(notificationServiceProvider).error('Failed to update reaction');
      return value;
    } finally {
      if (mounted) setState(() => _mutationState = MutationState.idle());
    }
  }

  @override
  void initState() {
    reactionsInfo = genInfo(
      widget.reactionGroups,
      selectedReaction: (final ReactionInfo? selectedReaction) {
        this.selectedReaction = selectedReaction;
      },
    );
    super.initState();
  }

  static List<ReactionInfo> genInfo(
    final List<ReactionGroupData> reactionGroups, {
    final void Function(ReactionInfo? selectedReaction)? selectedReaction,
  }) {
    final List<ReactionInfo> reactionsInfo = <ReactionInfo>[];
    for (final ReactionGroupData element in reactionGroups) {
      if (element.viewerHasReacted) {
        selectedReaction?.call(
          ReactionInfo(
            selectedReaction: element,
          ),
        );
      }
      reactionsInfo.add(
        ReactionInfo(
          selectedReaction: element,
        ),
      );
    }
    return reactionsInfo;
  }

  @override
  Widget build(final BuildContext context) => Row(
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: context.spacing.listInset,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: <Widget>[
                  if (widget.viewerCanReact && selectedReaction == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      child: _mutationState.isLoading
                          ? buildReactionButton(
                              loading: _mutationState.isLoading)
                          : AppReactionButton(
                              reactionGroups: widget.reactionGroups,
                              loading: _mutationState.isLoading,
                              onReactionChanged: _updateReaction,
                            ),
                    ),
                  ...List<Widget>.generate(
                    widget.reactionGroups.length,
                    (final int index) => reactionsInfo[index].reactorsCount > 0
                        ? AnimatedContentSwitcher(
                            transition: AnimationTransition.fadeScale,
                            key: ValueKey(reactionsInfo[index].reactorsCount),
                            child: IgnorePointer(
                              ignoring: _mutationState.isLoading,
                              child: ReactionItem(
                                reactionsInfo[index],
                                onTap: _mutationState.isLoading ||
                                        !widget.viewerCanReact
                                    ? null
                                    : (final ReactionInfo group) async {
                                        try {
                                          await _updateReaction(group);
                                        } on Exception catch (e, stackTrace) {
                                          AppLogger.error(
                                            'Failed to update reaction',
                                            error: e,
                                            stackTrace: stackTrace,
                                            tag: 'Reactions',
                                          );
                                        }
                                      },
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  static Padding buildReactionButton({required final bool loading}) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: SizedBox(
          height: 36,
          child: Center(
            child: _shimmer(
              const Icon(
                Icons.emoji_emotions_rounded,
                //   context,
                // ).currentSetting.faded3,
                size: 18,
              ),
              loading,
            ),
          ),
        ),
      );
}

class ReactionItem extends ConsumerStatefulWidget {
  const ReactionItem(this.reactionGroup, {this.onTap, super.key});

  final ReactionInfo reactionGroup;
  final Future<void> Function(ReactionInfo group)? onTap;

  @override
  ConsumerState<ReactionItem> createState() => ReactionItemState();
}

class ReactionItemState extends ConsumerState<ReactionItem> {
  bool _loading = false;

  Future<void> changeReaction() async {
    if (_loading) return;
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    try {
      await widget.onTap?.call(widget.reactionGroup);
    } catch (e, st) {
      AppLogger.warning(
        'Reaction toggle failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ref.read(notificationServiceProvider).error(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ReactionGroupData reactionGroup =
        widget.reactionGroup.selectedReaction;

    return BorderedContainer(
      backgroundColor: cardColor(context),
      onTap: widget.onTap != null ? changeReaction : null,
      onLongPress: () async {
        await _showUsersInSheet(context, reactionGroup);
      },
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 36,
        child: _shimmer(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              context.spacing.itemGap,
              Text(
                widget.reactionGroup.selectedReaction.content.emoji,
              ),
              context.spacing.itemGap,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.reactionGroup.reactorsCount.toString(),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: widget.reactionGroup.viewerHasReacted
                        ? context.colorScheme.onTertiary
                        : context.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              context.spacing.itemGap,
            ],
          ),
          _loading,
        ),
      ),
    );
  }

  Color cardColor(final BuildContext context) {
    final Color color = widget.reactionGroup.viewerHasReacted
        ? context.colorScheme.tertiary
        : context.colorScheme.tertiaryContainer;

    if (widget.onTap == null) {
      return color.withValues(alpha: 0.5);
    } else {
      return color;
    }
  }

  Future<void> _showUsersInSheet(
    final BuildContext context,
    final ReactionGroupData reactionGroup,
  ) async {
    final subjectId = reactionGroup.subject.id;
    final content = reactionGroup.content;
    final getReactorsPage = ref.read(getReactorsPageProvider);
    await AppSheet.scrollable(
      context,
      header: AppSheetHeader.text(
        reactionGroup.content.emoji,
        trailing: CloseButton(onPressed: () => Navigator.of(context).pop()),
      ),
      bodyBuilder: (
        final BuildContext context,
        final StateSetter setState,
        final ScrollController scrollController,
      ) =>
          PaginatedListSheetBody<ReactorsGroupEdge?>(
        scrollController: scrollController,
        createController: () =>
            PaginationController<ReactorsGroupEdge?, ReactorsGroupEdge?>(
          source: CursorForwardSource<ReactorsGroupEdge?>(
            fetch: ({required int first, String? after}) =>
                getReactorsPage(subjectId, content, first: first, after: after),
          ),
          idOf: (final ReactorsGroupEdge? e) => e?.cursor ?? '',
          pageSize: 20,
        ),
        itemBuilder: (
          final BuildContext context,
          final WidgetRef ref,
          final ReactorsGroupEdge? edge,
          final int index,
          final void Function(ItemPatch patch) applyPatch,
        ) {
          if (edge == null) return const SizedBox.shrink();
          final Actor actor = edge.node as Actor;
          return Padding(
            padding:
                EdgeInsets.symmetric(vertical: context.spacing.itemSpacing),
            child: BorderedContainer(
              padding: EdgeInsets.zero,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ProfileTile.login(
                      avatarUrl: actor.avatarUrl.toString(),
                      padding: context.spacing.pagePadding,
                      userLogin: actor.login,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        emptyBuilder: (final BuildContext context) => Padding(
          padding: context.spacing.spaciousPadding,
          child: Center(
            child: Text(
              'No reactors',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.muted,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppReactionButton extends StatelessWidget {
  const AppReactionButton({
    required this.reactionGroups,
    required this.loading,
    super.key,
    this.onReactionChanged,
  });

  final List<ReactionGroupData> reactionGroups;
  final bool loading;
  final Future<void> Function(ReactionInfo)? onReactionChanged;

  @override
  Widget build(final BuildContext context) {
    final List<ReactionInfo> genInfo =
        _ReactionBarState.genInfo(reactionGroups);

    return ReactionButton<ReactionInfo>(
      // splashColor: transparent,
      // boxPadding: context.spacing.pagePadding,
      itemSize: const Size(36, 36),
      isChecked: true,
      toggle: false,
      // shouldChangeReaction: false,
      // boxPosition: VerticalPosition.bottom,
      boxColor: context.colorScheme.primaryContainer,
      onReactionChanged: (
        final Reaction<ReactionInfo>? value,
      ) async {
        if (value?.value != null) {
          await onReactionChanged?.call(value!.value!);
        }
      },
      selectedReaction: Reaction<ReactionInfo>(
        icon: _ReactionBarState.buildReactionButton(loading: loading),
        value: null,
      ),
      // boxPadding: const EdgeInsets.all(4),
      reactions: List<Reaction<ReactionInfo>>.generate(
        reactionGroups.length,
        (final int index) => Reaction<ReactionInfo>(
          icon: Text(
            reactionGroups[index].content.emoji,
            // style: const TextStyle(18),
          ),
          value: genInfo[index],
        ),
      ),
    );
  }
}
