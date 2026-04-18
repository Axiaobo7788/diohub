import 'dart:async';

import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active-phase inline search field. Writes to [queryNotifier], updates pill phase on unfocus/clear.
class InlineSearchPillContent extends ConsumerStatefulWidget {
  const InlineSearchPillContent({
    required this.descriptor,
    required this.queryNotifier,
    super.key,
  });

  final DockPillDescriptor descriptor;
  final ValueNotifier<String> queryNotifier;

  @override
  ConsumerState<InlineSearchPillContent> createState() =>
      _InlineSearchPillContentState();
}

class _InlineSearchPillContentState
    extends ConsumerState<InlineSearchPillContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.queryNotifier.value);
    _focusNode = FocusNode()..requestFocus();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _dismiss();
  }

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.queryNotifier.value = text.trim();
    });
  }

  void _dismiss() {
    final text = _controller.text.trim();
    widget.queryNotifier.value = text;
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
    widget.queryNotifier.value = '';
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

/// Hint: truncated query text.
class InlineSearchPillHint extends StatelessWidget {
  const InlineSearchPillHint({required this.queryNotifier, super.key});

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
