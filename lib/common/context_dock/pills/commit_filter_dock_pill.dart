import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/commits/commit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Dock pill for commit author/path filtering.
///
/// Active: author/path TextField + type-selector companions.
/// Hint: "by @author" or "path: ...". Idle: no filter.
class CommitFilterDockPill extends DockPill {
  CommitFilterDockPill({
    required this.repo,
    required this.branch,
  });

  final RepoRef repo;
  final String branch;

  CommitFilterMode _mode = CommitFilterMode.author;
  CommitFilterMode get mode => _mode;
  set mode(CommitFilterMode v) {
    if (_mode == v) return;
    _mode = v;
    notifyListeners();
  }

  @override
  IconData get icon => Icons.filter_list_rounded;

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    _mode = CommitFilterMode.author;
    value = ActivePhase(companions: [
      BasicDockPill(
        iconData: Icons.person_outline,
        label: 'Author',
        onTapAction: (_) {
          _mode = CommitFilterMode.author;
          notifyListeners();
        },
      ),
      BasicDockPill(
        iconData: Octicons.file_code,
        label: 'Path',
        onTapAction: (_) {
          _mode = CommitFilterMode.path;
          notifyListeners();
        },
      ),
    ]);
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      ActivePhase() => _CommitFilterActiveContent(repo: repo, pill: this),
      HintPhase() => _CommitFilterHintContent(repo: repo),
      IdlePhase() => null,
    };
  }
}

enum CommitFilterMode { author, path }

class _CommitFilterActiveContent extends ConsumerStatefulWidget {
  const _CommitFilterActiveContent({
    required this.repo,
    required this.pill,
  });

  final RepoRef repo;
  final CommitFilterDockPill pill;

  @override
  ConsumerState<_CommitFilterActiveContent> createState() =>
      _CommitFilterActiveContentState();
}

class _CommitFilterActiveContentState
    extends ConsumerState<_CommitFilterActiveContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..requestFocus();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _dismiss();
  }

  void _dismiss() {
    final author = ref.read(commitAuthorFilterProvider(widget.repo));
    final path = ref.read(commitPathFilterProvider(widget.repo));
    widget.pill.value = (author != null || path != null)
        ? const HintPhase()
        : const IdlePhase();
  }

  void _onSubmitted(String text) {
    if (text.trim().isEmpty) return;
    final t = text.trim();
    if (widget.pill.mode == CommitFilterMode.author) {
      ref.read(commitAuthorFilterProvider(widget.repo).notifier).state = t;
    } else {
      ref.read(commitPathFilterProvider(widget.repo).notifier).state = t;
    }
    _dismiss();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.pill,
      builder: (context, _) {
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: _onSubmitted,
          decoration: InputDecoration(
            hintText: widget.pill.mode == CommitFilterMode.author
                ? 'Filter by author...'
                : 'Filter by path...',
            border: InputBorder.none,
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}

class _CommitFilterHintContent extends ConsumerWidget {
  const _CommitFilterHintContent({required this.repo});

  final RepoRef repo;

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}…';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(commitAuthorFilterProvider(repo));
    final path = ref.watch(commitPathFilterProvider(repo));

    if (author != null && author.isNotEmpty) {
      return Text(
        'by @$author',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
    if (path != null && path.isNotEmpty) {
      return Text(
        'path: ${_truncate(path, 15)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
    return const SizedBox.shrink();
  }
}
