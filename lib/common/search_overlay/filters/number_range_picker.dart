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

/// Number range picker widget for search filters.
/// Allows entering min/max numeric values.
class NumberRangePicker extends StatefulWidget {
  const NumberRangePicker({
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
  State<NumberRangePicker> createState() => _NumberRangePickerState();
}

class _NumberRangePickerState extends State<NumberRangePicker> {
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final String min = _minController.text.trim();
    final String max = _maxController.text.trim();
    final String key = qualifierKeyForSection(widget.section);
    final List<String> values = widget.state.activeQualifierValues(key);
    final String? activeValue = values.isEmpty ? null : values.first;
    if (activeValue != null) {
      final QualifierExpression? qe =
          findQualifierExpression(widget.state, key, activeValue);
      if (qe != null) widget.notifier.removeQualifier(qe);
    }

    if (min.isNotEmpty && max.isNotEmpty) {
      addQualifierFromValue(
          widget.notifier, widget.state, widget.section, key, '$min..$max');
    } else if (min.isNotEmpty) {
      addQualifierFromValue(
          widget.notifier, widget.state, widget.section, key, '>=$min');
    } else if (max.isNotEmpty) {
      addQualifierFromValue(
          widget.notifier, widget.state, widget.section, key, '<=$max');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String key = qualifierKeyForSection(widget.section);
    final List<String> values = widget.state.activeQualifierValues(key);
    final String? activeValue = values.isEmpty ? null : values.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (activeValue != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              label: Text('${widget.section.displayName}: $activeValue'),
              onDeleted: () {
                final QualifierExpression? qe =
                    findQualifierExpression(widget.state, key, activeValue);
                if (qe != null) widget.notifier.removeQualifier(qe);
              },
            ),
          ),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Min',
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: context.spacing.listInset,
              child: Text(
                '–',
                style: context.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Max',
                  isDense: true,
                ),
              ),
            ),
            context.spacing.itemGap,
            IconButton(
              icon: const Icon(Icons.check_rounded, size: 20),
              onPressed: _apply,
            ),
          ],
        ),
      ],
    );
  }
}
