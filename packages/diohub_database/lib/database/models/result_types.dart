part of '../database.dart';

/// Bookmark list item — bookmark relationship + entity data + optional entity-type snapshot.
typedef BookmarkWithEntity = ({
  BookmarkEntry bookmark,
  EntityCacheEntry entity,
  EntityTypeSnapshot? snapshot,
});

/// History list item — visit relationship + entity data.
typedef HistoryWithEntity = ({
  HistoryEntry visit,
  EntityCacheEntry entity,
});

/// Draft list item — draft + entity data.
typedef DraftWithEntity = ({
  DraftEntry draft,
  EntityCacheEntry entity,
});

/// Download list item — download + entity data.
typedef DownloadWithEntity = ({
  DownloadHistoryEntry download,
  EntityCacheEntry entity,
});
