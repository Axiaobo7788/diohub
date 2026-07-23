import 'package:diohub/common/nav_center/models/preset.dart';
import 'package:diohub/common/search_overlay/filters.dart' show SearchType;
import 'package:diohub/models/search/qualifier_parser_registry.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/filters/custom_filter.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart' show SearchState;
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub/providers/search/search_session_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected search type per scope (e.g. Issues vs Pulls). Defaults to
/// [SearchScope.searchType]; use [selectedSearchTypeProvider(scope)] in UI
/// and [switchSearchType] to update.
final selectedSearchTypeProvider =
    NotifierProvider.family<
      SelectedSearchTypeNotifier,
      SearchType,
      SearchScope
    >(SelectedSearchTypeNotifier.new);

class SelectedSearchTypeNotifier extends Notifier<SearchType> {
  SelectedSearchTypeNotifier(this._scope);
  final SearchScope _scope;

  @override
  SearchType build() => _scope.searchType;
}

/// One-off initial query when opening search (e.g. from TopicRef). Consumed by the first position.
final pendingSearchInitialQueryProvider =
    NotifierProvider<PendingSearchInitialQueryNotifier, String?>(
      PendingSearchInitialQueryNotifier.new,
    );

class PendingSearchInitialQueryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) {
    state = value;
  }
}

/// Family notifier: one [SearchState] per [SearchScope]. Single source of truth for search.
class SearchStateNotifier extends Notifier<SearchState> {
  SearchStateNotifier(this.scope);
  final SearchScope scope;
  late QualifierParserRegistry _registry;
  bool _didInitializeDefaultPreset = false;

  @override
  SearchState build() {
    final viewerLogin = ref.read(currentUserProvider).value?.login;
    final resolvedScope = _resolveScope(scope, viewerLogin);
    _registry = QualifierParserRegistry.forScope(resolvedScope);

    // The viewer can finish loading after this search scope is mounted. Listen
    // for that transition so @me-aware controls get the resolved scope without
    // making this notifier rebuild and discard the user's current query.
    ref.listen(currentUserProvider, (_, final next) {
      final nextScope = _resolveScope(scope, next.value?.login);
      if (nextScope == state.scope) return;
      _registry = QualifierParserRegistry.forScope(nextScope);
      state = state.copyWith(scope: nextScope);
    });

    return SearchState(scope: resolvedScope);
  }

  SearchScope _resolveScope(SearchScope scope, String? viewerLogin) {
    return scope.resolveViewerLogin(viewerLogin ?? '');
  }

  void updateFreeText(String text) {
    final result = _registry.extractFromText(text);
    if (result.qualifiers.isNotEmpty) {
      state = state.withParsedInput(
        freeText: result.freeText,
        qualifiers: result.qualifiers,
      );
    } else {
      state = state.copyWith(freeText: text);
    }
  }

  void setRawFreeText(String text) {
    state = state.copyWith(freeText: text);
    if (text.trim().isNotEmpty) {
      ref
          .read(searchSessionProvider.notifier)
          .setSession(
            SearchSessionState(
              sessionId: 'search-${DateTime.now().millisecondsSinceEpoch}',
              label: text.trim(),
            ),
          );
    }
  }

  void commitFreeText() {
    final result = _registry.extractFromText(state.freeText);
    if (result.qualifiers.isNotEmpty) {
      state = state.withParsedInput(
        freeText: result.freeText,
        qualifiers: result.qualifiers,
      );
    }
  }

  void addQualifier(QualifierExpression q) {
    state = state.copyWith(activeQualifiers: [...state.activeQualifiers, q]);
  }

  void removeQualifier(QualifierExpression q) {
    state = state.copyWith(
      activeQualifiers: state.activeQualifiers.where((e) => e != q).toList(),
    );
  }

  void updateSort(SortOption? sort) {
    state = state.copyWith(sort: sort);
  }

  void toggleQuickFilter(QuickFilter filter) {
    state = state.withQuickFilter(filter);
  }

  /// Replace state with [filter]'s qualifiers, sort, and free text.
  void applyCustomFilter(CustomFilter filter) {
    state = state.copyWith(
      freeText: filter.freeText ?? '',
      activeQualifiers: List<QualifierExpression>.from(filter.qualifiers),
      sort: filter.sort,
    );
  }

  void toggleQuickOption(QuickOption option, {required bool enabled}) {
    state = state.withQuickOption(option, enabled: enabled);
  }

  void switchSearchType(SearchType type) {
    ref.read(selectedSearchTypeProvider(scope).notifier).state = type;
  }

  void clear() {
    state = state.cleared;
  }

  void applyPreset(NavigationPreset preset) {
    if (preset.qualifier.isEmpty) {
      state = state.cleared;
      return;
    }
    final viewerLogin = ref.read(currentUserProvider).value?.login ?? '';
    final qs = preset.qualifier.replaceAll('@me', viewerLogin);
    final result = _registry.extractFromText(qs);
    if (result.qualifiers.isNotEmpty) {
      state = state.copyWith(
        freeText: result.freeText,
        activeQualifiers: result.qualifiers,
      );
    }
  }

  /// Applies the single default preset once for this provider lifecycle.
  ///
  /// Calling this from repeated widget builds is safe. If the user has already
  /// entered a query or selected a filter before initialization, their state is
  /// preserved and the default is considered consumed.
  void initializeDefaultPreset(Iterable<NavigationPreset> presets) {
    if (_didInitializeDefaultPreset) return;
    _didInitializeDefaultPreset = true;
    if (state.isActive) return;

    NavigationPreset? defaultPreset;
    for (final NavigationPreset preset in presets) {
      if (preset.isDefault) {
        defaultPreset = preset;
        break;
      }
    }
    if (defaultPreset != null) {
      applyPreset(defaultPreset);
    }
  }

  QualifierValueParser? parserForPartial(String partialToken) =>
      _registry.parserForPartial(partialToken);
}

final searchStateNotifierProvider =
    NotifierProvider.family<SearchStateNotifier, SearchState, SearchScope>(
      SearchStateNotifier.new,
    );
