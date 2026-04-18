import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/pagination/anchor_highlight.dart';
import 'package:diohub/common/pagination/backward_trigger.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/pagination/load_earlier_button.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Universal sliver for paginated lists. Renders backward loader, list,
/// optional gap indicator, and forward loader/error from [controller] state.
class PaginatedSliverList<R> extends StatelessWidget {
  const PaginatedSliverList({
    required this.controller,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.backwardTrigger = const ButtonBackwardTrigger(),
    this.anchorHighlight,
    this.gapBuilder,
    super.key,
  });

  final PaginationController<dynamic, R> controller;
  final Widget Function(BuildContext context, R item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final BackwardTrigger backwardTrigger;
  final bool Function(R item)? anchorHighlight;
  final Widget Function(
      BuildContext context, int? gapEstimate, VoidCallback onTap)? gapBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<R>>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final items = state.items;
        final hasBackward = state.hasMoreBackward;
        final phase = state.phase;

        return MultiSliver(
          children: [
            _buildBackwardSliver(context, state, hasBackward, phase),
            if (state.hasGap && gapBuilder != null)
              SliverToBoxAdapter(
                child: gapBuilder!(
                  context,
                  state.gapEstimate,
                  () => controller.fetchForward(),
                ),
              ),
            if (items.isEmpty && phase is Idle && !state.hasMoreForward)
              SliverFillRemaining(
                hasScrollBody: false,
                child: emptyBuilder?.call(context) ??
                    const EmptyState(message: 'Nothing here yet'),
              )
            else
              SliverList.builder(
                itemCount: items.length + _forwardSlotCount(state),
                findChildIndexCallback: (Key key) {
                  if (key is! ValueKey<String>) return null;
                  for (var i = 0; i < items.length; i++) {
                    if (controller.idOf(items[i]) == key.value) return i;
                  }
                  return null;
                },
                itemBuilder: (context, index) {
                  if (index < items.length) {
                    final item = items[index];
                    final itemId = controller.idOf(item);
                    final isHighlighted =
                        anchorHighlight?.call(item) ?? itemId == state.anchorId;
                    final child = itemBuilder(context, item, index);
                    return AnchorHighlight(
                      isHighlighted: isHighlighted,
                      child: KeyedSubtree(
                        key: ValueKey<String>(itemId),
                        child: child,
                      ),
                    );
                  }
                  return _buildForwardSlot(
                      context, state, index - items.length);
                },
              ),
          ],
        );
      },
    );
  }

  int _forwardSlotCount(PaginationState<R> state) {
    if (!state.hasMoreForward) return 0;
    return switch (state.phase) {
      LoadingForward() || Refreshing() => 1,
      Failed(:final direction) => direction == FetchDirection.forward ? 1 : 0,
      _ => 1,
    };
  }

  Widget _buildBackwardSliver(
    BuildContext context,
    PaginationState<R> state,
    bool hasBackward,
    PaginationPhase phase,
  ) {
    if (!hasBackward) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return switch (backwardTrigger) {
      ButtonBackwardTrigger(:final label) => SliverToBoxAdapter(
          child: phase is LoadingBackward
              ? Padding(
                  padding: context.spacing.pagePadding,
                  child: const Center(child: LoadingIndicator()),
                )
              : phase is Failed && phase.direction == FetchDirection.backward
                  ? _buildErrorTile(
                      context,
                      phase.error,
                      () => controller.fetchBackward(),
                    )
                  : LoadEarlierButton(
                      onTap: () => controller.fetchBackward(),
                      label: label,
                    ),
        ),
    };
  }

  Widget _buildForwardSlot(
      BuildContext context, PaginationState<R> state, int slotIndex) {
    final phase = state.phase;
    return switch (phase) {
      LoadingForward() || Refreshing() => Padding(
          padding: EdgeInsets.only(
            top: context.spacing.pagePadding.top,
            bottom: context.spacing.pagePadding.bottom,
            left: 0,
            right: 0,
          ),
          child: loadingBuilder?.call(context) ??
              Column(
                children: [
                  ListLoadingShimmers.timeline(context, itemCount: 2),
                  const SizedBox(height: 24),
                  const Center(child: LogoProgressIndicator(size: 32)),
                ],
              ),
        ),
      Failed(:final error, :final direction)
          when direction == FetchDirection.forward =>
        errorBuilder?.call(context, error, () => controller.fetchForward()) ??
            _buildErrorTile(context, error, () => controller.fetchForward()),
      _ => Padding(
          padding: EdgeInsets.only(
            top: context.spacing.pagePadding.top,
            bottom: context.spacing.pagePadding.bottom,
            left: 0,
            right: 0,
          ),
          child: loadingBuilder?.call(context) ??
              Column(
                children: [
                  ListLoadingShimmers.timeline(context, itemCount: 2),
                  const SizedBox(height: 24),
                  const Center(child: LogoProgressIndicator(size: 32)),
                ],
              ),
        ),
    };
  }

  Widget _buildErrorTile(
      BuildContext context, Object error, VoidCallback onRetry) {
    return Padding(
      padding: context.spacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          context.spacing.itemGap,
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
