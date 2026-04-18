import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/import_rule_base.dart';
import '../helpers/path_utils.dart';

class NoServiceImportInView extends ImportBoundaryRule {
  NoServiceImportInView()
      : super(
          code: const LintCode(
            name: 'no_service_import_in_view',
            problemMessage: 'View layer must not import services directly. '
                'Access service logic through a provider instead.',
            correctionMessage:
                'Create or use an existing provider that wraps this service.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  AppLayer get sourceLayer => AppLayer.view;

  @override
  List<AppLayer> get forbiddenTargetLayers => [AppLayer.services];

  @override
  String get suggestion => 'Use a provider instead.';

  /// Sanctioned pattern: view may import service_extensions for ref.extension.
  static bool _isAllowlisted(String importUri) =>
      importUri.endsWith('services/base/service_extensions.dart');

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final filePath = resolver.path;
      final fileLayer = resolveLayer(filePath);
      if (fileLayer != sourceLayer) return;

      final importUri = node.uri.stringValue;
      if (importUri == null) return;
      if (_isAllowlisted(importUri)) return;

      final importLayer = resolveImportLayer(importUri);
      if (forbiddenTargetLayers.contains(importLayer)) {
        reporter.atNode(node, code);
      }
    });
  }
}
