import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/search/match_strategy.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether client-side text filtering uses fuzzy matching (vs exact substring).
final Provider<bool> fuzzyFilteringProvider = Provider<bool>((ref) {
  return ref.watch(appearanceProvider).fuzzyFiltering;
});

/// Match strategy for client-side filters (substring or fuzzy) from app settings.
final Provider<MatchStrategy> matchStrategyProvider =
    Provider<MatchStrategy>((ref) {
  final fuzzy = ref.watch(fuzzyFilteringProvider);
  return fuzzy ? const FuzzyMatch() : const SubstringMatch();
});
