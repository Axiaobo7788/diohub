import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../helpers/path_utils.dart';

class NoDartIoInView extends DartLintRule {
  NoDartIoInView()
      : super(
          code: const LintCode(
            name: 'no_dart_io_in_view',
            problemMessage:
                'View layer must not import dart:io. Use platform-agnostic APIs or move to a lower layer.',
            errorSeverity: ErrorSeverity.WARNING,
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final fileLayer = resolveLayer(resolver.path);
      if (fileLayer != AppLayer.view) return;

      final uri = node.uri.stringValue;
      if (uri == 'dart:io') {
        reporter.atNode(node, code);
      }
    });
  }
}
