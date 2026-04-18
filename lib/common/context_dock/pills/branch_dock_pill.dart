import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/common/widgets/ref_selector_content.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/services/repositories/gql_order_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Callback for creating a new branch, returns a Future to show a sheet.
typedef CreateBranchCallback = Future<void> Function(
  BuildContext context,
  RepoRef repoRef,
  String repositoryId,
);

/// Dock pill for branch/tag ref selection.
///
/// Active: search field + overlay list + [Branches | Tags] companions.
/// Hint: branch/tag name when non-default. Idle: default ref.
class BranchDockPill extends DockPill {
  BranchDockPill({
    required this.repo,
    required this.defaultBranch,
    this.repositoryId,
    this.onCreateBranch,
  });

  final RepoRef repo;
  final String defaultBranch;

  /// When set, a "New branch" companion is shown when active.
  final String? repositoryId;

  /// Callback to show create branch sheet when "New branch" is tapped.
  /// This avoids common/ depending on view/.
  final CreateBranchCallback? onCreateBranch;

  RefKind _refKind = RefKind.branch;
  RefKind get refKind => _refKind;
  set refKind(RefKind v) {
    if (_refKind == v) return;
    _refKind = v;
    notifyListeners();
  }

  String? _searchQuery;
  String? get searchQuery => _searchQuery;
  set searchQuery(String? v) {
    if (_searchQuery == v) return;
    _searchQuery = v;
    notifyListeners();
  }

  @override
  IconData get icon => Octicons.git_branch;

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    _refKind = RefKind.branch;
    _searchQuery = null;
    final companions = <DockPill>[
      BasicDockPill(
        iconData: Octicons.git_branch,
        label: 'Branches',
        onTapAction: (_) {
          _refKind = RefKind.branch;
          notifyListeners();
        },
      ),
      BasicDockPill(
        iconData: Octicons.tag,
        label: 'Tags',
        onTapAction: (_) {
          _refKind = RefKind.tag;
          notifyListeners();
        },
      ),
    ];
    if (repositoryId != null && onCreateBranch != null) {
      companions.add(
        BasicDockPill(
          iconData: Octicons.plus,
          label: 'New branch',
          onTapAction: (_) {
            onCreateBranch!(context, repo, repositoryId!);
          },
        ),
      );
    }
    value = ActivePhase(companions: companions);
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      ActivePhase() => _BranchActiveContent(
          repo: repo,
          pill: this,
          defaultBranch: defaultBranch,
        ),
      HintPhase() => _BranchHintContent(
          repo: repo,
          defaultBranch: defaultBranch,
        ),
      IdlePhase() => null,
    };
  }

  @override
  Widget? buildOverlay(BuildContext context) {
    if (value is! ActivePhase) return null;
    return _BranchListOverlay(
      repo: repo,
      pill: this,
      defaultBranch: defaultBranch,
    );
  }
}

class _BranchActiveContent extends ConsumerStatefulWidget {
  const _BranchActiveContent({
    required this.repo,
    required this.pill,
    required this.defaultBranch,
  });

  final RepoRef repo;
  final BranchDockPill pill;
  final String defaultBranch;

  @override
  ConsumerState<_BranchActiveContent> createState() =>
      _BranchActiveContentState();
}

class _BranchActiveContentState extends ConsumerState<_BranchActiveContent> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.pill.searchQuery = text.isEmpty ? null : text;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.pill,
      builder: (context, _) {
        return TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: widget.pill.refKind == RefKind.branch
                ? 'Search branches...'
                : 'Search tags...',
            border: InputBorder.none,
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}

class _BranchListOverlay extends ConsumerWidget {
  const _BranchListOverlay({
    required this.repo,
    required this.pill,
    required this.defaultBranch,
  });

  final RepoRef repo;
  final BranchDockPill pill;
  final String defaultBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider(repo));
    final currentRefValue = switch (branchState) {
      BranchStateResolved(:final refValue) => refValue,
      BranchStateLoading() => '',
    };

    final orderBy = buildRefOrder();

    void onRefSelected(
      String name,
      RefKind kind, {
      required String oid,
      required String treeOid,
    }) {
      ref
          .read(branchProvider(repo).notifier)
          .setRef(name, kind, oid: oid, treeOid: treeOid);
      pill.value = kind == RefKind.branch && name == defaultBranch
          ? const IdlePhase()
          : const HintPhase();
    }

    return ListenableBuilder(
      listenable: pill,
      builder: (context, _) => RefSelectorContent(
        repo: repo,
        defaultBranch: defaultBranch,
        currentRefValue: currentRefValue,
        refKind: pill.refKind,
        onRefSelected: onRefSelected,
        orderBy: orderBy,
        searchQuery: pill.searchQuery,
      ),
    );
  }
}

class _BranchHintContent extends ConsumerWidget {
  const _BranchHintContent({
    required this.repo,
    required this.defaultBranch,
  });

  final RepoRef repo;
  final String defaultBranch;

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}…';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider(repo));
    final currentRefValue = switch (branchState) {
      BranchStateResolved(:final refValue) => refValue,
      BranchStateLoading() => '',
    };
    if (currentRefValue.isEmpty || currentRefValue == defaultBranch) {
      return const SizedBox.shrink();
    }
    return Text(
      _truncate(currentRefValue, 15),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
