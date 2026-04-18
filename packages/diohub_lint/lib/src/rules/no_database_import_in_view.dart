import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoDatabaseImportInView extends ImportBoundaryRule {
  NoDatabaseImportInView()
      : super(
          code: const LintCode(
            name: 'no_database_import_in_view',
            problemMessage: 'View layer must not import database directly. '
                'Access data through a provider instead.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.view;

  @override
  List<AppLayer> get forbiddenTargetLayers => [AppLayer.database];

  @override
  String get suggestion => 'Use a provider instead.';
}
