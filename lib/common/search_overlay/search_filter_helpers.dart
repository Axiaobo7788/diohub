import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';

/// Qualifier key used for parser lookup (e.g. status -> state).
String qualifierKeyForSection(FilterSectionDef section) {
  if (section.id == 'status') return 'state';
  return section.id;
}

/// Remove all qualifiers matching the given key.
void removeAllForKey(
  SearchStateNotifier notifier,
  SearchState state,
  String key,
) {
  final List<QualifierExpression> toRemove =
      state.activeQualifiers.where((QualifierExpression q) {
    final String s = q.qualifier.toQueryString();
    final String qKey = s.contains(':') ? s.substring(0, s.indexOf(':')) : s;
    return qKey == key;
  }).toList();
  for (final QualifierExpression q in toRemove) {
    notifier.removeQualifier(q);
  }
}

/// Find a qualifier expression matching the given key and value.
QualifierExpression? findQualifierExpression(
  SearchState state,
  String key,
  String value,
) {
  final String token = '$key:$value';
  for (final QualifierExpression q in state.activeQualifiers) {
    if (q.toQueryFragment() == token) return q;
  }
  return null;
}

/// Add a qualifier from a value using the appropriate parser.
void addQualifierFromValue(
  SearchStateNotifier notifier,
  SearchState state,
  FilterSectionDef section,
  String qualifierKey,
  String value,
) {
  final QualifierValueParser? parser =
      notifier.parserForPartial('$qualifierKey:');
  if (parser == null) return;
  final Qualifier? q = parser.tryParse(qualifierKey, value);
  if (q == null) return;
  final QualifierExpression qe = QualifierExpression(q);
  if (!section.multiSelect) {
    removeAllForKey(notifier, state, qualifierKey);
  }
  notifier.addQualifier(qe);
}
