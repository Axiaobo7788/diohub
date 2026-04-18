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

class DynamicChipRow extends ConsumerWidget {
  const DynamicChipRow({
    required this.scope,
    required this.section,
    required this.state,
    required this.notifier,
    required this.options,
    super.key,
  });

  final SearchScope scope;
  final FilterSectionDef section;
  final SearchState state;
  final SearchStateNotifier notifier;
  final List<FilterOption> options;

  static bool _isQualifierActive(SearchState state, String key, String value) {
    final String token = '$key:$value';
    return state.activeQualifiers
        .any((QualifierExpression q) => q.toQueryFragment() == token);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String qualifierKey = qualifierKeyForSection(section);

    return Wrap(
      spacing: context.spacing.tightSpacing,
      runSpacing: context.spacing.tightSpacing,
      children: options.map<Widget>((FilterOption option) {
        final String value = option.value;
        final String label = option.display;
        final bool selected = _isQualifierActive(state, qualifierKey, value);
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (bool _) {
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
          },
        );
      }).toList(),
    );
  }
}
