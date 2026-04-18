import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/commits/commit_providers.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode for commit filter: author or path.
enum CommitFilterMode { author, path }

class _CommitFilterPillModeNotifier extends Notifier<CommitFilterMode> {
  _CommitFilterPillModeNotifier(this._descriptor);

  final DockPillDescriptor _descriptor;

  @override
  CommitFilterMode build() => CommitFilterMode.author;
}

/// Current mode for a commit filter pill (author vs path).
final commitFilterPillModeProvider = NotifierProvider.autoDispose
    .family<_CommitFilterPillModeNotifier, CommitFilterMode,
        DockPillDescriptor>(_CommitFilterPillModeNotifier.new);

/// Active-phase: TextField for author or path filter. Updates commit providers via notifier (R2).
class CommitFilterPillContent extends ConsumerStatefulWidget {
  const CommitFilterPillContent({
    required this.repo,
    required this.descriptor,
    super.key,
  });

  final RepoRef repo;
  final DockPillDescriptor descriptor;

  @override
  ConsumerState<CommitFilterPillContent> createState() =>
      _CommitFilterPillContentState();
}

class _CommitFilterPillContentState
    extends ConsumerState<CommitFilterPillContent> {
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
    final notifier =
        ref.read(dockPillPhaseProvider(widget.descriptor).notifier);
    if (author != null || path != null) {
      notifier.hint();
    } else {
      notifier.idle();
    }
  }

  void _onSubmitted(String text) {
    if (text.trim().isEmpty) return;
    final t = text.trim();
    final mode = ref.read(commitFilterPillModeProvider(widget.descriptor));
    if (mode == CommitFilterMode.author) {
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
    final mode = ref.watch(commitFilterPillModeProvider(widget.descriptor));
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onSubmitted: _onSubmitted,
      decoration: InputDecoration(
        hintText: mode == CommitFilterMode.author
            ? 'Filter by author...'
            : 'Filter by path...',
        border: InputBorder.none,
        isDense: true,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Hint: "by @author" or "path: ...".
class CommitFilterPillHint extends ConsumerWidget {
  const CommitFilterPillHint({required this.repo, super.key});

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
