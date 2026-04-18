import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/search_filter_helpers.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaticChipRow extends ConsumerWidget {
  const StaticChipRow({
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

  static bool _isQualifierActive(SearchState state, String key, String value) {
    final String token = '$key:$value';
    return state.activeQualifiers
        .any((QualifierExpression q) => q.toQueryFragment() == token);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String>? options = section.optionsOrNull;
    if (options == null || options.isEmpty) return const SizedBox.shrink();

    final String qualifierKey = qualifierKeyForSection(section);
    final bool isSort = section.id == 'sort';

    return Wrap(
      spacing: context.spacing.tightSpacing,
      runSpacing: context.spacing.tightSpacing,
      children: options.entries.map((MapEntry<String, String> e) {
        final String value = e.key;
        final String label = e.value.isEmpty ? value : e.value;
        final bool selected = isSort
            ? (state.sort?.key == value)
            : _isQualifierActive(state, qualifierKey, value);
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (bool _) {
            if (isSort) {
              if (selected) {
                notifier.updateSort(null);
              } else {
                SortOption? option;
                for (final SortOption o in scope.sortConfig.options) {
                  if (o.key == value) {
                    option = o;
                    break;
                  }
                }
                if (option != null) notifier.updateSort(option);
              }
            } else {
              final QualifierValueParser? parser =
                  notifier.parserForPartial('$qualifierKey:');
              if (parser == null) return;
              final Qualifier? q = parser.tryParse(qualifierKey, value);
              if (q == null) return;
              final QualifierExpression qe = QualifierExpression(q);
              if (section.multiSelect) {
                if (selected) {
                  notifier.removeQualifier(qe);
                } else {
                  notifier.addQualifier(qe);
                }
              } else {
                removeAllForKey(notifier, state, qualifierKey);
                notifier.addQualifier(qe);
              }
            }
          },
        );
      }).toList(),
    );
  }
}
