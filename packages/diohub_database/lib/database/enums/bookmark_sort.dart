/// Sort options for bookmark lists. Sealed to allow entity-type-specific sorts.
/// Common sorts available for all entity types.
sealed class BookmarkSort {
  const BookmarkSort();
}

class SortByCreated extends BookmarkSort {
  const SortByCreated();
}

class SortByUpdated extends BookmarkSort {
  const SortByUpdated();
}

class SortByTitle extends BookmarkSort {
  const SortByTitle();
}

class SortByComments extends BookmarkSort {
  const SortByComments();
}

/// Sort repos by star count. Only when entityType is repo (or null).
class SortByStars extends BookmarkSort {
  const SortByStars();
}
