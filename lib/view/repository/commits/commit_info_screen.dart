import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/nav_center/models/screen_config.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/providers/commits/commit_providers.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/view/repository/commits/commit_screen_config.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

@RoutePage()
class CommitInfoScreen extends ConsumerWidget {
  const CommitInfoScreen({
    required this.commitRef,
    super.key,
  });

  factory CommitInfoScreen.fromRouteArgs({
    required final String owner,
    required final String name,
    required final String oid,
    final Key? key,
  }) =>
      CommitInfoScreen(
        commitRef: CommitRef(
          repo: RepoRef(owner: owner, name: name),
          oid: oid,
        ),
        key: key,
      );

  final CommitRef commitRef;
  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    ref.listen(commitDataProvider(commitRef), (final prev, final next) {
      if (prev is! AsyncData && next is AsyncData) {
        ref.read(entityStoreMutatorProvider).recordVisit(
              commitRef,
              snapshot: EntitySnapshot(title: commitRef.oid),
            );
      }
    });

    final AsyncValue<CommitData> commitAsync =
        ref.watch(commitDataProvider(commitRef));

    return AsyncValueBuilder<CommitData>(
      value: commitAsync,
      skeleton: (final _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: _buildLoadingSkeleton(context),
        ),
      ),
      error: (final Object error, final StackTrace stack) =>
          ScaffoldError('Error loading commit: $error', safeArea: true),
      data: (final CommitData commitData) {
        final ClipboardService clipboard =
            ref.read(clipboardServiceProvider);
        final ScreenConfig config = buildCommitScreenConfig(
          commitRef: commitRef,
          commitData: commitData,
          onRefresh: () async {
            ref.invalidate(commitDataProvider(commitRef));
          },
          ref: ref,
          clipboard: clipboard,
          context: context,
        );
        return NavCenterShell(config: config);
      },
    );
  }

  Widget _buildLoadingSkeleton(final BuildContext context) => DynamicScroll(
        bar: const CollapseBar(
          title: ShimmerScope(child: ShimmerBone.title(width: 200)),
          action: ShimmerScope(
            child: IconButton(
              icon: ShimmerBone.icon(size: 24),
              onPressed: null,
            ),
          ),
        ),
        expanded: (final BuildContext context) => ShimmerScope(
          child: Row(
            children: <Widget>[
              Icon(
                Octicons.repo,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.hinted,
              ),
              context.spacing.itemGap,
              const ShimmerBone.text(width: 120),
            ],
          ),
        ),
        bodyBuilder:
            (final BuildContext context, final DynamicScrollMetrics metrics) =>
                IgnorePointer(
          child: AppCustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: context.spacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const ShimmerScope(child: ShimmerBone.title(width: 280)),
                      context.spacing.sectionGap,
                      const ShimmerScope(child: ShimmerBone.block(height: 60)),
                      context.spacing.sectionGap,
                      ...List.generate(
                        3,
                        (final int index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ShimmerScope(
                            child: Row(
                              children: <Widget>[
                                const ShimmerBone.avatar(size: 32),
                                context.spacing.contentGap,
                                const Expanded(child: ShimmerBone.text()),
                                const ShimmerBone.icon(size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
