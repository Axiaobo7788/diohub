import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the current search session for history grouping.
/// Set when search executes, cleared when user navigates away from search.
class SearchSessionState {
  const SearchSessionState({
    required this.sessionId,
    this.label,
  });
  final String sessionId;
  final String? label;
}

class _SearchSessionNotifier extends Notifier<SearchSessionState?> {
  @override
  SearchSessionState? build() => null;

  void clear() {
    state = null;
  }

  void setSession(SearchSessionState session) {
    state = session;
  }
}

final searchSessionProvider =
    NotifierProvider<_SearchSessionNotifier, SearchSessionState?>(
  _SearchSessionNotifier.new,
);
