import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoViewImportInCommon extends ImportBoundaryRule {
  NoViewImportInCommon()
      : super(
          code: const LintCode(
            name: 'no_view_import_in_common',
            problemMessage: 'Common layer must not import view layer. '
                'Common code should not depend on UI.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.common;

  @override
  List<AppLayer> get forbiddenTargetLayers => [AppLayer.view];

  @override
  String get suggestion =>
      'Move shared logic out of view or into a lower layer.';
}
