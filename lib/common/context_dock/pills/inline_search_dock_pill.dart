import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dock pill for non-scope inline search (e.g. labels, branches, tags list).
///
/// Writes to [queryNotifier], not SearchStateNotifier.
/// Active: TextField. Hint: truncated query. Idle: empty.
class InlineSearchDockPill extends DockPill {
  InlineSearchDockPill({required this.queryNotifier});

  final ValueNotifier<String> queryNotifier;

  @override
  IconData get icon => Icons.search_rounded;

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    value = const ActivePhase();
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      ActivePhase() => _InlineSearchActiveContent(pill: this),
      HintPhase() => _InlineSearchHintContent(queryNotifier: queryNotifier),
      IdlePhase() => null,
    };
  }
}

class _InlineSearchActiveContent extends StatefulWidget {
  const _InlineSearchActiveContent({required this.pill});

  final InlineSearchDockPill pill;

  @override
  State<_InlineSearchActiveContent> createState() =>
      _InlineSearchActiveContentState();
}

class _InlineSearchActiveContentState
    extends State<_InlineSearchActiveContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.pill.queryNotifier.value);
    _focusNode = FocusNode()..requestFocus();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _dismiss();
  }

  void _dismiss() {
    final text = _controller.text.trim();
    widget.pill.queryNotifier.value = text;
    widget.pill.value = text.isEmpty ? const IdlePhase() : const HintPhase();
  }

  void _clear() {
    _controller.clear();
    widget.pill.queryNotifier.value = '';
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

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.pill.queryNotifier.value = text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onQueryChanged,
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

class _InlineSearchHintContent extends StatelessWidget {
  const _InlineSearchHintContent({required this.queryNotifier});

  final ValueNotifier<String> queryNotifier;

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}…';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: queryNotifier,
      builder: (BuildContext context, String value, Widget? child) {
        if (value.isEmpty) return const SizedBox.shrink();
        return Text(
          _truncate(value, 20),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        );
      },
    );
  }
}
