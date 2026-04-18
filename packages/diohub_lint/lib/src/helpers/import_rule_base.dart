import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'path_utils.dart';

/// Base class for rules that forbid imports from one layer into another.
abstract class ImportBoundaryRule extends DartLintRule {
  const ImportBoundaryRule({required super.code});

  /// The layer this rule applies to (the file must be IN this layer).
  AppLayer get sourceLayer;

  /// The layers that are forbidden to import from.
  List<AppLayer> get forbiddenTargetLayers;

  /// Optional: human-readable suggestion for the fix.
  String get suggestion;

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

      final importLayer = resolveImportLayer(importUri);
      if (forbiddenTargetLayers.contains(importLayer)) {
        reporter.atNode(node, code);
      }
    });
  }
}
