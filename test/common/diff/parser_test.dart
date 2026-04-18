import 'package:diohub/common/diff/diff.dart';
import 'package:test/test.dart';

void main() {
  group('parseUnifiedDiff', () {
    test('returns empty for null', () {
      final ParsedDiff result = parseUnifiedDiff(null);
      expect(result.hunks, isEmpty);
    });

    test('returns empty for empty string', () {
      final ParsedDiff result = parseUnifiedDiff('');
      expect(result.hunks, isEmpty);
    });

    test('returns empty when no @@ header', () {
      final ParsedDiff result = parseUnifiedDiff('some text\nno header here');
      expect(result.hunks, isEmpty);
    });

    test('parses single hunk', () {
      const String patch = '''
@@ -1,5 +1,6 @@
 line1
-line2
+line2new
 line3
''';
      final ParsedDiff result = parseUnifiedDiff(patch);
      expect(result.hunks.length, 1);
      final DiffHunk hunk = result.hunks.first;
      expect(hunk.info.removeStart, 1);
      expect(hunk.info.removeCount, 5);
      expect(hunk.info.addStart, 1);
      expect(hunk.info.addCount, 6);
      expect(hunk.rawLines, <String>[' line1', '-line2', '+line2new', ' line3']);
    });

    test('parses multiple hunks', () {
      const String patch = '''
@@ -1,3 +1,3 @@
 a
 b
 c
@@ -10,2 +10,2 @@
 x
 y
''';
      final ParsedDiff result = parseUnifiedDiff(patch);
      expect(result.hunks.length, 2);
      expect(result.hunks[0].info.removeStart, 1);
      expect(result.hunks[0].rawLines.length, 3);
      expect(result.hunks[1].info.removeStart, 10);
      expect(result.hunks[1].rawLines.length, 2);
    });

    test('normalizes line endings', () {
      const String patch = '@@ -1,1 +1,1 @@\r\n old\r\n+new\r\n';
      final ParsedDiff result = parseUnifiedDiff(patch);
      expect(result.hunks.length, 1);
      expect(result.hunks.first.rawLines, <String>[' old', '+new']);
    });

    test('buildDiffLines assigns line numbers correctly', () {
      const String patch = '''
@@ -1,3 +1,4 @@
 unchanged
-removed
+added
 same
''';
      final ParsedDiff parsed = parseUnifiedDiff(patch);
      expect(parsed.hunks.length, 1);
      final List<DiffLine> lines =
          buildDiffLines(parsed.hunks.first.info, parsed.hunks.first.rawLines);
      expect(lines.length, 4);
      expect(lines[0].prefix, ' ');
      expect(lines[0].oldLineNumber, 1);
      expect(lines[0].newLineNumber, 1);
      expect(lines[1].prefix, '-');
      expect(lines[1].oldLineNumber, 2);
      expect(lines[1].newLineNumber, null);
      expect(lines[2].prefix, '+');
      expect(lines[2].oldLineNumber, null);
      expect(lines[2].newLineNumber, 2);
      expect(lines[3].prefix, ' ');
      expect(lines[3].oldLineNumber, 3);
      expect(lines[3].newLineNumber, 3);
    });
  });
}
