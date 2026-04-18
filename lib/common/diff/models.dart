import 'package:diohub/common/diff/parser.dart';
import 'package:diohub_models/models/commits/diff_side.dart';

export 'package:diohub_models/models/commits/diff_side.dart';

/// Identity for a diff line (old and new line numbers; either can be null for add-only or remove-only).
typedef DiffLineKey = (int? oldLine, int? newLine);

/// Placeholder for a pending review comment (draft) before submit.
class PendingComment {
  const PendingComment({
    required this.path,
    required this.line,
    required this.side,
    required this.body,
    this.threadId,
  });

  final String path;
  final int line;
  final DiffSide side;
  final String body;
  final String? threadId;
}

/// Payload when user taps a line in a diff view (e.g. to add or open a review thread).
class DiffLineTapDetails {
  const DiffLineTapDetails({
    required this.prefix,
    this.oldLineNumber,
    this.newLineNumber,
  });

  final int? oldLineNumber;
  final int? newLineNumber;
  final String prefix;

  DiffLineKey get key => (oldLineNumber, newLineNumber);
}

/// One row in the diff: prefix (+/-/ ), optional old/new line numbers, content.
class DiffLine {
  const DiffLine({
    required this.prefix,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
  });

  final String prefix;
  final String content;
  final int? oldLineNumber;
  final int? newLineNumber;

  bool get isAddition => prefix == '+';
  bool get isRemoval => prefix == '-';
  bool get isContext => prefix == ' ' || prefix.isEmpty;
}

/// Builds a list of [DiffLine] for one hunk from [info] and [rawLines].
///
/// All line-number and prefix logic lives here; UI only displays the list.
List<DiffLine> buildDiffLines(
  final DiffHunkInfo info,
  final List<String> rawLines,
) {
  final List<DiffLine> result = <DiffLine>[];
  int oldLine = info.removeStart;
  int newLine = info.addStart;

  for (final String raw in rawLines) {
    final String prefix = raw.isEmpty ? ' ' : raw[0];
    final String content = raw.length > 1 ? raw.substring(1) : '';

    switch (prefix) {
      case '-':
        result.add(
          DiffLine(prefix: '-', content: content, oldLineNumber: oldLine++),
        );
      case '+':
        result.add(
          DiffLine(prefix: '+', content: content, newLineNumber: newLine++),
        );
      case ' ':
        result.add(
          DiffLine(
            prefix: ' ',
            content: content,
            oldLineNumber: oldLine++,
            newLineNumber: newLine++,
          ),
        );
      default:
        // Meta-lines (e.g. \ No newline at end of file) get no line numbers.
        result.add(DiffLine(prefix: prefix, content: content));
    }
  }

  return result;
}
