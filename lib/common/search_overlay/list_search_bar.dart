import 'dart:async';

import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Inline search/filter bar for list screens (e.g. repo Labels, Branches, Tags).
/// Updates [queryNotifier] on input; [onQueryChanged] is called after [debounceMs]
/// so the list can refresh with the new query.
class ListSearchBar extends StatefulWidget {
  const ListSearchBar({
    required this.queryNotifier,
    this.hintText = 'Filter',
    this.debounceMs = 300,
    this.onQueryChanged,
    super.key,
  });

  final ValueNotifier<String> queryNotifier;
  final String hintText;
  final int debounceMs;
  final VoidCallback? onQueryChanged;

  @override
  State<ListSearchBar> createState() => _ListSearchBarState();
}

class _ListSearchBarState extends State<ListSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.queryNotifier.value);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.queryNotifier.value = text;
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (mounted) widget.onQueryChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.pagePadding.left,
        spacing.tightSpacing,
        spacing.pagePadding.right,
        spacing.tightSpacing,
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon: widget.queryNotifier.value.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.queryNotifier.value = '';
                    setState(() {});
                    widget.onQueryChanged?.call();
                  },
                ),
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
