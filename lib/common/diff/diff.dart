/// Unified diff parsing and view model.
///
/// Use [parseUnifiedDiff] to parse a patch string, then [buildDiffLines]
/// per hunk to get [DiffLine] lists for the UI.
library;

import 'package:diohub/common/diff/diff.dart' show DiffLine;
import 'package:diohub/common/diff/models.dart' show DiffLine;

export 'diff_config.dart';
export 'diff_view.dart';
export 'models.dart';
export 'parser.dart';
