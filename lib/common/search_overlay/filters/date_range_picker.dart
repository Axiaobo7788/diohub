import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/search_filter_helpers.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:flutter/material.dart';

/// Date range picker widget for search filters.
/// Allows selecting "After", "Before", or custom date ranges.
class DateRangePicker extends StatelessWidget {
  const DateRangePicker({
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

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final String key = qualifierKeyForSection(section);
    final List<String> values = state.activeQualifierValues(key);
    final String? activeValue = values.isEmpty ? null : values.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (activeValue != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              label: Text('${section.displayName}: $activeValue'),
              onDeleted: () {
                final QualifierExpression? qe =
                    findQualifierExpression(state, key, activeValue);
                if (qe != null) notifier.removeQualifier(qe);
              },
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            ActionChip(
              label: const Text('After...'),
              onPressed: () async {
                final DateTime? date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2008),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  if (activeValue != null) {
                    final QualifierExpression? qe =
                        findQualifierExpression(state, key, activeValue);
                    if (qe != null) notifier.removeQualifier(qe);
                  }
                  addQualifierFromValue(
                      notifier, state, section, key, '>${_formatDate(date)}');
                }
              },
            ),
            ActionChip(
              label: const Text('Before...'),
              onPressed: () async {
                final DateTime? date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2008),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  if (activeValue != null) {
                    final QualifierExpression? qe =
                        findQualifierExpression(state, key, activeValue);
                    if (qe != null) notifier.removeQualifier(qe);
                  }
                  addQualifierFromValue(
                      notifier, state, section, key, '<${_formatDate(date)}');
                }
              },
            ),
            ActionChip(
              label: const Text('Range...'),
              onPressed: () async {
                final DateTimeRange? range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2008),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  if (activeValue != null) {
                    final QualifierExpression? qe =
                        findQualifierExpression(state, key, activeValue);
                    if (qe != null) notifier.removeQualifier(qe);
                  }
                  addQualifierFromValue(
                    notifier,
                    state,
                    section,
                    key,
                    '${_formatDate(range.start)}..${_formatDate(range.end)}',
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
