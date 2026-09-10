/// Unified diff parser: raw patch string → immutable [ParsedDiff] model.
///
/// Handles empty input, missing headers, line-ending normalization.
/// No Flutter/widget dependency; unit-testable.
library;

import 'dart:collection';

/// Info from a unified diff hunk header: @@ -oldStart,oldCount +newStart,newCount @@
class DiffHunkInfo {
  const DiffHunkInfo({
    required this.removeStart,
    required this.removeCount,
    required this.addStart,
    required this.addCount,
  });

  final int removeStart;
  final int removeCount;
  final int addStart;
  final int addCount;
}

/// One hunk: header info + raw lines (including the @@ line as first line in body).
class DiffHunk {
  const DiffHunk({
    required this.info,
    required this.rawLines,
    this.displayHeader,
  });

  final DiffHunkInfo info;
  final List<String> rawLines;

  /// Optional header string for display (e.g. '@@ -1,5 +1,6 @@').
  final String? displayHeader;
}

/// Result of parsing a unified diff string.
class ParsedDiff {
  const ParsedDiff({required this.hunks});

  final List<DiffHunk> hunks;

  bool get isEmpty => hunks.isEmpty;
}

/// Regex for hunk header: captures the part between @@ and @@ (e.g. "-1,5 +1,6").
final RegExp _headerPattern = RegExp(r'@@ (.+?) @@');

/// Parses a unified diff [patch] string into [ParsedDiff].
///
/// Returns empty [ParsedDiff] for null, empty, or input with no valid @@ headers.
/// Normalizes \r\n to \n before parsing.
ParsedDiff parseUnifiedDiff(final String? patch) {
  if (patch == null || patch.isEmpty) {
    return const ParsedDiff(hunks: <DiffHunk>[]);
  }
  final String normalized = patch.replaceAll('\r\n', '\n');
  final List<RegExpMatch> matches = _headerPattern
      .allMatches(normalized)
      .toList();
  if (matches.isEmpty) {
    return const ParsedDiff(hunks: <DiffHunk>[]);
  }

  final List<DiffHunk> hunks = <DiffHunk>[];
  for (int i = 0; i < matches.length; i++) {
    final RegExpMatch match = matches[i];
    final String? headerBody = match.group(1);
    if (headerBody == null || headerBody.isEmpty) continue;

    final DiffHunkInfo? info = _parseHeader(headerBody);
    if (info == null) continue;

    final int start = match.end;
    final int end = i + 1 < matches.length
        ? matches[i + 1].start
        : normalized.length;
    final String body = normalized.substring(start, end);
    final List<String> rawLines = body.split('\n');
    // Drop leading/trailing empty lines from split artifacts.
    final List<String> trimmed = rawLines
        .map((final String s) => s)
        .where((final String s) => s.isNotEmpty)
        .toList();

    hunks.add(
      DiffHunk(
        info: info,
        rawLines: trimmed,
        displayHeader: '@@ $headerBody @@',
      ),
    );
  }

  return ParsedDiff(hunks: hunks);
}

const int _maxCachedDiffEntries = 4;
const int _maxCachedDiffCharacters = 2 * 1024 * 1024;
final LinkedHashMap<String, ParsedDiff> _parsedDiffCache =
    LinkedHashMap<String, ParsedDiff>();
int _cachedDiffCharacters = 0;

/// Parses a patch while retaining a small, bounded set of render artifacts.
///
/// Diff widgets rebuild for settings and layout changes that do not change the
/// patch. Keeping the immutable parse result avoids repeating the synchronous
/// parser on the UI isolate. Very large patches bypass this cache so it cannot
/// become an unbounded second resource store.
ParsedDiff parseUnifiedDiffCached(final String? patch) {
  if (patch == null || patch.isEmpty) return parseUnifiedDiff(patch);
  final ParsedDiff? cached = _parsedDiffCache.remove(patch);
  if (cached != null) {
    _parsedDiffCache[patch] = cached;
    return cached;
  }

  final ParsedDiff parsed = parseUnifiedDiff(patch);
  if (patch.length > _maxCachedDiffCharacters) return parsed;
  while (_parsedDiffCache.length >= _maxCachedDiffEntries ||
      _cachedDiffCharacters + patch.length > _maxCachedDiffCharacters) {
    final String oldest = _parsedDiffCache.keys.first;
    _cachedDiffCharacters -= oldest.length;
    _parsedDiffCache.remove(oldest);
  }
  _parsedDiffCache[patch] = parsed;
  _cachedDiffCharacters += patch.length;
  return parsed;
}

/// Parses header body like "-1,5 +1,6" into [DiffHunkInfo], or null if invalid.
DiffHunkInfo? _parseHeader(final String headerBody) {
  final List<String> parts = headerBody.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return null;

  int? removeStart;
  int? removeCount;
  int? addStart;
  int? addCount;

  for (final String part in parts) {
    if (part.startsWith('-') && part.contains(',')) {
      final (int, int)? nums = _parseStartCount(part.substring(1));
      if (nums != null) {
        removeStart = nums.$1;
        removeCount = nums.$2;
      }
    } else if (part.startsWith('+') && part.contains(',')) {
      final (int, int)? nums = _parseStartCount(part.substring(1));
      if (nums != null) {
        addStart = nums.$1;
        addCount = nums.$2;
      }
    }
  }

  if (removeStart == null ||
      removeCount == null ||
      addStart == null ||
      addCount == null) {
    return null;
  }
  return DiffHunkInfo(
    removeStart: removeStart,
    removeCount: removeCount,
    addStart: addStart,
    addCount: addCount,
  );
}

/// Parses "start,count" into (start, count) or null.
(int, int)? _parseStartCount(final String s) {
  final int comma = s.indexOf(',');
  if (comma < 0) return null;
  final int? start = int.tryParse(s.substring(0, comma).trim());
  final int? count = int.tryParse(s.substring(comma + 1).trim());
  if (start == null || count == null || start < 0 || count < 0) return null;
  return (start, count);
}
