import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoUpwardImportInModels extends ImportBoundaryRule {
  NoUpwardImportInModels()
      : super(
          code: const LintCode(
            name: 'no_upward_import_in_models',
            problemMessage:
                'Models layer must not import view, providers, or services. '
                'Models should be pure data with no upward dependencies.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.models;

  @override
  List<AppLayer> get forbiddenTargetLayers =>
      [AppLayer.view, AppLayer.providers, AppLayer.services];

  @override
  String get suggestion => 'Keep models free of view/provider/service imports.';
}
