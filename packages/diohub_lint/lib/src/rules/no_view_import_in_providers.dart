import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoViewImportInProviders extends ImportBoundaryRule {
  NoViewImportInProviders()
      : super(
          code: const LintCode(
            name: 'no_view_import_in_providers',
            problemMessage: 'Providers layer must not import view layer. '
                'Providers should not depend on UI.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.providers;

  @override
  List<AppLayer> get forbiddenTargetLayers => [AppLayer.view];

  @override
  String get suggestion => 'Keep providers free of view imports.';
}
