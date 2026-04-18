import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dock pill for scope-based search.
///
/// Active: auto-focused TextField, 300ms debounce to SearchStateNotifier.
/// Hint: truncated query from SearchState.freeText. Idle: empty.
///
/// Constructor takes pure data only — no WidgetRef.
class SearchDockPill extends DockPill {
  SearchDockPill({required this.scope});

  final SearchScope scope;

  @override
  IconData get icon => Icons.search_rounded;

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    value = const ActivePhase();
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      ActivePhase() => _SearchActiveContent(scope: scope, pill: this),
      HintPhase() => _SearchHintContent(scope: scope),
      IdlePhase() => null,
    };
  }
}

class _SearchActiveContent extends ConsumerStatefulWidget {
  const _SearchActiveContent({required this.scope, required this.pill});

  final SearchScope scope;
  final DockPill pill;

  @override
  ConsumerState<_SearchActiveContent> createState() =>
      _SearchActiveContentState();
}

class _SearchActiveContentState extends ConsumerState<_SearchActiveContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final currentText =
        ref.read(searchStateNotifierProvider(widget.scope)).freeText;
    _controller = TextEditingController(text: currentText);
    _focusNode = FocusNode()..requestFocus();
    _focusNode.addListener(_onFocusChange);
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
    widget.pill.value = text.isEmpty ? const IdlePhase() : const HintPhase();
  }

  void _clear() {
    _controller.clear();
    ref
        .read(searchStateNotifierProvider(widget.scope).notifier)
        .updateFreeText('');
    widget.pill.value = const IdlePhase();
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

class _SearchHintContent extends ConsumerWidget {
  const _SearchHintContent({required this.scope});
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
