import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

typedef SettingsCollectionRowBuilder<T> =
    Widget Function(BuildContext context, T item);

class SettingsPaginatedCollection<T> extends StatelessWidget {
  const SettingsPaginatedCollection({
    required this.controller,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyDescription,
    super.key,
  });

  final PaginationController<T, T> controller;
  final SettingsCollectionRowBuilder<T> itemBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyDescription;

  @override
  Widget build(
    final BuildContext context,
  ) => ValueListenableBuilder<PaginationState<T>>(
    valueListenable: controller.state,
    builder:
        (
          final BuildContext context,
          final PaginationState<T> state,
          final Widget? _,
        ) {
          final bool initiallyLoading =
              state.items.isEmpty &&
              (state.phase is LoadingForward || state.phase is Refreshing);
          final bool initiallyFailed =
              state.items.isEmpty && state.phase is Failed;

          return AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            layoutBuilder:
                (
                  final Widget? currentChild,
                  final List<Widget> previousChildren,
                ) => Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    for (final Widget child in previousChildren)
                      IgnorePointer(child: ExcludeSemantics(child: child)),
                    ?currentChild,
                  ],
                ),
            child: initiallyLoading
                ? const _SettingsCollectionSkeleton(
                    key: ValueKey<String>('settings-collection-loading'),
                  )
                : initiallyFailed
                ? _SettingsCollectionError(
                    key: const ValueKey<String>('settings-collection-error'),
                    onRetry: controller.fetchForward,
                  )
                : state.items.isEmpty
                ? _SettingsCollectionEmpty(
                    key: const ValueKey<String>('settings-collection-empty'),
                    icon: emptyIcon,
                    title: emptyTitle,
                    description: emptyDescription,
                  )
                : Card.outlined(
                    key: const ValueKey<String>('settings-collection-content'),
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: <Widget>[
                        if (state.phase is Refreshing)
                          const LinearProgressIndicator(minHeight: 2),
                        for (
                          int index = 0;
                          index < state.items.length;
                          index++
                        ) ...<Widget>[
                          if (index > 0) const Divider(height: 1),
                          itemBuilder(context, state.items[index]),
                        ],
                        if (state.hasMoreForward ||
                            state.phase is LoadingForward ||
                            state.phase is Failed) ...<Widget>[
                          const Divider(height: 1),
                          _SettingsCollectionFooter(
                            phase: state.phase,
                            hasMore: state.hasMoreForward,
                            onLoadMore: controller.fetchForward,
                          ),
                        ],
                      ],
                    ),
                  ),
          );
        },
  );
}

class _SettingsCollectionSkeleton extends StatelessWidget {
  const _SettingsCollectionSkeleton({super.key});

  @override
  Widget build(final BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: <Widget>[
        const LinearProgressIndicator(minHeight: 2),
        for (int index = 0; index < 3; index++) ...<Widget>[
          if (index > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FractionallySizedBox(
                        widthFactor: index == 1 ? 0.46 : 0.64,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: index == 2 ? 0.58 : 0.78,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _SettingsCollectionError extends StatelessWidget {
  const _SettingsCollectionError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.settingsCollectionLoadError,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    ),
  );
}

class _SettingsCollectionEmpty extends StatelessWidget {
  const _SettingsCollectionEmpty({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(final BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SettingsCollectionFooter extends StatelessWidget {
  const _SettingsCollectionFooter({
    required this.phase,
    required this.hasMore,
    required this.onLoadMore,
  });

  final PaginationPhase phase;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Center(
      child: phase is LoadingForward
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : phase is Failed
          ? OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            )
          : hasMore
          ? TextButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more),
              label: Text(context.l10n.settingsLoadMore),
            )
          : const SizedBox.shrink(),
    ),
  );
}
