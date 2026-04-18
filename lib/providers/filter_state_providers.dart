import 'package:diohub_database/database/enums/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_state_providers.freezed.dart';

/// Bookmark filter state. The DAO accepts these as named params.
/// Single class — no parallel BookmarkQuery, no converter.
@freezed
abstract class BookmarkFilter with _$BookmarkFilter {
  const factory BookmarkFilter({
    EntityTypeFilter? entityType,
    EntityState? state,
    String? searchQuery,
    String? parentPath,
    @Default(BookmarkOrder.newest) BookmarkOrder order,
    @Default(true) bool descending,
    @Default(false) bool hasDrafts,
    @Default(false) bool hasDownloads,
  }) = _BookmarkFilter;
}

class _BookmarkFilterNotifier extends Notifier<BookmarkFilter> {
  @override
  BookmarkFilter build() => const BookmarkFilter();
}

/// Global bookmark filter state (Home → Bookmarks tab).
final bookmarkFilterProvider =
    NotifierProvider<_BookmarkFilterNotifier, BookmarkFilter>(
  _BookmarkFilterNotifier.new,
);

class _ScopedBookmarkFilterNotifier extends Notifier<BookmarkFilter> {
  _ScopedBookmarkFilterNotifier(this._arg);
  final String _arg;
  @override
  BookmarkFilter build() => BookmarkFilter(parentPath: _arg);
}

/// Scoped bookmark filter state (Repo → Bookmarks tab).
final scopedBookmarkFilterProvider =
    NotifierProvider.family<_ScopedBookmarkFilterNotifier, BookmarkFilter,
        String>(_ScopedBookmarkFilterNotifier.new);
