import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/gist_card.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/search/search_filter_providers.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/riverpod/delete_confirm_mutation_icon.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/providers/profile/gist_mutation_providers.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

const int _pageSize = 20;

/// Whether the viewer has starred gist [gistId]. Inlined here (only consumer).
final _gistStarredProvider = FutureProvider.autoDispose.family<bool, String>((
  final Ref ref,
  final String gistId,
) async {
  return ref.read(viewerSettingsServiceProvider).isGistStarred(gistId);
});

/// Returns a [TabBody] for the gists list on a user profile.
/// When [isViewer] is true, uses a controller-based list so delete calls
/// [applyPatch] (no refresh trigger). Optional [refreshRegistrar] for
/// pull-to-refresh and after "New gist" (viewer only).
TabBody createGistsBody(
  WidgetRef ref,
  UserRef userRef, {
  ValueNotifier<String>? queryNotifier,
  bool isViewer = false,
  ValueNotifier<Future<void> Function()?>? refreshRegistrar,
}) {
  if (!isViewer) {
    return _buildReadOnlyGistsBody(ref, userRef, queryNotifier: queryNotifier);
  }
  return SliverBuilderBody(
    refreshRegistrar: refreshRegistrar,
    sliverBuilder: (BuildContext context, WidgetRef ref) {
      final spacing = context.spacing;
      return [
        SliverPadding(
          padding: spacing.listInset,
          sliver: _ViewerGistsListSliver(
            key: ValueKey(userRef.login),
            userRef: userRef,
            refreshRegistrar: refreshRegistrar,
          ),
        ),
      ];
    },
  );
}

SliverListBody<UserGistEdge?> _buildReadOnlyGistsBody(
  WidgetRef ref,
  UserRef userRef, {
  ValueNotifier<String>? queryNotifier,
}) {
  return SliverListBody<UserGistEdge?>.textFilter(
    getCursor: (item) => item?.cursor,
    queryNotifier: queryNotifier,
    strategy: ref.watch(matchStrategyProvider),
    fields: [(item) => item?.node?.name, (item) => item?.node?.description],
    fetcher:
        ({String? after, int first = _pageSize, bool refresh = false}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getUserGists(userRef.login, refresh: refresh, after: after);
          final last = list.isNotEmpty ? list.last : null;
          return PaginatedResult(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
    itemBuilder: (BuildContext context, UserGistEdge? item) {
      return _buildGistTile(
        context,
        null,
        item,
        null,
        userRef: userRef,
        showDelete: false,
      );
    },
  );
}

Widget _buildGistTile(
  BuildContext context,
  WidgetRef? ref,
  UserGistEdge? item,
  void Function(ItemPatch)? applyPatch, {
  required UserRef userRef,
  required bool showDelete,
  VoidCallback? onRefresh,
}) {
  final UserGistNode? node = item?.node;
  if (node == null) return const SizedBox.shrink();
  final List<dynamic> rawFiles = node.files is List
      ? node.files as List
      : <dynamic>[];
  final List<GistFileInfo> files = rawFiles
      .map((dynamic f) => GistFileInfo(name: f.name as String))
      .toList();
  final gistData = GistCardData(
    name: node.name,
    description: node.description,
    isPublic: node.isPublic,
    isFork: false,
    createdAt: node.createdAt.toString(),
    updatedAt: node.updatedAt.toString(),
    starCount: node.stargazerCount,
    url: node.url,
    files: files,
    commentCount: null,
    forkCount: null,
  );
  final card = TapFeedback(
    onTap: () => openInAppBrowser(node.url),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.tightSpacing / 2),
      child: BorderedContainer(child: GistCard(data: gistData)),
    ),
  );
  if (!showDelete || ref == null || applyPatch == null) return card;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: card),
      Consumer(
        builder: (final BuildContext context, final WidgetRef r, _) {
          final AsyncValue<bool> starred = r.watch(
            _gistStarredProvider(node.name),
          );
          return IconButton(
            icon: Icon(
              starred.whenOrNull(data: (d) => d) == true
                  ? Icons.star
                  : Icons.star_border,
              color: starred.whenOrNull(data: (d) => d) == true
                  ? Colors.amber
                  : null,
            ),
            onPressed: starred.isLoading
                ? null
                : () async {
                    if (starred.whenOrNull(data: (d) => d) == true) {
                      await r
                          .read(viewerSettingsServiceProvider)
                          .unstarGist(node.name);
                    } else {
                      await r
                          .read(viewerSettingsServiceProvider)
                          .starGist(node.name);
                    }
                    r.invalidate(_gistStarredProvider(node.name));
                  },
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: () async {
          final String? newDescription = await showDialog<String>(
            context: context,
            builder: (final BuildContext ctx) => _EditGistDescriptionDialog(
              initialDescription: node.description ?? '',
            ),
          );
          if (newDescription != null) {
            await ref
                .read(viewerSettingsServiceProvider)
                .updateGist(gistId: node.name, description: newDescription);
            onRefresh?.call();
          }
        },
      ),
      DeleteConfirmMutationIcon(
        mutation: ref.watch(
          deleteGistMutationProvider((user: userRef, gistId: node.name)),
        ),
        onDelete: () {
          ref
              .read(
                deleteGistMutationProvider((
                  user: userRef,
                  gistId: node.name,
                )).notifier,
              )
              .delete(onSuccess: () => applyPatch(PatchDeleted(node.name)));
        },
        confirmTitle: 'Delete gist?',
        confirmExplanation:
            'This will permanently delete this gist. This cannot be undone.',
      ),
    ],
  );
}

/// Gists tab. Uses [createGistsBody] slivers.
class ProfileGistsTab extends ConsumerWidget {
  const ProfileGistsTab(this.userRef, {super.key});

  final UserRef userRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => MultiSliver(
    children: createGistsBody(ref, userRef).buildSliversWithRef(context, ref),
  );
}

/// Stateful sliver that owns the [PaginationController] for the viewer's gists list.
/// Keyed by [userRef.login] so state is preserved across parent rebuilds.
class _ViewerGistsListSliver extends ConsumerStatefulWidget {
  const _ViewerGistsListSliver({
    super.key,
    required this.userRef,
    this.refreshRegistrar,
  });

  final UserRef userRef;
  final ValueNotifier<Future<void> Function()?>? refreshRegistrar;

  @override
  ConsumerState<_ViewerGistsListSliver> createState() =>
      _ViewerGistsListSliverState();
}

class _ViewerGistsListSliverState
    extends ConsumerState<_ViewerGistsListSliver> {
  late final PaginationController<UserGistEdge?, UserGistEdge> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<UserGistEdge?, UserGistEdge>(
      source: CursorForwardSource<UserGistEdge?>(
        fetch: ({required int first, String? after}) async {
          final list = await ref
              .read(userInfoServiceProvider)
              .getUserGists(
                widget.userRef.login,
                refresh: after == null,
                after: after,
              );
          final last = list.isNotEmpty ? list.last : null;
          return CursorPage<UserGistEdge?>(
            items: list,
            hasNextPage: list.length >= first,
            endCursor: last?.cursor,
          );
        },
      ),
      idOf: (e) => e.node?.name ?? e.cursor,
      pageSize: _pageSize,
    );
    if (widget.refreshRegistrar != null) {
      widget.refreshRegistrar!.value = () => _controller.refresh();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaginatedSliverList<UserGistEdge?>(
      controller: _controller,
      itemBuilder: (BuildContext ctx, UserGistEdge? item, int index) {
        return _buildGistTile(
          ctx,
          ref,
          item,
          _controller.applyPatch,
          userRef: widget.userRef,
          showDelete: true,
          onRefresh: _controller.refresh,
        );
      },
    );
  }
}

class _EditGistDescriptionDialog extends StatefulWidget {
  const _EditGistDescriptionDialog({required this.initialDescription});

  final String initialDescription;

  @override
  State<_EditGistDescriptionDialog> createState() =>
      _EditGistDescriptionDialogState();
}

class _EditGistDescriptionDialogState
    extends State<_EditGistDescriptionDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit gist description'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Description'),
        maxLines: 3,
        autofocus: true,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
