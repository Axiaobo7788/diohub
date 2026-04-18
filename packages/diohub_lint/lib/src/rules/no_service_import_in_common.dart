import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoServiceImportInCommon extends ImportBoundaryRule {
  NoServiceImportInCommon()
      : super(
          code: const LintCode(
            name: 'no_service_import_in_common',
            problemMessage: 'Common layer must not import services directly. '
                'Use provider callbacks or pass dependencies from view.',
            correctionMessage:
                'Access service logic through a provider or callback.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.common;

  @override
  List<AppLayer> get forbiddenTargetLayers => [AppLayer.services];

  @override
  String get suggestion => 'Use a provider or callback instead.';
}
