import 'package:diohub/common/misc/ref_list_item.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/branch_notifier.dart' show RefKind;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback when user selects a ref. Caller updates branch state and/or dismisses UI.
typedef OnRefSelected = void Function(
  String name,
  RefKind kind, {
  required String oid,
  required String treeOid,
});

/// Shared ref list UI (Branches | Tags) for [BranchButton] and [BranchDockPill].
///
/// Renders a paginated list with [RefListItem] tiles. [refKind] switches
/// between branches and tags; [searchQuery] filters (nullable for sheet).
/// When [scrollController] is provided (e.g. from bottom sheet), the list attaches to it.
class RefSelectorContent extends ConsumerStatefulWidget {
  const RefSelectorContent({
    required this.repo,
    required this.defaultBranch,
    required this.currentRefValue,
    required this.refKind,
    required this.onRefSelected,
    required this.orderBy,
    this.searchQuery,
    this.scrollController,
    super.key,
  });

  final RepoRef repo;
  final String defaultBranch;
  final String currentRefValue;
  final RefKind refKind;
  final OnRefSelected onRefSelected;
  final RefOrder orderBy;
  final String? searchQuery;
  final ScrollController? scrollController;

  @override
  ConsumerState<RefSelectorContent> createState() => _RefSelectorContentState();
}

class _RefSelectorContentState extends ConsumerState<RefSelectorContent> {
  PaginationController<BranchEdge, BranchEdge>? _branchController;
  PaginationController<TagEdge, TagEdge>? _tagController;

  @override
  void initState() {
    super.initState();
    if (widget.refKind == RefKind.branch) {
      _branchController = PaginationController<BranchEdge, BranchEdge>(
        source: CursorForwardSource<BranchEdge>(
          fetch: ({required int first, String? after}) async {
            final r = await widget.repo.branches(ref.read(apiClientProvider)).fetchBranchesPaginated(
              first: first,
              after: after,
              query: (widget.searchQuery?.isEmpty ?? true)
                  ? null
                  : widget.searchQuery,

              orderField: Enum$RefOrderField.TAG_COMMIT_DATE,
              orderDirection: Enum$OrderDirection.DESC,
            );
            return CursorPage<BranchEdge>(
              items: r.items,
              hasNextPage: r.hasNextPage,
              endCursor: r.endCursor,
            );
          },
        ),
        idOf: (BranchEdge e) => e.cursor,
        pageSize: 15,
      );
    } else {
      _tagController = PaginationController<TagEdge, TagEdge>(
        source: CursorForwardSource<TagEdge>(
          fetch: ({required int first, String? after}) async {
            final r = await widget.repo.branches(ref.read(apiClientProvider)).fetchTagsPaginated(
              first: first,
              after: after,
              query: (widget.searchQuery?.isEmpty ?? true)
                  ? null
                  : widget.searchQuery,
              orderField: Enum$RefOrderField.TAG_COMMIT_DATE,
              orderDirection: OrderDirection.DESC,
            );
            return CursorPage<TagEdge>(
              items: r.items,
              hasNextPage: r.hasNextPage,
              endCursor: r.endCursor,
            );
          },
        ),
        idOf: (TagEdge e) => e.cursor,
        pageSize: 15,
      );
    }
  }

  @override
  void didUpdateWidget(RefSelectorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repo != widget.repo ||
        oldWidget.orderBy != widget.orderBy ||
        oldWidget.searchQuery != widget.searchQuery) {
      _branchController?.refresh();
      _tagController?.refresh();
    }
  }

  @override
  void dispose() {
    _branchController?.dispose();
    _tagController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.refKind == RefKind.branch) {
      final controller = _branchController!;
      return AppCustomScrollView(
        controller: widget.scrollController,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: PaginatedSliverList<BranchEdge>(
              controller: controller,
              itemBuilder: (
                BuildContext context,
                BranchEdge edge,
                int index,
              ) =>
                  _buildBranchTile(
                context,
                edge,
                widget.currentRefValue,
                widget.defaultBranch,
                widget.onRefSelected,
              ),
            ),
          ),
        ],
      );
    }

    final controller = _tagController!;
    return AppCustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: PaginatedSliverList<TagEdge>(
            controller: controller,
            itemBuilder: (
              BuildContext context,
              TagEdge edge,
              int index,
            ) =>
                _buildTagTile(
              context,
              edge,
              widget.currentRefValue,
              widget.onRefSelected,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildBranchTile(
    final BuildContext context,
    final BranchEdge edge,
    final String currentBranch,
    final String defaultBranchName,
    final OnRefSelected onRefSelected,
  ) {
    final BranchNode? node = edge.node;
    if (node == null) return const SizedBox.shrink();
    final String branchName = node.name;
    DateTime? committedDate;
    String? messageHeadline;
    String? authorAvatarUrl;
    String? authorLogin;
    String? ciState;
    bool? signatureVerified;
    int? openPullRequestCount;
    String? commitOid;
    String? treeOid;
    node.target?.maybeWhen(
      commit: (final BranchCommit c) {
        committedDate = c.committedDate;
        messageHeadline = c.messageHeadline;
        commitOid = c.oid;
        treeOid = c.tree.oid;
        final StatusState? statusState = c.statusCheckRollup?.state;
        ciState = statusState?.name;
        signatureVerified = c.signature?.isValid;
        final BranchCommitAuthor? a = c.author;
        if (a != null) {
          authorAvatarUrl = a.avatarUrl.toString();
          authorLogin = a.user?.login;
        }
      },
      orElse: () {},
    );
    openPullRequestCount = node.associatedPullRequests.totalCount;
    final RefListItemBranchData branchData = RefListItemBranchData(
      name: branchName,
      isDefault: defaultBranchName == branchName,
      isCurrent: branchName == currentBranch,
      committedDate: committedDate,
      messageHeadline: messageHeadline,
      authorAvatarUrl: authorAvatarUrl,
      authorLogin: authorLogin,
      hasProtection: node.branchProtectionRule != null,
      ciState: ciState,
      openPullRequestCount: openPullRequestCount,
      signatureVerified: signatureVerified,
    );
    final bool canSwitch =
        (commitOid?.isNotEmpty ?? false) && (treeOid?.isNotEmpty ?? false);
    return Padding(
      padding: context.spacing.screenPadding,
      child: RefListItem(
        variant: RefListItemVariant.branch,
        branchData: branchData,
        isHighlighted: branchName == currentBranch,
        onTap: canSwitch
            ? () => onRefSelected(
                  branchName,
                  RefKind.branch,
                  oid: commitOid!,
                  treeOid: treeOid!,
                )
            : null,
      ),
    );
  }

  static Widget _buildTagTile(
    final BuildContext context,
    final TagEdge edge,
    final String currentRefValue,
    final OnRefSelected onRefSelected,
  ) {
    final TagNode? node = edge.node;
    if (node == null) return const SizedBox.shrink();
    final String tagName = node.name;
    bool isAnnotated = false;
    String? message;
    String? taggerName;
    String? taggerAvatarUrl;
    DateTime? committedDate;
    String? tagOid;
    String? treeOid;
    node.target?.maybeWhen(
      tag: (final TagAsTag t) {
        isAnnotated = t.message != null && t.message!.isNotEmpty;
        message = t.message;
        taggerName = t.tagger?.name;
        taggerAvatarUrl = t.tagger?.avatarUrl.toString();
        committedDate = t.tagger?.date ??
            t.target.maybeWhen(
              commit: (final TagTargetCommit c) {
                tagOid = c.oid;
                treeOid = c.tree.oid;
                return c.committedDate;
              },
              orElse: () => null,
            );
        tagOid ??= t.target.maybeWhen(
          commit: (final TagTargetCommit c) => c.oid,
          orElse: () => null,
        );
        treeOid ??= t.target.maybeWhen(
          commit: (final TagTargetCommit c) => c.tree.oid,
          orElse: () => null,
        );
      },
      commit: (final TagAsCommit c) {
        committedDate = c.committedDate;
        tagOid = c.oid;
        treeOid = c.tree.oid;
      },
      orElse: () {},
    );
    final RefListItemTagData tagData = RefListItemTagData(
      name: tagName,
      isAnnotated: isAnnotated,
      message: message,
      taggerName: taggerName,
      taggerAvatarUrl: taggerAvatarUrl,
      committedDate: committedDate,
    );
    final bool canSwitch =
        (tagOid?.isNotEmpty ?? false) && (treeOid?.isNotEmpty ?? false);
    return Padding(
      padding: context.spacing.screenPadding,
      child: RefListItem(
        variant: RefListItemVariant.tag,
        tagData: tagData,
        isHighlighted: currentRefValue == tagName,
        onTap: canSwitch
            ? () => onRefSelected(
                  tagName,
                  RefKind.tag,
                  oid: tagOid!,
                  treeOid: treeOid!,
                )
            : null,
      ),
    );
  }
}
