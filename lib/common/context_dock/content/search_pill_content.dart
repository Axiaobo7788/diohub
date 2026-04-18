import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active-phase search field: TextField, 300ms debounce, writes to search notifier.
/// On unfocus updates pill phase via [dockPillPhaseProvider](descriptor).
class SearchPillContent extends ConsumerStatefulWidget {
  const SearchPillContent({
    required this.scope,
    required this.descriptor,
    super.key,
  });

  final SearchScope scope;
  final DockPillDescriptor descriptor;

  @override
  ConsumerState<SearchPillContent> createState() => _SearchPillContentState();
}

class _SearchPillContentState extends ConsumerState<SearchPillContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialText =
        ref.read(searchStateNotifierProvider(widget.scope)).freeText;
    _controller = TextEditingController(text: initialText);
    _focusNode = FocusNode()..addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _dismiss();
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(searchStateNotifierProvider(widget.scope).notifier)
          .updateFreeText(text);
    });
  }

  void _dismiss() {
    final text = _controller.text.trim();
    final notifier =
        ref.read(dockPillPhaseProvider(widget.descriptor).notifier);
    if (text.isEmpty) {
      notifier.idle();
    } else {
      notifier.hint();
    }
  }

  void _clear() {
    _controller.clear();
    ref
        .read(searchStateNotifierProvider(widget.scope).notifier)
        .updateFreeText('');
    ref.read(dockPillPhaseProvider(widget.descriptor).notifier).idle();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      searchStateNotifierProvider(widget.scope).select((s) => s.freeText),
      (prev, next) {
        if (next != _controller.text) {
          _controller.text = next;
          _controller.selection = TextSelection.collapsed(offset: next.length);
        }
      },
    );
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: _clear,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Hint-phase label: truncated free text from search state.
class SearchPillHint extends ConsumerWidget {
  const SearchPillHint({required this.scope, super.key});

  final SearchScope scope;

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}…';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freeText =
        ref.watch(searchStateNotifierProvider(scope).select((s) => s.freeText));
    if (freeText.isEmpty) return const SizedBox.shrink();

    return Text(
      _truncate(freeText, 20),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
