import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/search_filter_helpers.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSearchPicker extends ConsumerStatefulWidget {
  const UserSearchPicker({
    required this.scope,
    required this.section,
    required this.state,
    required this.notifier,
    super.key,
  });

  final SearchScope scope;
  final FilterSectionDef section;
  final SearchState state;
  final SearchStateNotifier notifier;

  @override
  ConsumerState<UserSearchPicker> createState() => _UserSearchPickerState();
}

class _UserSearchPickerState extends ConsumerState<UserSearchPicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addUser(String username) {
    if (username.isEmpty) return;
    final String key = qualifierKeyForSection(widget.section);
    addQualifierFromValue(
      widget.notifier,
      widget.state,
      widget.section,
      key,
      username,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final String key = qualifierKeyForSection(widget.section);
    final List<String> activeValues = widget.state.activeQualifierValues(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (activeValues.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeValues.map((String v) {
              final QualifierExpression? qe =
                  findQualifierExpression(widget.state, key, v);
              return Chip(
                label: Text(v),
                onDeleted: qe != null
                    ? () => widget.notifier.removeQualifier(qe)
                    : null,
              );
            }).toList(),
          ),
        if (activeValues.isNotEmpty) context.spacing.itemGap,
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Search ${widget.section.displayName.toLowerCase()}...',
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _addUser(_controller.text.trim()),
            ),
          ),
          onSubmitted: (String v) => _addUser(v.trim()),
        ),
      ],
    );
  }
}
