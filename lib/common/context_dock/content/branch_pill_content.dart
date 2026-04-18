import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/widgets/ref_selector_content.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/dock/branch_pill_state_provider.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/services/repositories/gql_order_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active-phase branch search field. Writes to [branchPillStateProvider](descriptor).
class BranchPillContent extends ConsumerStatefulWidget {
  const BranchPillContent({
    required this.repo,
    required this.descriptor,
    required this.defaultBranch,
    super.key,
  });

  final RepoRef repo;
  final DockPillDescriptor descriptor;
  final String defaultBranch;

  @override
  ConsumerState<BranchPillContent> createState() => _BranchPillContentState();
}

class _BranchPillContentState extends ConsumerState<BranchPillContent> {
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
      ref
          .read(branchPillStateProvider(widget.descriptor).notifier)
          .setSearchQuery(text.isEmpty ? null : text);
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
    final branchState = ref.watch(branchPillStateProvider(widget.descriptor));
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: branchState.refKind == RefKind.branch
            ? 'Search branches...'
            : 'Search tags...',
        border: InputBorder.none,
        isDense: true,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Overlay: ref list (branches/tags) with search. Updates [branchProvider] and pill phase on selection.
class BranchPillOverlay extends ConsumerWidget {
  const BranchPillOverlay({
    required this.repo,
    required this.descriptor,
    required this.defaultBranch,
    super.key,
  });

  final RepoRef repo;
  final DockPillDescriptor descriptor;
  final String defaultBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider(repo));
    final currentRefValue = switch (branchState) {
      BranchStateResolved(:final refValue) => refValue,
      BranchStateLoading() => '',
    };

    final pillState = ref.watch(branchPillStateProvider(descriptor));
    final phaseNotifier = ref.read(dockPillPhaseProvider(descriptor).notifier);
    final branchNotifier = ref.read(branchProvider(repo).notifier);

    final orderBy = buildRefOrder();

    void onRefSelected(
      String name,
      RefKind kind, {
      required String oid,
      required String treeOid,
    }) {
      branchNotifier.setRef(name, kind, oid: oid, treeOid: treeOid);
      if (kind == RefKind.branch && name == defaultBranch) {
        phaseNotifier.idle();
      } else {
        phaseNotifier.hint();
      }
    }

    return RefSelectorContent(
      repo: repo,
      defaultBranch: defaultBranch,
      currentRefValue: currentRefValue,
      refKind: pillState.refKind,
      onRefSelected: onRefSelected,
      orderBy: orderBy,
      searchQuery: pillState.searchQuery,
    );
  }
}

/// Hint-phase label: truncated branch/tag name when non-default.
class BranchPillHint extends ConsumerWidget {
  const BranchPillHint({
    required this.repo,
    required this.defaultBranch,
    super.key,
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
