// ignore_for_file: avoid_classes_with_only_static_members

/// Helper for splitting date ranges into chunks and fetching data
class DateChunkingHelper {
  /// Split date range into year chunks
  ///
  /// Returns list of (from, to) tuples for each year
  static List<(DateTime, DateTime)> splitIntoYearChunks(
    DateTime from,
    DateTime to,
  ) {
    final chunks = <(DateTime, DateTime)>[];
    var currentFrom = from;

    while (currentFrom.isBefore(to) ||
        (currentFrom.year == to.year &&
            currentFrom.month == to.month &&
            currentFrom.day == to.day)) {
      final oneYearLater = DateTime(
        currentFrom.year + 1,
        currentFrom.month,
        currentFrom.day,
      );

      DateTime chunkTo;
      if (oneYearLater.isAfter(to)) {
        chunkTo = to;
      } else {
        chunkTo = DateTime(
          currentFrom.year,
          12,
          31,
        );
      }

      chunks.add((currentFrom, chunkTo));

      if (chunkTo.year == to.year &&
          chunkTo.month == to.month &&
          chunkTo.day == to.day) {
        break;
      }

      currentFrom = chunkTo.add(const Duration(days: 1));

      if (chunks.length > 100) {
        throw Exception(
          'Date range splitting exceeded maximum chunks (100). Range: $from to $to',
        );
      }
    }

    return chunks;
  }

  /// Split date range into quarterly chunks (3-month periods)
  ///
  /// **Why quarterly instead of yearly?**
  /// - Used for commit repository limit workaround (maxRepositories: 50)
  /// - Different repos are active in different time periods
  /// - Quarterly chunks are small enough to surface different repos
  /// - But large enough to avoid excessive API calls
  /// - Yearly chunks might still hit the 50 repo limit if user is very active
  ///
  /// **Example:**
  /// - User has 75 repos with commits
  /// - Q1 query: Gets repos 1-30 (different repos active in Q1)
  /// - Q2 query: Gets repos 31-50 (different repos active in Q2)
  /// - Q3 query: Gets repos 51-60 (repos that were missing before)
  /// - Q4 query: Gets repos 61-75 (remaining repos)
  /// - Result: All 75 repos retrieved by querying different time periods
  static List<(DateTime, DateTime)> splitIntoQuarterlyChunks(
    DateTime from,
    DateTime to,
  ) {
    final chunks = <(DateTime, DateTime)>[];
    var currentFrom = from;

    // Loop until we've covered the entire date range
    // The condition handles edge cases where from == to
    while (currentFrom.isBefore(to) ||
        (currentFrom.year == to.year &&
            currentFrom.month == to.month &&
            currentFrom.day == to.day)) {
      // Calculate which quarter we're in (1-4)
      // Formula: ((month - 1) / 3) + 1 gives us quarter number
      final quarter = ((currentFrom.month - 1) ~/ 3) + 1;
      final quarterEndMonth = quarter * 3;

      DateTime chunkTo;
      // Handle case where we're in the same year and quarter extends past 'to'
      if (currentFrom.year == to.year && quarterEndMonth > to.month) {
        chunkTo = to;
      } else {
        // Calculate last day of current quarter
        // Next quarter starts on month 1 of next quarter, so subtract 1 day
        final nextQuarterStart = DateTime(
          currentFrom.year,
          quarterEndMonth > 12 ? 1 : quarterEndMonth,
          1,
        );
        chunkTo = nextQuarterStart.subtract(const Duration(days: 1));

        // Ensure we don't go past the end date
        if (chunkTo.isAfter(to)) {
          chunkTo = to;
        }
      }

      chunks.add((currentFrom, chunkTo));

      // Exit condition: we've reached the end date
      if (chunkTo.year == to.year &&
          chunkTo.month == to.month &&
          chunkTo.day == to.day) {
        break;
      }

      // Move to next day after current chunk ends
      // This ensures no gaps or overlaps between chunks
      currentFrom = chunkTo.add(const Duration(days: 1));

      // Safety check: prevent infinite loops from date calculation bugs
      if (chunks.length > 100) {
        throw Exception(
          'Date range splitting exceeded maximum chunks (100). Range: $from to $to',
        );
      }
    }

    return chunks;
  }

  /// Fetch data in chunks with optional parallel execution
  ///
  /// **Why parallel fetching?**
  /// - Chunks are independent (different date ranges)
  /// - No data dependencies between chunks
  /// - Dramatically reduces total fetch time (4 chunks fetch simultaneously)
  /// - Trade-off: More concurrent API requests (but GitHub API handles this well)
  ///
  /// **Why eagerError: true?**
  /// - If one chunk fails, fail fast rather than waiting for all chunks
  /// - Better error messages (know which chunk failed immediately)
  /// - Prevents wasting time on remaining chunks if one fails
  ///
  /// **When to use sequential (parallel: false)?**
  /// - Rate limiting concerns (if API has strict limits)
  /// - Memory constraints (parallel fetches use more memory)
  /// - Need to process chunks as they arrive (streaming)
  ///
  /// [chunkSplitter] - Function that splits date range into chunks
  /// [fetchChunk] - Function that fetches data for a chunk
  /// [parallel] - Whether to fetch chunks in parallel (default: true)
  static Future<List<T>> fetchInChunks<T>({
    required DateTime from,
    required DateTime to,
    required List<(DateTime, DateTime)> Function(DateTime, DateTime)
        chunkSplitter,
    required Future<T> Function(DateTime from, DateTime to) fetchChunk,
    bool parallel = true,
  }) async {
    final chunks = chunkSplitter(from, to);

    // Early return for empty ranges
    if (chunks.isEmpty) {
      return [];
    }

    if (parallel) {
      // Fetch all chunks simultaneously
      // eagerError: true means fail immediately if any chunk fails
      return await Future.wait(
        chunks.map((chunk) => fetchChunk(chunk.$1, chunk.$2)),
        eagerError: true,
      );
    } else {
      // Sequential fetching (one at a time)
      // Useful for rate limiting or memory constraints
      final results = <T>[];
      for (final chunk in chunks) {
        results.add(await fetchChunk(chunk.$1, chunk.$2));
      }
      return results;
    }
  }
}
