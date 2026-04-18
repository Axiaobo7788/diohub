import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookmarkViewMode { flat, byRepo, byType }

extension BookmarkViewModeX on BookmarkViewMode {
  String get label => switch (this) {
        BookmarkViewMode.flat => 'Flat',
        BookmarkViewMode.byRepo => 'By Repo',
        BookmarkViewMode.byType => 'By Type',
      };
}

class _BookmarkViewModeNotifier extends Notifier<BookmarkViewMode> {
  @override
  BookmarkViewMode build() => BookmarkViewMode.flat;
}

final bookmarkViewModeProvider =
    NotifierProvider<_BookmarkViewModeNotifier, BookmarkViewMode>(
  _BookmarkViewModeNotifier.new,
);

enum HistoryViewMode { byTime, byRepo, flat }

extension HistoryViewModeX on HistoryViewMode {
  String get label => switch (this) {
        HistoryViewMode.byTime => 'By Time',
        HistoryViewMode.byRepo => 'By Repo',
        HistoryViewMode.flat => 'Flat',
      };
}

class _HistoryViewModeNotifier extends Notifier<HistoryViewMode> {
  @override
  HistoryViewMode build() => HistoryViewMode.byTime;
}

final historyViewModeProvider =
    NotifierProvider<_HistoryViewModeNotifier, HistoryViewMode>(
  _HistoryViewModeNotifier.new,
);
