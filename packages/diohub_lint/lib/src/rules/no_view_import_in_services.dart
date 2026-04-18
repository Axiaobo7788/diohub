import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoViewImportInServices extends ImportBoundaryRule {
  NoViewImportInServices()
      : super(
          code: const LintCode(
            name: 'no_view_import_in_services',
            problemMessage: 'Services layer must not import view or providers. '
                'Services should only depend on lower layers.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.services;

  @override
  List<AppLayer> get forbiddenTargetLayers =>
      [AppLayer.view, AppLayer.providers];

  @override
  String get suggestion => 'Remove view/provider imports from services.';
}
