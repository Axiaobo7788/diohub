import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/search_filter_helpers.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Text picker widget for search filters.
/// Allows free text entry with chips for multiple values.
class TextPicker extends StatefulWidget {
  const TextPicker({
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
  State<TextPicker> createState() => _TextPickerState();
}

class _TextPickerState extends State<TextPicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    final String key = qualifierKeyForSection(widget.section);
    addQualifierFromValue(
      widget.notifier,
      widget.state,
      widget.section,
      key,
      value,
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
            hintText: 'Enter ${widget.section.displayName.toLowerCase()}...',
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: _add,
            ),
          ),
          onSubmitted: (_) => _add(),
        ),
      ],
    );
  }
}
